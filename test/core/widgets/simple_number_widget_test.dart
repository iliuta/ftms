import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/widgets/simple_number_widget.dart';

import 'package:ftms/core/config/ftms_display_config.dart';

class DummyParam {
  final int value;
  final num factor;
  DummyParam(this.value, {this.factor = 1});
  @override
  String toString() => value.toString();
}

void main() {
  testWidgets('SimpleNumberWidget displays label, value, unit, and icon', (WidgetTester tester) async {
    final displayField = FtmsDisplayField(
      name: 'speed',
      label: 'Speed',
      display: 'number',
      unit: 'km/h',
      icon: 'bike',
      min: 0,
      max: 60,
    );
    final param = DummyParam(42);
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
