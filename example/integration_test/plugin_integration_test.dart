import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:banana_player/banana_player.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('BananaPlayerController instantiation test', (WidgetTester tester) async {
    final BananaPlayerController controller = BananaPlayerController();
    expect(controller, isNotNull);
  });
}
