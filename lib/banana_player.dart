import 'dart:async';
import 'package:flutter/widgets.dart';
import 'src/player_api.g.dart';

export 'src/player_api.g.dart' show PlaybackState, PlayerConfig;

class BananaPlayerController {
  BananaPlayerController() {
    _ensureFlutterApiInitialized();
  }

  static bool _apiInitialized = false;
  static final Map<int, BananaPlayerController> _controllers = {};

  static void _ensureFlutterApiInitialized() {
    if (!_apiInitialized) {
      BananaPlayerFlutterApi.setUp(_GlobalFlutterApiHandler());
      _apiInitialized = true;
    }
  }

  final BananaPlayerHostApi _hostApi = BananaPlayerHostApi();

  int? _textureId;
  int? get textureId => _textureId;

  PlaybackState _playbackState = PlaybackState.idle;
  PlaybackState get playbackState => _playbackState;

  final StreamController<PlaybackState> _stateStreamController =
      StreamController<PlaybackState>.broadcast();
  Stream<PlaybackState> get onPlaybackStateChanged =>
      _stateStreamController.stream;

  final StreamController<int> _positionStreamController =
      StreamController<int>.broadcast();
  Stream<int> get onPositionChanged => _positionStreamController.stream;

  final StreamController<String> _errorStreamController =
      StreamController<String>.broadcast();
  Stream<String> get onError => _errorStreamController.stream;

  bool _isDisposed = false;

  Future<int> initialize({
    required String url,
    bool autoPlay = true,
    double volume = 1.0,
  }) async {
    final config = PlayerConfig(url: url, autoPlay: autoPlay, volume: volume);
    final textureId = await _hostApi.create(config);
    _textureId = textureId;
    _controllers[textureId] = this;
    return textureId;
  }

  Future<void> play() async {
    if (_textureId != null && !_isDisposed) {
      await _hostApi.play(_textureId!);
    }
  }

  Future<void> pause() async {
    if (_textureId != null && !_isDisposed) {
      await _hostApi.pause(_textureId!);
    }
  }

  Future<void> seekTo(Duration position) async {
    if (_textureId != null && !_isDisposed) {
      await _hostApi.seekTo(_textureId!, position.inMilliseconds);
    }
  }

  Future<void> setVolume(double volume) async {
    if (_textureId != null && !_isDisposed) {
      await _hostApi.setVolume(_textureId!, volume.clamp(0.0, 1.0));
    }
  }

  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    if (_textureId != null) {
      _controllers.remove(_textureId);
      await _hostApi.dispose(_textureId!);
    }
    await _stateStreamController.close();
    await _positionStreamController.close();
    await _errorStreamController.close();
  }

  void _handlePlaybackStateChanged(PlaybackState state) {
    _playbackState = state;
    _stateStreamController.add(state);
  }

  void _handlePositionChanged(int positionMs) {
    _positionStreamController.add(positionMs);
  }

  void _handleError(String errorCode, String errorMessage) {
    _errorStreamController.add('$errorCode: $errorMessage');
  }
}

class _GlobalFlutterApiHandler implements BananaPlayerFlutterApi {
  @override
  void onPlaybackStateChanged(int textureId, PlaybackState state) {
    BananaPlayerController._controllers[textureId]?._handlePlaybackStateChanged(
      state,
    );
  }

  @override
  void onPositionChanged(int textureId, int positionMs) {
    BananaPlayerController._controllers[textureId]?._handlePositionChanged(
      positionMs,
    );
  }

  @override
  void onError(int textureId, String errorCode, String errorMessage) {
    BananaPlayerController._controllers[textureId]?._handleError(
      errorCode,
      errorMessage,
    );
  }
}

/// A convenience widget to display the video texture for a [BananaPlayerController].
class BananaPlayerView extends StatelessWidget {
  const BananaPlayerView({super.key, required this.controller});

  final BananaPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final textureId = controller.textureId;
    if (textureId == null) {
      return const SizedBox.shrink();
    }
    return Texture(textureId: textureId);
  }
}
