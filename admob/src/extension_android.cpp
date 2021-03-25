#if defined(DM_PLATFORM_ANDROID)

#include <android/native_window_jni.h>
#include <dmsdk/sdk.h>

#include "extension.h"
#include "android/java_lua.h"

static jobject java_extension_object = NULL;
static jmethodID java_extension_update = NULL;
static jmethodID java_extension_app_activate = NULL;
static jmethodID java_extension_app_deactivate = NULL;
static jmethodID java_extension_finalize = NULL;
static jmethodID java_extension_enable_debug = NULL;
static jmethodID java_extension_init = NULL;
static jmethodID java_extension_hide_banner = NULL;
static jmethodID java_extension_load = NULL;
static jmethodID java_extension_is_loaded = NULL;
static jmethodID java_extension_show = NULL;

int EXTENSION_ENABLE_DEBUG(lua_State *L) {
	int result = 0;
	if (java_extension_object != NULL) {
		ThreadAttacher attacher;
		result = attacher.env->CallIntMethod(java_extension_object, java_extension_enable_debug, (jlong)L);
	}
	return result;
}

int EXTENSION_INIT(lua_State *L) {
	int result = 0;
	if (java_extension_object != NULL) {
		ThreadAttacher attacher;
		result = attacher.env->CallIntMethod(java_extension_object, java_extension_init, (jlong)L);
	}
	return result;
}

int EXTENSION_HIDE_BANNER(lua_State *L) {
	int result = 0;
	if (java_extension_object != NULL) {
		ThreadAttacher attacher;
		result = attacher.env->CallIntMethod(java_extension_object, java_extension_hide_banner, (jlong)L);
	}
	return result;
}

int EXTENSION_LOAD(lua_State *L) {
	int result = 0;
	if (java_extension_object != NULL) {
		ThreadAttacher attacher;
		result = attacher.env->CallIntMethod(java_extension_object, java_extension_load, (jlong)L);
	}
	return result;
}

int EXTENSION_IS_LOADED(lua_State *L) {
	int result = 0;
	if (java_extension_object != NULL) {
		ThreadAttacher attacher;
		result = attacher.env->CallIntMethod(java_extension_object, java_extension_is_loaded, (jlong)L);
	}
	return result;
}

int EXTENSION_SHOW(lua_State *L) {
	int result = 0;
	if (java_extension_object != NULL) {
		ThreadAttacher attacher;
		result = attacher.env->CallIntMethod(java_extension_object, java_extension_show, (jlong)L);
	}
	return result;
}

void EXTENSION_INITIALIZE(lua_State *L) {
	// Mention java_lua.h exports so they don't get optimized away.
	if (L == NULL) {
		JAVA_LUA_REGISTRYINDEX(NULL, NULL, 0);
		JAVA_LUA_GETTOP(NULL, NULL, 0);
	}
	ThreadAttacher attacher;
	JNIEnv *env = attacher.env;
	ClassLoader class_loader = ClassLoader(env);

	// Invoke Extension from the Java extension.
	jclass java_extension_class = class_loader.load("extension/" EXTENSION_NAME_STRING "/Extension");
	if (java_extension_class == NULL) {
		dmLogError("java_extension_class is NULL");
	}
	jmethodID java_extension_constructor = env->GetMethodID(java_extension_class, "<init>", "(Landroid/app/Activity;)V");
	java_extension_enable_debug = env->GetMethodID(java_extension_class, "enable_debug", "(J)I");
	java_extension_init = env->GetMethodID(java_extension_class, "init", "(J)I");
	java_extension_hide_banner = env->GetMethodID(java_extension_class, "hide_banner", "(J)I");
	java_extension_load = env->GetMethodID(java_extension_class, "load", "(J)I");
	java_extension_is_loaded = env->GetMethodID(java_extension_class, "is_loaded", "(J)I");
	java_extension_show = env->GetMethodID(java_extension_class, "show", "(J)I");
	java_extension_finalize = env->GetMethodID(java_extension_class, "extension_finalize", "(J)V");
	java_extension_update = env->GetMethodID(java_extension_class, "update", "(J)V");
	java_extension_app_activate = env->GetMethodID(java_extension_class, "app_activate", "(J)V");
	java_extension_app_deactivate = env->GetMethodID(java_extension_class, "app_deactivate", "(J)V");
	java_extension_object = (jobject)env->NewGlobalRef(env->NewObject(java_extension_class, java_extension_constructor, dmGraphics::GetNativeAndroidActivity()));
	if (java_extension_object == NULL) {
		dmLogError("java_extension_object is NULL");
	}
}

void EXTENSION_UPDATE(lua_State *L) {
	if (java_extension_object != NULL) {
		ThreadAttacher attacher;
		// Update the Java side so it can invoke any pending listeners.
		attacher.env->CallVoidMethod(java_extension_object, java_extension_update, (jlong)L);
	}
}

void EXTENSION_APP_ACTIVATE(lua_State *L) {
	if (java_extension_object != NULL) {
		ThreadAttacher attacher;
		attacher.env->CallVoidMethod(java_extension_object, java_extension_app_activate, (jlong)L);
	}
}

void EXTENSION_APP_DEACTIVATE(lua_State *L) {
	if (java_extension_object != NULL) {
		ThreadAttacher attacher;
		attacher.env->CallVoidMethod(java_extension_object, java_extension_app_deactivate, (jlong)L);
	}
}

void EXTENSION_FINALIZE(lua_State *L) {
	ThreadAttacher attacher;
	if (java_extension_object != NULL) {
		attacher.env->CallVoidMethod(java_extension_object, java_extension_finalize, (jlong)L);
		attacher.env->DeleteGlobalRef(java_extension_object);
	}
	java_extension_object = NULL;
}

#endif
