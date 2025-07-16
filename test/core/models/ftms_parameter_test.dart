import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/models/live_data_field_value.dart';

void main() {
  group('LiveDataFieldValue', () {
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

    test('can be created with floating point values', () {
      final param = LiveDataFieldValue(
        name: 'Speed',
        value: 25.5,
        factor: 1.5,
      );
      
      expect(param.name, equals('Speed'));
      expect(param.value, equals(25.5));
      expect(param.factor, equals(1.5));
      expect(param.getScaledValue(), equals(38.25));
    });

    test('can be created with negative values', () {
      final param = LiveDataFieldValue(
        name: 'Gradient',
        value: -5,
        factor: 1,
        unit: '%',
      );
      
      expect(param.name, equals('Gradient'));
      expect(param.value, equals(-5));
      expect(param.factor, equals(1));
      expect(param.unit, equals('%'));
      expect(param.getScaledValue(), equals(-5));
    });

    test('can be created with zero values', () {
      final param = LiveDataFieldValue(
        name: 'Power',
        value: 0,
        factor: 2,
      );
      
      expect(param.value, equals(0));
      expect(param.factor, equals(2));
      expect(param.getScaledValue(), equals(0));
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

    test('getScaledValue works with zero factor', () {
      final param = LiveDataFieldValue(
        name: 'Test',
        value: 100,
        factor: 0,
      );
      
      expect(param.getScaledValue(), equals(0));
    });

    test('isWithinTarget returns true when value is within range', () {
      final param = LiveDataFieldValue(
        name: 'Power',
        value: 100,
        factor: 1,
      );
      
      // Target 100, value 100 (scaled) should be within ±10%
      expect(param.isWithinTarget(100, 0.1), isTrue);
      
      // Target 100, value 95 (scaled) should be within ±10% (90-110 range)
      final param2 = LiveDataFieldValue(name: 'Power', value: 95, factor: 1);
      expect(param2.isWithinTarget(100, 0.1), isTrue);
      
      // Target 100, value 110 (scaled) should be within ±10% (90-110 range)
      final param3 = LiveDataFieldValue(name: 'Power', value: 110, factor: 1);
      expect(param3.isWithinTarget(100, 0.1), isTrue);
    });

    test('isWithinTarget returns false when value is outside range', () {
      // Target 100, value 89 (scaled) should be outside ±10% (90-110 range)
      final param1 = LiveDataFieldValue(name: 'Power', value: 89, factor: 1);
      expect(param1.isWithinTarget(100, 0.1), isFalse);
      
      // Target 100, value 111 (scaled) should be outside ±10% (90-110 range)
      final param2 = LiveDataFieldValue(name: 'Power', value: 111, factor: 1);
      expect(param2.isWithinTarget(100, 0.1), isFalse);
    });

    test('isWithinTarget works with scaling factor', () {
      // Value 50 with factor 2 = scaled value 100, target 100 should be within range
      final param = LiveDataFieldValue(name: 'Power', value: 50, factor: 2);
      expect(param.isWithinTarget(100, 0.1), isTrue);
      
      // Value 40 with factor 2 = scaled value 80, target 100 should be outside range (90-110)
      final param2 = LiveDataFieldValue(name: 'Power', value: 40, factor: 2);
      expect(param2.isWithinTarget(100, 0.1), isFalse);
    });

    test('isWithinTarget works with different target ranges', () {
      final param = LiveDataFieldValue(name: 'Power', value: 95, factor: 1);
      
      // Within 10% range (90-110)
      expect(param.isWithinTarget(100, 0.1), isTrue);
      
      // Outside 4% range (96-104)
      expect(param.isWithinTarget(100, 0.04), isFalse);
      
      // Within 20% range (80-120)
      expect(param.isWithinTarget(100, 0.2), isTrue);
    });

    test('isWithinTarget works with zero target', () {
      final param = LiveDataFieldValue(name: 'Power', value: 5, factor: 1);
      
      // Target 0, value 5 should be outside any positive range
      expect(param.isWithinTarget(0, 0.1), isFalse);
      
      final param2 = LiveDataFieldValue(name: 'Power', value: 0, factor: 1);
      
      // Target 0, value 0 should be within range
      expect(param2.isWithinTarget(0, 0.1), isTrue);
    });


    test('isWithinTarget returns false when target is null', () {
      final param = LiveDataFieldValue(name: 'Power', value: 100, factor: 1);
      expect(param.isWithinTarget(null, 0.1), isFalse);
    });

    test('isWithinTarget works with very small target ranges', () {
      final param = LiveDataFieldValue(name: 'Power', value: 100.2, factor: 1);
      
      // Target 100, value 100.2 should be outside 0.1% range (99.9-100.1)
      expect(param.isWithinTarget(100, 0.001), isFalse);
      
      // Target 100, value 100.05 should be within 0.1% range (99.9-100.1)
      final param2 = LiveDataFieldValue(name: 'Power', value: 100.05, factor: 1);
      expect(param2.isWithinTarget(100, 0.001), isTrue);
    });

    test('getFormattedValue returns correct format', () {
      final param = LiveDataFieldValue(
        name: 'Power',
        value: 250,
        unit: 'W',
      );
      
      expect(param.getFormattedValue(), equals('250 W'));
    });

    test('getFormattedValue works with empty unit', () {
      final param = LiveDataFieldValue(
        name: 'Power',
        value: 250,
        unit: '',
      );
      
      expect(param.getFormattedValue(), equals('250 '));
    });

    test('getFormattedValue works with floating point values', () {
      final param = LiveDataFieldValue(
        name: 'Speed',
        value: 25.5,
        unit: 'km/h',
      );
      
      expect(param.getFormattedValue(), equals('25.5 km/h'));
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

    test('copyWith can update all properties', () {
      final original = LiveDataFieldValue(
        name: 'Power',
        value: 100,
        factor: 1,
        unit: 'W',
        flag: true,
        size: 2,
        signed: false,
      );
      
      final updated = original.copyWith(
        name: 'Speed',
        value: 50,
        factor: 2,
        unit: 'km/h',
        flag: false,
        size: 4,
        signed: true,
      );
      
      expect(updated.name, equals('Speed'));
      expect(updated.value, equals(50));
      expect(updated.factor, equals(2));
      expect(updated.unit, equals('km/h'));
      expect(updated.flag, equals(false));
      expect(updated.size, equals(4));
      expect(updated.signed, equals(true));
    });

    test('copyWith with null values preserves original', () {
      final original = LiveDataFieldValue(
        name: 'Power',
        value: 100,
        factor: 1,
        unit: 'W',
      );
      
      final updated = original.copyWith();
      
      expect(updated.name, equals(original.name));
      expect(updated.value, equals(original.value));
      expect(updated.factor, equals(original.factor));
      expect(updated.unit, equals(original.unit));
    });

    test('toString returns value as string', () {
      final param = LiveDataFieldValue(name: 'Power', value: 250);
      expect(param.toString(), equals('250'));
    });

    test('toString works with floating point values', () {
      final param = LiveDataFieldValue(name: 'Speed', value: 25.5);
      expect(param.toString(), equals('25.5'));
    });

    test('toString works with negative values', () {
      final param = LiveDataFieldValue(name: 'Gradient', value: -5);
      expect(param.toString(), equals('-5'));
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

    test('equality considers all properties', () {
      final param1 = LiveDataFieldValue(
        name: 'Power',
        value: 250,
        factor: 1,
        unit: 'W',
        flag: true,
        size: 2,
        signed: false,
      );
      
      final param2 = LiveDataFieldValue(
        name: 'Power',
        value: 250,
        factor: 1,
        unit: 'W',
        flag: true,
        size: 2,
        signed: false,
      );
      
      final param3 = LiveDataFieldValue(
        name: 'Power',
        value: 250,
        factor: 1,
        unit: 'W',
        flag: false, // Different flag
        size: 2,
        signed: false,
      );
      
      expect(param1, equals(param2));
      expect(param1, isNot(equals(param3)));
    });

    test('equality works with null flags', () {
      final param1 = LiveDataFieldValue(
        name: 'Power',
        value: 250,
        factor: 1,
        unit: 'W',
        flag: null,
      );
      
      final param2 = LiveDataFieldValue(
        name: 'Power',
        value: 250,
        factor: 1,
        unit: 'W',
        flag: null,
      );
      
      expect(param1, equals(param2));
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

    test('hashCode considers all properties', () {
      final param1 = LiveDataFieldValue(
        name: 'Power',
        value: 250,
        factor: 1,
        unit: 'W',
        flag: true,
        size: 2,
        signed: false,
      );
      
      final param2 = LiveDataFieldValue(
        name: 'Power',
        value: 250,
        factor: 1,
        unit: 'W',
        flag: true,
        size: 2,
        signed: false,
      );
      
      final param3 = LiveDataFieldValue(
        name: 'Speed', // Different name
        value: 250,
        factor: 1,
        unit: 'W',
        flag: true,
        size: 2,
        signed: false,
      );
      
      expect(param1.hashCode, equals(param2.hashCode));
      expect(param1.hashCode, isNot(equals(param3.hashCode)));
    });

    test('can work with very large values', () {
      final param = LiveDataFieldValue(
        name: 'Distance',
        value: 999999999,
        factor: 1,
        unit: 'm',
      );
      
      expect(param.value, equals(999999999));
      expect(param.getScaledValue(), equals(999999999));
      expect(param.getFormattedValue(), equals('999999999 m'));
    });

    test('can work with very small values', () {
      final param = LiveDataFieldValue(
        name: 'Precision',
        value: 0.0001,
        factor: 1,
        unit: 'mm',
      );
      
      expect(param.value, equals(0.0001));
      expect(param.getScaledValue(), equals(0.0001));
      expect(param.getFormattedValue(), equals('0.0001 mm'));
    });
  });
}
