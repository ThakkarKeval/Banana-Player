import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'banana_player_method_channel.dart';

abstract class BananaPlayerPlatform extends PlatformInterface {
  /// Constructs a BananaPlayerPlatform.
  BananaPlayerPlatform() : super(token: _token);

  static final Object _token = Object();

  static BananaPlayerPlatform _instance = MethodChannelBananaPlayer();

  /// The default instance of [BananaPlayerPlatform] to use.
  ///
  /// Defaults to [MethodChannelBananaPlayer].
  static BananaPlayerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BananaPlayerPlatform] when
  /// they register themselves.
  static set instance(BananaPlayerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }
}
