//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <media_kit_libs_linux/media_kit_libs_linux_plugin.h>
#include <media_kit_video/media_kit_video_plugin.h>
#include <tflite_flutter/tflite_flutter_plugin.h>
#include <tflite_flutter_helper/tflite_flutter_helper_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) media_kit_libs_linux_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "MediaKitLibsLinuxPlugin");
  media_kit_libs_linux_plugin_register_with_registrar(media_kit_libs_linux_registrar);
  g_autoptr(FlPluginRegistrar) media_kit_video_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "MediaKitVideoPlugin");
  media_kit_video_plugin_register_with_registrar(media_kit_video_registrar);
  g_autoptr(FlPluginRegistrar) tflite_flutter_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "TfliteFlutterPlugin");
  tflite_flutter_plugin_register_with_registrar(tflite_flutter_registrar);
  g_autoptr(FlPluginRegistrar) tflite_flutter_helper_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "TfliteFlutterHelperPlugin");
  tflite_flutter_helper_plugin_register_with_registrar(tflite_flutter_helper_registrar);
}
