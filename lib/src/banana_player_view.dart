import 'package:flutter/widgets.dart';

import 'banana_player_controller.dart';

/// A widget that displays the video output of a [BananaPlayerController].
class BananaPlayerView extends StatelessWidget {
  const BananaPlayerView({
    super.key,
    required this.controller,
    this.placeholder,
    this.filterQuality = FilterQuality.low,
  });

  /// The player controller providing the texture.
  final BananaPlayerController controller;

  /// Optional widget displayed when the player has not yet initialized.
  final Widget? placeholder;

  /// Quality of texture filtering applied during rendering.
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final textureId = controller.textureId;
        if (textureId == null) {
          return placeholder ?? const SizedBox.shrink();
        }
        return Texture(textureId: textureId, filterQuality: filterQuality);
      },
    );
  }
}
