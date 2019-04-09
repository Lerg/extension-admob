#include <jni.h>

#include "../extension.h"

// Each extension must have unique exported symbols. Construct function names based on the extension name.
#define JAVA_FUNCTION_NAME(extension_name, function_name) Java_extension_ ## extension_name ## _Lua_ ## function_name
#define JAVA_FUNCTION_NAME_EXPANDED(extension_name, function_name) JAVA_FUNCTION_NAME(extension_name, function_name)

#define JAVA_LUA_DMSCRIPT_GETINSTANCE JAVA_FUNCTION_NAME_EXPANDED(EXTENSION_NAME, lua_1dmscript_1getinstance)
#define JAVA_LUA_DMSCRIPT_SETINSTANCE JAVA_FUNCTION_NAME_EXPANDED(EXTENSION_NAME, lua_1dmscript_1setinstance)
#define JAVA_LUA_REGISTRYINDEX JAVA_FUNCTION_NAME_EXPANDED(EXTENSION_NAME, lua_1registryindex)
#define JAVA_LUA_CALL JAVA_FUNCTION_NAME_EXPANDED(EXTENSION_NAME, lua_1call)
#define JAVA_LUA_ERROR JAVA_FUNCTION_NAME_EXPANDED(EXTENSION_NAME, lua_1error)
#define JAVA_LUA_PUSHBOOLEAN JAVA_FUNCTION_NAME_EXPANDED(EXTENSION_NAME, lua_1pushboolean)
#define JAVA_LUA_PUSHINTEGER JAVA_FUNCTION_NAME_EXPANDED(EXTENSION_NAME, lua_1pushinteger)
#define JAVA_LUA_PUSHNIL JAVA_FUNCTION_NAME_EXPANDED(EXTENSION_NAME, lua_1pushnil)
#define JAVA_LUA_PUSHNUMBER JAVA_FUNCTION_NAME_EXPANDED(EXTENSION_NAME, lua_1pushnumber)
#define JAVA_LUA_PUSHSTRING JAVA_FUNCTION_NAME_EXPANDED(EXTENSION_NAME, lua_1pushstring)
#define JAVA_LUA_GETTOP JAVA_FUNCTION_NAME_EXPANDED(EXTENSION_NAME, lua_1gettop)
#define JAVA_LUA_POP JAVA_FUNCTION_NAME_EXPANDED(EXTENSION_NAME, lua_1pop)
#define JAVA_LUA_PUSHVALUE JAVA_FUNCTION_NAME_EXPANDED(EXTENSION_NAME, lua_1pushvalue)
#define JAVA_LUA_NEWTABLE JAVA_FUNCTION_NAME_EXPANDED(EXTENSION_NAME, lua_1newtable)
#define JAVA_LUA_NEXT JAVA_FUNCTION_NAME_EXPANDED(EXTENSION_NAME, lua_1next)
#define JAVA_LUA_RAWGETI JAVA_FUNCTION_NAME_EXPANDED(EXTENSION_NAME, lua_1rawgeti)
#define JAVA_LUA_TOBOOLEAN JAVA_FUNCTION_NAME_EXPANDED(EXTENSION_NAME, lua_1toboolean)
#define JAVA_LUA_TONUMBER JAVA_FUNCTION_NAME_EXPANDED(EXTENSION_NAME, lua_1tonumber)
#define JAVA_LUA_TOPOINTER JAVA_FUNCTION_NAME_EXPANDED(EXTENSION_NAME, lua_1topointer)
#define JAVA_LUA_TOSTRING JAVA_FUNCTION_NAME_EXPANDED(EXTENSION_NAME, lua_1tostring)
#define JAVA_LUA_TYPE JAVA_FUNCTION_NAME_EXPANDED(EXTENSION_NAME, lua_1type)
#define JAVA_LUA_SETTABLE JAVA_FUNCTION_NAME_EXPANDED(EXTENSION_NAME, lua_1settable)
#define JAVA_LUA_REF JAVA_FUNCTION_NAME_EXPANDED(EXTENSION_NAME, lua_1ref)
#define JAVA_LUA_UNREF JAVA_FUNCTION_NAME_EXPANDED(EXTENSION_NAME, lua_1unref)

extern "C" {
	void JNICALL JAVA_LUA_DMSCRIPT_GETINSTANCE(JNIEnv *env, jobject obj, jlong L);
	void JNICALL JAVA_LUA_DMSCRIPT_SETINSTANCE(JNIEnv *env, jobject obj, jlong L);
	jint JNICALL JAVA_LUA_REGISTRYINDEX(JNIEnv *env, jobject obj, jlong L);
	void JNICALL JAVA_LUA_CALL(JNIEnv *env, jobject obj, jlong L, jint nargs, jint nresults);
	void JNICALL JAVA_LUA_ERROR(JNIEnv *env, jobject obj, jlong L, jstring s);
	void JNICALL JAVA_LUA_PUSHBOOLEAN(JNIEnv *env, jobject obj, jlong L, jboolean b);
	void JNICALL JAVA_LUA_PUSHINTEGER(JNIEnv *env, jobject obj, jlong L, jint n);
	void JNICALL JAVA_LUA_PUSHNIL(JNIEnv *env, jobject obj, jlong L);
	void JNICALL JAVA_LUA_PUSHNUMBER(JNIEnv *env, jobject obj, jlong L, jdouble n);
	void JNICALL JAVA_LUA_PUSHSTRING(JNIEnv *env, jobject obj, jlong L, jstring s);
	jint JNICALL JAVA_LUA_GETTOP(JNIEnv *env, jobject obj, jlong L);
	void JNICALL JAVA_LUA_POP(JNIEnv *env, jobject obj, jlong L, jint n);
	void JNICALL JAVA_LUA_PUSHVALUE(JNIEnv *env, jobject obj, jlong L, jint index);
	void JNICALL JAVA_LUA_NEWTABLE(JNIEnv *env, jobject obj, jlong L);
	jint JNICALL JAVA_LUA_NEXT(JNIEnv *env, jobject obj, jlong L, jint index);
	void JNICALL JAVA_LUA_RAWGETI(JNIEnv *env, jobject obj, jlong L, jint index, jint n);
	jboolean JNICALL JAVA_LUA_TOBOOLEAN(JNIEnv *env, jobject obj, jlong L, jint index);
	jdouble JNICALL JAVA_LUA_TONUMBER(JNIEnv *env, jobject obj, jlong L, jint index);
	jlong JNICALL JAVA_LUA_TOPOINTER(JNIEnv *env, jobject obj, jlong L, jint index);
	jstring JNICALL JAVA_LUA_TOSTRING(JNIEnv *env, jobject obj, jlong L, jint index);
	jint JNICALL JAVA_LUA_TYPE(JNIEnv *env, jobject obj, jlong L, jint index);
	void JNICALL JAVA_LUA_SETTABLE(JNIEnv *env, jobject obj, jlong L, jint index);
	jint JNICALL JAVA_LUA_REF(JNIEnv *env, jobject obj, jlong L, jint index);
	void JNICALL JAVA_LUA_UNREF(JNIEnv *env, jobject obj, jlong L, jint index, jint ref);
}