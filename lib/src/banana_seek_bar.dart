import 'package:flutter/material.dart';
import 'banana_player_controller.dart';

/// A customizable seek bar widget for [BananaPlayerController].
///
/// Supports interactive dragging, buffered track preview, live stream detection,
/// and formatted time labels (current position / total duration).
class BananaSeekBar extends StatefulWidget {
  const BananaSeekBar({
    super.key,
    required this.controller,
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.bufferedTrackColor,
    this.thumbColor,
    this.thumbRadius = 6.0,
    this.trackHeight = 3.5,
    this.showTimeLabels = true,
    this.timeTextStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 4.0),
    this.onSeek,
  });

  /// The player controller providing position, duration, and buffered progress.
  final BananaPlayerController controller;

  /// Color of the played portion of the track.
  final Color? activeTrackColor;

  /// Color of the unplayed/background portion of the track.
  final Color? inactiveTrackColor;

  /// Color of the buffered/cached portion of the track.
  final Color? bufferedTrackColor;

  /// Color of the draggable slider thumb.
  final Color? thumbColor;

  /// Radius of the slider thumb.
  final double thumbRadius;

  /// Height of the seek bar track line.
  final double trackHeight;

  /// Whether to display elapsed time and total duration labels.
  final bool showTimeLabels;

  /// Style applied to the time labels.
  final TextStyle? timeTextStyle;

  /// Outer padding around the seek bar.
  final EdgeInsetsGeometry padding;

  /// Optional callback invoked when the user commits a seek operation.
  final ValueChanged<Duration>? onSeek;

  @override
  State<BananaSeekBar> createState() => _BananaSeekBarState();
}

class _BananaSeekBarState extends State<BananaSeekBar> {
  bool _isDragging = false;
  Duration _dragPosition = Duration.zero;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final duration = widget.controller.duration;
        final isLive = widget.controller.isLive;
        final position = _isDragging ? _dragPosition : widget.controller.position;
        final buffered = widget.controller.bufferedPosition;

        final theme = Theme.of(context);
        final activeColor = widget.activeTrackColor ?? theme.colorScheme.primary;
        final inactiveColor = widget.inactiveTrackColor ?? Colors.white.withValues(alpha: 0.15);
        final bufferedColor = widget.bufferedTrackColor ?? Colors.white.withValues(alpha: 0.35);
        final thumbColor = widget.thumbColor ?? activeColor;

        final labelStyle = widget.timeTextStyle ??
            TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.75),
              fontFeatures: const [FontFeature.tabularFigures()],
            );

        if (isLive) {
          return Padding(
            padding: widget.padding,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'LIVE STREAM',
                  style: labelStyle.copyWith(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Text(_formatDuration(position), style: labelStyle),
              ],
            ),
          );
        }

        final durationMs = duration.inMilliseconds.toDouble();
        final positionMs = position.inMilliseconds.toDouble().clamp(0.0, durationMs > 0 ? durationMs : 0.0);
        final bufferedFraction = durationMs > 0 ? (buffered.inMilliseconds / durationMs).clamp(0.0, 1.0) : 0.0;

        return Padding(
          padding: widget.padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Slider with underlying buffered bar
              LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Inactive track background
                      Container(
                        height: widget.trackHeight,
                        width: constraints.maxWidth,
                        decoration: BoxDecoration(
                          color: inactiveColor,
                          borderRadius: BorderRadius.circular(widget.trackHeight / 2),
                        ),
                      ),
                      // Buffered progress bar
                      Container(
                        height: widget.trackHeight,
                        width: constraints.maxWidth * bufferedFraction,
                        decoration: BoxDecoration(
                          color: bufferedColor,
                          borderRadius: BorderRadius.circular(widget.trackHeight / 2),
                        ),
                      ),
                      // Slider control
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: widget.trackHeight,
                          activeTrackColor: activeColor,
                          inactiveTrackColor: Colors.transparent, // Handled by stack underneath
                          thumbColor: thumbColor,
                          overlayColor: activeColor.withValues(alpha: 0.2),
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: widget.thumbRadius,
                            elevation: 2,
                          ),
                          overlayShape: RoundSliderOverlayShape(
                            overlayRadius: widget.thumbRadius * 2.2,
                          ),
                          trackShape: const _FullWidthTrackShape(),
                        ),
                        child: Slider(
                          value: durationMs > 0 ? positionMs : 0.0,
                          min: 0.0,
                          max: durationMs > 0 ? durationMs : 1.0,
                          onChangeStart: durationMs > 0
                              ? (value) {
                                  setState(() {
                                    _isDragging = true;
                                    _dragPosition = Duration(milliseconds: value.round());
                                  });
                                }
                              : null,
                          onChanged: durationMs > 0
                              ? (value) {
                                  setState(() {
                                    _dragPosition = Duration(milliseconds: value.round());
                                  });
                                }
                              : null,
                          onChangeEnd: durationMs > 0
                              ? (value) {
                                  final target = Duration(milliseconds: value.round());
                                  widget.controller.seekTo(target);
                                  widget.onSeek?.call(target);
                                  setState(() {
                                    _isDragging = false;
                                  });
                                }
                              : null,
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (widget.showTimeLabels) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(position), style: labelStyle),
                    Text(_formatDuration(duration), style: labelStyle),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    if (duration < Duration.zero) return '0:00';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final secondsStr = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      final minutesStr = minutes.toString().padLeft(2, '0');
      return '$hours:$minutesStr:$secondsStr';
    }
    return '$minutes:$secondsStr';
  }
}

/// Custom TrackShape removing default horizontal padding for precise edge-to-edge alignment.
class _FullWidthTrackShape extends RoundedRectSliderTrackShape {
  const _FullWidthTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 3.5;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(offset.dx, trackTop, parentBox.size.width, trackHeight);
  }
}
