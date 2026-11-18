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

class VideoQuality {
  VideoQuality({
    required this.id,
    required this.width,
    required this.height,
    required this.bitrate,
    required this.isSelected,
    this.label,
    this.frameRate,
  });

  String id;
  int width;
  int height;
  int bitrate;
  bool isSelected;
  String? label;
  double? frameRate;
}

/// A closed captions / subtitle track representation.
class SubtitleTrack {
  SubtitleTrack({
    required this.id,
    required this.label,
    required this.isSelected,
    this.language,
  });

  /// Unique track identifier or index, or 'off' when disabled.
  String id;

  /// Human-readable title (e.g. 'English', 'Spanish', 'Off').
  String label;

  /// Whether this subtitle track is currently selected.
  bool isSelected;

  /// BCP 47 or ISO language code (e.g. 'en', 'es'), if known.
  String? language;
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

  List<VideoQuality> getVideoQualities(int textureId);

  void setVideoQuality(int textureId, String qualityId);

  void setPlaybackSpeed(int textureId, double speed);

  /// Fetches available closed captions / subtitle tracks for the current media.
  List<SubtitleTrack> getSubtitleTracks(int textureId);

  /// Selects a closed caption track by [trackId], or pass 'off' to disable subtitles.
  void setSubtitleTrack(int textureId, String trackId);

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

  void onVideoQualitiesChanged(int textureId, List<VideoQuality> qualities);

  void onSubtitleTracksChanged(int textureId, List<SubtitleTrack> tracks);

  void onSubtitleTextChanged(int textureId, String? text);

  void onError(int textureId, String errorCode, String errorMessage);
}
