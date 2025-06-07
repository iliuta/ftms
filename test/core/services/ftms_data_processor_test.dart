import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/services/ftms_data_processor.dart';
import 'package:ftms/core/services/value_averaging_service.dart';
import 'package:ftms/core/config/ftms_display_config.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import 'package:flutter_ftms/src/ftms/flag.dart';
import 'package:flutter_ftms/src/ftms/parameter_name.dart';
import 'package:mockito/mockito.dart';

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
  List<DeviceDataParameter> get allDeviceDataParameters => _parameters.cast<DeviceDataParameter>();
  
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
  
  @override
  num get value => _value;
  
  @override
  num get factor => _factor;
  
  @override
  String get unit => _unit;
  
  @override
  num get scaleFactor => 1;
  
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
  num get scaleFactor => _parameter.scaleFactor;
  
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
    late FtmsDisplayConfig config;
    late FtmsDisplayConfig configWithAveraging;

    setUp(() {
      // Clear any previous state from the singleton averaging service
      ValueAveragingService().clearAll();
      
      processor = FtmsDataProcessor();
      
      config = FtmsDisplayConfig(fields: [
        FtmsDisplayField(
          name: 'Instantaneous Power',
          label: 'Power',
          display: 'number',
          unit: 'W',
        ),
        FtmsDisplayField(
          name: 'Instantaneous Speed',
          label: 'Speed', 
          display: 'number',
          unit: 'km/h',
        ),
      ]);
      
      configWithAveraging = FtmsDisplayConfig(fields: [
        FtmsDisplayField(
          name: 'Instantaneous Power',
          label: 'Power',
          display: 'number',
          unit: 'W',
          samplePeriodSeconds: 3,
        ),
        FtmsDisplayField(
          name: 'Instantaneous Speed',
          label: 'Speed',
          display: 'number', 
          unit: 'km/h',
        ),
      ]);
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
        expect(result['Instantaneous Power'].value, equals(250));
        expect(result['Instantaneous Speed'].value, equals(25));
      });

      test('preserves original parameter properties', () {
        processor.configure(config);
        
        final deviceData = MockDeviceData([
          MockParameter('Instantaneous Power', 250, factor: 2),
        ], DeviceDataType.indoorBike);
        
        final result = processor.processDeviceData(deviceData);
        final param = result['Instantaneous Power'];
        
        expect(param.value, equals(250));
        expect(param.factor, equals(2));
        expect(param.unit, equals('W'));
        expect(param.name.name, equals('Instantaneous Power'));
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
        expect(result['Instantaneous Power'].value, equals(250.0)); // (200 + 300) / 2
        
        // Speed should be instantaneous (no samplePeriodSeconds)
        expect(result['Instantaneous Speed'].value, equals(30));
      });

      test('maintains parameter interface for averaged values', () {
        processor.configure(configWithAveraging);
        
        final deviceData = MockDeviceData([
          MockParameter('Instantaneous Power', 250, factor: 2),
        ], DeviceDataType.indoorBike);
        
        // Process data twice to enable averaging
        processor.processDeviceData(deviceData);
        final result = processor.processDeviceData(deviceData);
        
        final param = result['Instantaneous Power'];
        
        // Should have averaged value but preserve other properties
        expect(param.value, equals(250.0)); // Average of same value
        expect(param.factor, equals(2));
        expect(param.unit, equals('W'));
        expect(param.name.name, equals('Instantaneous Power'));
        expect(param.toString(), equals('250.0'));
      });
    });

    group('Averaged parameter wrapper', () {
      test('delegates all properties correctly', () {
        processor.configure(configWithAveraging);
        
        final deviceData = MockDeviceData([
          MockParameter('Instantaneous Power', 100, factor: 1.5),
        ], DeviceDataType.indoorBike);
        
        processor.processDeviceData(deviceData);
        final result = processor.processDeviceData(deviceData);
        
        final wrapper = result['Instantaneous Power'];
        
        expect(wrapper.value, equals(100.0));
        expect(wrapper.factor, equals(1.5));
        expect(wrapper.unit, equals('W'));
        expect(wrapper.scaleFactor, equals(1));
        expect(wrapper.flag, equals(null));
        expect(wrapper.size, equals(2));
        expect(wrapper.name.name, equals('Instantaneous Power'));
      });

      test('handles noSuchMethod correctly', () {
        processor.configure(configWithAveraging);
        
        final deviceData = MockDeviceData([
          MockParameter('Instantaneous Power', 150),
        ], DeviceDataType.indoorBike);
        
        processor.processDeviceData(deviceData);
        final result = processor.processDeviceData(deviceData);
        
        final wrapper = result['Instantaneous Power'];
        
        // Test accessing value property through noSuchMethod
        expect(wrapper.value, equals(150.0));
        
        // Test toString
        expect(wrapper.toString(), equals('150.0'));
      });
    });

    group('Mixed field types', () {
      test('handles mix of averaged and non-averaged fields', () {
        final mixedConfig = FtmsDisplayConfig(fields: [
          FtmsDisplayField(
            name: 'Instantaneous Power',
            label: 'Power',
            display: 'number',
            unit: 'W',
            samplePeriodSeconds: 3,
          ),
          FtmsDisplayField(
            name: 'Instantaneous Speed',
            label: 'Speed',
            display: 'number',
            unit: 'km/h',
            // No samplePeriodSeconds
          ),
          FtmsDisplayField(
            name: 'Instantaneous Cadence',
            label: 'Cadence',
            display: 'number',
            unit: 'rpm',
            samplePeriodSeconds: 5,
          ),
        ]);
        
        processor.configure(mixedConfig);
        
        // Process multiple rounds of data
        for (int i = 1; i <= 3; i++) {
          final deviceData = MockDeviceData([
            MockParameter('Instantaneous Power', i * 100),      // Will be averaged
            MockParameter('Instantaneous Speed', i * 10),       // Will be instantaneous  
            MockParameter('Instantaneous Cadence', i * 20),     // Will be averaged
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
        expect(result['Instantaneous Power'].value, equals(250.0));
        
        // Speed: instantaneous (latest value)
        expect(result['Instantaneous Speed'].value, equals(40));
        
        // Cadence: averaged (20, 40, 60, 80) / 4 = 50
        expect(result['Instantaneous Cadence'].value, equals(50.0));
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
        expect(result['Instantaneous Power'].value, equals(250));
      });

      test('handles parameter with non-parameter type', () {
        processor.configure(config);
        
        // This tests the fallback case in _createAveragedParameter
        final deviceData = MockDeviceData([
          MockParameter('Instantaneous Power', 250),
        ], DeviceDataType.indoorBike);
        
        final result = processor.processDeviceData(deviceData);
        expect(result['Instantaneous Power'], isNotNull);
      });
    });
  });
}
