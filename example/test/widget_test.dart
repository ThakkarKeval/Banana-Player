import 'package:flutter_test/flutter_test.dart';
import 'package:banana_player_example/main.dart';

void main() {
  testWidgets('Verify player example screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const BananaPlayerApp());

    expect(find.text('BANANA'), findsOneWidget);
    expect(find.text('PLAYER'), findsOneWidget);
  });
}
