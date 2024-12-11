import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sindh_truck_cargo_hub/main.dart'; // Ensure this path is correct

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp()); // Ensure MyApp is correct

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget); // Check if '0' is displayed
    expect(find.text('1'), findsNothing); // Check if '1' is not displayed

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump(); // Rebuild the widget tree

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing); // Check if '0' is no longer displayed
    expect(find.text('1'), findsOneWidget); // Check if '1' is now displayed
  });
}
