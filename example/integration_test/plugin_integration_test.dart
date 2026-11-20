import 'package:banana_player/banana_player.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loads native player and reports playback failures', (_) async {
    final controller = BananaPlayerController();
    final errorFuture = controller.onError.first.timeout(
      const Duration(seconds: 15),
    );

    try {
      await controller.initialize(
        url: 'file:///banana_player_missing_media_for_test.mp4',
        autoPlay: false,
      );
      expect(controller.isInitialized, isTrue);

      final playbackError = await errorFuture;
      expect(playbackError, isNotEmpty);

      await expectLater(
        controller.setVideoQuality('-1'),
        throwsA(isA<PlatformException>()),
      );
    } finally {
      await controller.dispose();
    }
  });
}
