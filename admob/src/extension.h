#ifndef extension_h
#define extension_h

// The name of the extension affects Lua module name and Java package name.
#define EXTENSION_NAME admob

// Convert extension name to C const string.
#define STRINGIFY(s) #s
#define STRINGIFY_EXPANDED(s) STRINGIFY(s)
#define EXTENSION_NAME_STRING STRINGIFY_EXPANDED(EXTENSION_NAME)

#include <dmsdk/sdk.h>

// Each extension must have unique exported symbols. Construct function names based on the extension name.
#define FUNCTION_NAME(extension_name, function_name) Extension_ ## extension_name ## _ ## function_name
#define FUNCTION_NAME_EXPANDED(extension_name, function_name) FUNCTION_NAME(extension_name, function_name)

#define APP_INITIALIZE FUNCTION_NAME_EXPANDED(EXTENSION_NAME, AppInitialize)
#define APP_FINALIZE FUNCTION_NAME_EXPANDED(EXTENSION_NAME, AppFinalize)
#define INITIALIZE FUNCTION_NAME_EXPANDED(EXTENSION_NAME, Initialize)
#define UPDATE FUNCTION_NAME_EXPANDED(EXTENSION_NAME, Update)
#define FINALIZE FUNCTION_NAME_EXPANDED(EXTENSION_NAME, Finalize)

// The following functions are implemented for each platform.
// Lua API.
#define EXTENSION_ENABLE_DEBUG FUNCTION_NAME_EXPANDED(EXTENSION_NAME, enable_debug)
int EXTENSION_ENABLE_DEBUG(lua_State *L);

#define EXTENSION_INIT FUNCTION_NAME_EXPANDED(EXTENSION_NAME, init)
int EXTENSION_INIT(lua_State *L);

#define EXTENSION_LOAD FUNCTION_NAME_EXPANDED(EXTENSION_NAME, load)
int EXTENSION_LOAD(lua_State *L);

#define EXTENSION_IS_LOADED FUNCTION_NAME_EXPANDED(EXTENSION_NAME, is_loaded)
int EXTENSION_IS_LOADED(lua_State *L);

#define EXTENSION_SHOW FUNCTION_NAME_EXPANDED(EXTENSION_NAME, show)
int EXTENSION_SHOW(lua_State *L);

#define EXTENSION_HIDE_BANNER FUNCTION_NAME_EXPANDED(EXTENSION_NAME, hide_banner)
int EXTENSION_HIDE_BANNER(lua_State *L);

// Extension lifecycle functions.
#define EXTENSION_INITIALIZE FUNCTION_NAME_EXPANDED(EXTENSION_NAME, initialize)
#define EXTENSION_UPDATE FUNCTION_NAME_EXPANDED(EXTENSION_NAME, update)
#define EXTENSION_ON_EVENT FUNCTION_NAME_EXPANDED(EXTENSION_NAME, on_event)
#define EXTENSION_APP_ACTIVATE FUNCTION_NAME_EXPANDED(EXTENSION_NAME, app_activate)
#define EXTENSION_APP_DEACTIVATE FUNCTION_NAME_EXPANDED(EXTENSION_NAME, app_deactivate)
#define EXTENSION_FINALIZE FUNCTION_NAME_EXPANDED(EXTENSION_NAME, finalize)
void EXTENSION_INITIALIZE(lua_State *L);
void EXTENSION_UPDATE(lua_State *L);
void EXTENSION_APP_ACTIVATE(lua_State *L);
void EXTENSION_APP_DEACTIVATE(lua_State *L);
void EXTENSION_FINALIZE(lua_State *L);

#if defined(DM_PLATFORM_ANDROID)

namespace {
	// JNI access is only valid on an attached thread.
	struct ThreadAttacher {
		JNIEnv *env;
		bool has_attached;
		ThreadAttacher() : env(NULL), has_attached(false) {
			if (dmGraphics::GetNativeAndroidJavaVM()->GetEnv((void **)&env, JNI_VERSION_1_6) != JNI_OK) {
				dmGraphics::GetNativeAndroidJavaVM()->AttachCurrentThread(&env, NULL);
				has_attached = true;
			}
		}
		~ThreadAttacher() {
			if (has_attached) {
				if (env->ExceptionCheck()) {
					env->ExceptionDescribe();
				}
				env->ExceptionClear();
				dmGraphics::GetNativeAndroidJavaVM()->DetachCurrentThread();
			}
		}
	};

	// Dynamic Java class loading.
	struct ClassLoader {
		private:
			JNIEnv *env;
			jobject class_loader_object;
			jmethodID load_class;
		public:
			ClassLoader(JNIEnv *env) : env(env) {
				jclass activity_class = env->FindClass("android/app/NativeActivity");
				jclass class_loader_class = env->FindClass("java/lang/ClassLoader");
				jmethodID get_class_loader = env->GetMethodID(activity_class, "getClassLoader", "()Ljava/lang/ClassLoader;");
				load_class = env->GetMethodID(class_loader_class, "loadClass", "(Ljava/lang/String;)Ljava/lang/Class;");
				class_loader_object = env->CallObjectMethod(dmGraphics::GetNativeAndroidActivity(), get_class_loader);
			}
			jclass load(const char *class_name) {
				jstring class_name_string = env->NewStringUTF(class_name);
				jclass loaded_class = (jclass)env->CallObjectMethod(class_loader_object, load_class, class_name_string);
				env->DeleteLocalRef(class_name_string);
				return loaded_class;
			}
	};
}

#endif
#endif
