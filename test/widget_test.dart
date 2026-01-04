// Basic widget test for Hexapod Control app

import 'package:flutter_test/flutter_test.dart';

import 'package:hexapod_control/main.dart';

void main() {
  testWidgets('App launches with setup and control tabs', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HexapodControlApp());

    // Verify that we have the bottom navigation bar with two items
    expect(find.text('Setup'), findsOneWidget);
    expect(find.text('Control'), findsOneWidget);

    // Verify the setup screen is shown by default
    expect(find.text('Setup Connection'), findsOneWidget);
  });
}
