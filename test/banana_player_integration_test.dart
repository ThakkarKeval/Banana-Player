import 'package:banana_player/banana_player.dart';
import 'package:banana_player/src/player_api.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const codec = BananaPlayerHostApi.pigeonChannelCodec;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<Map<String, Object?>> recordedNativeCalls;
  bool emitReadyDuringCreate = false;
  int nextTextureId = 100;

  setUp(() {
    recordedNativeCalls = [];
    emitReadyDuringCreate = false;
    nextTextureId = 100;

    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.create',
      (ByteData? message) async {
        final args = codec.decodeMessage(message) as List<Object?>?;
        final config = args?[0] as PlayerConfig?;
        final assignedId = ++nextTextureId;
        recordedNativeCalls.add({
          'method': 'create',
          'url': config?.url,
          'autoPlay': config?.autoPlay,
          'volume': config?.volume,
          'assignedId': assignedId,
        });
        if (emitReadyDuringCreate) {
          await messenger.handlePlatformMessage(
            'dev.flutter.pigeon.banana_player.BananaPlayerFlutterApi.onPlaybackStateChanged',
            codec.encodeMessage(<Object?>[assignedId, PlaybackState.ready]),
            (_) {},
          );
        }
        return codec.encodeMessage(<Object?>[assignedId]);
      },
    );

    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.play',
      (ByteData? message) async {
        final args = codec.decodeMessage(message) as List<Object?>?;
        recordedNativeCalls.add({'method': 'play', 'textureId': args?[0]});
        return codec.encodeMessage(<Object?>[null]);
      },
    );

    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.pause',
      (ByteData? message) async {
        final args = codec.decodeMessage(message) as List<Object?>?;
        recordedNativeCalls.add({'method': 'pause', 'textureId': args?[0]});
        return codec.encodeMessage(<Object?>[null]);
      },
    );

    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.setSource',
      (ByteData? message) async {
        final args = codec.decodeMessage(message) as List<Object?>?;
        recordedNativeCalls.add({
          'method': 'setSource',
          'textureId': args?[0],
          'url': args?[1],
        });
        return codec.encodeMessage(<Object?>[null]);
      },
    );

    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.seekTo',
      (ByteData? message) async {
        final args = codec.decodeMessage(message) as List<Object?>?;
        recordedNativeCalls.add({
          'method': 'seekTo',
          'textureId': args?[0],
          'positionMs': args?[1],
        });
        return codec.encodeMessage(<Object?>[null]);
      },
    );

    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.setVolume',
      (ByteData? message) async {
        final args = codec.decodeMessage(message) as List<Object?>?;
        recordedNativeCalls.add({
          'method': 'setVolume',
          'textureId': args?[0],
          'volume': args?[1],
        });
        return codec.encodeMessage(<Object?>[null]);
      },
    );

    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.setPlaybackSpeed',
      (ByteData? message) async {
        final args = codec.decodeMessage(message) as List<Object?>?;
        recordedNativeCalls.add({
          'method': 'setPlaybackSpeed',
          'textureId': args?[0],
          'speed': args?[1],
        });
        return codec.encodeMessage(<Object?>[null]);
      },
    );

    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.getVideoQualities',
      (ByteData? message) async {
        final args = codec.decodeMessage(message) as List<Object?>?;
        recordedNativeCalls.add({
          'method': 'getVideoQualities',
          'textureId': args?[0],
        });
        return codec.encodeMessage(<Object?>[<Object?>[]]);
      },
    );

    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.setVideoQuality',
      (ByteData? message) async {
        final args = codec.decodeMessage(message) as List<Object?>?;
        recordedNativeCalls.add({
          'method': 'setVideoQuality',
          'textureId': args?[0],
          'qualityId': args?[1],
        });
        return codec.encodeMessage(<Object?>[null]);
      },
    );

    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.getSubtitleTracks',
      (ByteData? message) async {
        final args = codec.decodeMessage(message) as List<Object?>?;
        recordedNativeCalls.add({
          'method': 'getSubtitleTracks',
          'textureId': args?[0],
        });
        return codec.encodeMessage(<Object?>[<Object?>[]]);
      },
    );

    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.setSubtitleTrack',
      (ByteData? message) async {
        final args = codec.decodeMessage(message) as List<Object?>?;
        recordedNativeCalls.add({
          'method': 'setSubtitleTrack',
          'textureId': args?[0],
          'trackId': args?[1],
        });
        return codec.encodeMessage(<Object?>[null]);
      },
    );

    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.getDuration',
      (ByteData? message) async {
        final args = codec.decodeMessage(message) as List<Object?>?;
        recordedNativeCalls.add({
          'method': 'getDuration',
          'textureId': args?[0],
        });
        return codec.encodeMessage(<Object?>[60000]);
      },
    );

    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.getPosition',
      (ByteData? message) async {
        final args = codec.decodeMessage(message) as List<Object?>?;
        recordedNativeCalls.add({
          'method': 'getPosition',
          'textureId': args?[0],
        });
        return codec.encodeMessage(<Object?>[15000]);
      },
    );

    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.dispose',
      (ByteData? message) async {
        final args = codec.decodeMessage(message) as List<Object?>?;
        recordedNativeCalls.add({
          'method': 'dispose',
          'textureId': args?[0],
        });
        return codec.encodeMessage(<Object?>[null]);
      },
    );
  });

  tearDown(() {
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.create',
      null,
    );
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.play',
      null,
    );
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.pause',
      null,
    );
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.setSource',
      null,
    );
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.seekTo',
      null,
    );
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.setVolume',
      null,
    );
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.setPlaybackSpeed',
      null,
    );
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.getVideoQualities',
      null,
    );
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.setVideoQuality',
      null,
    );
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.getSubtitleTracks',
      null,
    );
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.setSubtitleTrack',
      null,
    );
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.getDuration',
      null,
    );
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.getPosition',
      null,
    );
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.banana_player.BananaPlayerHostApi.dispose',
      null,
    );
  });

  group('BananaPlayer Dart-to-Native Host API Integration', () {
    test(
      'applies playback speed selected before initialization',
      () async {
        final controller = BananaPlayerController();
        await controller.setPlaybackSpeed(1.5);

        await controller.initialize(url: 'https://example.com/video.mp4');

        final createIndex = recordedNativeCalls.indexWhere(
          (call) => call['method'] == 'create',
        );
        final speedIndex = recordedNativeCalls.indexWhere(
          (call) => call['method'] == 'setPlaybackSpeed',
        );
        expect(controller.playbackSpeed, 1.5);
        expect(speedIndex, greaterThan(createIndex));
        expect(recordedNativeCalls[speedIndex]['speed'], 1.5);
        await controller.dispose();
      },
    );

    test(
      'buffers native events emitted before create returns',
      () async {
        emitReadyDuringCreate = true;
        final controller = BananaPlayerController();

        await controller.initialize(url: 'https://example.com/video.mp4');

        expect(controller.playbackState, PlaybackState.ready);
        await controller.dispose();
      },
    );

    test('initializes and dispatches control calls across host channels', () async {
      final controller = BananaPlayerController();
      expect(controller.isInitialized, isFalse);

      await controller.initialize(
        url: 'https://example.com/video.mp4',
        autoPlay: true,
        volume: 0.75,
      );

      expect(controller.isInitialized, isTrue);
      expect(controller.textureId, 101);

      // Verify create call recorded
      expect(recordedNativeCalls.first['method'], 'create');
      expect(recordedNativeCalls.first['url'], 'https://example.com/video.mp4');
      expect(recordedNativeCalls.first['autoPlay'], true);
      expect(recordedNativeCalls.first['volume'], 0.75);

      // Play & Pause
      await controller.play();
      expect(recordedNativeCalls.any((c) => c['method'] == 'play' && c['textureId'] == 101), isTrue);

      await controller.pause();
      expect(recordedNativeCalls.any((c) => c['method'] == 'pause' && c['textureId'] == 101), isTrue);

      // Seek
      await controller.seekTo(const Duration(seconds: 42));
      expect(
        recordedNativeCalls.any((c) => c['method'] == 'seekTo' && c['textureId'] == 101 && c['positionMs'] == 42000),
        isTrue,
      );

      // Volume & Speed
      await controller.setVolume(0.5);
      expect(
        recordedNativeCalls.any((c) => c['method'] == 'setVolume' && c['textureId'] == 101 && c['volume'] == 0.5),
        isTrue,
      );

      await controller.setPlaybackSpeed(1.5);
      expect(
        recordedNativeCalls.any((c) => c['method'] == 'setPlaybackSpeed' && c['textureId'] == 101 && c['speed'] == 1.5),
        isTrue,
      );

      // Set source
      await controller.setSource('https://example.com/video2.mp4');
      expect(
        recordedNativeCalls.any((c) => c['method'] == 'setSource' && c['textureId'] == 101 && c['url'] == 'https://example.com/video2.mp4'),
        isTrue,
      );

      // Video Quality & Subtitle Track
      await controller.setVideoQuality('1080p');
      expect(
        recordedNativeCalls.any((c) => c['method'] == 'setVideoQuality' && c['textureId'] == 101 && c['qualityId'] == '1080p'),
        isTrue,
      );

      await controller.setSubtitleTrack('en');
      expect(
        recordedNativeCalls.any((c) => c['method'] == 'setSubtitleTrack' && c['textureId'] == 101 && c['trackId'] == 'en'),
        isTrue,
      );

      // Dispose
      await controller.dispose();
      expect(recordedNativeCalls.last, {'method': 'dispose', 'textureId': 101});
      expect(controller.isInitialized, isFalse);
    });
  });

  group('BananaPlayer Native-to-Dart FlutterApi Event Delivery', () {
    test('routes inbound platform events to controller state and streams', () async {
      final controller = BananaPlayerController();
      controller.updateStateForTesting(textureId: 105);

      PlaybackState? stateReceived;
      Duration? posReceived;
      Duration? durReceived;
      Duration? bufReceived;
      List<VideoQuality>? qualitiesReceived;
      List<SubtitleTrack>? subtitlesReceived;
      String? subtitleTextReceived;
      String? errorReceived;

      final s1 = controller.onPlaybackStateChanged.listen((s) => stateReceived = s);
      final s2 = controller.onPositionChanged.listen((p) => posReceived = p);
      final s3 = controller.onDurationChanged.listen((d) => durReceived = d);
      final s4 = controller.onBufferedPositionChanged.listen((b) => bufReceived = b);
      final s5 = controller.onVideoQualitiesChanged.listen((q) => qualitiesReceived = q);
      final s6 = controller.onSubtitleTracksChanged.listen((t) => subtitlesReceived = t);
      final s7 = controller.onSubtitleTextChanged.listen((txt) => subtitleTextReceived = txt);
      final s8 = controller.onError.listen((e) => errorReceived = e);

      // 1. Simulate onPlaybackStateChanged
      await messenger.handlePlatformMessage(
        'dev.flutter.pigeon.banana_player.BananaPlayerFlutterApi.onPlaybackStateChanged',
        codec.encodeMessage(<Object?>[105, PlaybackState.ready]),
        (_) {},
      );
      expect(controller.playbackState, PlaybackState.ready);
      expect(stateReceived, PlaybackState.ready);

      // 2. Simulate onPositionChanged
      await messenger.handlePlatformMessage(
        'dev.flutter.pigeon.banana_player.BananaPlayerFlutterApi.onPositionChanged',
        codec.encodeMessage(<Object?>[105, 15000, 120000, 45000]),
        (_) {},
      );
      expect(controller.position, const Duration(seconds: 15));
      expect(controller.duration, const Duration(seconds: 120));
      expect(controller.bufferedPosition, const Duration(seconds: 45));
      expect(posReceived, const Duration(seconds: 15));
      expect(durReceived, const Duration(seconds: 120));
      expect(bufReceived, const Duration(seconds: 45));

      // 3. Simulate onVideoQualitiesChanged
      final qualities = [
        VideoQuality(id: 'auto', width: 0, height: 0, bitrate: 0, isSelected: true),
        VideoQuality(id: '1080p', width: 1920, height: 1080, bitrate: 5000000, isSelected: false),
      ];
      await messenger.handlePlatformMessage(
        'dev.flutter.pigeon.banana_player.BananaPlayerFlutterApi.onVideoQualitiesChanged',
        codec.encodeMessage(<Object?>[105, qualities]),
        (_) {},
      );
      expect(controller.videoQualities.length, 2);
      expect(controller.selectedQuality?.id, 'auto');
      expect(qualitiesReceived?.length, 2);

      // 4. Simulate onSubtitleTracksChanged
      final subtitles = [
        SubtitleTrack(id: 'off', label: 'Off', isSelected: false),
        SubtitleTrack(id: 'en', label: 'English', language: 'en', isSelected: true),
      ];
      await messenger.handlePlatformMessage(
        'dev.flutter.pigeon.banana_player.BananaPlayerFlutterApi.onSubtitleTracksChanged',
        codec.encodeMessage(<Object?>[105, subtitles]),
        (_) {},
      );
      expect(controller.subtitleTracks.length, 2);
      expect(controller.isSubtitlesEnabled, isTrue);
      expect(subtitlesReceived?.length, 2);

      // 5. Simulate onSubtitleTextChanged
      await messenger.handlePlatformMessage(
        'dev.flutter.pigeon.banana_player.BananaPlayerFlutterApi.onSubtitleTextChanged',
        codec.encodeMessage(<Object?>[105, 'Hello from Banana Player']),
        (_) {},
      );
      expect(controller.currentSubtitleText, 'Hello from Banana Player');
      expect(subtitleTextReceived, 'Hello from Banana Player');

      // 6. Simulate onError
      await messenger.handlePlatformMessage(
        'dev.flutter.pigeon.banana_player.BananaPlayerFlutterApi.onError',
        codec.encodeMessage(<Object?>[105, 'IO_ERROR', 'Network connection timed out']),
        (_) {},
      );
      expect(controller.errorMessage, 'IO_ERROR: Network connection timed out');
      expect(errorReceived, 'IO_ERROR: Network connection timed out');

      await s1.cancel();
      await s2.cancel();
      await s3.cancel();
      await s4.cancel();
      await s5.cancel();
      await s6.cancel();
      await s7.cancel();
      await s8.cancel();
      await controller.dispose();
    });
  });

  group('Multiple Simultaneous Players Integration', () {
    test('routes events and calls independently across distinct texture IDs', () async {
      final controllerA = BananaPlayerController();
      final controllerB = BananaPlayerController();

      controllerA.updateStateForTesting(textureId: 201);
      controllerB.updateStateForTesting(textureId: 202);

      expect(controllerA.textureId, 201);
      expect(controllerB.textureId, 202);

      // Update Player A
      await messenger.handlePlatformMessage(
        'dev.flutter.pigeon.banana_player.BananaPlayerFlutterApi.onPlaybackStateChanged',
        codec.encodeMessage(<Object?>[201, PlaybackState.ready]),
        (_) {},
      );
      await messenger.handlePlatformMessage(
        'dev.flutter.pigeon.banana_player.BananaPlayerFlutterApi.onPositionChanged',
        codec.encodeMessage(<Object?>[201, 10000, 60000, 20000]),
        (_) {},
      );

      // Verify only Player A updated, Player B remains in default state
      expect(controllerA.playbackState, PlaybackState.ready);
      expect(controllerA.position, const Duration(seconds: 10));
      expect(controllerB.playbackState, PlaybackState.idle);
      expect(controllerB.position, Duration.zero);

      // Update Player B
      await messenger.handlePlatformMessage(
        'dev.flutter.pigeon.banana_player.BananaPlayerFlutterApi.onPlaybackStateChanged',
        codec.encodeMessage(<Object?>[202, PlaybackState.buffering]),
        (_) {},
      );
      await messenger.handlePlatformMessage(
        'dev.flutter.pigeon.banana_player.BananaPlayerFlutterApi.onPositionChanged',
        codec.encodeMessage(<Object?>[202, 35000, 180000, 50000]),
        (_) {},
      );

      // Verify Player B received its update without impacting Player A
      expect(controllerB.playbackState, PlaybackState.buffering);
      expect(controllerB.position, const Duration(seconds: 35));
      expect(controllerA.playbackState, PlaybackState.ready);
      expect(controllerA.position, const Duration(seconds: 10));

      // Disposing Player A does not affect Player B
      await controllerA.dispose();
      expect(controllerA.isInitialized, isFalse);
      expect(controllerB.isInitialized, isTrue);

      // Player B can still receive events
      await messenger.handlePlatformMessage(
        'dev.flutter.pigeon.banana_player.BananaPlayerFlutterApi.onPlaybackStateChanged',
        codec.encodeMessage(<Object?>[202, PlaybackState.ready]),
        (_) {},
      );
      expect(controllerB.playbackState, PlaybackState.ready);

      await controllerB.dispose();
      expect(controllerB.isInitialized, isFalse);
    });
  });

  group('BananaPlayerView Texture Rendering Integration', () {
    testWidgets('renders placeholder when controller is uninitialized', (tester) async {
      final controller = BananaPlayerController();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BananaPlayerView(
            controller: controller,
            placeholder: const Text('Loading Player...'),
          ),
        ),
      );

      expect(find.text('Loading Player...'), findsOneWidget);
      expect(find.byType(Texture), findsNothing);
      await controller.dispose();
    });

    testWidgets('renders native hardware Texture when initialized', (tester) async {
      final controller = BananaPlayerController();
      controller.updateStateForTesting(textureId: 301);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BananaPlayerView(controller: controller),
        ),
      );

      final textureFinder = find.byType(Texture);
      expect(textureFinder, findsOneWidget);

      final textureWidget = tester.widget<Texture>(textureFinder);
      expect(textureWidget.textureId, 301);

      await controller.dispose();
    });

    testWidgets('renders multiple simultaneous Texture widgets side-by-side', (tester) async {
      final controller1 = BananaPlayerController();
      final controller2 = BananaPlayerController();

      controller1.updateStateForTesting(textureId: 401);
      controller2.updateStateForTesting(textureId: 402);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: BananaPlayerView(controller: controller1),
              ),
              SizedBox(
                height: 200,
                child: BananaPlayerView(controller: controller2),
              ),
            ],
          ),
        ),
      );

      final textures = tester.widgetList<Texture>(find.byType(Texture)).toList();
      expect(textures.length, 2);
      expect(textures[0].textureId, 401);
      expect(textures[1].textureId, 402);

      await controller1.dispose();
      await controller2.dispose();
    });

    testWidgets('renders subtitle overlay over Texture when subtitle text is emitted', (tester) async {
      final controller = BananaPlayerController();
      controller.updateStateForTesting(
        textureId: 501,
        subtitleText: 'Subtitle cue active',
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: BananaPlayerView(controller: controller),
        ),
      );

      expect(find.byType(Texture), findsOneWidget);
      expect(find.text('Subtitle cue active'), findsOneWidget);

      // Clearing subtitle text removes overlay text
      controller.updateStateForTesting(subtitleText: '');
      await tester.pump();

      expect(find.text('Subtitle cue active'), findsNothing);
      expect(find.byType(Texture), findsOneWidget);

      await controller.dispose();
    });
  });
}
