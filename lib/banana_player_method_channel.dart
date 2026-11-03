import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'banana_player_platform_interface.dart';

/// An implementation of [BananaPlayerPlatform] that uses method channels.
class MethodChannelBananaPlayer extends BananaPlayerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('banana_player');
}
