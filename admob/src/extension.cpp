#include "extension.h"

// This is the entry point of the extension. It defines Lua API of the extension.

static const luaL_reg lua_functions[] = {
	{"enable_debug", EXTENSION_ENABLE_DEBUG},
	{"init", EXTENSION_INIT},
	{"load", EXTENSION_LOAD},
	{"is_loaded", EXTENSION_IS_LOADED},
	{"show", EXTENSION_SHOW},
	{"hide_banner", EXTENSION_HIDE_BANNER},
	{0, 0}
};

dmExtension::Result APP_INITIALIZE(dmExtension::AppParams *params) {
	return dmExtension::RESULT_OK;
}

dmExtension::Result APP_FINALIZE(dmExtension::AppParams *params) {
	return dmExtension::RESULT_OK;
}

dmExtension::Result INITIALIZE(dmExtension::Params *params) {
	luaL_register(params->m_L, EXTENSION_NAME_STRING, lua_functions);
	lua_pop(params->m_L, 1);
	EXTENSION_INITIALIZE(params->m_L);
	return dmExtension::RESULT_OK;
}

dmExtension::Result UPDATE(dmExtension::Params *params) {
	EXTENSION_UPDATE(params->m_L);
	return dmExtension::RESULT_OK;
}

void EXTENSION_ON_EVENT(dmExtension::Params *params, const dmExtension::Event *event) {
	switch (event->m_Event) {
		case dmExtension::EVENT_ID_ACTIVATEAPP:
			EXTENSION_APP_ACTIVATE(params->m_L);
			break;
		case dmExtension::EVENT_ID_DEACTIVATEAPP:
			EXTENSION_APP_DEACTIVATE(params->m_L);
			break;
	}
}

dmExtension::Result FINALIZE(dmExtension::Params *params) {
	EXTENSION_FINALIZE(params->m_L);
	return dmExtension::RESULT_OK;
}

DM_DECLARE_EXTENSION(EXTENSION_NAME, EXTENSION_NAME_STRING, APP_INITIALIZE, APP_FINALIZE, INITIALIZE, UPDATE, EXTENSION_ON_EVENT, FINALIZE)