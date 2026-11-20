# Compatibility

## Flutter and Dart

- Flutter: 3.47.0 or later
- Dart: 3.13.7 or later

## Android

- Minimum Android API: 24
- Compile SDK: 36
- Java and Kotlin JVM target: 17
- Android Gradle Plugin: 9.3.1
- Kotlin: 2.4.21
- Media3 / ExoPlayer: 1.5.1

The Android backend includes Media3's progressive, HLS, and DASH modules. Available codecs and formats still depend on the Android device.

## iOS

- Minimum deployment target: iOS 15.0
- Native backend: AVPlayer / AVFoundation
- Manual variant selection is available for HLS streams when the OS exposes variant metadata. Other sources may expose no selectable quality list.

## Source types

The controller accepts HTTP(S) URLs, local file paths and file:// URLs, and Flutter assets. Network access requires the host application's network policy and platform permissions to allow the requested URL.
