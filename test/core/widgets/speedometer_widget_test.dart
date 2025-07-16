import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/config/live_data_field_config.dart';
import 'package:ftms/core/models/live_data_field_value.dart';
import 'package:ftms/core/widgets/speedometer_widget.dart';

void main() {
  testWidgets('SpeedometerWidget displays label and value', (WidgetTester tester) async {
    final displayField = LiveDataFieldConfig(
      name: 'speed',
      label: 'Speed',
      unit: 'km/h',
      min: 0,
      max: 60,
      display: 'speedometer',
    );

    final param = LiveDataFieldValue(
      name: 'speed',
      value: 30,
      factor: 1,
      unit: 'km/h',
      flag: null,
      size: 2,
      signed: false,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SpeedometerWidget(
          displayField: displayField,
          param: param,
          color: Colors.blue,
        ),
      ),
    ));

    expect(find.text('Speed'), findsOneWidget);
    expect(find.text('30 km/h'), findsOneWidget);
  });

  testWidgets('SpeedometerWidget displays with target interval', (WidgetTester tester) async {
    final displayField = LiveDataFieldConfig(
      name: 'Speed',
      label: 'Speed',
      display: 'speedometer',
      unit: 'km/h',
      min: 0,
      max: 60,
      targetRange: 0.1,
    );

    final param = LiveDataFieldValue(
      name: 'Speed',
      value: 30,
      unit: 'km/h',
      factor: 1,
      signed: false,
    );

    final targetInterval = (lower: 25.0, upper: 35.0);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SpeedometerWidget(
          displayField: displayField,
          param: param,
          color: Colors.blue,
          targetInterval: targetInterval,
        ),
      ),
    ));

    expect(find.text('Speed'), findsOneWidget);
    expect(find.text('30 km/h'), findsOneWidget);

    // Verify the widget renders without errors (target range is visual, hard to test directly)
    expect(tester.takeException(), isNull);
  });

  testWidgets('SpeedometerWidget displays with inverted field and target interval', (WidgetTester tester) async {
    final displayField = LiveDataFieldConfig(
      name: 'Pace',
      label: 'Pace',
      display: 'speedometer',
      unit: 'min/km',
      min: 10, // slower (higher values)
      max: 3,  // faster (lower values)
      targetRange: 0.1,
    );

    final param = LiveDataFieldValue(
      name: 'Pace',
      value: 5,
      unit: 'min/km',
      factor: 1,
      signed: false,
    );

    final targetInterval = (lower: 4.5, upper: 5.5);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SpeedometerWidget(
          displayField: displayField,
          param: param,
          color: Colors.blue,
          targetInterval: targetInterval,
        ),
      ),
    ));

    expect(find.text('Pace'), findsOneWidget);
    expect(find.text('5 min/km'), findsOneWidget);
    
    // Verify the widget renders without errors (target range is visual, hard to test directly)
    expect(tester.takeException(), isNull);
  });
}