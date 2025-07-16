import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/config/live_data_display_config.dart';
import 'package:ftms/core/config/live_data_field_config.dart';
import 'package:ftms/core/models/device_types.dart';

void main() {
  group('FtmsDisplayConfig', () {
    test('can parse from JSON', () {
      final json = {
        "ftmsMachineType": "DeviceDataType.indoorBike",
        'fields': [
          {
            'name': 'Speed',
            'label': 'Speed',
            'display': 'number',
            'unit': 'km/h',
            'min': 0,
            'max': 60,
            'icon': 'bike',
            'targetRange': 0.12,
          }
        ]
      };
      final config = LiveDataDisplayConfig.fromJson(json);
      expect(config.deviceType, DeviceType.indoorBike);
      expect(config.fields.length, 1);
      expect(config.fields.first.name, 'Speed');
      expect(config.fields.first.icon, 'bike');
      expect(config.fields.first.samplePeriodSeconds, isNull);
      expect(config.fields.first.targetRange, equals(0.12));
    });

    test('can parse field with samplePeriodSeconds', () {
      final json = {
        "ftmsMachineType": "DeviceDataType.indoorBike",
        'fields': [
          {
            'name': 'Power',
            'label': 'Power',
            'display': 'speedometer',
            'unit': 'W',
            'min': 0,
            'max': 1000,
            'samplePeriodSeconds': 3
          }
        ]
      };
      final config = LiveDataDisplayConfig.fromJson(json);
      expect(config.deviceType, DeviceType.indoorBike);
      expect(config.fields.length, 1);
      expect(config.fields.first.name, 'Power');
      expect(config.fields.first.samplePeriodSeconds, equals(3));
      expect(config.fields.first.targetRange, equals(0.1)); // Default value when not specified
    });

    test('can parse mixed fields with and without averaging', () {
      final json = {
        "ftmsMachineType": "DeviceDataType.indoorBike",
        'fields': [
          {
            'name': 'Power',
            'label': 'Power',
            'display': 'speedometer',
            'unit': 'W',
            'samplePeriodSeconds': 3
          },
          {
            'name': 'Speed',
            'label': 'Speed',
            'display': 'number',
            'unit': 'km/h'
          },
          {
            'name': 'Cadence',
            'label': 'Cadence',
            'display': 'number',
            'unit': 'rpm',
            'samplePeriodSeconds': 5
          }
        ]
      };
      final config = LiveDataDisplayConfig.fromJson(json);
      expect(config.fields.length, 3);
      
      final powerField = config.fields.firstWhere((f) => f.name == 'Power');
      final speedField = config.fields.firstWhere((f) => f.name == 'Speed');
      final cadenceField = config.fields.firstWhere((f) => f.name == 'Cadence');
      
      expect(powerField.samplePeriodSeconds, equals(3));
      expect(speedField.samplePeriodSeconds, isNull);
      expect(cadenceField.samplePeriodSeconds, equals(5));
    });

    test('handles zero samplePeriodSeconds', () {
      final json = {
        "ftmsMachineType": "DeviceDataType.rower",
        'fields': [
          {
            'name': 'Power',
            'label': 'Power',
            'display': 'number',
            'unit': 'W',
            'samplePeriodSeconds': 0
          }
        ]
      };
      final config = LiveDataDisplayConfig.fromJson(json);
      expect(config.fields.first.samplePeriodSeconds, equals(0));
    });

    test('handles negative samplePeriodSeconds', () {
      final json = {
        "ftmsMachineType": "DeviceDataType.indoorBike",
        'fields': [
          {
            'name': 'Power',
            'label': 'Power',
            'display': 'number',
            'unit': 'W',
            'samplePeriodSeconds': -1
          }
        ]
      };
      final config = LiveDataDisplayConfig.fromJson(json);
      expect(config.fields.first.samplePeriodSeconds, equals(-1));
    });
  });

  group('FtmsDisplayField', () {
    test('can be created with all properties', () {
      final field = LiveDataFieldConfig(
        name: 'Power',
        label: 'Power',
        display: 'speedometer',
        unit: 'W',
        min: 0,
        max: 1000,
        icon: 'power',
        samplePeriodSeconds: 3,
        availableAsTarget: true,
        userSetting: 'cyclingFtp',
        targetRange: 0.05,
      );
      
      expect(field.name, equals('Power'));
      expect(field.label, equals('Power'));
      expect(field.display, equals('speedometer'));
      expect(field.unit, equals('W'));
      expect(field.min, equals(0));
      expect(field.max, equals(1000));
      expect(field.icon, equals('power'));
      expect(field.samplePeriodSeconds, equals(3));
      expect(field.availableAsTarget, equals(true));
      expect(field.userSetting, equals('cyclingFtp'));
      expect(field.targetRange, equals(0.05));
    });

    test('can be created without optional properties', () {
      final field = LiveDataFieldConfig(
        name: 'Speed',
        label: 'Speed',
        display: 'number',
        unit: 'km/h',
      );
      
      expect(field.name, equals('Speed'));
      expect(field.label, equals('Speed'));
      expect(field.display, equals('number'));
      expect(field.unit, equals('km/h'));
      expect(field.min, isNull);
      expect(field.max, isNull);
      expect(field.icon, isNull);
      expect(field.samplePeriodSeconds, isNull);
      expect(field.availableAsTarget, equals(false));
      expect(field.userSetting, isNull);
      expect(field.targetRange, equals(0.1)); // Default value
    });

    test('can be created with custom targetRange', () {
      final field = LiveDataFieldConfig(
        name: 'Heart Rate',
        label: 'Heart Rate',
        display: 'number',
        unit: 'bpm',
        targetRange: 0.15,
      );
      
      expect(field.name, equals('Heart Rate'));
      expect(field.label, equals('Heart Rate'));
      expect(field.display, equals('number'));
      expect(field.unit, equals('bpm'));
      expect(field.targetRange, equals(0.15));
    });

    test('can parse from JSON with targetRange', () {
      final json = {
        'name': 'Power',
        'label': 'Power',
        'display': 'speedometer',
        'unit': 'W',
        'min': 0,
        'max': 1000,
        'icon': 'power',
        'samplePeriodSeconds': 3,
        'availableAsTarget': true,
        'userSetting': 'cyclingFtp',
        'targetRange': 0.08,
      };
      
      final field = LiveDataFieldConfig.fromJson(json);
      
      expect(field.name, equals('Power'));
      expect(field.label, equals('Power'));
      expect(field.display, equals('speedometer'));
      expect(field.unit, equals('W'));
      expect(field.min, equals(0));
      expect(field.max, equals(1000));
      expect(field.icon, equals('power'));
      expect(field.samplePeriodSeconds, equals(3));
      expect(field.availableAsTarget, equals(true));
      expect(field.userSetting, equals('cyclingFtp'));
      expect(field.targetRange, equals(0.08));
    });

    test('can parse from JSON without targetRange (uses default)', () {
      final json = {
        'name': 'Speed',
        'label': 'Speed',
        'display': 'number',
        'unit': 'km/h',
      };
      
      final field = LiveDataFieldConfig.fromJson(json);
      
      expect(field.name, equals('Speed'));
      expect(field.label, equals('Speed'));
      expect(field.display, equals('number'));
      expect(field.unit, equals('km/h'));
      expect(field.targetRange, equals(0.1)); // Default value
    });

    test('computeTargetInterval works with normal fields (min <= max)', () {
      final config = LiveDataFieldConfig(
        name: 'Speed',
        label: 'Speed',
        display: 'number',
        unit: 'km/h',
        min: 0,
        max: 60,
        targetRange: 0.1,
      );
      
      final interval = config.computeTargetInterval(20);
      expect(interval, isNotNull);
      expect(interval!.lower, equals(18.0));
      expect(interval.upper, equals(22.0));
    });

    test('computeTargetInterval works with inverted fields (min > max)', () {
      final config = LiveDataFieldConfig(
        name: 'Pace',
        label: 'Pace',
        display: 'number',
        unit: 'min/km',
        min: 10, // slower pace (higher value)
        max: 3,  // faster pace (lower value)
        targetRange: 0.1,
      );
      
      final interval = config.computeTargetInterval(5);
      expect(interval, isNotNull);
      expect(interval!.lower, equals(4.5));
      expect(interval.upper, equals(5.5));
    });

    test('computeTargetInterval applies bounds correctly for normal fields', () {
      final config = LiveDataFieldConfig(
        name: 'Speed',
        label: 'Speed',
        display: 'number',
        unit: 'km/h',
        min: 5,  // Use a higher minimum to make clamping more likely
        max: 60,
        targetRange: 0.5, // Use a large range to trigger bounds
      );
      
      // Target that would go below minimum bound
      final interval1 = config.computeTargetInterval(8);
      expect(interval1, isNotNull);
      expect(interval1!.lower, equals(5.0)); // Clamped to min (8 - 4 = 4, but min is 5)
      expect(interval1.upper, equals(12.0));
      
      // Target near maximum
      final interval2 = config.computeTargetInterval(58);
      expect(interval2, isNotNull);
      expect(interval2!.lower, equals(29.0)); // 58 - 29 = 29
      expect(interval2.upper, equals(60.0)); // Clamped to max (58 + 29 = 87, but max is 60)
    });

    test('computeTargetInterval applies bounds correctly for inverted fields', () {
      final config = LiveDataFieldConfig(
        name: 'Pace',
        label: 'Pace',
        display: 'number',
        unit: 'min/km',
        min: 10, // slower pace (higher value)
        max: 3,  // faster pace (lower value)
        targetRange: 0.2,
      );
      
      // Target near "fast" limit (close to max value)
      final interval1 = config.computeTargetInterval(3.5);
      expect(interval1, isNotNull);
      expect(interval1!.lower, equals(3.0)); // Clamped to max (fastest allowed)
      expect(interval1.upper, equals(4.2));
      
      // Target near "slow" limit (close to min value)
      final interval2 = config.computeTargetInterval(9);
      expect(interval2, isNotNull);
      expect(interval2!.lower, equals(7.2));
      expect(interval2.upper, equals(10.0)); // Clamped to min (slowest allowed)
    });

    test('computeTargetInterval works without bounds', () {
      final config = LiveDataFieldConfig(
        name: 'Power',
        label: 'Power',
        display: 'number',
        unit: 'W',
        targetRange: 0.1,
      );
      
      final interval = config.computeTargetInterval(100);
      expect(interval, isNotNull);
      expect(interval!.lower, equals(90.0));
      expect(interval.upper, equals(110.0));
    });

    test('computeTargetInterval returns null for null target', () {
      final config = LiveDataFieldConfig(
        name: 'Speed',
        label: 'Speed',
        display: 'number',
        unit: 'km/h',
        targetRange: 0.1,
      );
      
      final interval = config.computeTargetInterval(null);
      expect(interval, isNull);
    });

    test('computeTargetInterval works with negative targets', () {
      final config = LiveDataFieldConfig(
        name: 'Gradient',
        label: 'Gradient',
        display: 'number',
        unit: '%',
        min: -20,
        max: 20,
        targetRange: 0.1,
      );
      
      final interval = config.computeTargetInterval(-10);
      expect(interval, isNotNull);
      expect(interval!.lower, equals(-11.0));
      expect(interval.upper, equals(-9.0));
    });

  });
}
