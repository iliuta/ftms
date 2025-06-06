// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


// Import the test config to mock Bluetooth APIs
import 'test_config.dart';
import 'package:fmts/main.dart';

void main() {
  // Setup mocks for Bluetooth APIs
  setupBluetoothMocks();

  testWidgets('FTMS scan page shows scan button', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Look for the scan button text
    expect(find.text('Scan FTMS Devices'), findsOneWidget);
    // Optionally, check that the button is enabled
    final scanButton = find.widgetWithText(ElevatedButton, 'Scan FTMS Devices');
    expect(scanButton, findsOneWidget);
  });
}
