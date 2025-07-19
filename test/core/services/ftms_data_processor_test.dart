import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/models/device_types.dart';
import 'package:ftms/core/services/ftms_data_processor.dart';
import 'package:ftms/core/services/value_averaging_service.dart';
import 'package:ftms/core/config/live_data_display_config.dart';
import 'package:ftms/core/config/live_data_field_config.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import 'package:flutter_ftms/src/ftms/flag.dart';
import 'package:flutter_ftms/src/ftms/parameter_name.dart';

// Mock classes for testing
class MockDeviceData extends DeviceData {
  final List<MockParameter> _parameters;
  final DeviceDataType _type;

  MockDeviceData(this._parameters, this._type) : super([0, 0, 0, 0]);

  @override
  DeviceDataType get deviceDataType => _type;

  @override
  List<Flag> get allDeviceDataFlags => [];

  @override
  List<DeviceDataParameter> get allDeviceDataParameters =>
      _parameters.cast<DeviceDataParameter>();

  @override
  List<DeviceDataParameterValue> getDeviceDataParameterValues() {
    return _parameters.map((p) => MockParameterValue(p)).toList();
  }
}

class MockParameter implements DeviceDataParameter {
  final ParameterName _name;
  final num _value;
  final num _factor;
  final String _unit;

  MockParameter(String name, this._value, {num? factor, String? unit})
      : _name = _getParameterName(name),
        _factor = factor ?? 1,
        _unit = unit ?? 'W';

  static ParameterName _getParameterName(String name) {
    // Create a mock parameter name that has the same string representation
    return MockDeviceDataParameterName(name);
  }

  @override
  ParameterName get name => _name;

  num get value => _value;

  @override
  num get factor => _factor;

  @override
  String get unit => _unit;

  @override
  Flag? get flag => null;

  @override
  int get size => 2;

  @override
  bool get signed => false;

  @override
  DeviceDataParameterValue toDeviceDataParameterValue(int value) {
    return MockParameterValue(this);
  }

  @override
  String toString() => _value.toString();
}

class MockDeviceDataParameterName implements ParameterName {
  final String _name;

  MockDeviceDataParameterName(this._name);

  @override
  String get name => _name;

  @override
  String toString() => _name;
}

class MockParameterValue implements DeviceDataParameterValue {
  final MockParameter _parameter;

  MockParameterValue(this._parameter);

  @override
  ParameterName get name => _parameter.name;

  @override
  int get value => _parameter.value.toInt();

  @override
  num get factor => _parameter.factor;

  @override
  String get unit => _parameter.unit;

  @override
  Flag? get flag => _parameter.flag;

  @override
  int get size => _parameter.size;

  @override
  bool get signed => _parameter.signed;

  @override
  DeviceDataParameterValue toDeviceDataParameterValue(int value) {
    return MockParameterValue(_parameter);
  }

  @override
  String toString() => _parameter.toString();
}

void main() {
  group('FtmsDataProcessor', () {
    late FtmsDataProcessor processor;
    late LiveDataDisplayConfig config;
    late LiveDataDisplayConfig configWithAveraging;

    setUp(() {
      // Clear any previous state from the singleton averaging service
      ValueAveragingService().clearAll();

      processor = FtmsDataProcessor();

      config = LiveDataDisplayConfig(fields: [
        LiveDataFieldConfig(
          name: 'Instantaneous Power',
          label: 'Power',
          display: 'number',
          unit: 'W',
        ),
        LiveDataFieldConfig(
          name: 'Instantaneous Speed',
          label: 'Speed',
          display: 'number',
          unit: 'km/h',
        ),
      ], deviceType: DeviceType.indoorBike);

      configWithAveraging = LiveDataDisplayConfig(
        fields: [
          LiveDataFieldConfig(
            name: 'Instantaneous Power',
            label: 'Power',
            display: 'number',
            unit: 'W',
            samplePeriodSeconds: 3,
          ),
          LiveDataFieldConfig(
            name: 'Instantaneous Speed',
            label: 'Speed',
            display: 'number',
            unit: 'km/h',
          ),
        ],
        deviceType: DeviceType.indoorBike,
      );
    });

    group('Configuration', () {
      test('configures without averaging fields', () {
        processor.configure(config);
        // Should not throw and should handle data processing
        expect(() => processor.configure(config), returnsNormally);
      });

      test('configures with averaging fields', () {
        processor.configure(configWithAveraging);
        expect(() => processor.configure(configWithAveraging), returnsNormally);
      });

      test('prevents reconfiguration', () {
        processor.configure(config);

        // Second configuration should be ignored
        processor.configure(configWithAveraging);

        // Should still work with original config
        expect(() => processor.configure(config), returnsNormally);
      });

      test('can be reset and reconfigured', () {
        processor.configure(config);
        processor.reset();

        // Should be able to configure again after reset
        expect(() => processor.configure(configWithAveraging), returnsNormally);
      });
    });

    group('Data processing without averaging', () {
      test('processes device data with no averaging', () {
        processor.configure(config);

        final deviceData = MockDeviceData([
          MockParameter('Instantaneous Power', 250),
          MockParameter('Instantaneous Speed', 25),
        ], DeviceDataType.indoorBike);

        final result = processor.processDeviceData(deviceData);

        expect(result, hasLength(2));
        expect(result['Instantaneous Power'], isNotNull);
        expect(result['Instantaneous Speed'], isNotNull);
        expect(result['Instantaneous Power']!.value, equals(250));
        expect(result['Instantaneous Speed']!.value, equals(25));
      });

      test('preserves original parameter properties', () {
        processor.configure(config);

        final deviceData = MockDeviceData([
          MockParameter('Instantaneous Power', 250, factor: 2),
        ], DeviceDataType.indoorBike);

        final result = processor.processDeviceData(deviceData);
        final param = result['Instantaneous Power']!;

        expect(param.value, equals(250));
        expect(param.factor, equals(2));
        expect(param.unit, equals('W'));
        expect(param.name, equals('Instantaneous Power'));
      });
    });

    group('Data processing with averaging', () {
      test('applies averaging to configured fields', () {
        processor.configure(configWithAveraging);

        // Process multiple data points
        final deviceData1 = MockDeviceData([
          MockParameter('Instantaneous Power', 200),
          MockParameter('Instantaneous Speed', 20),
        ], DeviceDataType.indoorBike);

        final deviceData2 = MockDeviceData([
          MockParameter('Instantaneous Power', 300),
          MockParameter('Instantaneous Speed', 30),
        ], DeviceDataType.indoorBike);

        processor.processDeviceData(deviceData1);
        final result = processor.processDeviceData(deviceData2);

        // Power should be averaged (has samplePeriodSeconds)
        expect(result['Instantaneous Power']!.value,
            equals(250.0)); // (200 + 300) / 2

        // Speed should be instantaneous (no samplePeriodSeconds)
        expect(result['Instantaneous Speed']!.value, equals(30));
      });

      test('maintains parameter interface for averaged values', () {
        processor.configure(configWithAveraging);

        final deviceData = MockDeviceData([
          MockParameter('Instantaneous Power', 250, factor: 2),
        ], DeviceDataType.indoorBike);

        // Process data twice to enable averaging
        processor.processDeviceData(deviceData);
        final result = processor.processDeviceData(deviceData);

        final param = result['Instantaneous Power']!;

        // Should have averaged value but preserve other properties
        expect(param.value, equals(250.0)); // Average of same value
        expect(param.factor, equals(2));
        expect(param.unit, equals('W'));
        expect(param.name, equals('Instantaneous Power'));
        expect(param.toString(), contains('250.0'));
      });
    });

    group('Averaged parameter properties', () {
      test('maintains all properties correctly', () {
        processor.configure(configWithAveraging);

        final deviceData = MockDeviceData([
          MockParameter('Instantaneous Power', 100, factor: 1.5),
        ], DeviceDataType.indoorBike);

        processor.processDeviceData(deviceData);
        final result = processor.processDeviceData(deviceData);

        final param = result['Instantaneous Power']!;

        expect(param.value, equals(100.0));
        expect(param.factor, equals(1.5));
        expect(param.unit, equals('W'));
        expect(param.flag, equals(null));
        expect(param.size, equals(2));
        expect(param.name, equals('Instantaneous Power'));
      });

      test('handles averaged values correctly', () {
        processor.configure(configWithAveraging);

        final deviceData = MockDeviceData([
          MockParameter('Instantaneous Power', 150),
        ], DeviceDataType.indoorBike);

        processor.processDeviceData(deviceData);
        final result = processor.processDeviceData(deviceData);

        final param = result['Instantaneous Power']!;

        // Test accessing value property
        expect(param.value, equals(150.0));

        // Test toString contains the value
        expect(param.toString(), contains('150.0'));
      });
    });

    group('Mixed field types', () {
      test('handles mix of averaged and non-averaged fields', () {
        final mixedConfig = LiveDataDisplayConfig(fields: [
          LiveDataFieldConfig(
            name: 'Instantaneous Power',
            label: 'Power',
            display: 'number',
            unit: 'W',
            samplePeriodSeconds: 3,
          ),
          LiveDataFieldConfig(
            name: 'Instantaneous Speed',
            label: 'Speed',
            display: 'number',
            unit: 'km/h',
            // No samplePeriodSeconds
          ),
          LiveDataFieldConfig(
            name: 'Instantaneous Cadence',
            label: 'Cadence',
            display: 'number',
            unit: 'rpm',
            samplePeriodSeconds: 5,
          ),
        ], deviceType: DeviceType.indoorBike);

        processor.configure(mixedConfig);

        // Process multiple rounds of data
        for (int i = 1; i <= 3; i++) {
          final deviceData = MockDeviceData([
            MockParameter('Instantaneous Power', i * 100),
            // Will be averaged
            MockParameter('Instantaneous Speed', i * 10),
            // Will be instantaneous
            MockParameter('Instantaneous Cadence', i * 20),
            // Will be averaged
          ], DeviceDataType.indoorBike);

          processor.processDeviceData(deviceData);
        }

        final finalData = MockDeviceData([
          MockParameter('Instantaneous Power', 400),
          MockParameter('Instantaneous Speed', 40),
          MockParameter('Instantaneous Cadence', 80),
        ], DeviceDataType.indoorBike);

        final result = processor.processDeviceData(finalData);

        // Power: averaged (100, 200, 300, 400) / 4 = 250
        expect(result['Instantaneous Power']!.value, equals(250.0));

        // Speed: instantaneous (latest value)
        expect(result['Instantaneous Speed']!.value, equals(40));

        // Cadence: averaged (20, 40, 60, 80) / 4 = 50
        expect(result['Instantaneous Cadence']!.value, equals(50.0));
      });
    });

    group('Edge cases', () {
      test('handles empty device data', () {
        processor.configure(config);

        final deviceData = MockDeviceData([], DeviceDataType.indoorBike);
        final result = processor.processDeviceData(deviceData);

        expect(result, isEmpty);
      });

      test('handles null parameter values', () {
        processor.configure(configWithAveraging);

        // Create a mock parameter that returns null for value
        final deviceData = MockDeviceData([
          MockParameter('Instantaneous Power', 100),
        ], DeviceDataType.indoorBike);

        expect(() => processor.processDeviceData(deviceData), returnsNormally);
      });

      test('handles unconfigured processor', () {
        // Don't configure the processor
        final deviceData = MockDeviceData([
          MockParameter('Instantaneous Power', 250),
        ], DeviceDataType.indoorBike);

        final result = processor.processDeviceData(deviceData);

        // Should still work, just no averaging
        expect(result['Instantaneous Power']!.value, equals(250));
      });

      test('handles parameter processing correctly', () {
        processor.configure(config);

        final deviceData = MockDeviceData([
          MockParameter('Instantaneous Power', 250),
        ], DeviceDataType.indoorBike);

        final result = processor.processDeviceData(deviceData);
        expect(result['Instantaneous Power'], isNotNull);
      });
    });

    group('Cumulative field processing', () {
      late FtmsDataProcessor processor;
      late LiveDataDisplayConfig cumulativeConfig;

      setUp(() {
        processor = FtmsDataProcessor();
        cumulativeConfig = LiveDataDisplayConfig(
          fields: [
            LiveDataFieldConfig(
              name: 'Total Distance',
              label: 'Distance',
              display: 'number',
              unit: 'm',
              isCumulative: true,
            ),
            LiveDataFieldConfig(
              name: 'Total Energy',
              label: 'Calories',
              display: 'number',
              unit: 'kcal',
              isCumulative: true,
            ),
            LiveDataFieldConfig(
              name: 'Instantaneous Power',
              label: 'Power',
              display: 'number',
              unit: 'W',
              // Not cumulative
            ),
          ],
          deviceType: DeviceType.rower,
        );
      });

      test('maintains cumulative values when they increase', () {
        processor.configure(cumulativeConfig);

        // Initial values
        final deviceData1 = MockDeviceData([
          MockParameter('Total Distance', 100),
          MockParameter('Total Energy', 50),
          MockParameter('Instantaneous Power', 200),
        ], DeviceDataType.rower);

        final result1 = processor.processDeviceData(deviceData1);
        expect(result1['Total Distance']!.value, equals(100));
        expect(result1['Total Energy']!.value, equals(50));
        expect(result1['Instantaneous Power']!.value, equals(200));

        // Values increase normally
        final deviceData2 = MockDeviceData([
          MockParameter('Total Distance', 250),
          MockParameter('Total Energy', 75),
          MockParameter('Instantaneous Power', 180),
        ], DeviceDataType.rower);

        final result2 = processor.processDeviceData(deviceData2);
        expect(result2['Total Distance']!.value, equals(250));
        expect(result2['Total Energy']!.value, equals(75));
        expect(result2['Instantaneous Power']!.value, equals(180));
      });

      test('handles device reconnection by continuing accumulation', () {
        processor.configure(cumulativeConfig);

        // Initial workout data
        final deviceData1 = MockDeviceData([
          MockParameter('Total Distance', 500),
          MockParameter('Total Energy', 100),
        ], DeviceDataType.rower);

        final result1 = processor.processDeviceData(deviceData1);
        expect(result1['Total Distance']!.value, equals(500));
        expect(result1['Total Energy']!.value, equals(100));

        // Device disconnects and reconnects - values reset to low numbers
        // This should be detected and handled by continuing accumulation
        final deviceData2 = MockDeviceData([
          MockParameter('Total Distance', 50), // Device reset to 50
          MockParameter('Total Energy', 10),   // Device reset to 10
        ], DeviceDataType.rower);

        final result2 = processor.processDeviceData(deviceData2);
        // Should add the reset values to the previous total
        expect(result2['Total Distance']!.value, equals(550)); // 500 + 50
        expect(result2['Total Energy']!.value, equals(110));   // 100 + 10
      });

      test('handles multiple data points after device reset correctly', () {
        processor.configure(cumulativeConfig);

        // Initial workout data - disconnected at 500m
        final deviceData1 = MockDeviceData([
          MockParameter('Total Distance', 500),
        ], DeviceDataType.rower);

        final result1 = processor.processDeviceData(deviceData1);
        expect(result1['Total Distance']!.value, equals(500));

        // Device disconnects and reconnects - series of values after reset
        // Values: 0, 14, 25, 30, 33, 50
        // Expected results: 500, 514, 525, 530, 533, 550

        // After reconnection: 0 (reset detected)
        final deviceData2 = MockDeviceData([
          MockParameter('Total Distance', 0),
        ], DeviceDataType.rower);
        final result2 = processor.processDeviceData(deviceData2);
        expect(result2['Total Distance']!.value, equals(500)); // 500 offset + 0

        // Next: 14
        final deviceData3 = MockDeviceData([
          MockParameter('Total Distance', 14),
        ], DeviceDataType.rower);
        final result3 = processor.processDeviceData(deviceData3);
        expect(result3['Total Distance']!.value, equals(514)); // 500 offset + 14

        // Next: 25
        final deviceData4 = MockDeviceData([
          MockParameter('Total Distance', 25),
        ], DeviceDataType.rower);
        final result4 = processor.processDeviceData(deviceData4);
        expect(result4['Total Distance']!.value, equals(525)); // 500 offset + 25

        // Next: 30
        final deviceData5 = MockDeviceData([
          MockParameter('Total Distance', 30),
        ], DeviceDataType.rower);
        final result5 = processor.processDeviceData(deviceData5);
        expect(result5['Total Distance']!.value, equals(530)); // 500 offset + 30

        // Next: 33
        final deviceData6 = MockDeviceData([
          MockParameter('Total Distance', 33),
        ], DeviceDataType.rower);
        final result6 = processor.processDeviceData(deviceData6);
        expect(result6['Total Distance']!.value, equals(533)); // 500 offset + 33

        // Final: 50
        final deviceData7 = MockDeviceData([
          MockParameter('Total Distance', 50),
        ], DeviceDataType.rower);
        final result7 = processor.processDeviceData(deviceData7);
        expect(result7['Total Distance']!.value, equals(550)); // 500 offset + 50
      });

      test('ignores small decreases to avoid false positives', () {
        processor.configure(cumulativeConfig);

        // Initial values
        final deviceData1 = MockDeviceData([
          MockParameter('Total Distance', 200),
        ], DeviceDataType.rower);

        final result1 = processor.processDeviceData(deviceData1);
        expect(result1['Total Distance']!.value, equals(200));

        // Small decrease (less than 50% drop) - should be ignored
        final deviceData2 = MockDeviceData([
          MockParameter('Total Distance', 190),
        ], DeviceDataType.rower);

        final result2 = processor.processDeviceData(deviceData2);
        // Should maintain previous value, not decrease
        expect(result2['Total Distance']!.value, equals(200));
      });

      test('resets cumulative values when processor is reset', () {
        processor.configure(cumulativeConfig);

        // Build up some cumulative values
        final deviceData = MockDeviceData([
          MockParameter('Total Distance', 300),
          MockParameter('Total Energy', 80),
        ], DeviceDataType.rower);

        final result1 = processor.processDeviceData(deviceData);
        expect(result1['Total Distance']!.value, equals(300));
        expect(result1['Total Energy']!.value, equals(80));

        // Reset processor
        processor.reset();

        // Configure again and process - should start from zero
        processor.configure(cumulativeConfig);
        final newDeviceData = MockDeviceData([
          MockParameter('Total Distance', 100),
          MockParameter('Total Energy', 25),
        ], DeviceDataType.rower);

        final result2 = processor.processDeviceData(newDeviceData);
        expect(result2['Total Distance']!.value, equals(100));
        expect(result2['Total Energy']!.value, equals(25));
      });
    });
  });
}
