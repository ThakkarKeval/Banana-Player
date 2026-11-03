#include "include/banana_player/banana_player_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "banana_player_plugin.h"

void BananaPlayerPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  banana_player::BananaPlayerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
