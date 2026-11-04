import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:banana_player/banana_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('BananaPlayerController can be instantiated', () {
    final controller = BananaPlayerController();
    expect(controller, isNotNull);
    expect(controller.videoQualities, isEmpty);
    expect(controller.selectedQuality, isNull);
  });

  group('BananaSeekBar widget validation', () {
    testWidgets('allows valid direct widgets (Row, Column, Icon, Container, Image)', (tester) async {
      final controller = BananaPlayerController();

      // Passing valid direct widgets should not throw
      final seekBar = MaterialApp(
        home: Scaffold(
          body: BananaSeekBar(
            controller: controller,
            leading: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_circle_fill),
                Text('0:00'),
              ],
            ),
            trailing: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fullscreen),
              ],
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
    });

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
          trailing: GridView.count(crossAxisCount: 2, children: const [Text('item')]),
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

    testWidgets('rejects builder returning ListView during pump', (tester) async {
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
  });
}
