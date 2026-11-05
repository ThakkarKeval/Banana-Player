import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:banana_player/banana_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 1. Block rotation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const BananaPlayerApp());
}

/// Authentic Banana Player Theme
class BananaTheme {
  static const Color primaryYellow = Color(0xFFFFD200); // Ripe Banana Yellow
  static const Color brightYellow = Color(0xFFFFE033);  // Electric Banana Yellow
  static const Color amberGold = Color(0xFFFFA000);     // Warm Amber Gold
  static const Color deepNavy = Color(0xFF142036);      // Cinema Deep Blue
  static const Color darkCanvas = Color(0xFF0F0F14);    // Studio Canvas Dark
  static const Color cardSurface = Color(0xFF181822);   // Card Surface
  static const Color cardSurfaceLight = Color(0xFF232330); // Raised Surface
  static const Color alertRed = Color(0xFFE53935);      // Mute / Error Red
}

class MediaPreset {
  final String title;
  final String subtitle;
  final String tag;
  final String url;
  final IconData icon;

  const MediaPreset({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.url,
    required this.icon,
  });
}

const List<MediaPreset> _kPresets = [
  MediaPreset(
    title: 'Flutter Butterfly',
    subtitle: 'Nature Demo • MP4',
    tag: 'MP4 HD',
    url: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
    icon: Icons.eco_rounded,
  ),
  MediaPreset(
    title: 'Apple Advanced HLS',
    subtitle: 'Multi-rate 60/30 FPS • HLS fMP4',
    tag: 'HLS 60FPS',
    url: 'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8',
    icon: Icons.speed_rounded,
  ),
  MediaPreset(
    title: 'Mux Adaptive Stream',
    subtitle: 'Multi-bitrate Stream • HLS',
    tag: 'HLS LIVE',
    url: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
    icon: Icons.stream_rounded,
  ),
];

class BananaPlayerApp extends StatelessWidget {
  const BananaPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Banana Player',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: BananaTheme.darkCanvas,
        colorScheme: const ColorScheme.dark(
          primary: BananaTheme.primaryYellow,
          secondary: BananaTheme.amberGold,
          surface: BananaTheme.cardSurface,
        ),
      ),
      home: const BananaPlayerHome(),
    );
  }
}

class BananaPlayerHome extends StatefulWidget {
  const BananaPlayerHome({super.key});

  @override
  State<BananaPlayerHome> createState() => _BananaPlayerHomeState();
}

class _BananaPlayerHomeState extends State<BananaPlayerHome> {
  final BananaPlayerController _controller = BananaPlayerController();
  int _selectedPresetIndex = 0;
  bool _isMuted = false;
  bool _useCustomWidgets = false;
  bool _isSwitchingPreset = false;

  String _formatDuration(Duration duration) {
    if (duration < Duration.zero) return '0:00';
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final secondsStr = seconds.toString().padLeft(2, '0');
    return '$minutes:$secondsStr';
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentPreset();
  }

  Future<void> _loadCurrentPreset() async {
    final preset = _kPresets[_selectedPresetIndex];
    await _controller.initialize(
      url: preset.url,
      autoPlay: true,
      volume: _isMuted ? 0.0 : 1.0,
    );
  }

  Future<void> _switchPreset(int index) async {
    if (index == _selectedPresetIndex || _isSwitchingPreset) return;
    setState(() {
      _selectedPresetIndex = index;
      _isSwitchingPreset = true;
    });
    try {
      final preset = _kPresets[index];
      await _controller.setSource(preset.url);
    } finally {
      // Allow the new stream to prepare and render smoothly
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) {
        setState(() {
          _isSwitchingPreset = false;
        });
      }
    }
  }

  Future<void> _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    await _controller.setVolume(_isMuted ? 0.0 : 1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPreset = _kPresets[_selectedPresetIndex];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Banana branding
              _buildHeader(),
              const SizedBox(height: 16),

              // Cinema Video Player View
              _buildPlayerStage(),
              const SizedBox(height: 16),

              // Player Controls Deck (Listenable to controller)
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => _buildControlDeck(),
              ),
              const SizedBox(height: 24),

              // Fixed Media Presets (No URL Editing)
              _buildPresetSelector(currentPreset),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [BananaTheme.primaryYellow, BananaTheme.amberGold],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: BananaTheme.primaryYellow.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 26),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'BANANA',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: BananaTheme.primaryYellow,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'PLAYER',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: BananaTheme.primaryYellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: BananaTheme.primaryYellow.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    'CINEMA EDITION',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: BananaTheme.primaryYellow,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'ExoPlayer Native Engine',
                  style: TextStyle(fontSize: 11, color: Colors.white54),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayerStage() {
    final currentPreset = _kPresets[_selectedPresetIndex];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BananaTheme.primaryYellow.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: BananaTheme.primaryYellow.withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Colors.black),
              BananaPlayerView(
                controller: _controller,
                placeholder: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: BananaTheme.primaryYellow,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Preparing Stream...',
                        style: TextStyle(
                          color: BananaTheme.primaryYellow.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Smooth animated cross-fade scrim when switching presets
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _isSwitchingPreset
                      ? Container(
                          key: const ValueKey('switching_scrim'),
                          color: Colors.black.withValues(alpha: 0.85),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    color: BananaTheme.primaryYellow,
                                    strokeWidth: 3,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Loading ${currentPreset.title}...',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('empty_scrim')),
                ),
              ),

              // Floating State Badge with smooth size animation
              Positioned(
                top: 12,
                left: 12,
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) => AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: _buildLiveBadge(_controller.playbackState),
                  ),
                ),
              ),
              // Floating Quality & Speed Controls with smooth size animation
              Positioned(
                top: 12,
                right: 12,
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) => AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSpeedBadge(),
                        const SizedBox(width: 8),
                        _buildQualityBadge(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedBadge() {
    final speed = _controller.playbackSpeed;
    final speedText = speed == 1.0 ? '1.0x' : '${speed.toStringAsFixed(speed % 1 == 0 ? 0 : 2)}x';

    return InkWell(
      onTap: _controller.isInitialized ? () => _showSpeedPicker(context) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: BananaTheme.cardSurface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: speed != 1.0
                ? BananaTheme.brightYellow
                : Colors.white.withValues(alpha: 0.25),
          ),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.speed_rounded,
              color: speed != 1.0 ? BananaTheme.brightYellow : Colors.white70,
              size: 13,
            ),
            const SizedBox(width: 4),
            Text(
              speedText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: speed != 1.0 ? BananaTheme.brightYellow : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeedPicker(BuildContext context) {
    const speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    final currentSpeed = _controller.playbackSpeed;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BananaTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.speed_rounded, color: BananaTheme.primaryYellow, size: 24),
                    const SizedBox(width: 10),
                    const Text(
                      'Playback Speed',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: BananaTheme.primaryYellow.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${currentSpeed == 1.0 ? '1.0' : currentSpeed}x ACTIVE',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: BananaTheme.primaryYellow,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: speeds.map((speed) {
                        final isSelected = (currentSpeed - speed).abs() < 0.01;
                        final label = speed == 1.0 ? '1.0x • Normal' : '${speed}x';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? BananaTheme.primaryYellow
                                    : Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            tileColor: isSelected
                                ? BananaTheme.primaryYellow.withValues(alpha: 0.12)
                                : BananaTheme.cardSurfaceLight,
                            leading: Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              color: isSelected ? BananaTheme.primaryYellow : Colors.white38,
                              size: 20,
                            ),
                            title: Text(
                              label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? BananaTheme.primaryYellow : Colors.white,
                              ),
                            ),
                            onTap: () {
                              _controller.setPlaybackSpeed(speed);
                              Navigator.pop(bottomSheetContext);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQualityBadge() {
    final qualities = _controller.videoQualities;
    final selected = _controller.selectedQuality;
    final String label = selected?.label ?? (qualities.isNotEmpty ? 'Auto' : 'HD');

    return InkWell(
      onTap: qualities.isNotEmpty ? () => _showQualityPicker(context) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: BananaTheme.cardSurface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: BananaTheme.primaryYellow.withValues(alpha: 0.5),
          ),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.tune_rounded,
              color: BananaTheme.primaryYellow,
              size: 13,
            ),
            const SizedBox(width: 5),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQualityPicker(BuildContext context) {
    final qualities = _controller.videoQualities;
    final selected = _controller.selectedQuality;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BananaTheme.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.65,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.high_quality_rounded, color: BananaTheme.primaryYellow, size: 24),
                      const SizedBox(width: 10),
                      const Text(
                        'Video Stream Quality',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: BananaTheme.primaryYellow.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'HLS ABR',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: BananaTheme.primaryYellow,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: qualities.map((quality) {
                          final isCurrent = quality.id == selected?.id ||
                              (selected == null && quality.id == 'auto');
                          final bitrateText = quality.bitrate > 0
                              ? ' • ${(quality.bitrate / 1000000).toStringAsFixed(1)} Mbps'
                              : '';
                          final fpsText = (quality.frameRate != null && quality.frameRate! > 0)
                              ? ' • ${quality.frameRate!.round()} fps'
                              : '';
                          final resolutionText = quality.height > 0
                              ? '${quality.width}x${quality.height}'
                              : (quality.id == 'auto' ? 'Adaptive bitrate based on network' : '');

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isCurrent
                                      ? BananaTheme.primaryYellow
                                      : Colors.white.withValues(alpha: 0.06),
                                ),
                              ),
                              tileColor: isCurrent
                                  ? BananaTheme.primaryYellow.withValues(alpha: 0.12)
                                  : BananaTheme.cardSurfaceLight,
                              leading: Icon(
                                isCurrent ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                color: isCurrent ? BananaTheme.primaryYellow : Colors.white38,
                                size: 20,
                              ),
                              title: Text(
                                quality.label ?? (quality.height > 0 ? '${quality.height}p' : quality.id),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent ? BananaTheme.primaryYellow : Colors.white,
                                ),
                              ),
                              subtitle: resolutionText.isNotEmpty
                                  ? Text(
                                      '$resolutionText$bitrateText$fpsText',
                                      style: const TextStyle(fontSize: 12, color: Colors.white54),
                                    )
                                  : null,
                              trailing: (quality.frameRate != null && quality.frameRate! > 0)
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isCurrent
                                            ? BananaTheme.primaryYellow.withValues(alpha: 0.2)
                                            : Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isCurrent
                                              ? BananaTheme.primaryYellow.withValues(alpha: 0.4)
                                              : Colors.white12,
                                        ),
                                      ),
                                      child: Text(
                                        '${quality.frameRate!.round()} FPS',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                          color: isCurrent ? BananaTheme.primaryYellow : Colors.white70,
                                        ),
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                _controller.setVideoQuality(quality.id);
                                Navigator.pop(bottomSheetContext);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiveBadge(PlaybackState state) {
    Color bg;
    Color dot;
    String label;

    switch (state) {
      case PlaybackState.ready:
        bg = BananaTheme.deepNavy.withValues(alpha: 0.85);
        dot = BananaTheme.brightYellow;
        label = 'PLAYING';
        break;
      case PlaybackState.buffering:
        bg = BananaTheme.amberGold.withValues(alpha: 0.85);
        dot = Colors.white;
        label = 'BUFFERING';
        break;
      case PlaybackState.ended:
        bg = BananaTheme.alertRed.withValues(alpha: 0.85);
        dot = Colors.white;
        label = 'ENDED (TAP PLAY)';
        break;
      case PlaybackState.paused:
        bg = Colors.black54;
        dot = Colors.grey;
        label = 'PAUSED';
        break;
      case PlaybackState.idle:
        bg = Colors.black54;
        dot = Colors.grey;
        label = 'IDLE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dot.withValues(alpha: 0.5)),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: dot, blurRadius: 4, spreadRadius: 1),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlDeck() {
    final state = _controller.playbackState;
    final isPlaying = state == PlaybackState.ready;
    final isEnded = state == PlaybackState.ended;
    final isInitialized = _controller.isInitialized;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: BananaTheme.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row with Seekbar Mode Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _useCustomWidgets ? 'CUSTOM WIDGETS' : 'DEFAULT SEEKBAR VIEW',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Colors.white54,
                ),
              ),
              InkWell(
                onTap: () => setState(() => _useCustomWidgets = !_useCustomWidgets),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _useCustomWidgets
                        ? BananaTheme.amberGold.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _useCustomWidgets ? BananaTheme.amberGold : Colors.white24,
                    ),
                  ),
                  child: Text(
                    _useCustomWidgets ? 'Show Default View' : 'Try Custom Direct Widgets',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _useCustomWidgets ? BananaTheme.primaryYellow : Colors.white70,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Seek Bar (Default View or Custom Direct Widgets)
          if (!_useCustomWidgets)
            BananaSeekBar(
              controller: _controller,
              activeTrackColor: BananaTheme.primaryYellow,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
              bufferedTrackColor: BananaTheme.amberGold.withValues(alpha: 0.35),
              thumbColor: BananaTheme.brightYellow,
              thumbRadius: 7.0,
              trackHeight: 4.0,
              showTimeLabels: true,
              timeTextStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            )
          else
            BananaSeekBar(
              controller: _controller,
              activeTrackColor: BananaTheme.primaryYellow,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
              bufferedTrackColor: BananaTheme.amberGold.withValues(alpha: 0.35),
              trackHeight: 5.0,
              showTimeLabels: false,
              // Direct custom thumb widget (banana circle with amber border)
              customThumb: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [BananaTheme.brightYellow, BananaTheme.amberGold],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: BananaTheme.primaryYellow.withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 14,
                  color: Colors.black,
                ),
              ),
              // Direct custom leading widget (Row with icon and format)
              leading: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: BananaTheme.cardSurfaceLight,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.hd_rounded, size: 14, color: BananaTheme.primaryYellow),
                    SizedBox(width: 3),
                    Text(
                      '1080p',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: BananaTheme.primaryYellow,
                      ),
                    ),
                  ],
                ),
              ),
              // Direct custom trailing widget (Pill with remaining duration)
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: BananaTheme.primaryYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: BananaTheme.primaryYellow.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '-${_formatDuration(_controller.duration > _controller.position ? _controller.duration - _controller.position : Duration.zero)}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: BananaTheme.primaryYellow,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              // Direct custom scrub tooltip floating above thumb
              scrubTooltipBuilder: (context, scrubPos) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: BananaTheme.deepNavy,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: BananaTheme.primaryYellow, width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    _formatDuration(scrubPos),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 12),

          // Action controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Replay to 0s
              _buildCircleAction(
                icon: Icons.replay_rounded,
                tooltip: 'Replay (0s)',
                onPressed: isInitialized ? () => _controller.seekTo(Duration.zero) : null,
              ),

              // Step backward 10s
              _buildCircleAction(
                icon: Icons.replay_10_rounded,
                tooltip: 'Rewind 10s',
                onPressed: isInitialized
                    ? () {
                        final newPos = _controller.position - const Duration(seconds: 10);
                        _controller.seekTo(newPos < Duration.zero ? Duration.zero : newPos);
                      }
                    : null,
              ),

              // Main Play / Pause Button with Banana Yellow Gradient
              GestureDetector(
                onTap: isInitialized
                    ? () {
                        if (isPlaying) {
                          _controller.pause();
                        } else {
                          // Automatically restarts if video has ended
                          _controller.play();
                        }
                      }
                    : null,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isEnded
                          ? [BananaTheme.alertRed, BananaTheme.amberGold]
                          : [BananaTheme.brightYellow, BananaTheme.primaryYellow],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isEnded ? BananaTheme.alertRed : BananaTheme.primaryYellow)
                            .withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isEnded
                        ? Icons.replay_rounded
                        : (isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    color: isEnded ? Colors.white : Colors.black,
                    size: 36,
                  ),
                ),
              ),

              // Step forward 10s
              _buildCircleAction(
                icon: Icons.forward_10_rounded,
                tooltip: 'Forward 10s',
                onPressed: isInitialized
                    ? () {
                        final newPos = _controller.position + const Duration(seconds: 10);
                        final maxDur = _controller.duration;
                        if (maxDur > Duration.zero && newPos > maxDur) {
                          _controller.seekTo(maxDur);
                        } else {
                          _controller.seekTo(newPos);
                        }
                      }
                    : null,
              ),

              // Mute / Unmute Toggle
              _buildCircleAction(
                icon: _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                tooltip: _isMuted ? 'Unmute' : 'Mute',
                color: _isMuted ? BananaTheme.alertRed : null,
                onPressed: isInitialized ? _toggleMute : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: BananaTheme.cardSurfaceLight,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: IconButton(
        icon: Icon(icon, color: color ?? Colors.white.withValues(alpha: 0.9)),
        tooltip: tooltip,
        iconSize: 24,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildPresetSelector(MediaPreset activePreset) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.movie_creation_outlined, color: BananaTheme.primaryYellow, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Select Stream',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: BananaTheme.primaryYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: BananaTheme.primaryYellow.withValues(alpha: 0.4)),
              ),
              child: const Text(
                'STREAM PRESETS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: BananaTheme.primaryYellow,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(_kPresets.length, (index) {
          final preset = _kPresets[index];
          final isSelected = index == _selectedPresetIndex;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => _switchPreset(index),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? BananaTheme.primaryYellow.withValues(alpha: 0.12)
                      : BananaTheme.cardSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? BananaTheme.primaryYellow
                        : Colors.white.withValues(alpha: 0.08),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: BananaTheme.primaryYellow.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? BananaTheme.primaryYellow
                            : BananaTheme.cardSurfaceLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        preset.icon,
                        color: isSelected ? Colors.black : Colors.white70,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preset.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? BananaTheme.primaryYellow : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            preset.subtitle,
                            style: const TextStyle(fontSize: 12, color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? BananaTheme.primaryYellow.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? BananaTheme.primaryYellow.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        preset.tag,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: isSelected ? BananaTheme.primaryYellow : Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
