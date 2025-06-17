import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/models/live_data_field_value.dart';

void main() {
  group('FtmsParameter', () {
    test('can be created with all properties', () {
      final param = LiveDataFieldValue(
        name: 'Power',
        value: 250,
        factor: 2,
        unit: 'W',
        flag: true,
        size: 4,
        signed: false,
      );
      
      expect(param.name, equals('Power'));
      expect(param.value, equals(250));
      expect(param.factor, equals(2));
      expect(param.unit, equals('W'));
      expect(param.flag, equals(true));
      expect(param.size, equals(4));
      expect(param.signed, equals(false));
    });

    test('can be created with default values', () {
      final param = LiveDataFieldValue(
        name: 'Speed',
        value: 25,
      );
      
      expect(param.name, equals('Speed'));
      expect(param.value, equals(25));
      expect(param.factor, equals(1));
      expect(param.unit, equals(''));
      expect(param.flag, isNull);
      expect(param.size, equals(2));
      expect(param.signed, equals(false));
    });

    test('getScaledValue returns correct value', () {
      final param = LiveDataFieldValue(
        name: 'Power',
        value: 100,
        factor: 2.5,
      );
      
      expect(param.getScaledValue(), equals(250));
    });

    test('getScaledValue works with integer factor', () {
      final param = LiveDataFieldValue(
        name: 'Speed',
        value: 20,
        factor: 3,
      );
      
      expect(param.getScaledValue(), equals(60));
    });

    test('isWithinTarget returns true when value is within range', () {
      final param = LiveDataFieldValue(
        name: 'Power',
        value: 100,
        factor: 1,
      );
      
      // Target 100, value 100 (scaled) should be within ±10%
      expect(param.isWithinTarget(100), isTrue);
      
      // Target 100, value 95 (scaled) should be within ±10% (90-110 range)
      final param2 = LiveDataFieldValue(name: 'Power', value: 95, factor: 1);
      expect(param2.isWithinTarget(100), isTrue);
      
      // Target 100, value 110 (scaled) should be within ±10% (90-110 range)
      final param3 = LiveDataFieldValue(name: 'Power', value: 110, factor: 1);
      expect(param3.isWithinTarget(100), isTrue);
    });

    test('isWithinTarget returns false when value is outside range', () {
      // Target 100, value 89 (scaled) should be outside ±10% (90-110 range)
      final param1 = LiveDataFieldValue(name: 'Power', value: 89, factor: 1);
      expect(param1.isWithinTarget(100), isFalse);
      
      // Target 100, value 111 (scaled) should be outside ±10% (90-110 range)
      final param2 = LiveDataFieldValue(name: 'Power', value: 111, factor: 1);
      expect(param2.isWithinTarget(100), isFalse);
    });

    test('isWithinTarget works with scaling factor', () {
      // Value 50 with factor 2 = scaled value 100, target 100 should be within range
      final param = LiveDataFieldValue(name: 'Power', value: 50, factor: 2);
      expect(param.isWithinTarget(100), isTrue);
      
      // Value 40 with factor 2 = scaled value 80, target 100 should be outside range (90-110)
      final param2 = LiveDataFieldValue(name: 'Power', value: 40, factor: 2);
      expect(param2.isWithinTarget(100), isFalse);
    });

    test('isWithinTarget returns false when target is null', () {
      final param = LiveDataFieldValue(name: 'Power', value: 100, factor: 1);
      expect(param.isWithinTarget(null), isFalse);
    });

    test('getFormattedValue returns correct format', () {
      final param = LiveDataFieldValue(
        name: 'Power',
        value: 250,
        unit: 'W',
      );
      
      expect(param.getFormattedValue(), equals('250 W'));
    });

    test('copyWith creates new instance with updated values', () {
      final original = LiveDataFieldValue(
        name: 'Power',
        value: 100,
        factor: 1,
        unit: 'W',
      );
      
      final updated = original.copyWith(value: 200, factor: 2);
      
      expect(updated.name, equals('Power'));
      expect(updated.value, equals(200));
      expect(updated.factor, equals(2));
      expect(updated.unit, equals('W'));
      
      // Original should be unchanged
      expect(original.value, equals(100));
      expect(original.factor, equals(1));
    });

    test('toString returns value as string', () {
      final param = LiveDataFieldValue(name: 'Power', value: 250);
      expect(param.toString(), equals('250'));
    });

    test('equality works correctly', () {
      final param1 = LiveDataFieldValue(
        name: 'Power',
        value: 250,
        factor: 1,
        unit: 'W',
      );
      
      final param2 = LiveDataFieldValue(
        name: 'Power',
        value: 250,
        factor: 1,
        unit: 'W',
      );
      
      final param3 = LiveDataFieldValue(
        name: 'Power',
        value: 300,
        factor: 1,
        unit: 'W',
      );
      
      expect(param1, equals(param2));
      expect(param1, isNot(equals(param3)));
    });

    test('hashCode works correctly', () {
      final param1 = LiveDataFieldValue(
        name: 'Power',
        value: 250,
        factor: 1,
        unit: 'W',
      );
      
      final param2 = LiveDataFieldValue(
        name: 'Power',
        value: 250,
        factor: 1,
        unit: 'W',
      );
      
      expect(param1.hashCode, equals(param2.hashCode));
    });
  });
}
