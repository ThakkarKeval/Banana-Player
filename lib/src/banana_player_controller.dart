import 'dart:async';
import 'dart:io' show File;

import 'package:flutter/foundation.dart';

import 'player_api.g.dart';

/// Controller managing a native video player instance (ExoPlayer on Android, AVPlayer on iOS).
class BananaPlayerController extends ChangeNotifier {
  /// Creates a new [BananaPlayerController].
  BananaPlayerController() {
    _ensureFlutterApiInitialized();
  }

  static bool _apiInitialized = false;
  static final Map<int, BananaPlayerController> _activeControllers = {};

  static void _ensureFlutterApiInitialized() {
    if (!_apiInitialized) {
      BananaPlayerFlutterApi.setUp(_GlobalFlutterApiHandler());
      _apiInitialized = true;
    }
  }

  final BananaPlayerHostApi _hostApi = BananaPlayerHostApi();

  int? _textureId;
  PlaybackState _playbackState = PlaybackState.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _bufferedPosition = Duration.zero;
  List<VideoQuality> _videoQualities = const [];
  double _playbackSpeed = 1.0;
  String? _errorMessage;
  bool _isDisposed = false;

  /// The native surface texture ID used by the Flutter [Texture] widget.
  int? get textureId => _textureId;

  /// Whether the player has been successfully created and has a valid texture.
  bool get isInitialized => _textureId != null && !_isDisposed;

  /// Current playback speed multiplier (e.g. 1.0 = normal, 1.5 = 1.5x, 2.0 = 2x).
  double get playbackSpeed => _playbackSpeed;

  /// The current state of playback (`idle`, `buffering`, `ready`, `ended`).
  PlaybackState get playbackState => _playbackState;

  /// Whether the player is currently in the `ready` playback state.
  bool get isPlaying => _playbackState == PlaybackState.ready;

  /// Last known playback position.
  Duration get position => _position;

  /// Total duration of the media. Returns [Duration.zero] if unknown or live stream.
  Duration get duration => _duration;

  /// Last known buffered/cached position.
  Duration get bufferedPosition => _bufferedPosition;

  /// Available video qualities for HLS/DASH multi-bitrate streams.
  List<VideoQuality> get videoQualities => _videoQualities;

  /// Currently selected video quality (including 'Auto' if active).
  VideoQuality? get selectedQuality {
    for (final q in _videoQualities) {
      if (q.isSelected) return q;
    }
    return null;
  }

  /// Whether the current media is a live stream or indeterminate duration.
  bool get isLive =>
      _playbackState != PlaybackState.buffering &&
      _duration <= Duration.zero &&
      _position > Duration.zero;

  /// Last error message, if any.
  String? get errorMessage => _errorMessage;

  // Streams for event-driven architectures
  final StreamController<PlaybackState> _stateStreamController =
      StreamController<PlaybackState>.broadcast();

  /// Broadcast stream emitting the current [PlaybackState] whenever it changes.
  Stream<PlaybackState> get onPlaybackStateChanged =>
      _stateStreamController.stream;

  final StreamController<Duration> _positionStreamController =
      StreamController<Duration>.broadcast();

  /// Broadcast stream emitting the current playback [Duration] as media plays or seeks.
  Stream<Duration> get onPositionChanged => _positionStreamController.stream;

  final StreamController<Duration> _durationStreamController =
      StreamController<Duration>.broadcast();

  /// Broadcast stream emitting the total media [Duration] once it is loaded or updated.
  Stream<Duration> get onDurationChanged => _durationStreamController.stream;

  final StreamController<Duration> _bufferedStreamController =
      StreamController<Duration>.broadcast();

  /// Broadcast stream emitting the cached/buffered [Duration] as media streams.
  Stream<Duration> get onBufferedPositionChanged =>
      _bufferedStreamController.stream;

  final StreamController<List<VideoQuality>> _qualitiesStreamController =
      StreamController<List<VideoQuality>>.broadcast();

  /// Broadcast stream emitting available [VideoQuality] options when tracks change.
  Stream<List<VideoQuality>> get onVideoQualitiesChanged =>
      _qualitiesStreamController.stream;

  final StreamController<String> _errorStreamController =
      StreamController<String>.broadcast();

  /// Broadcast stream emitting an error message string when a playback failure occurs.
  Stream<String> get onError => _errorStreamController.stream;

  /// Normalizes a given URL, asset path, or file URI into a format recognizable by native engines.
  static String _normalizeUrl(String source) {
    final trimmed = source.trim();
    if (trimmed.startsWith('assets/')) {
      return 'asset:///$trimmed';
    }
    return trimmed;
  }

  /// Initializes the native player with the given [url].
  ///
  /// Can be a network URL (`http://`, `https://`), a local file URI (`file://`),
  /// a raw local filesystem path (`/path/to/video.mp4`), or an asset (`asset:///assets/...`).
  Future<int> initialize({
    required String url,
    bool autoPlay = true,
    double volume = 1.0,
  }) async {
    if (_isDisposed) {
      throw StateError('Cannot initialize a disposed BananaPlayerController');
    }

    // Safely release previous player instance if re-initializing
    if (_textureId != null) {
      final oldId = _textureId!;
      _activeControllers.remove(oldId);
      _textureId = null;
      await _hostApi.dispose(oldId);
    }

    _errorMessage = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    _bufferedPosition = Duration.zero;
    _videoQualities = const [];
    final normalized = _normalizeUrl(url);
    final config = PlayerConfig(
      url: normalized,
      autoPlay: autoPlay,
      volume: volume,
    );
    final textureId = await _hostApi.create(config);

    _textureId = textureId;
    _activeControllers[textureId] = this;
    notifyListeners();

    return textureId;
  }

  /// Initializes playback from a local device [File].
  Future<int> initializeFile(
    File file, {
    bool autoPlay = true,
    double volume = 1.0,
  }) {
    return initialize(
      url: file.uri.toString(),
      autoPlay: autoPlay,
      volume: volume,
    );
  }

  /// Initializes playback from a bundled Flutter asset (e.g. `assets/videos/intro.mp4`).
  Future<int> initializeAsset(
    String assetPath, {
    bool autoPlay = true,
    double volume = 1.0,
    String? package,
  }) {
    var cleanPath = assetPath.trim();
    while (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }
    final resolvedPath = package != null
        ? 'packages/$package/$cleanPath'
        : cleanPath;
    return initialize(
      url: 'asset:///$resolvedPath',
      autoPlay: autoPlay,
      volume: volume,
    );
  }

  /// Changes the media source URL without destroying and recreating the surface or decoder.
  Future<void> setSource(String url) async {
    if (_isDisposed) {
      throw StateError(
        'Cannot set source on a disposed BananaPlayerController',
      );
    }
    _errorMessage = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    _bufferedPosition = Duration.zero;
    _videoQualities = const [];
    _playbackState = PlaybackState.buffering;
    notifyListeners();

    final normalized = _normalizeUrl(url);
    if (_textureId != null) {
      await _hostApi.setSource(_textureId!, normalized);
    } else {
      await initialize(url: normalized);
    }
  }

  /// Changes the media source to a local device [File].
  Future<void> setSourceFile(File file) {
    return setSource(file.uri.toString());
  }

  /// Changes the media source to a bundled Flutter asset (e.g. `assets/videos/intro.mp4`).
  Future<void> setSourceAsset(String assetPath, {String? package}) {
    var cleanPath = assetPath.trim();
    while (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }
    final resolvedPath = package != null
        ? 'packages/$package/$cleanPath'
        : cleanPath;
    return setSource('asset:///$resolvedPath');
  }

  /// Starts playback. Restarts from the beginning if the video has ended.
  Future<void> play() async {
    if (isInitialized) {
      if (_playbackState == PlaybackState.ended ||
          (_duration > Duration.zero &&
              (_duration - _position).inMilliseconds.abs() < 250)) {
        await seekTo(Duration.zero);
      }
      await _hostApi.play(_textureId!);
    }
  }

  /// Pauses playback.
  Future<void> pause() async {
    if (isInitialized) {
      await _hostApi.pause(_textureId!);
    }
  }

  /// Seeks to a specific [position].
  Future<void> seekTo(Duration position) async {
    if (isInitialized) {
      await _hostApi.seekTo(_textureId!, position.inMilliseconds);
      _position = position;
      notifyListeners();
    }
  }

  /// Sets player audio volume between 0.0 (silent) and 1.0 (full volume).
  Future<void> setVolume(double volume) async {
    if (isInitialized) {
      await _hostApi.setVolume(_textureId!, volume.clamp(0.0, 1.0));
    }
  }

  /// Retrieves the current duration directly from the native player engine.
  Future<Duration> getDuration() async {
    if (isInitialized) {
      final ms = await _hostApi.getDuration(_textureId!);
      if (ms > 0) {
        _duration = Duration(milliseconds: ms);
        notifyListeners();
      }
    }
    return _duration;
  }

  /// Retrieves the current playback position directly from the native player engine.
  Future<Duration> getPosition() async {
    if (isInitialized) {
      final ms = await _hostApi.getPosition(_textureId!);
      if (ms >= 0) {
        _position = Duration(milliseconds: ms);
        notifyListeners();
      }
    }
    return _position;
  }

  /// Fetches available video qualities for the current media (e.g. HLS/DASH multi-bitrate streams).
  Future<List<VideoQuality>> getVideoQualities() async {
    if (isInitialized) {
      final qualities = await _hostApi.getVideoQualities(_textureId!);
      _videoQualities = List<VideoQuality>.unmodifiable(qualities);
      _qualitiesStreamController.add(_videoQualities);
      notifyListeners();
    }
    return _videoQualities;
  }

  /// Sets the video playback quality.
  /// Pass `"auto"` to restore adaptive bitrate streaming, or pass a specific [VideoQuality.id].
  Future<void> setVideoQuality(String qualityId) async {
    if (isInitialized) {
      await _hostApi.setVideoQuality(_textureId!, qualityId);
      await getVideoQualities();
    }
  }

  /// Sets the playback speed multiplier (e.g. 0.5, 0.75, 1.0, 1.25, 1.5, 2.0).
  /// Speeds are clamped between 0.25x and 4.0x.
  Future<void> setPlaybackSpeed(double speed) async {
    final clamped = speed.clamp(0.25, 4.0);
    _playbackSpeed = clamped;
    notifyListeners();
    if (isInitialized) {
      await _hostApi.setPlaybackSpeed(_textureId!, clamped);
    }
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    if (_textureId != null) {
      _activeControllers.remove(_textureId);
      await _hostApi.dispose(_textureId!);
      _textureId = null;
    }

    await _stateStreamController.close();
    await _positionStreamController.close();
    await _durationStreamController.close();
    await _bufferedStreamController.close();
    await _qualitiesStreamController.close();
    await _errorStreamController.close();

    super.dispose();
  }

  void _handlePlaybackStateChanged(PlaybackState state) {
    _playbackState = state;
    if (state == PlaybackState.ended && _duration > Duration.zero) {
      _position = _duration;
    }
    _stateStreamController.add(state);
    notifyListeners();
  }

  void _handlePositionChanged(
    int positionMs,
    int durationMs,
    int bufferedPositionMs,
  ) {
    final newPos = Duration(milliseconds: positionMs);
    final newDur = Duration(milliseconds: durationMs);
    final newBuf = Duration(milliseconds: bufferedPositionMs);

    final bool changed =
        _position != newPos ||
        _duration != newDur ||
        _bufferedPosition != newBuf;

    _position = newPos;
    if (newDur > Duration.zero) {
      _duration = newDur;
    }
    _bufferedPosition = newBuf;

    _positionStreamController.add(_position);
    if (_duration > Duration.zero) {
      _durationStreamController.add(_duration);
    }
    _bufferedStreamController.add(_bufferedPosition);

    if (changed) {
      notifyListeners();
    }
  }

  void _handleVideoQualitiesChanged(List<VideoQuality> qualities) {
    _videoQualities = List<VideoQuality>.unmodifiable(qualities);
    _qualitiesStreamController.add(_videoQualities);
    notifyListeners();
  }

  void _handleError(String errorCode, String errorMessage) {
    _errorMessage = '$errorCode: $errorMessage';
    _errorStreamController.add(_errorMessage!);
    notifyListeners();
  }

  /// Normalizes a URL for testing purposes.
  @visibleForTesting
  static String normalizeUrlForTesting(String url) => _normalizeUrl(url);

  /// Updates internal controller state for unit and widget testing.
  @visibleForTesting
  void updateStateForTesting({
    int? textureId,
    PlaybackState? playbackState,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    List<VideoQuality>? videoQualities,
    String? errorMessage,
  }) {
    if (textureId != null) _textureId = textureId;
    if (playbackState != null) {
      _playbackState = playbackState;
      _stateStreamController.add(playbackState);
    }
    if (position != null) {
      _position = position;
      _positionStreamController.add(position);
    }
    if (duration != null) {
      _duration = duration;
      _durationStreamController.add(duration);
    }
    if (bufferedPosition != null) {
      _bufferedPosition = bufferedPosition;
      _bufferedStreamController.add(bufferedPosition);
    }
    if (videoQualities != null) {
      _videoQualities = List<VideoQuality>.unmodifiable(videoQualities);
      _qualitiesStreamController.add(_videoQualities);
    }
    if (errorMessage != null) {
      _errorMessage = errorMessage;
      _errorStreamController.add(errorMessage);
    }
    notifyListeners();
  }
}

class _GlobalFlutterApiHandler implements BananaPlayerFlutterApi {
  @override
  void onPlaybackStateChanged(int textureId, PlaybackState state) {
    BananaPlayerController._activeControllers[textureId]
        ?._handlePlaybackStateChanged(state);
  }

  @override
  void onPositionChanged(
    int textureId,
    int positionMs,
    int durationMs,
    int bufferedPositionMs,
  ) {
    BananaPlayerController._activeControllers[textureId]
        ?._handlePositionChanged(positionMs, durationMs, bufferedPositionMs);
  }

  @override
  void onVideoQualitiesChanged(int textureId, List<VideoQuality> qualities) {
    BananaPlayerController._activeControllers[textureId]
        ?._handleVideoQualitiesChanged(qualities);
  }

  @override
  void onError(int textureId, String errorCode, String errorMessage) {
    BananaPlayerController._activeControllers[textureId]?._handleError(
      errorCode,
      errorMessage,
    );
  }
}
