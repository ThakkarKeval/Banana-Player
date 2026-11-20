# Banana Player Compatibility Matrix

This document outlines the official platform, dependency, and framework compatibility targets for `banana_player`.

---

## Target Matrix Overview

| Layer | Supported Version | Notes |
|:---|:---|:---|
| **Flutter SDK** | `>= 3.47.0` | Uses modern Flutter embedding and Pigeon `30.0.4` |
| **Dart SDK** | `^3.13.7` | Sound null-safety, records, and pattern matching |
| **Android compileSdk** | `36` (Android 16 / Vanilla Ice Cream) | Compatible with latest Android tooling |
| **Android minSdk** | `24` (Android 7.0 Nougat) | Covers >98% of active Android devices worldwide |
| **Android JVM / Java Target** | `Java 17` | Required by Android Gradle Plugin 8.x / 9.x |
| **Android Gradle Plugin (AGP)** | `9.3.1` (tested with 8.x - 9.x) | Uses Gradle version catalog `gradle/libs.versions.toml` |
| **Kotlin** | `2.4.21` (tested with 1.9.x - 2.x) | Modern Kotlin compiler and language features |
| **AndroidX Media3** | `1.5.1` | ExoPlayer core, HLS, DASH, and DefaultLoadControl |
| **Kotlin Coroutines** | `1.8.1` | `kotlinx-coroutines-android` & `kotlinx-coroutines-test` |
| **iOS Target** | `iOS 15.0+` | AVPlayer / AVFoundation hardware decoding |

---

## Android Dependency Centralization

All native Android versions are centrally maintained in both:
1. **Gradle Version Catalog**: [`android/gradle/libs.versions.toml`](android/gradle/libs.versions.toml)
2. **Centralized Versions Object**: [`android/build.gradle.kts`](android/build.gradle.kts)

### Android Version Catalog (`libs.versions.toml`)
```toml
[versions]
agp = "9.3.1"
kotlin = "2.4.21"
compileSdk = "36"
minSdk = "24"
media3 = "1.5.1"
coroutines = "1.8.1"
mockito = "5.11.0"

[libraries]
media3-exoplayer = { module = "androidx.media3:media3-exoplayer", version.ref = "media3" }
media3-exoplayer-hls = { module = "androidx.media3:media3-exoplayer-hls", version.ref = "media3" }
media3-exoplayer-dash = { module = "androidx.media3:media3-exoplayer-dash", version.ref = "media3" }
kotlinx-coroutines-android = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-android", version.ref = "coroutines" }
kotlinx-coroutines-test = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-test", version.ref = "coroutines" }
mockito-core = { module = "org.mockito:mockito-core", version.ref = "mockito" }
```

---

## Media3 Capabilities & Format Support

| Protocol / Container | Status | Under the Hood |
|:---|:---:|:---|
| **HLS (`.m3u8`)** | Supported | `androidx.media3:media3-exoplayer-hls:1.5.1` |
| **DASH (`.mpd`)** | Supported | `androidx.media3:media3-exoplayer-dash:1.5.1` |
| **Progressive MP4, WebM, MKV** | Supported | `androidx.media3:media3-exoplayer:1.5.1` |
| **Closed Captions / Subtitles** | Supported | Embedded CEA-608/708, WebVTT, and SubRip text tracks |
| **Adaptive Bitrate (ABR)** | Supported | Automatic resolution/bitrate switching with manual track override |
| **Flutter SurfaceTexture** | Supported | Direct GPU texture rendering via `TextureRegistry.SurfaceTextureEntry` |

---

## Upgrades & Compatibility Policy

- **Media3 Updates**: We keep Media3 pinned to stable releases (`1.5.x`). When upgrading Media3, ensure all modules (`exoplayer`, `hls`, `dash`) share the identical version to avoid ABI incompatibilities.
- **Flutter Compatibility**: Upgrades to Pigeon and Flutter platform channels are backward-compatible with Flutter `>= 3.47.0`.
