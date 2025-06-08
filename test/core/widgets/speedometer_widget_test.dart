import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/models/ftms_display_field.dart';
import 'package:ftms/core/models/ftms_parameter.dart';
import 'package:ftms/core/widgets/speedometer_widget.dart';

void main() {
  testWidgets('SpeedometerWidget displays label and value', (WidgetTester tester) async {
    final displayField = FtmsDisplayField(
      name: 'speed',
      label: 'Speed',
      unit: 'km/h',
      min: 0,
      max: 60,
      display: 'speedometer',
    );

    final param = FtmsParameter(
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
}