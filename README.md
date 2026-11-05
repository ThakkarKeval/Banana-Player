# Banana Player 🍌

A high-performance, cross-platform video player plugin for Flutter. Powered natively by **AndroidX Media3 (ExoPlayer)** on Android and **AVPlayer** on iOS, rendered directly into Flutter via hardware-accelerated `Texture` widgets.

[![pub package](https://img.shields.io/pub/v/banana_player.svg)](https://pub.dev/packages/banana_player)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub](https://img.shields.io/github/stars/ThakkarKeval/Banana-Player?style=social)](https://github.com/ThakkarKeval/Banana-Player)

---

## Features

* 🚀 **Native Texture Rendering**: Direct GPU-to-GPU surface texture rendering—no expensive platform view hierarchy overlay.
* 📱 **Dual Engine Support**:
  * **Android**: AndroidX Media3 / ExoPlayer with HLS and DASH extensions.
  * **iOS**: Native AVPlayer with HLS stream support.
* 🎚️ **Adaptive Bitrate & Quality Selection**: Read video track resolutions, bitrates, and frame rates on the fly; switch tracks manually or let ABR adapt automatically.
* ⏩ **Variable Playback Speed**: Smooth rate switching from `0.25x` to `2.0x`.
* 🎯 **BananaSeekBar Widget**:
  * Dual-track progress bar (active playback + buffered range).
  * Scrubbing preview tooltip (`scrubTooltipBuilder`).
  * Direct widget slot overrides for custom thumbs, tracks, leading, and trailing badges.
* 📡 **Event-Driven Architecture**: Listen to state, position, buffer, and quality changes via streams or `ChangeNotifier`.

---

## Platform Support

| Platform | Minimum Version | Native Backend |
| :--- | :--- | :--- |
| **Android** | API 24 (Android 7.0+) | AndroidX Media3 / ExoPlayer 1.5.1 |
| **iOS** | iOS 15.0+ | AVPlayer / AVFoundation |

---

## Installation

Add `banana_player` to your `pubspec.yaml`:

```yaml
dependencies:
  banana_player: ^0.0.1
```

Or run:

```bash
flutter pub add banana_player
```

### Android Configuration

Ensure your `android/app/build.gradle.kts` has a `minSdk` of 24 or higher:

```kotlin
android {
    defaultConfig {
        minSdk = 24
    }
}
```

Internet permission is automatically included by the plugin's manifest. If loading insecure `http://` streams, enable cleartext traffic in your application manifest:

```xml
<application
    android:usesCleartextTraffic="true"
    ...>
</application>
```

### iOS Configuration

Ensure your iOS deployment target is 15.0 or higher in `ios/Podfile`:

```ruby
platform :ios, '15.0'
```

If loading insecure `http://` streams, configure App Transport Security in `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

---

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:banana_player/banana_player.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final BananaPlayerController _controller = BananaPlayerController();

  @override
  void initState() {
    super.initState();
    _controller.initialize(
      url: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      autoPlay: true,
      volume: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // 1. Video surface
              BananaPlayerView(
                controller: _controller,
                placeholder: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),

              // 2. Seek bar
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: BananaSeekBar(
                  controller: _controller,
                  activeTrackColor: Colors.amber,
                  thumbColor: Colors.amberAccent,
                  showTimeLabels: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Advanced Usage

### 1. Local Files & Bundled Assets

Play local device files or packaged Flutter assets directly:

```dart
// 1. Play from local device file (downloaded / recorded)
final File videoFile = File('/path/to/video.mp4');
await _controller.initializeFile(videoFile);

// 2. Play from bundled Flutter asset
await _controller.initializeAsset('assets/videos/intro.mp4');

// 3. Or use initialize with automatic path resolution
await _controller.initialize(url: '/storage/emulated/0/Download/movie.mp4');
await _controller.initialize(url: 'assets/videos/intro.mp4');
```

### 2. Quality Selection (HLS / Multi-bitrate)

```dart
// Inspect available video streams
final List<VideoQuality> qualities = _controller.videoQualities;

for (final quality in qualities) {
  print('${quality.label} - ${quality.width}x${quality.height} @ ${quality.bitrate} bps');
}

// Switch to a specific resolution (e.g. '1080p') or back to auto ABR
_controller.setVideoQuality('auto');
```

### 2. Custom Seek Bar Overrides

`BananaSeekBar` supports complete custom widget replacement for thumbs, badges, and scrub tooltips:

```dart
BananaSeekBar(
  controller: _controller,
  activeTrackColor: Colors.amber,
  bufferedTrackColor: Colors.white24,
  showTimeLabels: false,
  // Custom thumb widget
  customThumb: Container(
    width: 20,
    height: 20,
    decoration: const BoxDecoration(
      color: Colors.amber,
      shape: BoxShape.circle,
    ),
    child: const Icon(Icons.play_arrow, size: 12, color: Colors.black),
  ),
  // Custom floating scrub tooltip
  scrubTooltipBuilder: (context, scrubPosition) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${scrubPosition.inMinutes}:${(scrubPosition.inSeconds % 60).toString().padLeft(2, '0')}',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  },
)
```

---

## API Reference

### `BananaPlayerController`

| Property / Method | Description |
|:---|:---|
| `initialize({required String url, bool autoPlay, double volume})` | Creates the native player instance (network stream, local file, or asset). |
| `initializeFile(File file, {bool autoPlay, double volume})` | Initializes playback from a local device `File`. |
| `initializeAsset(String assetPath, {bool autoPlay, double volume, String? package})` | Initializes playback from a bundled Flutter asset. |
| `setSource(String url)` | Changes the media source URL without destroying the surface or decoder. |
| `setSourceFile(File file)` | Changes the media source to a local device `File`. |
| `setSourceAsset(String assetPath, {String? package})` | Changes the media source to a bundled Flutter asset. |
| `play()` / `pause()` | Controls playback state. |
| `seekTo(Duration position)` | Seeks native player to target duration. |
| `setPlaybackSpeed(double speed)` | Sets playback speed (e.g., 0.5, 1.0, 1.5, 2.0). |
| `setVideoQuality(String qualityId)` | Switches video stream quality track. |
| `setVolume(double volume)` | Sets output audio volume (`0.0` to `1.0`). |
| `playbackState` | Current `PlaybackState` (`idle`, `buffering`, `ready`, `ended`, `paused`). |
| `videoQualities` | List of available `VideoQuality` tracks. |
| `position` / `duration` / `bufferedPosition` | Duration metrics. |
| `dispose()` | Releases native player and texture resources. |

---

## Author

Created and maintained by **Keval Thakkar** ([thakkarkpt123@gmail.com](mailto:thakkarkpt123@gmail.com) • [GitHub](https://github.com/ThakkarKeval)).

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
