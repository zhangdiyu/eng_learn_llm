import 'package:flutter_test/flutter_test.dart';
import 'package:daily_english_quest/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const DailyEnglishQuestApp());
    await tester.pumpAndSettle();
  });
}
