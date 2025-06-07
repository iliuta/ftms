import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/utils/simple_number_widget.dart';

void main() {
  testWidgets('SimpleNumberWidget displays label, value, unit, and icon', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SimpleNumberWidget(
          label: 'Speed',
          value: 42,
          unit: 'km/h',
          icon: 'bike',
        ),
      ),
    ));
    expect(find.text('Speed'), findsOneWidget);
    expect(find.text('42 km/h'), findsOneWidget);
    expect(find.byIcon(Icons.pedal_bike), findsOneWidget);
  });
}
