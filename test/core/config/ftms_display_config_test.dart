import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/config/ftms_display_config.dart';
import 'package:ftms/core/models/ftms_display_field.dart';

void main() {
  group('FtmsDisplayConfig', () {
    test('can parse from JSON', () {
      final json = {
        'fields': [
          {
            'name': 'Speed',
            'label': 'Speed',
            'display': 'number',
            'unit': 'km/h',
            'min': 0,
            'max': 60,
            'icon': 'bike'
          }
        ]
      };
      final config = FtmsDisplayConfig.fromJson(json);
      expect(config.fields.length, 1);
      expect(config.fields.first.name, 'Speed');
      expect(config.fields.first.icon, 'bike');
      expect(config.fields.first.samplePeriodSeconds, isNull);
    });

    test('can parse field with samplePeriodSeconds', () {
      final json = {
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
      final config = FtmsDisplayConfig.fromJson(json);
      expect(config.fields.length, 1);
      expect(config.fields.first.name, 'Power');
      expect(config.fields.first.samplePeriodSeconds, equals(3));
    });

    test('can parse mixed fields with and without averaging', () {
      final json = {
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
      final config = FtmsDisplayConfig.fromJson(json);
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
      final config = FtmsDisplayConfig.fromJson(json);
      expect(config.fields.first.samplePeriodSeconds, equals(0));
    });

    test('handles negative samplePeriodSeconds', () {
      final json = {
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
      final config = FtmsDisplayConfig.fromJson(json);
      expect(config.fields.first.samplePeriodSeconds, equals(-1));
    });
  });

  group('FtmsDisplayField', () {
    test('can be created with all properties', () {
      final field = FtmsDisplayField(
        name: 'Power',
        label: 'Power',
        display: 'speedometer',
        unit: 'W',
        min: 0,
        max: 1000,
        icon: 'power',
        samplePeriodSeconds: 3,
      );
      
      expect(field.name, equals('Power'));
      expect(field.label, equals('Power'));
      expect(field.display, equals('speedometer'));
      expect(field.unit, equals('W'));
      expect(field.min, equals(0));
      expect(field.max, equals(1000));
      expect(field.icon, equals('power'));
      expect(field.samplePeriodSeconds, equals(3));
    });

    test('can be created without optional properties', () {
      final field = FtmsDisplayField(
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
    });
  });
}
