// Smoke test — verifies CarerMedsApp builds without throwing.

import 'package:flutter_test/flutter_test.dart';

import 'package:carermeds/app.dart';

void main() {
  testWidgets('CarerMedsApp builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const CarerMedsApp());
    // If we reach this line the widget tree assembled successfully.
    expect(find.byType(CarerMedsApp), findsOneWidget);
  });
}
