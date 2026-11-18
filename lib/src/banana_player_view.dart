import 'package:flutter/widgets.dart';

import 'banana_player_controller.dart';

/// A widget that displays the video output and optional closed captions overlay of a [BananaPlayerController].
class BananaPlayerView extends StatelessWidget {
  /// Creates a [BananaPlayerView] bound to [controller].
  const BananaPlayerView({
    super.key,
    required this.controller,
    this.placeholder,
    this.filterQuality = FilterQuality.low,
    this.showSubtitles = true,
    this.subtitleTextStyle,
    this.subtitleDecoration,
    this.subtitlePadding = const EdgeInsets.only(
      bottom: 24.0,
      left: 16.0,
      right: 16.0,
    ),
    this.subtitleAlignment = Alignment.bottomCenter,
    this.subtitleBuilder,
  });

  /// The player controller providing the texture and subtitle cues.
  final BananaPlayerController controller;

  /// Optional widget displayed when the player has not yet initialized.
  final Widget? placeholder;

  /// Quality of texture filtering applied during rendering.
  final FilterQuality filterQuality;

  /// Whether to render the closed caption / subtitle overlay when subtitle text is present.
  final bool showSubtitles;

  /// Custom text style applied to the subtitle cues.
  final TextStyle? subtitleTextStyle;

  /// Visual decoration (e.g. background container) for the subtitle container.
  final Decoration? subtitleDecoration;

  /// Outer padding for the subtitle overlay within the video surface.
  final EdgeInsetsGeometry subtitlePadding;

  /// Alignment of the subtitle container within the video surface (defaults to [Alignment.bottomCenter]).
  final Alignment subtitleAlignment;

  /// Custom builder for closed caption subtitle rendering.
  final Widget Function(BuildContext context, String subtitleText)?
  subtitleBuilder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final textureId = controller.textureId;
        if (textureId == null) {
          return placeholder ?? const SizedBox.shrink();
        }

        final videoTexture = Texture(
          textureId: textureId,
          filterQuality: filterQuality,
        );

        final subtitleText = controller.currentSubtitleText;
        if (!showSubtitles || subtitleText == null || subtitleText.isEmpty) {
          return videoTexture;
        }

        return Stack(
          fit: StackFit.passthrough,
          children: [
            videoTexture,
            Positioned.fill(
              child: Align(
                alignment: subtitleAlignment,
                child: Padding(
                  padding: subtitlePadding,
                  child: subtitleBuilder != null
                      ? subtitleBuilder!(context, subtitleText)
                      : _buildDefaultSubtitleView(context, subtitleText),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDefaultSubtitleView(BuildContext context, String text) {
    const style = TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 15.0,
      fontWeight: FontWeight.w600,
      shadows: [
        Shadow(
          offset: Offset(0, 1.5),
          blurRadius: 3.0,
          color: Color(0xFF000000),
        ),
      ],
    );

    final decoration =
        subtitleDecoration ??
        BoxDecoration(
          color: const Color(0xB3000000),
          borderRadius: BorderRadius.circular(4.0),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: decoration,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: subtitleTextStyle ?? style,
      ),
    );
  }
}
