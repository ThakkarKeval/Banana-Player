## 0.0.7

* **Modular Android Player Architecture**: Decomposed `BananaPlayer` into dedicated, single-responsibility collaborators:
  * `MediaUriResolver`: Handles network, local filesystem (`file://`), and Flutter asset (`asset://`) URI resolution.
  * `PlayerTrackManager`: Encapsulates video quality track parsing, ABR overrides, and closed captions/subtitle selection.
  * `PlayerEventNotifier`: Dispatches structured, throttled playback and position events to Flutter with diagnostic logging.
  * `BananaPlayerInstance`: Contract interface enabling mock/fake injection and decoupling.
* **Predictable Error Handling**: Added typed `FlutterError` exceptions (`player_not_found`, `invalid_argument`, `plugin_not_attached`) across host API endpoints instead of silently returning default values.
* **Thread Safety & Lifecycle**: Secured player session storage using `ConcurrentHashMap` with atomic teardown upon engine detachment.
* **Centralized Dependency Management**:
  * Added Gradle Version Catalog (`android/gradle/libs.versions.toml`) pinning AndroidX Media3 (`1.5.1`), Coroutines (`1.8.1`), and Mockito (`5.11.0`).
  * Added [COMPATIBILITY.md](COMPATIBILITY.md) detailing SDK targets, JVM limits, and supported media formats.
* **Comprehensive Test Suite**:
  * Added native unit tests for Android plugin, URI resolver, event notifier, and track manager.
  * Added end-to-end integration tests covering Dart-to-native communication, event streaming, multi-player isolation, and hardware texture rendering.

## 0.0.6

* Upgraded Pigeon bridge code generator to `^30.0.4` and regenerated Dart, Kotlin, and Swift communication bindings.
* Upgraded Android build toolchain to Android Gradle Plugin `9.3.1`, Gradle `9.9.1`, and Kotlin `2.4.21`.
* Updated dependencies to latest stable versions (`meta: ^1.19.0`, `cupertino_icons: ^2.0.0`).
* Verified native Android compilation and test passes.

## 0.0.5

* Decoupled `BananaSeekBar` and player views from `package:flutter/material.dart` in favor of core `package:flutter/widgets.dart` for Flutter 3.50+ compliance (50/50 pub.dev static analysis score).
* Hardened `BananaPlayerController` lifecycle against async initialization race conditions using generation counters and immediate orphaned texture cleanup.
* Prevented stream exceptions, listener notifications, and memory leaks on post-disposal native events.
* Added boundary clamping and state synchronization to `seekTo` (resetting `ended` state when seeking backwards).
* Added proper recovery to `idle` state upon native playback errors across Android Media3 and iOS AVPlayer.
* Fixed iOS `AVPlayerItemVideoOutput` cleanup leak in `removeItemObservers()` and added synthetic `auto` track option for parity with Android.
* Made Android and iOS native player `dispose()` calls strictly idempotent.
* Aligned Dart and Flutter SDK environment constraints (`sdk: ^3.13.7` with `flutter: '>=3.47.0'`).
* Hardened README documentation examples with subtitle track safety guards and clarified consumer design system requirements.
* Added 5 focused regression tests covering boundary seeks, idempotent disposal, post-disposal initialization guards, and stale event rejection.

## 0.0.4

* Added **Closed Captions & Subtitles** support across Android (Media3 ExoPlayer) and iOS (AVPlayer):
  * Query embedded subtitle tracks (`getSubtitleTracks()`).
  * Dynamic track switching and disabling (`setSubtitleTrack(...)`, `disableSubtitles()`).
  * Real-time subtitle cue notifications via `onSubtitleTextChanged` and `onSubtitleTracksChanged` streams.
  * Built-in, fully customizable subtitle overlay in `BananaPlayerView` with typography, decoration, padding, and custom builder support.
* Expanded test coverage with comprehensive unit and widget tests for `BananaPlayerController`, `BananaPlayerView`, and `BananaSeekBar`.
* Documented library, constructors, and event stream getters (zero `dartdoc` warnings).
* Added GitHub Actions continuous integration (CI) workflow for automated linting, testing, and formatting verification.
* Excluded test coverage and local documentation artifacts in `.pubignore`.

## 0.0.3

* Added local storage media playback support (`file://` URIs and raw filesystem paths).
* Added bundled Flutter asset playback support (`initializeAsset(...)`, `setSourceAsset(...)`).
* Added `initializeFile(...)` and `setSourceFile(...)` convenience methods to `BananaPlayerController`.
* Automatic normalization of file paths and asset paths across Android and iOS engines.
* Expanded documentation with local file and asset quickstart examples.

## 0.0.2

* Verified repository, issue tracker, and metadata configuration.
* Added documentation and project links for pub.dev.

## 0.0.1

* Initial release of Banana Player.
* Android native playback engine powered by AndroidX Media3 / ExoPlayer.
* iOS native playback engine powered by AVPlayer.
* Native texture rendering via Flutter `Texture` widget.
* Multi-bitrate HLS and adaptive stream support with automatic and manual video track / quality selection.
* Playback speed control (0.25x – 2.0x).
* Highly customizable `BananaSeekBar` supporting custom thumb, track, leading, trailing, and scrub tooltip widgets.
* Typed native interop powered by Pigeon.
