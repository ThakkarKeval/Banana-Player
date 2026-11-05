import 'package:flutter_test/flutter_test.dart';
import 'package:banana_player_example/main.dart';
import 'package:banana_player_example/strings.dart';

void main() {
  testWidgets('Verify player example screen renders', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BananaPlayerApp());

    expect(find.text(AppStrings.brandBanana), findsOneWidget);
    expect(find.text(AppStrings.brandPlayer), findsOneWidget);
  });
}
