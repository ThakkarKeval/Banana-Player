import 'dart:async';
import 'package:flutter/foundation.dart';
import 'player_api.g.dart';

/// Controller managing a native video player instance (ExoPlayer on Android, AVPlayer on iOS).
class BananaPlayerController extends ChangeNotifier {
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
  String? _errorMessage;
  bool _isDisposed = false;

  /// The native surface texture ID used by the Flutter [Texture] widget.
  int? get textureId => _textureId;

  /// Whether the player has been successfully created and has a valid texture.
  bool get isInitialized => _textureId != null && !_isDisposed;

  /// The current state of playback (`idle`, `buffering`, `ready`, `ended`).
  PlaybackState get playbackState => _playbackState;

  /// Whether the player is currently in the `ready` playback state.
  bool get isPlaying => _playbackState == PlaybackState.ready;

  /// Last known playback position.
  Duration get position => _position;

  /// Last error message, if any.
  String? get errorMessage => _errorMessage;

  // Streams for event-driven architectures
  final StreamController<PlaybackState> _stateStreamController =
      StreamController<PlaybackState>.broadcast();
  Stream<PlaybackState> get onPlaybackStateChanged =>
      _stateStreamController.stream;

  final StreamController<Duration> _positionStreamController =
      StreamController<Duration>.broadcast();
  Stream<Duration> get onPositionChanged =>
      _positionStreamController.stream;

  final StreamController<String> _errorStreamController =
      StreamController<String>.broadcast();
  Stream<String> get onError => _errorStreamController.stream;

  /// Initializes the native player with the given [url].
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
    final config = PlayerConfig(url: url, autoPlay: autoPlay, volume: volume);
    final textureId = await _hostApi.create(config);

    _textureId = textureId;
    _activeControllers[textureId] = this;
    notifyListeners();

    return textureId;
  }

  /// Changes the media source URL without destroying and recreating the surface or decoder.
  Future<void> setSource(String url) async {
    if (_isDisposed) {
      throw StateError('Cannot set source on a disposed BananaPlayerController');
    }
    _errorMessage = null;
    _playbackState = PlaybackState.buffering;
    notifyListeners();

    if (_textureId != null) {
      await _hostApi.setSource(_textureId!, url);
    } else {
      await initialize(url: url);
    }
  }

  /// Starts playback. Restarts from the beginning if the video has ended.
  Future<void> play() async {
    if (isInitialized) {
      if (_playbackState == PlaybackState.ended) {
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
    await _errorStreamController.close();

    super.dispose();
  }

  void _handlePlaybackStateChanged(PlaybackState state) {
    _playbackState = state;
    _stateStreamController.add(state);
    notifyListeners();
  }

  void _handlePositionChanged(int positionMs) {
    _position = Duration(milliseconds: positionMs);
    _positionStreamController.add(_position);
    notifyListeners();
  }

  void _handleError(String errorCode, String errorMessage) {
    _errorMessage = '$errorCode: $errorMessage';
    _errorStreamController.add(_errorMessage!);
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
  void onPositionChanged(int textureId, int positionMs) {
    BananaPlayerController._activeControllers[textureId]
        ?._handlePositionChanged(positionMs);
  }

  @override
  void onError(int textureId, String errorCode, String errorMessage) {
    BananaPlayerController._activeControllers[textureId]
        ?._handleError(errorCode, errorMessage);
  }
}
