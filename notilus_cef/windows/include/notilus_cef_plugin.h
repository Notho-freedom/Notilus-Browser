#ifndef NOTILUS_CEF_PLUGIN_H_
#define NOTILUS_CEF_PLUGIN_H_

#include <flutter_plugin_registrar.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if __cplusplus
extern "C" {
#endif

FLUTTER_PLUGIN_EXPORT void NotilusCefPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#if __cplusplus
}  // extern "C"
#endif

#endif  // NOTILUS_CEF_PLUGIN_H_

