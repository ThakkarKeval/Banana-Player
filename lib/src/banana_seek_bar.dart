import 'package:flutter/material.dart';
import 'banana_player_controller.dart';

/// Current state snapshot passed to [BananaSeekBar] builder functions.
class BananaSeekBarValue {
  const BananaSeekBarValue({
    required this.position,
    required this.duration,
    required this.bufferedPosition,
    required this.isDragging,
    required this.isLive,
  });

  /// The active playback position or user scrub preview position.
  final Duration position;

  /// Total duration of the media.
  final Duration duration;

  /// Current buffered/cached media position.
  final Duration bufferedPosition;

  /// Whether the user is currently touching or dragging the seek thumb.
  final bool isDragging;

  /// Whether the media is a live stream or has indeterminate length.
  final bool isLive;

  /// Playback progress normalized between 0.0 and 1.0.
  double get progressFraction {
    if (duration <= Duration.zero) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  /// Buffered progress normalized between 0.0 and 1.0.
  double get bufferedFraction {
    if (duration <= Duration.zero) return 0.0;
    return (bufferedPosition.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  /// Remaining playback duration.
  Duration get remaining {
    if (duration <= position) return Duration.zero;
    return duration - position;
  }
}

/// A fully customizable seek bar widget for [BananaPlayerController].
///
/// Features a default cinema-ready seekbar (with buffered preview, scrub preview,
/// live stream badge, and tabular timestamps), while allowing developers to supply
/// direct widgets ([leading], [trailing], [customThumb], [customTrack], [timeLabel],
/// [overlay], [builder]).
///
/// **Widget Validation:** Direct custom widgets are strictly validated. Structural
/// and graphical widgets ([Row], [Column], [Flex], [Stack], [Container], [Image],
/// [Icon], [Text], [ShapeDecoration], vector/shape drawings, [CustomPaint], etc.) are
/// permitted. Scrollable list widgets ([ListView], [GridView], [SingleChildScrollView],
/// [Scrollable], etc.) are forbidden and will throw an [ArgumentError].
class BananaSeekBar extends StatefulWidget {
  BananaSeekBar({
    super.key,
    required this.controller,
    // Colors and styling for default view
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.bufferedTrackColor,
    this.thumbColor,
    this.thumbRadius = 6.0,
    this.trackHeight = 4.0,
    this.showTimeLabels = true,
    this.timeTextStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 4.0),
    this.onSeek,
    this.onScrubStart,
    this.onScrubUpdate,
    this.onScrubEnd,

    // Direct customizable widgets
    this.customThumb,
    this.thumbBuilder,
    this.customTrack,
    this.trackBuilder,
    this.leading,
    this.trailing,
    this.timeLabel,
    this.timeLabelBuilder,
    this.overlay,
    this.scrubTooltipBuilder,
    this.builder,
  }) {
    // Validate direct widgets immediately at construction time
    validateWidget(customThumb, parameterName: 'customThumb');
    validateWidget(customTrack, parameterName: 'customTrack');
    validateWidget(leading, parameterName: 'leading');
    validateWidget(trailing, parameterName: 'trailing');
    validateWidget(timeLabel, parameterName: 'timeLabel');
    validateWidget(overlay, parameterName: 'overlay');
  }

  /// The player controller providing position, duration, and buffered progress.
  final BananaPlayerController controller;

  /// Color of the played portion of the track in default mode.
  final Color? activeTrackColor;

  /// Color of the unplayed/background portion of the track in default mode.
  final Color? inactiveTrackColor;

  /// Color of the buffered/cached portion of the track in default mode.
  final Color? bufferedTrackColor;

  /// Color of the draggable slider thumb in default mode.
  final Color? thumbColor;

  /// Radius of the slider thumb in default mode.
  final double thumbRadius;

  /// Height of the track bar in default mode.
  final double trackHeight;

  /// Whether to display elapsed time and total duration labels.
  final bool showTimeLabels;

  /// Style applied to the time labels.
  final TextStyle? timeTextStyle;

  /// Outer padding around the seek bar.
  final EdgeInsetsGeometry padding;

  /// Callback invoked when the user commits a seek operation.
  final ValueChanged<Duration>? onSeek;

  /// Callback invoked when scrubbing begins.
  final ValueChanged<Duration>? onScrubStart;

  /// Callback invoked continuously as the user scrubs.
  final ValueChanged<Duration>? onScrubUpdate;

  /// Callback invoked when scrubbing ends.
  final ValueChanged<Duration>? onScrubEnd;

  // --- Direct Customizable Slots ---

  /// A direct custom widget used as the thumb (e.g. [Icon], [Image], [Container] shape).
  final Widget? customThumb;

  /// Dynamic builder for the thumb widget based on current [BananaSeekBarValue].
  final Widget Function(BuildContext context, BananaSeekBarValue value)? thumbBuilder;

  /// A direct custom track widget (e.g. custom painted bar or gradient shape).
  final Widget? customTrack;

  /// Dynamic builder for the track widget based on current [BananaSeekBarValue].
  final Widget Function(BuildContext context, BananaSeekBarValue value)? trackBuilder;

  /// A direct widget placed to the left of the track (e.g. title, icon, or play button).
  final Widget? leading;

  /// A direct widget placed to the right of the track (e.g. fullscreen icon, remaining time).
  final Widget? trailing;

  /// A direct widget overriding the bottom time labels area.
  final Widget? timeLabel;

  /// Dynamic builder for the time label area based on current [BananaSeekBarValue].
  final Widget Function(BuildContext context, BananaSeekBarValue value)? timeLabelBuilder;

  /// A direct widget overlaid onto the seekbar (e.g. chapter markers, banner).
  final Widget? overlay;

  /// Dynamic builder for a scrub preview tooltip floating above the thumb while dragging.
  final Widget Function(BuildContext context, Duration scrubPosition)? scrubTooltipBuilder;

  /// Full layout builder providing [BananaSeekBarValue] and [defaultLayout].
  final Widget Function(
    BuildContext context,
    BananaSeekBarValue value,
    Widget defaultLayout,
  )? builder;

  /// Validates that [widget] is an allowed seekbar element.
  ///
  /// Structural and visual widgets (such as [Row], [Column], [Flex], [Stack],
  /// [Container], [DecoratedBox], [Image], [Icon], [Text], [ShapeDecoration],
  /// vector/shape drawings, [CustomPaint], [Padding], [SizedBox], [Center], [Align])
  /// are valid.
  ///
  /// Scrollable list widgets (such as [ListView], [GridView], [SingleChildScrollView],
  /// [Scrollable], [PageView], [CustomScrollView], etc.) are disallowed and throw an [ArgumentError].
  static void validateWidget(Widget? widget, {String parameterName = 'widget'}) {
    if (widget == null) return;

    _assertNotScrollable(widget, parameterName);

    // Recursively check children of common layout widgets to prevent nested list widgets
    if (widget is MultiChildRenderObjectWidget) {
      for (final child in widget.children) {
        validateWidget(child, parameterName: '$parameterName -> ${child.runtimeType}');
      }
    } else if (widget is SingleChildRenderObjectWidget) {
      if (widget.child != null) {
        validateWidget(widget.child, parameterName: '$parameterName -> ${widget.child.runtimeType}');
      }
    } else if (widget is Container && widget.child != null) {
      validateWidget(widget.child, parameterName: '$parameterName -> ${widget.child.runtimeType}');
    }
  }

  static void _assertNotScrollable(Widget widget, String parameterName) {
    final String typeName = widget.runtimeType.toString().toLowerCase();
    final bool isScrollable = widget is ScrollView ||
        widget is SingleChildScrollView ||
        widget is Scrollable ||
        widget is ListWheelScrollView ||
        widget is PageView ||
        typeName.contains('listview') ||
        typeName.contains('gridview') ||
        typeName.contains('scrollview') ||
        typeName.contains('listwheel') ||
        typeName.contains('pageview');

    if (isScrollable) {
      throw ArgumentError.value(
        widget,
        parameterName,
        'Scrollable list widgets (${widget.runtimeType}) are not allowed in BananaSeekBar. '
        'Allowed widgets include Row, Column, Container, Shape, Image, Icon, CustomPaint, Text, etc.',
      );
    }
  }

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

        final value = BananaSeekBarValue(
          position: position,
          duration: duration,
          bufferedPosition: buffered,
          isDragging: _isDragging,
          isLive: isLive,
        );

        final defaultLayout = _buildDefaultLayout(context, value);

        if (widget.builder != null) {
          final customLayout = widget.builder!(context, value, defaultLayout);
          BananaSeekBar.validateWidget(customLayout, parameterName: 'builder result');
          return customLayout;
        }

        return defaultLayout;
      },
    );
  }

  Widget _buildDefaultLayout(BuildContext context, BananaSeekBarValue value) {
    final theme = Theme.of(context);
    final labelStyle = widget.timeTextStyle ??
        TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.75),
          fontFeatures: const [FontFeature.tabularFigures()],
        );

    // Live Stream view
    if (value.isLive) {
      return Padding(
        padding: widget.padding,
        child: Row(
          children: [
            if (widget.leading != null) ...[
              widget.leading!,
              const SizedBox(width: 8),
            ],
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
            Text(_formatDuration(value.position), style: labelStyle),
            if (widget.trailing != null) ...[
              const SizedBox(width: 8),
              widget.trailing!,
            ],
          ],
        ),
      );
    }

    final activeColor = widget.activeTrackColor ?? theme.colorScheme.primary;
    final inactiveColor = widget.inactiveTrackColor ?? Colors.white.withValues(alpha: 0.15);
    final bufferedColor = widget.bufferedTrackColor ?? Colors.white.withValues(alpha: 0.35);
    final thumbColor = widget.thumbColor ?? activeColor;

    return Padding(
      padding: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row containing optional leading, interactive track, and optional trailing
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 8),
              ],
              Expanded(
                child: _buildInteractiveTrackArea(
                  context: context,
                  value: value,
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                  bufferedColor: bufferedColor,
                  thumbColor: thumbColor,
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 8),
                widget.trailing!,
              ],
            ],
          ),

          // Time labels area
          if (widget.timeLabel != null)
            widget.timeLabel!
          else if (widget.timeLabelBuilder != null)
            _buildValidatedTimeLabel(context, value)
          else if (widget.showTimeLabels) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(value.position), style: labelStyle),
                Text(_formatDuration(value.duration), style: labelStyle),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInteractiveTrackArea({
    required BuildContext context,
    required BananaSeekBarValue value,
    required Color activeColor,
    required Color inactiveColor,
    required Color bufferedColor,
    required Color thumbColor,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final durationMs = value.duration.inMilliseconds.toDouble();
        final progressFraction = value.progressFraction;
        final bufferedFraction = value.bufferedFraction;

        // Custom or default thumb widget
        Widget thumbWidget;
        if (widget.customThumb != null) {
          thumbWidget = widget.customThumb!;
        } else if (widget.thumbBuilder != null) {
          thumbWidget = widget.thumbBuilder!(context, value);
          BananaSeekBar.validateWidget(thumbWidget, parameterName: 'thumbBuilder result');
        } else {
          // Default sleek circular thumb with shadow and tap glow
          thumbWidget = Container(
            width: widget.thumbRadius * 2,
            height: widget.thumbRadius * 2,
            decoration: BoxDecoration(
              color: thumbColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: thumbColor.withValues(alpha: 0.45),
                  blurRadius: _isDragging ? 8 : 4,
                  spreadRadius: _isDragging ? 2 : 0,
                ),
              ],
            ),
          );
        }

        // Custom or default track widget
        Widget trackWidget;
        if (widget.customTrack != null) {
          trackWidget = widget.customTrack!;
        } else if (widget.trackBuilder != null) {
          trackWidget = widget.trackBuilder!(context, value);
          BananaSeekBar.validateWidget(trackWidget, parameterName: 'trackBuilder result');
        } else {
          // Default track with buffered progress bar
          trackWidget = Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Inactive track
              Container(
                height: widget.trackHeight,
                width: totalWidth,
                decoration: BoxDecoration(
                  color: inactiveColor,
                  borderRadius: BorderRadius.circular(widget.trackHeight / 2),
                ),
              ),
              // Buffered progress
              Container(
                height: widget.trackHeight,
                width: totalWidth * bufferedFraction,
                decoration: BoxDecoration(
                  color: bufferedColor,
                  borderRadius: BorderRadius.circular(widget.trackHeight / 2),
                ),
              ),
              // Active progress
              Container(
                height: widget.trackHeight,
                width: totalWidth * progressFraction,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(widget.trackHeight / 2),
                ),
              ),
            ],
          );
        }

        // Calculate thumb horizontal position
        final thumbSize = widget.thumbRadius * 2;
        final thumbLeft = (totalWidth * progressFraction - (thumbSize / 2))
            .clamp(0.0, totalWidth > thumbSize ? totalWidth - thumbSize : 0.0);

        void updateSeek(double localX) {
          if (durationMs <= 0 || totalWidth <= 0) return;
          final fraction = (localX / totalWidth).clamp(0.0, 1.0);
          final targetMs = (fraction * durationMs).round();
          final targetDuration = Duration(milliseconds: targetMs);
          setState(() {
            _dragPosition = targetDuration;
          });
          widget.onScrubUpdate?.call(targetDuration);
        }

        void commitSeek(double localX) {
          if (durationMs <= 0 || totalWidth <= 0) {
            setState(() => _isDragging = false);
            return;
          }
          final fraction = (localX / totalWidth).clamp(0.0, 1.0);
          final targetMs = (fraction * durationMs).round();
          final targetDuration = Duration(milliseconds: targetMs);
          widget.controller.seekTo(targetDuration);
          widget.onSeek?.call(targetDuration);
          widget.onScrubEnd?.call(targetDuration);
          setState(() {
            _isDragging = false;
          });
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) {
            if (durationMs <= 0) return;
            setState(() {
              _isDragging = true;
            });
            updateSeek(details.localPosition.dx);
            widget.onScrubStart?.call(_dragPosition);
          },
          onHorizontalDragUpdate: (details) {
            updateSeek(details.localPosition.dx);
          },
          onHorizontalDragEnd: (details) {
            if (_isDragging) {
              widget.controller.seekTo(_dragPosition);
              widget.onSeek?.call(_dragPosition);
              widget.onScrubEnd?.call(_dragPosition);
              setState(() {
                _isDragging = false;
              });
            }
          },
          onTapDown: (details) {
            commitSeek(details.localPosition.dx);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                // Track bar
                trackWidget,

                // Optional custom overlay (e.g. chapter markers)
                if (widget.overlay != null) widget.overlay!,

                // Scrub preview tooltip when dragging
                if (_isDragging && widget.scrubTooltipBuilder != null)
                  Positioned(
                    left: thumbLeft - 20,
                    top: -30,
                    child: widget.scrubTooltipBuilder!(context, _dragPosition),
                  ),

                // Thumb widget
                Positioned(
                  left: thumbLeft,
                  child: thumbWidget,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildValidatedTimeLabel(BuildContext context, BananaSeekBarValue value) {
    final widgetLabel = widget.timeLabelBuilder!(context, value);
    BananaSeekBar.validateWidget(widgetLabel, parameterName: 'timeLabelBuilder result');
    return widgetLabel;
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
