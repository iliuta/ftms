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

// Edge case: param.factor is not a number and cannot be parsed
class WeirdParam {
  final int value;
  final String factor;
  WeirdParam(this.value, {this.factor = 'not_a_number'});
  @override
  String toString() => value.toString();
}

void main() {
  testWidgets('FtmsLiveDataDisplayWidget covers all branches for 100% coverage', (WidgetTester tester) async {
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
      FtmsDisplayField(
        name: 'Power',
        label: 'Power',
        display: 'speedometer',
        unit: 'W',
        min: 0,
        max: 500,
        icon: null,
      ),
      FtmsDisplayField(
        name: 'Missing',
        label: 'Missing',
        display: 'number',
        unit: '',
      ),
      FtmsDisplayField(
        name: 'Unknown',
        label: 'Unknown',
        display: 'not_a_widget',
        unit: '',
      ),
    ]);
    final paramValueMap = {
      'Speed': DummyParam(10),
      'Power': DummyParam(200),
      // 'Missing' is intentionally missing
      'Unknown': DummyParam(1),
    };
    final targets = {
      'Speed': 10,
      'Power': 150,
    };
    bool isWithinTarget(num? value, num? target, {num factor = 1}) {
      if (value == null || target == null) return false;
      return value >= target;
    }
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FtmsLiveDataDisplayWidget(
          config: config,
          paramValueMap: paramValueMap,
          targets: targets,
          isWithinTarget: isWithinTarget,
          defaultColor: Colors.purple,
        ),
      ),
    ));
    // Number widget
    expect(find.text('Speed'), findsOneWidget);
    expect(find.text('10 km/h'), findsOneWidget);
    // Speedometer widget
    expect(find.text('Power'), findsOneWidget);
    expect(find.text('200 W'), findsOneWidget);
    // Missing param
    expect(find.textContaining('Missing: (not available)'), findsOneWidget);
    // Unknown display type
    expect(find.textContaining('Unknown: (unknown display type)'), findsOneWidget);
    // Color logic: Speed should be green (10 >= 10), Power should be green (200 >= 150)
    // (We can't directly check color, but we exercised the branch)
    // Multiple columns: force a small width to test row logic
    await tester.pumpWidget(SizedBox(
      width: 200,
      child: MaterialApp(
        home: Scaffold(
          body: FtmsLiveDataDisplayWidget(
            config: config,
            paramValueMap: paramValueMap,
          ),
        ),
      ),
    ));
    expect(find.text('Speed'), findsOneWidget);
    expect(find.text('Power'), findsOneWidget);
    // Edge case: param.factor is not a number and cannot be parsed
    final weirdConfig = FtmsDisplayConfig(fields: [
      FtmsDisplayField(
        name: 'Weird',
        label: 'Weird',
        display: 'number',
        unit: 'u',
      ),
    ]);
    final weirdParamValueMap = {
      'Weird': WeirdParam(5),
    };
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FtmsLiveDataDisplayWidget(
          config: weirdConfig,
          paramValueMap: weirdParamValueMap,
        ),
      ),
    ));
    expect(find.text('Weird'), findsOneWidget);
    expect(find.text('5 u'), findsOneWidget);

    // Edge case: isWithinTarget returns false (should color red, branch exercised)
    bool alwaysFalse(num? value, num? target, {num factor = 1}) => false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FtmsLiveDataDisplayWidget(
          config: config,
          paramValueMap: paramValueMap,
          targets: targets,
          isWithinTarget: alwaysFalse,
        ),
      ),
    ));
    expect(find.text('Speed'), findsOneWidget);
    expect(find.text('Power'), findsOneWidget);

    // Edge case: single field, very large width (all fields in one row)
    final singleConfig = FtmsDisplayConfig(fields: [
      FtmsDisplayField(
        name: 'Speed',
        label: 'Speed',
        display: 'number',
        unit: 'km/h',
      ),
    ]);
    final singleParamValueMap = {
      'Speed': DummyParam(99),
    };
    await tester.pumpWidget(SizedBox(
      width: 1000,
      child: MaterialApp(
        home: Scaffold(
          body: FtmsLiveDataDisplayWidget(
            config: singleConfig,
            paramValueMap: singleParamValueMap,
          ),
        ),
      ),
    ));
    expect(find.text('Speed'), findsOneWidget);
    expect(find.text('99 km/h'), findsOneWidget);
  });
}
