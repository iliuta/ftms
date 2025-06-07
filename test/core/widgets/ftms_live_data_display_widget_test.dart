import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/widgets/ftms_live_data_display_widget.dart';
import 'package:ftms/core/config/ftms_display_config.dart';


// The widget expects each value to have a .value property (like a parameter object)
class DummyParam {
  final int value;
  final num factor;
  DummyParam(this.value, {this.factor = 1});
  @override
  String toString() => value.toString();
}

void main() {
  testWidgets('FtmsLiveDataDisplayWidget displays fields from config', (WidgetTester tester) async {
    final config = FtmsDisplayConfig(fields: [
      FtmsDisplayField(
        name: 'Speed',
        label: 'Speed',
        display: 'number',
        unit: 'km/h',
        min: 0,
        max: 60,
        icon: 'bike',
      ),
    ]);
    final paramValueMap = {
      'Speed': DummyParam(42),
    };
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FtmsLiveDataDisplayWidget(
          config: config,
          paramValueMap: paramValueMap,
        ),
      ),
    ));
    expect(find.text('Speed'), findsOneWidget);
    expect(find.text('42 km/h'), findsOneWidget);
  });
}
