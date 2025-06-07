import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/widgets/speedometer_widget.dart';
import 'package:ftms/core/config/ftms_display_config.dart';

class DummyParam {
  final int value;
  final num factor;
  DummyParam(this.value, {this.factor = 1});
  @override
  String toString() => value.toString();
}

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

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SpeedometerWidget(
          displayField: displayField,
          param: DummyParam(30, factor: 1),
          color: Colors.blue,
        ),
      ),
    ));

    expect(find.text('Speed'), findsOneWidget);
    expect(find.text('30 km/h'), findsOneWidget);
  });
}