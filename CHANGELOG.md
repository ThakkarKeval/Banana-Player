## 0.0.4

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
