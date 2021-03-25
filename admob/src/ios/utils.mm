#if defined(DM_PLATFORM_IOS)

#import "utils.h"

@implementation LuaScriptListener
@end

@implementation LuaTask
@end

@implementation Utils

static lua_State *_L;
static NSMutableArray *tasks = [[NSMutableArray alloc] init];

+(id)alloc {
	[NSException raise:@"Cannot be instantiated!" format:@"Static class 'Utils' cannot be instantiated!"];
	return nil;
}

+(void)check_arg_count:(lua_State*)L count:(int)count_exact {
	int count = lua_gettop(L);
	[Utils assert:count == count_exact message:[NSString stringWithFormat:@"This function requires %d arguments. Got %d.", count_exact, count]];
}

+(void)check_arg_count:(lua_State*)L from:(int)count_from to:(int)count_to {
	int count = lua_gettop(L);
	[Utils assert:count >= count_from && count <= count_to message:[NSString stringWithFormat:@"This function requires from %d to %d arguments. Got %d.", count_from, count_to, count]];
}

+(void)assert:(bool)condition message:(NSString*)message {
	if (!condition) {
		luaL_error(_L, "%s", [message UTF8String]);
	}
}

+(int)new_ref:(lua_State*)L {
	return luaL_ref(L, LUA_REGISTRYINDEX);
}

+(int)new_ref:(lua_State*)L index:(int)index {
	lua_pushvalue(L, index);
	return luaL_ref(L, LUA_REGISTRYINDEX);
}

+(void)delete_ref_if_not_nil:(int)ref {
	if ((ref != LUA_REFNIL) && (ref != LUA_NOREF)) {
		luaL_unref(_L, LUA_REGISTRYINDEX, ref);
	}
}

+(void)put:(NSMutableDictionary*)hastable key:(NSString*)key value:(NSObject*)value {
	if (value != nil) {
		[hastable setObject:value forKey:key];
	}
}

+(NSMutableDictionary*)new_event:(NSString*)name {
	return [NSMutableDictionary dictionaryWithDictionary:@{@"name" : name}];
}

+(void)dispatch_event:(LuaScriptListener*)script_listener event:(NSMutableDictionary*)event {
	[self dispatch_event:script_listener event:event delete_ref:false];
}

+(void)dispatch_event:(LuaScriptListener*)script_listener event:(NSMutableDictionary*)event delete_ref:(bool)delete_ref {
	if ((script_listener.listener == LUA_REFNIL) || (script_listener.listener == LUA_NOREF) || (script_listener.script_instance == LUA_REFNIL) || (script_listener.script_instance == LUA_NOREF)) {
		return;
	}
	LuaTask *task = [[LuaTask alloc] init];
	task.script_listener = script_listener;
	task.event = [NSDictionary dictionaryWithDictionary:event];
	task.delete_ref = delete_ref;
	[tasks addObject:task];
}

+(void)set_c_function_as_field:(lua_State*)L name:(const char*)name function:(lua_CFunction)function {
	lua_pushcfunction(L, function);
	lua_setfield(L, -2, name);
}

+(void)set_c_closure_as_field:(lua_State*)L name:(const char*)name function:(lua_CFunction)function upvalue:(void*)upvalue {
	lua_pushlightuserdata(L, upvalue);
	lua_pushcclosure(L, function, 1);
	lua_setfield(L, -2, name);
}

+(void)push_value:(lua_State*)L value:(NSObject*)object {
	if (object == nil) {
		lua_pushnil(L);
	} else if ([object isKindOfClass:[NSString class]]) {
		lua_pushstring(L, [(NSString*)object UTF8String]);
	} else if ([object isKindOfClass:[NSNumber class]]) {
		NSNumber *number = (NSNumber*)object;
		const char *cType = [number objCType];
		if ([number isKindOfClass:NSClassFromString(@"__NSCFBoolean")]) {
			lua_pushboolean(L, [number boolValue]);
		} else if ((strcmp(cType, @encode(int))) == 0) {
			lua_pushinteger(L, [number intValue]);
		} else if ((strcmp(cType, @encode(long))) == 0) {
			lua_pushnumber(L, [number doubleValue]);
		} else if ((strcmp(cType, @encode(long long))) == 0) {
			lua_pushnumber(L, [number doubleValue]);
		} else if ((strcmp(cType, @encode(float))) == 0) {
			lua_pushnumber(L, [number doubleValue]);
		} else if ((strcmp(cType, @encode(double))) == 0) {
			lua_pushnumber(L, [number doubleValue]);
		} else if ((strcmp(cType, @encode(BOOL))) == 0) {
			lua_pushboolean(L, [number boolValue]);
		} else {
			luaL_error(L, "Utils.push_value(): failed to push an NSNumber value. C type: %s", cType);
		}
	} else if([object isKindOfClass:[NSData class]]) {
		lua_pushstring(L, (const char*)[(NSData*)object bytes]);
	} else if ([object isKindOfClass:[LuaLightuserdata class]]) {
		lua_pushlightuserdata(L, [(LuaLightuserdata*)object get_pointer]);
	} else if ([object conformsToProtocol:@protocol(LuaPushable)]) {
		[(NSObject <LuaPushable>*)object push:L];
	} else if ([object isKindOfClass:[NSArray class]]) {
		NSMutableDictionary* hashtable = [NSMutableDictionary dictionary];
		int i = 1;
		for (id o in (NSArray*)object) {
			[hashtable setObject:o forKey:@(i)];
		}
		[self push_hashtable:L hashtable:hashtable];
	} else if ([object isKindOfClass:[NSDictionary class]]) {
		[self push_hashtable:L hashtable:(NSDictionary*)object];
	} else {
		luaL_error(L, "Utils.pushValue(): failed to push an object: %s", [[object description] UTF8String]);
	}
}

+(void)push_hashtable:(lua_State*)L hashtable:(NSDictionary*)hashtable {
	if (hashtable == nil) {
		lua_newtable(L);
	} else {
		lua_newtable(L);
		int tableIndex = lua_gettop(L);
		for (id key in hashtable) {
			[self push_value:L value:key];
			[self push_value:L value:[hashtable objectForKey:key]];
			lua_settable(L, tableIndex);
		}
	}
}

+(void)execute_tasks:(lua_State*)L {
	_L = L;
	while (tasks.count > 0) {
		LuaTask *task = tasks.firstObject;
		lua_rawgeti(L, LUA_REGISTRYINDEX, task.script_listener.listener);
		lua_rawgeti(L, LUA_REGISTRYINDEX, task.script_listener.script_instance);
		dmScript::SetInstance(L);
		[self push_hashtable:L hashtable:task.event];
		lua_call(L, 1, 0);
		if (task.delete_ref) {
			luaL_unref(L, LUA_REGISTRYINDEX, task.script_listener.listener);
			luaL_unref(L, LUA_REGISTRYINDEX, task.script_listener.script_instance);
		}
		[tasks removeObjectAtIndex:0];
	}
}

@end

@implementation LuaLightuserdata {
	void *lightuserdata;
}

-(instancetype)init:(void*)pointer {
	self = [super init];
	lightuserdata = pointer;
	return self;
}

-(void*)get_pointer {
	return lightuserdata;
}

@end

@implementation Table {
	lua_State *_L;
	int _index;
	NSMutableDictionary *_hashtable;
	Scheme *_scheme;
}
-(id)init:(lua_State*)L index:(int)index {
	self = [super init];
	_L = L;
	_index = index;
	return self;
}

-(void)parse:(Scheme*)scheme {
	_scheme = scheme;
	_hashtable = [self to_hashtable:_L index:_index path_list:nil];
}


-(bool)get_boolean:(NSString*)path default:(bool)default_value {
	NSNumber *result = [self get_boolean:path];
	if (result != nil) {
		return [result boolValue];
	} else {
		return default_value;
	}
}

-(NSNumber*)get_boolean:(NSString*)path {
	id object = [self get:path];
	if (object != nil && [object isKindOfClass:[NSNumber class]] && (((strcmp([object objCType], @encode(BOOL))) == 0) || [object isKindOfClass:NSClassFromString(@"__NSCFBoolean")])) {
		return (NSNumber*)object;
	} else {
		return nil;
	}
}

-(NSString*)get_string:(NSString*)path default:(NSString*)default_value {
	NSString* result = [self get_string:path];
	if (result != nil) {
		return result;
	} else {
		return default_value;
	}
}

-(NSString*)get_string:(NSString*)path {
	id object = [self get:path];
	if (object != nil && [object isKindOfClass:[NSString class]]) {
		return (NSString*)object;
	} else {
		return nil;
	}
}

-(NSString*)get_string_not_null:(NSString*)path {
	NSString *result = [self get_string:path];
	[Utils assert:result != nil message:[NSString stringWithFormat:@"Table's property '%@' is not a string.", path]];
	return result;
}

-(double)get_double:(NSString*)path default:(double)default_value {
	NSNumber *result = [self get_double:path];
	if (result != nil) {
		return [result doubleValue];
	} else {
		return default_value;
	}
}

-(NSNumber*)get_double:(NSString*)path {
	id object = [self get:path];
	if (object != nil && [object isKindOfClass:[NSNumber class]]) {
		return (NSNumber*)object;
	} else {
		return nil;
	}
}

-(double)get_double_not_null:(NSString*)path {
	NSNumber *result = [self get_double:path];
	[Utils assert:result != nil message:[NSString stringWithFormat:@"Table's property '%@' is not a number.", path]];
	return [result doubleValue];
}

-(int)get_integer:(NSString*)path default:(int)default_value {
	NSNumber *result = [self get_integer:path];
	if (result != nil) {
		return [result intValue];
	} else {
		return default_value;
	}
}

-(NSNumber*)get_integer:(NSString*)path {
	id object = [self get:path];
	if (object != nil && [object isKindOfClass:[NSNumber class]]) {
		return (NSNumber*)object;
	} else {
		return nil;
	}
}

-(int)get_integer_not_null:(NSString*)path {
	NSNumber *result = [self get_integer:path];
	[Utils assert:result != nil message:[NSString stringWithFormat:@"Table's property '%@' is not a number.", path]];
	return [result intValue];
}

-(long)get_long:(NSString*)path default:(long)default_value {
	NSNumber *result = [self get_long:path];
	if (result != nil) {
		return [result longValue];
	} else {
		return default_value;
	}
}

-(NSNumber*)get_long:(NSString*)path {
	id object = [self get:path];
	if (object != nil && [object isKindOfClass:[NSNumber class]]) {
		return (NSNumber*)object;
	} else {
		return nil;
	}
}

-(long)get_long_not_null:(NSString*)path {
	NSNumber *result = [self get_long:path];
	[Utils assert:result != nil message:[NSString stringWithFormat:@"Table's property '%@' is not a number.", path]];
	return [result longValue];
}

-(NSData*)get_byte_array:(NSString*)path default:(NSData*)default_value {
	NSData *result = [self get_byte_array:path];
	if (result != nil) {
		return result;
	} else {
		return default_value;
	}
}

-(NSData*)get_byte_array:(NSString*)path {
	id object = [self get:path];
	if (object != nil && [object isKindOfClass:[NSData class]]) {
		return (NSData*)object;
	} else {
		return nil;
	}
}

-(NSData*)get_byte_array_not_null:(NSString*)path {
	NSData *result = [self get_byte_array:path];
	[Utils assert:result != nil message:[NSString stringWithFormat:@"Table's property '%@' is not a byte array.", path]];
	return result;
}

-(LuaLightuserdata*)get_lightuserdata:(NSString*)path default:(LuaLightuserdata*)default_value {
	LuaLightuserdata *result = [self get_lightuserdata:path];
	if (result != nil) {
		return result;
	} else {
		return default_value;
	}
}

-(LuaLightuserdata*)get_lightuserdata:(NSString*)path {
	id object = [self get:path];
	if (object != nil && [object isKindOfClass:[LuaLightuserdata class]]) {
		return (LuaLightuserdata*)object;
	} else {
		return nil;
	}
}

-(LuaLightuserdata*)get_lightuserdata_not_null:(NSString*)path {
	LuaLightuserdata *result = [self get_lightuserdata:path];
	[Utils assert:result != nil message:[NSString stringWithFormat:@"Table's property '%@' is not a lightuserdata.", path]];
	return result;
}

-(int)get_function:(NSString*)path default:(int)default_value {
	NSNumber *result = [self get_function:path];
	if (result != nil) {
		return [result intValue];
	} else {
		return default_value;
	}
}

-(NSNumber*)get_function:(NSString*)path {
	id object = [self get:path];
	if (object != nil && [object isKindOfClass:[NSNumber class]]) {
		return (NSNumber*)object;
	} else {
		return nil;
	}
}

-(NSDictionary*)get_table:(NSString*)path default:(NSDictionary*)default_value {
    NSDictionary *result = [self get_table:path];
    if (result != nil) {
        return result;
    } else {
        return default_value;
    }
}

-(NSDictionary*)get_table:(NSString*)path {
	id object = [self get:path];
	if (object != nil && [object isKindOfClass:[NSMutableDictionary class]]) {
		return [NSDictionary dictionaryWithDictionary:(NSMutableDictionary*)[self get:path]];
	} else {
		return nil;
	}
}

-(id)get:(NSString*)path {
	if ([path isEqualToString:@""]) {
		return _hashtable;
	} else {
		id current = nil;
		for (NSString *p in [path componentsSeparatedByString:@"."]) {
			if (current == nil) {
				current = [_hashtable objectForKey:p];
			} else if ([current isKindOfClass:[NSMutableDictionary class]]) {
				NSMutableDictionary* h = (NSMutableDictionary*)current;
				current = [h objectForKey:p];
			}
		}
		return current;
	}
}

-(id)to_value:(lua_State*)L index:(int)index path_list:(NSMutableArray*)path_list {
	if ((index < 0) && (index > LUA_REGISTRYINDEX)) {
		index = lua_gettop(L) + index + 1;
	}
	id o = nil;
	if (_scheme == nil) {
		switch (lua_type(L, index)) {
			case LUA_TSTRING:
				o = @(lua_tostring(L, index));
				break;
			case LUA_TNUMBER:
				o = @(lua_tonumber(L, index));
				break;
			case LUA_TBOOLEAN:
				o = [NSNumber numberWithBool:lua_toboolean(L, index)];
				break;
			case LUA_TLIGHTUSERDATA:
				o = [[LuaLightuserdata alloc] init:lua_touserdata(L, index)];
				break;
			case LUA_TTABLE:
				o = [self to_hashtable:L index:index path_list:path_list];
				break;
		}
	} else {
		NSString *path = [path_list componentsJoinedByString:@"."];
		NSObject *rule = [_scheme get:path];
		if (!rule && path_list.count > 1) {
			path = [[[path_list subarrayWithRange:NSMakeRange(0, path_list.count - 1)] componentsJoinedByString:@"."] stringByAppendingString:@".#"];
			rule = [_scheme get:path];
		}
		switch (lua_type(L, index)) {
			case LUA_TSTRING:
				if ([rule isKindOfClass:[NSNumber class]] && [(NSNumber*)rule intValue] == LUA_TSTRING) {
					o = @(lua_tostring(L, index));
				} else if ([rule isKindOfClass:[NSNumber class]] && [(NSNumber*)rule intValue] == _scheme.LuaTypeNumeric) {
					NSString* value = @(lua_tostring(L, index));
					bool isNumeric = [[@([value doubleValue]) stringValue] isEqualToString:value] || [[@([value intValue]) stringValue] isEqualToString:value];
					if (isNumeric) {
						o = value;
					}
				} else if ([rule isKindOfClass:[NSNumber class]] && [(NSNumber*)rule intValue] == _scheme.LuaTypeByteArray) {
					//o = L.toByteArray(index);
				}
				break;
			case LUA_TNUMBER:
				if ([rule isKindOfClass:[NSNumber class]] && (([(NSNumber*)rule intValue] == LUA_TNUMBER) || ([(NSNumber*)rule intValue] == _scheme.LuaTypeNumeric))) {
					o = @(lua_tonumber(L, index));
				}
				break;
			case LUA_TBOOLEAN:
				if ([rule isKindOfClass:[NSNumber class]] && [(NSNumber*)rule intValue] == LUA_TBOOLEAN) {
					o = [NSNumber numberWithBool:lua_toboolean(L, index)];
				}
				break;
			case LUA_TLIGHTUSERDATA:
				if ([rule isKindOfClass:[NSNumber class]] && [(NSNumber*)rule intValue] == LUA_TLIGHTUSERDATA) {
					o = [[LuaLightuserdata alloc] init:lua_touserdata(L, index)];
				}
				break;
			case LUA_TUSERDATA:
				if ([rule isKindOfClass:[NSNumber class]] && [(NSNumber*)rule intValue] == LUA_TUSERDATA) {
					o = [[LuaLightuserdata alloc] init:lua_touserdata(L, index)];
				}
				break;
			case LUA_TFUNCTION:
				if ([rule isKindOfClass:[NSNumber class]] && [(NSNumber*)rule intValue] == LUA_TFUNCTION) {
					o = @([Utils new_ref:L index:index]);
				}
				break;
			case LUA_TTABLE:
				if ([rule isKindOfClass:[NSNumber class]] && [(NSNumber*)rule intValue] == LUA_TTABLE) {
					o = [self to_hashtable:L index:index path_list:path_list];
				}
		}
	}
	return o;
}

-(NSMutableDictionary*)to_hashtable:(lua_State*)L index:(int)index path_list:(NSMutableArray*)path_list {
	if ((index < 0) && (index > LUA_REGISTRYINDEX)) {
		index = lua_gettop(L) + index + 1;
	}

	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	luaL_checktype(L, index, LUA_TTABLE);
	lua_pushnil(L);

	NSMutableArray *path = path_list != nil ? path_list : [NSMutableArray array];
	for (; lua_next(L, index); lua_pop(L, 1)) {
		id key = nil;
		if (lua_type(L, -2) == LUA_TSTRING) {
			key = @(lua_tostring(L, -2));
			[path addObject:(NSString*)key];
		} else if (lua_type(L, -2) == LUA_TNUMBER) {
			key = @(lua_tointeger(L, -2));
			[path addObject:@"#"];
		}
		if (key != nil) {
			id value = [self to_value:L index:-1 path_list:path];
			if (value != nil) {
				[result setObject:value forKey:key];
			}
			[path removeObjectAtIndex:[path count] - 1];
		}
	}

	return result;
}
@end

@implementation Scheme {
	NSMutableDictionary* scheme;
}

-(id)init {
	self = [super init];
	scheme = [NSMutableDictionary dictionary];
	_LuaTypeNumeric = 1000;
	_LuaTypeByteArray = 1001;
	return self;
}

-(void)string:(NSString*)path {
	[scheme setObject:@LUA_TSTRING forKey:path];
}

-(void)number:(NSString*)path {
	[scheme setObject:@LUA_TNUMBER forKey:path];
}

-(void)boolean:(NSString*)path {
	[scheme setObject:@LUA_TBOOLEAN forKey:path];
}

-(void)table:(NSString*)path {
	[scheme setObject:@LUA_TTABLE forKey:path];
}

-(void)function:(NSString*)path {
	[scheme setObject:@LUA_TFUNCTION forKey:path];
}

-(void)lightuserdata:(NSString*)path {
	[scheme setObject:@LUA_TLIGHTUSERDATA forKey:path];
}

-(void)userdata:(NSString*)path {
	[scheme setObject:@LUA_TUSERDATA forKey:path];
}

-(void)numeric:(NSString*)path {
	[scheme setObject:@(_LuaTypeNumeric) forKey:path];
}

-(void)byteArray:(NSString*)path {
	[scheme setObject:@(_LuaTypeByteArray) forKey:path];
}

-(id)get:(NSString*)path {
	return [scheme objectForKey:path];
}

@end

#endif
