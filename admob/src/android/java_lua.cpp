#if defined(DM_PLATFORM_ANDROID)

#include "java_lua.h"

extern "C" {
	JNIEXPORT void JNICALL JAVA_LUA_DMSCRIPT_GETINSTANCE(JNIEnv *env, jobject obj, jlong L) {
		dmScript::GetInstance((lua_State*)L);
	}

	JNIEXPORT void JNICALL JAVA_LUA_DMSCRIPT_SETINSTANCE(JNIEnv *env, jobject obj, jlong L) {
		dmScript::SetInstance((lua_State*)L);
	}

	JNIEXPORT jint JNICALL JAVA_LUA_REGISTRYINDEX(JNIEnv *env, jobject obj, jlong L) {
		return LUA_REGISTRYINDEX;
	}

	JNIEXPORT void JNICALL JAVA_LUA_CALL(JNIEnv *env, jobject obj, jlong L, jint nargs, jint nresults) {
		lua_call((lua_State*)L, nargs, nresults);
	}

	JNIEXPORT void JNICALL JAVA_LUA_ERROR(JNIEnv *env, jobject obj, jlong L, jstring s) {
		// TODO
		luaL_error((lua_State*)L, "");
	}

	JNIEXPORT void JNICALL JAVA_LUA_PUSHBOOLEAN(JNIEnv *env, jobject obj, jlong L, jboolean b) {
		lua_pushboolean((lua_State*)L, b);
	}

	JNIEXPORT void JNICALL JAVA_LUA_PUSHINTEGER(JNIEnv *env, jobject obj, jlong L, jint n) {
		lua_pushinteger((lua_State*)L, n);
	}

	JNIEXPORT void JNICALL JAVA_LUA_PUSHNIL(JNIEnv *env, jobject obj, jlong L) {
		lua_pushnil((lua_State*)L);
	}

	JNIEXPORT void JNICALL JAVA_LUA_PUSHNUMBER(JNIEnv *env, jobject obj, jlong L, jdouble n) {
		lua_pushnumber((lua_State*)L, n);
	}

	JNIEXPORT void JNICALL JAVA_LUA_PUSHSTRING(JNIEnv *env, jobject obj, jlong L, jstring s) {
		const char *c_str = env->GetStringUTFChars(s, 0);
		lua_pushstring((lua_State*)L, c_str);
		env->ReleaseStringUTFChars(s, c_str);
	}

	JNIEXPORT jint JNICALL JAVA_LUA_GETTOP(JNIEnv *env, jobject obj, jlong L) {
		return lua_gettop((lua_State*)L);
	}
	JNIEXPORT void JNICALL JAVA_LUA_POP(JNIEnv *env, jobject obj, jlong L, jint n) {
		lua_pop((lua_State*)L, n);
	}

	JNIEXPORT void JNICALL JAVA_LUA_PUSHVALUE(JNIEnv *env, jobject obj, jlong L, jint index) {
		lua_pushvalue((lua_State*)L, index);
	}

	JNIEXPORT void JNICALL JAVA_LUA_NEWTABLE(JNIEnv *env, jobject obj, jlong L) {
		lua_newtable((lua_State*)L);
	}
	
	JNIEXPORT jint JNICALL JAVA_LUA_NEXT(JNIEnv *env, jobject obj, jlong L, jint index) {
		return lua_next((lua_State*)L, index);
	}
	
	JNIEXPORT void JNICALL JAVA_LUA_RAWGETI(JNIEnv *env, jobject obj, jlong L, jint index, jint n) {
		lua_rawgeti((lua_State*)L, index, n);
	}
	
	JNIEXPORT jboolean JNICALL JAVA_LUA_TOBOOLEAN(JNIEnv *env, jobject obj, jlong L, jint index) {
		return (bool)lua_toboolean((lua_State*)L, index);
	}
	
	JNIEXPORT jdouble JNICALL JAVA_LUA_TONUMBER(JNIEnv *env, jobject obj, jlong L, jint index) {
		return lua_tonumber((lua_State*)L, index);
	}
	
	JNIEXPORT jlong JNICALL JAVA_LUA_TOPOINTER(JNIEnv *env, jobject obj, jlong L, jint index) {
		return (jlong)lua_topointer((lua_State*)L, index);
	}
	
	JNIEXPORT jstring JNICALL JAVA_LUA_TOSTRING(JNIEnv *env, jobject obj, jlong L, jint index) {
		return env->NewStringUTF(lua_tostring((lua_State*)L, index));
	}
	
	JNIEXPORT jint JNICALL JAVA_LUA_TYPE(JNIEnv *env, jobject obj, jlong L, jint index) {
		return lua_type((lua_State*)L, index);
	}
	
	JNIEXPORT void JNICALL JAVA_LUA_SETTABLE(JNIEnv *env, jobject obj, jlong L, jint index) {
		lua_settable((lua_State*)L, index);
	}
	
	JNIEXPORT jint JNICALL JAVA_LUA_REF(JNIEnv *env, jobject obj, jlong L, jint index) {
		return luaL_ref((lua_State*)L, index);
	}
	
	JNIEXPORT void JNICALL JAVA_LUA_UNREF(JNIEnv *env, jobject obj, jlong L, jint index, jint ref) {
		luaL_unref((lua_State*)L, index, ref);
	}
}

#endif