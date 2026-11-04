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

/// AmaiZe Cheese-Chilli inspired color palette
class AmaizeTheme {
  static const Color nachoYellow = Color(0xFFFFCC00);
  static const Color brightYellow = Color(0xFFFFE033);
  static const Color chilliRed = Color(0xFFE21B23);
  static const Color cheeseAmber = Color(0xFFFF9100);
  static const Color deepNavy = Color(0xFF142552);
  static const Color darkCanvas = Color(0xFF101014);
  static const Color cardSurface = Color(0xFF1A1A22);
  static const Color cardSurfaceLight = Color(0xFF242430);
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
        scaffoldBackgroundColor: AmaizeTheme.darkCanvas,
        colorScheme: const ColorScheme.dark(
          primary: AmaizeTheme.nachoYellow,
          secondary: AmaizeTheme.chilliRed,
          surface: AmaizeTheme.cardSurface,
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
    if (index == _selectedPresetIndex) return;
    setState(() {
      _selectedPresetIndex = index;
    });
    final preset = _kPresets[index];
    await _controller.setSource(preset.url);
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
              // Header with Cheese Chilli branding
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
              colors: [AmaizeTheme.nachoYellow, AmaizeTheme.cheeseAmber],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AmaizeTheme.nachoYellow.withValues(alpha: 0.3),
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
                    color: AmaizeTheme.nachoYellow,
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
                    color: AmaizeTheme.chilliRed,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'CHEESE CHILLI',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Colors.white,
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AmaizeTheme.nachoYellow.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AmaizeTheme.nachoYellow.withValues(alpha: 0.15),
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
                        color: AmaizeTheme.nachoYellow,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Preparing Stream...',
                        style: TextStyle(
                          color: AmaizeTheme.nachoYellow.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Floating State Badge
              Positioned(
                top: 12,
                left: 12,
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) => _buildLiveBadge(_controller.playbackState),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveBadge(PlaybackState state) {
    Color bg;
    Color dot;
    String label;

    switch (state) {
      case PlaybackState.ready:
        bg = AmaizeTheme.deepNavy.withValues(alpha: 0.85);
        dot = AmaizeTheme.brightYellow;
        label = 'PLAYING';
        break;
      case PlaybackState.buffering:
        bg = AmaizeTheme.cheeseAmber.withValues(alpha: 0.85);
        dot = Colors.white;
        label = 'BUFFERING';
        break;
      case PlaybackState.ended:
        bg = AmaizeTheme.chilliRed.withValues(alpha: 0.85);
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
        color: AmaizeTheme.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Replay to 0s
          _buildCircleAction(
            icon: Icons.replay_rounded,
            tooltip: 'Replay (0s)',
            onPressed: isInitialized ? () => _controller.seekTo(Duration.zero) : null,
          ),

          // Main Play / Pause Button with Cheese Yellow Gradient
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
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isEnded
                      ? [AmaizeTheme.chilliRed, AmaizeTheme.cheeseAmber]
                      : [AmaizeTheme.brightYellow, AmaizeTheme.nachoYellow],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isEnded ? AmaizeTheme.chilliRed : AmaizeTheme.nachoYellow)
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
                size: 38,
              ),
            ),
          ),

          // Mute / Unmute Toggle
          _buildCircleAction(
            icon: _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            tooltip: _isMuted ? 'Unmute' : 'Mute',
            color: _isMuted ? AmaizeTheme.chilliRed : null,
            onPressed: isInitialized ? _toggleMute : null,
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
        color: AmaizeTheme.cardSurfaceLight,
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
            const Icon(Icons.movie_creation_outlined, color: AmaizeTheme.nachoYellow, size: 20),
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
                color: AmaizeTheme.chilliRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AmaizeTheme.chilliRed.withValues(alpha: 0.4)),
              ),
              child: const Text(
                'LOCKED URLS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                  color: AmaizeTheme.chilliRed,
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
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AmaizeTheme.nachoYellow.withValues(alpha: 0.12)
                      : AmaizeTheme.cardSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AmaizeTheme.nachoYellow
                        : Colors.white.withValues(alpha: 0.08),
                    width: isSelected ? 1.6 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AmaizeTheme.nachoYellow
                            : AmaizeTheme.cardSurfaceLight,
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
                              color: isSelected ? AmaizeTheme.nachoYellow : Colors.white,
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
                            ? AmaizeTheme.nachoYellow.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        preset.tag,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AmaizeTheme.nachoYellow : Colors.white60,
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
