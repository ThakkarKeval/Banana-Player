import 'package:pigeon/pigeon.dart';

// Configure output paths for generated files
@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/player_api.g.dart',
    dartOptions: DartOptions(),
    kotlinOut: 'android/src/main/kotlin/com/cavernlabs/banana/player/banana_player/PlayerApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.cavernlabs.banana.player.banana_player',
    ),
    swiftOut: 'ios/banana_player/Sources/banana_player/PlayerApi.g.swift',
    swiftOptions: SwiftOptions(),
  ),
)
// 1. Data Models (Passed across the bridge)
class PlayerConfig {
  PlayerConfig({required this.url, this.autoPlay = true, this.volume = 1.0});

  String url;
  bool autoPlay;
  double volume;
}

enum PlaybackState { idle, buffering, ready, ended, paused }

// 2. Class 1: Dart -> Native (HostApi)
@HostApi()
abstract class BananaPlayerHostApi {
  /// Initializes native player (ExoPlayer/AVPlayer), registers SurfaceTexture,
  /// and returns the textureId for Flutter's Texture widget.
  int create(PlayerConfig config);

  void play(int textureId);

  void pause(int textureId);

  void setSource(int textureId, String url);

  void seekTo(int textureId, int positionMs);

  void setVolume(int textureId, double volume);

  int getDuration(int textureId);

  int getPosition(int textureId);

  void dispose(int textureId);
}

// 3. Class 2: Native -> Dart (FlutterApi)
@FlutterApi()
abstract class BananaPlayerFlutterApi {
  void onPlaybackStateChanged(int textureId, PlaybackState state);

  void onPositionChanged(
    int textureId,
    int positionMs,
    int durationMs,
    int bufferedPositionMs,
  );

  void onError(int textureId, String errorCode, String errorMessage);
}
