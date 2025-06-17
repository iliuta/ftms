import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/config/live_data_field_config.dart';
import 'package:ftms/core/models/live_data_field_value.dart';
import 'package:ftms/core/widgets/simple_number_widget.dart';

void main() {
  testWidgets('SimpleNumberWidget displays label, value, unit, and icon', (WidgetTester tester) async {
    final displayField = LiveDataFieldConfig(
      name: 'speed',
      label: 'Speed',
      display: 'number',
      unit: 'km/h',
      icon: 'bike',
      min: 0,
      max: 60,
    );
    final param = LiveDataFieldValue(
      name: 'speed',
      value: 42,
      factor: 1,
      unit: 'km/h',
      flag: null,
      size: 2,
      signed: false,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SimpleNumberWidget(displayField, param, null),
      ),
    ));
    expect(find.text('Speed'), findsOneWidget);
    expect(find.text('42 km/h'), findsOneWidget);
    expect(find.byIcon(Icons.pedal_bike), findsOneWidget);
  });
}
