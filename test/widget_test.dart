import 'package:flutter_test/flutter_test.dart';

import 'package:ahp_driver_app/main.dart';

void main() {
  testWidgets('app renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Welcome to\nAHP Driver APP'), findsOneWidget);
    expect(find.text('Sign In'), findsNothing);
  });
}
