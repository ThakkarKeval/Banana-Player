import 'package:flutter_test/flutter_test.dart';
import 'package:banana_player/banana_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('BananaPlayerController can be instantiated', () {
    final controller = BananaPlayerController();
    expect(controller, isNotNull);
  });
}
