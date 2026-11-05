import 'package:banana_player/banana_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BananaPlayerController', () {
    test('instantiates with expected default values', () {
      final controller = BananaPlayerController();
      expect(controller.textureId, isNull);
      expect(controller.isInitialized, isFalse);
      expect(controller.playbackSpeed, 1.0);
      expect(controller.playbackState, PlaybackState.idle);
      expect(controller.isPlaying, isFalse);
      expect(controller.position, Duration.zero);
      expect(controller.duration, Duration.zero);
      expect(controller.bufferedPosition, Duration.zero);
      expect(controller.videoQualities, isEmpty);
      expect(controller.selectedQuality, isNull);
      expect(controller.isLive, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('normalizes URLs and asset paths correctly', () {
      expect(
        BananaPlayerController.normalizeUrlForTesting('assets/video.mp4'),
        'asset:///assets/video.mp4',
      );
      expect(
        BananaPlayerController.normalizeUrlForTesting(
          'https://example.com/stream.m3u8',
        ),
        'https://example.com/stream.m3u8',
      );
      expect(
        BananaPlayerController.normalizeUrlForTesting(
          'file:///var/mobile/video.mp4',
        ),
        'file:///var/mobile/video.mp4',
      );
      expect(
        BananaPlayerController.normalizeUrlForTesting(
          '  /storage/emulated/0/DCIM/video.mp4  ',
        ),
        '/storage/emulated/0/DCIM/video.mp4',
      );
    });

    test('clamps playback speed between 0.25 and 4.0', () async {
      final controller = BananaPlayerController();

      await controller.setPlaybackSpeed(0.1);
      expect(controller.playbackSpeed, 0.25);

      await controller.setPlaybackSpeed(10.0);
      expect(controller.playbackSpeed, 4.0);

      await controller.setPlaybackSpeed(1.75);
      expect(controller.playbackSpeed, 1.75);
    });

    test('identifies selected video quality', () {
      final controller = BananaPlayerController();
      final q1 = VideoQuality(
        id: '720p',
        width: 1280,
        height: 720,
        bitrate: 2500000,
        isSelected: false,
      );
      final q2 = VideoQuality(
        id: '1080p',
        width: 1920,
        height: 1080,
        bitrate: 5000000,
        isSelected: true,
      );

      controller.updateStateForTesting(videoQualities: [q1, q2]);
      expect(controller.videoQualities.length, 2);
      expect(controller.selectedQuality, isNotNull);
      expect(controller.selectedQuality?.id, '1080p');
      expect(controller.selectedQuality?.height, 1080);
    });

    test('identifies live stream based on duration and position', () {
      final controller = BananaPlayerController();
      expect(controller.isLive, isFalse);

      controller.updateStateForTesting(
        playbackState: PlaybackState.ready,
        position: const Duration(seconds: 15),
        duration: Duration.zero,
      );
      expect(controller.isLive, isTrue);

      controller.updateStateForTesting(playbackState: PlaybackState.buffering);
      expect(controller.isLive, isFalse);
    });

    test('emits updates across all broadcast streams', () async {
      final controller = BananaPlayerController();

      PlaybackState? emittedState;
      Duration? emittedPos;
      Duration? emittedDur;
      Duration? emittedBuf;
      List<VideoQuality>? emittedQualities;
      String? emittedError;

      final s1 = controller.onPlaybackStateChanged.listen(
        (s) => emittedState = s,
      );
      final s2 = controller.onPositionChanged.listen((p) => emittedPos = p);
      final s3 = controller.onDurationChanged.listen((d) => emittedDur = d);
      final s4 = controller.onBufferedPositionChanged.listen(
        (b) => emittedBuf = b,
      );
      final s5 = controller.onVideoQualitiesChanged.listen(
        (q) => emittedQualities = q,
      );
      final s6 = controller.onError.listen((e) => emittedError = e);

      controller.updateStateForTesting(
        playbackState: PlaybackState.ready,
        position: const Duration(seconds: 12),
        duration: const Duration(seconds: 60),
        bufferedPosition: const Duration(seconds: 30),
        videoQualities: [
          VideoQuality(
            id: 'auto',
            width: 0,
            height: 0,
            bitrate: 0,
            isSelected: true,
          ),
        ],
        errorMessage: 'Network error',
      );

      await Future<void>.delayed(Duration.zero);

      expect(emittedState, PlaybackState.ready);
      expect(emittedPos, const Duration(seconds: 12));
      expect(emittedDur, const Duration(seconds: 60));
      expect(emittedBuf, const Duration(seconds: 30));
      expect(emittedQualities?.length, 1);
      expect(emittedError, 'Network error');

      await s1.cancel();
      await s2.cancel();
      await s3.cancel();
      await s4.cancel();
      await s5.cancel();
      await s6.cancel();
      await controller.dispose();
    });

    test('throws StateError when calling methods after disposal', () async {
      final controller = BananaPlayerController();
      await controller.dispose();

      expect(
        () => controller.initialize(url: 'https://test.com/v.mp4'),
        throwsA(isA<StateError>()),
      );
      expect(
        () => controller.setSource('https://test.com/v.mp4'),
        throwsA(isA<StateError>()),
      );

      // Subsequent dispose should be safe and idempotent
      await expectLater(controller.dispose(), completes);
    });
  });

  group('BananaSeekBarValue', () {
    test('computes progress and buffered fractions accurately', () {
      const zeroValue = BananaSeekBarValue(
        position: Duration.zero,
        duration: Duration.zero,
        bufferedPosition: Duration.zero,
        isDragging: false,
        isLive: false,
      );
      expect(zeroValue.progressFraction, 0.0);
      expect(zeroValue.bufferedFraction, 0.0);
      expect(zeroValue.remaining, Duration.zero);

      const activeValue = BananaSeekBarValue(
        position: Duration(seconds: 30),
        duration: Duration(seconds: 120),
        bufferedPosition: Duration(seconds: 60),
        isDragging: true,
        isLive: false,
      );
      expect(activeValue.progressFraction, 0.25);
      expect(activeValue.bufferedFraction, 0.5);
      expect(activeValue.remaining, const Duration(seconds: 90));
      expect(activeValue.isDragging, isTrue);

      const overflowValue = BananaSeekBarValue(
        position: Duration(seconds: 150),
        duration: Duration(seconds: 120),
        bufferedPosition: Duration(seconds: 180),
        isDragging: false,
        isLive: false,
      );
      expect(overflowValue.progressFraction, 1.0);
      expect(overflowValue.bufferedFraction, 1.0);
      expect(overflowValue.remaining, Duration.zero);
    });
  });

  group('BananaPlayerView', () {
    testWidgets('shows placeholder when uninitialized', (tester) async {
      final controller = BananaPlayerController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BananaPlayerView(
              controller: controller,
              placeholder: const Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Texture), findsNothing);
    });

    testWidgets(
      'shows SizedBox.shrink when placeholder is null and uninitialized',
      (tester) async {
        final controller = BananaPlayerController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: BananaPlayerView(controller: controller)),
          ),
        );

        expect(find.byType(Texture), findsNothing);
      },
    );

    testWidgets('renders Texture widget when initialized with textureId', (
      tester,
    ) async {
      final controller = BananaPlayerController();
      controller.updateStateForTesting(textureId: 101);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BananaPlayerView(
              controller: controller,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      );

      final textureFinder = find.byType(Texture);
      expect(textureFinder, findsOneWidget);
      final Texture textureWidget = tester.widget(textureFinder);
      expect(textureWidget.textureId, 101);
      expect(textureWidget.filterQuality, FilterQuality.medium);
    });
  });

  group('BananaSeekBar layout & styling', () {
    testWidgets('renders default layout with formatted timestamps', (
      tester,
    ) async {
      final controller = BananaPlayerController();
      controller.updateStateForTesting(
        position: const Duration(minutes: 1, seconds: 23),
        duration: const Duration(minutes: 5, seconds: 40),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BananaSeekBar(controller: controller)),
        ),
      );

      expect(find.text('1:23'), findsOneWidget);
      expect(find.text('5:40'), findsOneWidget);
    });

    testWidgets('formats hour-level timestamps accurately', (tester) async {
      final controller = BananaPlayerController();
      controller.updateStateForTesting(
        position: const Duration(hours: 1, minutes: 2, seconds: 3),
        duration: const Duration(hours: 2, minutes: 30, seconds: 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BananaSeekBar(controller: controller)),
        ),
      );

      expect(find.text('1:02:03'), findsOneWidget);
      expect(find.text('2:30:00'), findsOneWidget);
    });

    testWidgets('renders LIVE badge when media is live', (tester) async {
      final controller = BananaPlayerController();
      controller.updateStateForTesting(
        playbackState: PlaybackState.ready,
        position: const Duration(seconds: 45),
        duration: Duration.zero,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BananaSeekBar(controller: controller)),
        ),
      );

      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('0:45'), findsOneWidget);
    });

    testWidgets('renders direct customizable slots properly', (tester) async {
      final controller = BananaPlayerController();
      controller.updateStateForTesting(
        position: const Duration(seconds: 10),
        duration: const Duration(seconds: 60),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BananaSeekBar(
              controller: controller,
              leading: const Icon(Icons.skip_previous, key: Key('leading-btn')),
              trailing: const Icon(Icons.skip_next, key: Key('trailing-btn')),
              customThumb: const Icon(Icons.star, key: Key('star-thumb')),
              customTrack: Container(key: const Key('custom-track-bar')),
              overlay: const Text('Chapter 1', key: Key('chapter-overlay')),
              timeLabel: const Text('Custom Time', key: Key('custom-time-lbl')),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('leading-btn')), findsOneWidget);
      expect(find.byKey(const Key('trailing-btn')), findsOneWidget);
      expect(find.byKey(const Key('star-thumb')), findsOneWidget);
      expect(find.byKey(const Key('custom-track-bar')), findsOneWidget);
      expect(find.byKey(const Key('chapter-overlay')), findsOneWidget);
      expect(find.byKey(const Key('custom-time-lbl')), findsOneWidget);
    });

    testWidgets('invokes custom builder with value and defaultLayout', (
      tester,
    ) async {
      final controller = BananaPlayerController();
      controller.updateStateForTesting(
        position: const Duration(seconds: 15),
        duration: const Duration(seconds: 60),
      );

      BananaSeekBarValue? capturedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BananaSeekBar(
              controller: controller,
              builder: (context, value, defaultLayout) {
                capturedValue = value;
                return Column(
                  children: [
                    const Text('Custom Seek Area', key: Key('custom-title')),
                    defaultLayout,
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('custom-title')), findsOneWidget);
      expect(capturedValue?.position, const Duration(seconds: 15));
      expect(capturedValue?.duration, const Duration(seconds: 60));
    });
  });

  group('BananaSeekBar widget validation', () {
    testWidgets(
      'allows valid direct widgets (Row, Column, Icon, Container, Image)',
      (tester) async {
        final controller = BananaPlayerController();

        final seekBar = MaterialApp(
          home: Scaffold(
            body: BananaSeekBar(
              controller: controller,
              leading: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(Icons.play_circle_fill), Text('0:00')],
              ),
              trailing: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [Icon(Icons.fullscreen)],
              ),
              customThumb: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                ),
              ),
              customTrack: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        );

        await tester.pumpWidget(seekBar);
        expect(find.byType(BananaSeekBar), findsOneWidget);
        expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
        expect(find.byIcon(Icons.fullscreen), findsOneWidget);
      },
    );

    test('rejects direct ListView with ArgumentError', () {
      final controller = BananaPlayerController();

      expect(
        () => BananaSeekBar(
          controller: controller,
          leading: ListView(children: const [Text('invalid')]),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects nested ListView inside Row with ArgumentError', () {
      final controller = BananaPlayerController();

      expect(
        () => BananaSeekBar(
          controller: controller,
          leading: Row(
            children: [
              ListView(children: const [Text('nested list')]),
            ],
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects direct GridView with ArgumentError', () {
      final controller = BananaPlayerController();

      expect(
        () => BananaSeekBar(
          controller: controller,
          trailing: GridView.count(
            crossAxisCount: 2,
            children: const [Text('item')],
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects SingleChildScrollView with ArgumentError', () {
      final controller = BananaPlayerController();

      expect(
        () => BananaSeekBar(
          controller: controller,
          customThumb: const SingleChildScrollView(child: Text('item')),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    testWidgets('rejects builder returning ListView during pump', (
      tester,
    ) async {
      final controller = BananaPlayerController();

      final seekBar = MaterialApp(
        home: Scaffold(
          body: BananaSeekBar(
            controller: controller,
            builder: (context, value, defaultLayout) {
              return ListView(children: const [Text('bad')]);
            },
          ),
        ),
      );

      await tester.pumpWidget(seekBar);
      expect(tester.takeException(), isA<ArgumentError>());
    });

    testWidgets(
      'resets dragging state when app lifecycle pauses or goes inactive',
      (tester) async {
        final controller = BananaPlayerController();
        BananaSeekBarValue? capturedValue;

        final seekBar = MaterialApp(
          home: Scaffold(
            body: BananaSeekBar(
              controller: controller,
              builder: (context, value, defaultLayout) {
                capturedValue = value;
                return defaultLayout;
              },
            ),
          ),
        );

        await tester.pumpWidget(seekBar);
        expect(capturedValue?.isDragging, false);

        // Simulate app pausing (e.g. app switched)
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();

        expect(capturedValue?.isDragging, false);
      },
    );
  });
}
