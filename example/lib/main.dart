import 'package:flutter/material.dart';
import 'package:banana_player/banana_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final BananaPlayerController _controller = BananaPlayerController();
  bool _initialized = false;
  PlaybackState _state = PlaybackState.idle;

  // Standard public test video
  static const String _testVideoUrl =
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

  @override
  void initState() {
    super.initState();
    _controller.onPlaybackStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _state = state;
        });
      }
    });
  }

  Future<void> _initPlayer() async {
    await _controller.initialize(
      url: _testVideoUrl,
      autoPlay: true,
      volume: 1.0,
    );
    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Banana Player (ExoPlayer)')),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.black,
                  child: _initialized
                      ? BananaPlayerView(controller: _controller)
                      : const Center(
                          child: Text(
                            'Tap "Initialize Player"',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Playback State: ${_state.name.toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _initialized ? null : _initPlayer,
                    child: const Text('Initialize & Play'),
                  ),
                  ElevatedButton(
                    onPressed: _initialized ? () => _controller.play() : null,
                    child: const Text('Play'),
                  ),
                  ElevatedButton(
                    onPressed: _initialized ? () => _controller.pause() : null,
                    child: const Text('Pause'),
                  ),
                  ElevatedButton(
                    onPressed: _initialized
                        ? () => _controller.seekTo(Duration.zero)
                        : null,
                    child: const Text('Replay (0s)'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
