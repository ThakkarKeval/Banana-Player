//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <banana_player/banana_player_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) banana_player_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "BananaPlayerPlugin");
  banana_player_plugin_register_with_registrar(banana_player_registrar);
}
