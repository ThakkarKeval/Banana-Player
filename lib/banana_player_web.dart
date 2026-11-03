import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'banana_player_platform_interface.dart';

/// A web implementation of the BananaPlayerPlatform of the BananaPlayer plugin.
class BananaPlayerWeb extends BananaPlayerPlatform {
  /// Constructs a BananaPlayerWeb
  BananaPlayerWeb();

  static void registerWith(Registrar registrar) {
    BananaPlayerPlatform.instance = BananaPlayerWeb();
  }
}
