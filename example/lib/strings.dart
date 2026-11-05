/// Centralized string constants and formatting helpers for the Banana Player example app.
abstract final class AppStrings {
  // App Title
  static const String appTitle = 'Banana Player';

  // Branding & Header
  static const String brandBanana = 'BANANA';
  static const String brandPlayer = 'PLAYER';
  static const String cinemaEdition = 'CINEMA EDITION';
  static const String playerViewPlugin = 'Player View Plugin';

  // Formatter defaults
  static const String zeroDuration = '0:00';

  // Player Stage
  static const String preparingStream = 'Preparing Stream...';
  static String loadingPreset(String title) => 'Loading $title...';

  // Playback States
  static const String statePlaying = 'PLAYING';
  static const String stateBuffering = 'BUFFERING';
  static const String stateEnded = 'ENDED (TAP PLAY)';
  static const String statePaused = 'PAUSED';
  static const String stateIdle = 'IDLE';

  // Speed Badge & Picker
  static const String playbackSpeed = 'Playback Speed';
  static const String speedNormal = '1.0x • Normal';
  static String speedActive(String speed) => '${speed}x ACTIVE';
  static String speedLabel(double speed) => speed == 1.0
      ? '1.0x'
      : '${speed.toStringAsFixed(speed % 1 == 0 ? 0 : 2)}x';
  static String speedPickerItem(double speed) =>
      speed == 1.0 ? speedNormal : '${speed}x';

  // Quality Badge & Picker
  static const String videoStreamQuality = 'Video Stream Quality';
  static const String hlsAbr = 'HLS ABR';
  static const String qualityAuto = 'Auto';
  static const String qualityHd = 'HD';
  static const String qualityAutoId = 'auto';
  static const String adaptiveBitrateDesc = 'Adaptive bitrate based on network';
  static String bitrateMbps(double bitrate) =>
      ' • ${(bitrate / 1000000).toStringAsFixed(1)} Mbps';
  static String fps(int frameRate) => ' • $frameRate fps';
  static String fpsBadge(int frameRate) => '$frameRate FPS';

  // Control Deck
  static const String defaultSeekbarView = 'DEFAULT SEEKBAR VIEW';
  static const String customWidgets = 'CUSTOM WIDGETS';
  static const String showDefaultView = 'Show Default View';
  static const String tryCustomWidgets = 'Try Custom Direct Widgets';
  static const String preview1080p = '1080p';

  // Tooltips
  static const String tooltipReplay = 'Replay (0s)';
  static const String tooltipRewind10 = 'Rewind 10s';
  static const String tooltipForward10 = 'Forward 10s';
  static const String tooltipMute = 'Mute';
  static const String tooltipUnmute = 'Unmute';

  // Stream Presets Section
  static const String selectStream = 'Select Stream';
  static const String streamPresets = 'STREAM PRESETS';

  // Presets Data
  static const String presetButterflyTitle = 'Flutter Butterfly';
  static const String presetButterflySubtitle = 'Nature Demo • MP4';
  static const String presetButterflyTag = 'MP4 HD';
  static const String presetButterflyUrl =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';

  static const String presetAppleTitle = 'Apple Advanced HLS';
  static const String presetAppleSubtitle = 'Multi-rate 60/30 FPS • HLS fMP4';
  static const String presetAppleTag = 'HLS 60FPS';
  static const String presetAppleUrl =
      'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8';

  static const String presetMuxTitle = 'Mux Adaptive Stream';
  static const String presetMuxSubtitle = 'Multi-bitrate Stream • HLS';
  static const String presetMuxTag = 'HLS LIVE';
  static const String presetMuxUrl =
      'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';
}
