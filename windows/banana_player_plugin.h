#ifndef FLUTTER_PLUGIN_BANANA_PLAYER_PLUGIN_H_
#define FLUTTER_PLUGIN_BANANA_PLAYER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace banana_player {

class BananaPlayerPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  BananaPlayerPlugin();

  virtual ~BananaPlayerPlugin();

  // Disallow copy and assign.
  BananaPlayerPlugin(const BananaPlayerPlugin&) = delete;
  BananaPlayerPlugin& operator=(const BananaPlayerPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace banana_player

#endif  // FLUTTER_PLUGIN_BANANA_PLAYER_PLUGIN_H_
