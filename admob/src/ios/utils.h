#ifndef utils_h
#define utils_h

#include "../extension.h"
#import <Foundation/Foundation.h>

#define LuaScriptListener FUNCTION_NAME_EXPANDED(EXTENSION_NAME, LuaScriptListener)
#define LuaTask FUNCTION_NAME_EXPANDED(EXTENSION_NAME, LuaTask)
#define LuaLightuserdata FUNCTION_NAME_EXPANDED(EXTENSION_NAME, LuaLightuserdata)
#define Utils FUNCTION_NAME_EXPANDED(EXTENSION_NAME, Utils)
#define Scheme FUNCTION_NAME_EXPANDED(EXTENSION_NAME, Scheme)
#define Table FUNCTION_NAME_EXPANDED(EXTENSION_NAME, Table)
#define LuaPushable FUNCTION_NAME_EXPANDED(EXTENSION_NAME, LuaPushable)

@interface LuaScriptListener : NSObject
@property(nonatomic) int listener;
@property(nonatomic) int script_instance;
@end

@interface LuaTask : NSObject
@property(nonatomic,retain) LuaScriptListener *script_listener;
@property(nonatomic,retain) NSDictionary *event;
@property(nonatomic) bool delete_ref;
@end

@interface LuaLightuserdata : NSObject
-(instancetype)init:(void*)pointer;
-(void*)get_pointer;
@end

@interface Utils : NSObject

+(void)check_arg_count:(lua_State*)L count:(int)count_exact;
+(void)check_arg_count:(lua_State*)L from:(int)count_from to:(int)count_to;
+(int)new_ref:(lua_State*)L;
+(int)new_ref:(lua_State*)L index:(int)index;
+(void)delete_ref_if_not_nil:(int)ref;
+(void)put:(NSMutableDictionary*)hastable key:(NSString*)key value:(NSObject*)value;
+(NSMutableDictionary*)new_event:(NSString*)name;
+(void)dispatch_event:(LuaScriptListener*)script_listener event:(NSMutableDictionary*)event;
+(void)dispatch_event:(LuaScriptListener*)script_listener event:(NSMutableDictionary*)event delete_ref:(bool)delete_ref;
+(void)set_c_function_as_field:(lua_State*)L name:(const char*)name function:(lua_CFunction)function;
+(void)set_c_closure_as_field:(lua_State*)L name:(const char*)name function:(lua_CFunction)function upvalue:(void*)upvalue;
+(void)push_value:(lua_State*)L value:(NSObject*)object;
+(void)push_hashtable:(lua_State*)L hashtable:(NSDictionary*)hashtable;
+(void)execute_tasks:(lua_State*)L;

@end

@interface Scheme : NSObject
@property(nonatomic, readonly) int LuaTypeNumeric;
@property(nonatomic, readonly) int LuaTypeByteArray;

-(void)string:(NSString*)path;
-(void)number:(NSString*)path;
-(void)boolean:(NSString*)path;
-(void)table:(NSString*)path;
-(void)function:(NSString*)path;
-(void)lightuserdata:(NSString*)path;
-(void)userdata:(NSString*)path;
-(void)numeric:(NSString*)path;
-(void)byteArray:(NSString*)path;
-(id)get:(NSString*)path;

@end

@interface Table : NSObject

-(id)init:(lua_State*)L index:(int)index;
-(void)parse:(Scheme*)scheme;
-(bool)get_boolean:(NSString*)path default:(bool)default_value;
-(NSNumber*)get_boolean:(NSString*)path;
-(NSString*)get_string:(NSString*)path default:(NSString*)default_value;
-(NSString*)get_string:(NSString*)path;
-(NSString*)get_string_not_null:(NSString*)path;
-(double)get_double:(NSString*)path default:(double)default_value;
-(NSNumber*)get_double:(NSString*)path;
-(double)get_double_not_null:(NSString*)path;
-(int)get_integer:(NSString*)path default:(int)default_value;
-(NSNumber*)get_integer:(NSString*)path;
-(int)get_integer_not_null:(NSString*)path;
-(long)get_long:(NSString*)path default:(long)default_value;
-(NSNumber*)get_long:(NSString*)path;
-(long)get_long_not_null:(NSString*)path;
-(NSData*)get_byte_array:(NSString*)path default:(NSData*)default_value;
-(NSData*)get_byte_array:(NSString*)path;
-(NSData*)get_byte_array_not_null:(NSString*)path;
-(LuaLightuserdata*)get_lightuserdata:(NSString*)path default:(LuaLightuserdata*)default_value;
-(LuaLightuserdata*)get_lightuserdata:(NSString*)path;
-(LuaLightuserdata*)get_lightuserdata_not_null:(NSString*)pat;
-(int)get_function:(NSString*)path default:(int)default_value;
-(NSNumber*)get_function:(NSString*)path;
-(NSDictionary*)get_table:(NSString*)path default:(NSDictionary*)default_value;
-(NSDictionary*)get_table:(NSString*)path;

@end

@protocol LuaPushable
-(void)push:(lua_State*)L;
@end

#endif
