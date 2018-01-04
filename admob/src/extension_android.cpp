#if defined(DM_PLATFORM_ANDROID)

#include <dmsdk/sdk.h>
#include <jnlua.h>
#include "extension.h"

// Cache references.
static jobject lua_loader_object = NULL;
static jmethodID lua_loader_update = NULL;
static jobject lua_state_object = NULL;

dmExtension::Result APP_INITIALIZE(dmExtension::AppParams* params) {
	return dmExtension::RESULT_OK;
}

dmExtension::Result APP_FINALIZE(dmExtension::AppParams* params) {
	// Mention JNLua exports so they don't get optimized away.
	if (params == NULL) {
		Java_com_naef_jnlua_LuaState_lua_1version(NULL, NULL);
	}
	return dmExtension::RESULT_OK;
}

dmExtension::Result INITIALIZE(dmExtension::Params* params) {
	ThreadAttacher attacher;
	JNIEnv* env = attacher.env;
	ClassLoader class_loader = ClassLoader(env);

	// Prepare LuaState of JNLua with an actual Lua state.
	jclass lua_state_class = class_loader.load("com/naef/jnlua/LuaState");
	jmethodID lua_state_constructor = env->GetMethodID(lua_state_class, "<init>", "(J)V");
	lua_state_object = (jobject)env->NewGlobalRef(env->NewObject(lua_state_class, lua_state_constructor, (jlong)params->m_L));

	// Invoke LuaLoader from the extension.
	jclass lua_loader_class = class_loader.load("extension/" EXTENSION_NAME_STRING "/LuaLoader");
	jmethodID lua_loader_constructor = env->GetMethodID(lua_loader_class, "<init>", "(Landroid/app/Activity;)V");
	jmethodID lua_loader_invoke = env->GetMethodID(lua_loader_class, "invoke", "(Lcom/naef/jnlua/LuaState;)I");
	lua_loader_update = env->GetMethodID(lua_loader_class, "update", "(Lcom/naef/jnlua/LuaState;)V");
	lua_loader_object = (jobject)env->NewGlobalRef(env->NewObject(lua_loader_class, lua_loader_constructor, dmGraphics::GetNativeAndroidActivity()));
	int result = (int)env->CallIntMethod(lua_loader_object, lua_loader_invoke, lua_state_object);
	if (result > 0) {
		lua_pop(params->m_L, result);
	}

	return dmExtension::RESULT_OK;
}

dmExtension::Result UPDATE(dmExtension::Params* params) {
	ThreadAttacher attacher;
	// Update the Java side so it can invoke any pending listeners.
	attacher.env->CallVoidMethod(lua_loader_object, lua_loader_update, lua_state_object);
	return dmExtension::RESULT_OK;
}

dmExtension::Result FINALIZE(dmExtension::Params* params) {
	ThreadAttacher attacher;
	attacher.env->DeleteGlobalRef(lua_loader_object);
	attacher.env->DeleteGlobalRef(lua_state_object);
	return dmExtension::RESULT_OK;
}

DECLARE_DEFOLD_EXTENSION

#endif