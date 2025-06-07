import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/widgets/speedometer_widget.dart';

void main() {
  testWidgets('SpeedometerWidget displays label and value', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SpeedometerWidget(
          value: 30,
          min: 0,
          max: 60,
          label: 'Speed',
          unit: 'km/h',
        ),
      ),
    ));
    expect(find.text('Speed'), findsOneWidget);
    expect(find.text('30 km/h'), findsOneWidget);
  });
}
