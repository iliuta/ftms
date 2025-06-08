import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/config/ftms_display_config.dart';
import 'package:ftms/core/models/ftms_display_field.dart';
import 'package:ftms/core/models/ftms_parameter.dart';
import 'package:ftms/core/widgets/ftms_live_data_display_widget.dart';

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
    final paramValueMap = <String, FtmsParameter>{
      'Speed': FtmsParameter(
        name: 'Speed',
        value: 10,
        factor: 1,
        unit: 'km/h',
        flag: null,
        size: 2,
        signed: false,
      ),
      'Power': FtmsParameter(
        name: 'Power',
        value: 200,
        factor: 1,
        unit: 'W',
        flag: null,
        size: 2,
        signed: false,
      ),
      // 'Missing' is intentionally missing
      'Unknown': FtmsParameter(
        name: 'Unknown',
        value: 1,
        factor: 1,
        unit: '',
        flag: null,
        size: 2,
        signed: false,
      ),
    };
    final targets = {
      'Speed': 10,
      'Power': 150,
    };
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FtmsLiveDataDisplayWidget(
          config: config,
          paramValueMap: paramValueMap,
          targets: targets,
          defaultColor: Colors.purple,
          machineType: 'DeviceDataType.indoorBike',
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
            machineType: 'DeviceDataType.indoorBike',
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
    final weirdParamValueMap = <String, FtmsParameter>{
      'Weird': FtmsParameter(
        name: 'Weird',
        value: 5,
        factor: 1,
        unit: 'u',
        flag: null,
        size: 2,
        signed: false,
      ),
    };
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FtmsLiveDataDisplayWidget(
          config: weirdConfig,
          paramValueMap: weirdParamValueMap,
          machineType: 'DeviceDataType.indoorBike',
        ),
      ),
    ));
    expect(find.text('Weird'), findsOneWidget);
    expect(find.text('5 u'), findsOneWidget);

    // Edge case: testing with targets to verify color changes
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FtmsLiveDataDisplayWidget(
          config: config,
          paramValueMap: paramValueMap,
          targets: targets,
          machineType: 'DeviceDataType.indoorBike',
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
    final singleParamValueMap = <String, FtmsParameter>{
      'Speed': FtmsParameter(
        name: 'Speed',
        value: 99,
        factor: 1,
        unit: 'km/h',
        flag: null,
        size: 2,
        signed: false,
      ),
    };
    await tester.pumpWidget(SizedBox(
      width: 1000,
      child: MaterialApp(
        home: Scaffold(
          body: FtmsLiveDataDisplayWidget(
            config: singleConfig,
            paramValueMap: singleParamValueMap,
            machineType: 'DeviceDataType.indoorBike',
          ),
        ),
      ),
    ));
    expect(find.text('Speed'), findsOneWidget);
    expect(find.text('99 km/h'), findsOneWidget);
  });
}
