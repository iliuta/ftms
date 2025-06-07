import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/services/value_averaging_service.dart';

void main() {
  group('ValueAveragingService', () {
    late ValueAveragingService service;

    setUp(() {
      service = ValueAveragingService();
      // Reset service state for each test
      service.clearAll();
    });

    group('Singleton pattern', () {
      test('returns same instance', () {
        final instance1 = ValueAveragingService();
        final instance2 = ValueAveragingService();
        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('Field configuration', () {
      test('configures field for averaging', () {
        service.configureField('Power', 3);
        expect(service.isFieldAveraged('Power'), isTrue);
        expect(service.isFieldAveraged('Speed'), isFalse);
      });

      test('handles multiple field configurations', () {
        service.configureField('Power', 3);
        service.configureField('Speed', 5);
        
        expect(service.isFieldAveraged('Power'), isTrue);
        expect(service.isFieldAveraged('Speed'), isTrue);
        expect(service.isFieldAveraged('Cadence'), isFalse);
      });

      test('handles zero sample period', () {
        service.configureField('Power', 0);
        expect(service.isFieldAveraged('Power'), isTrue);
      });

      test('handles negative sample period', () {
        service.configureField('Power', -1);
        expect(service.isFieldAveraged('Power'), isTrue);
      });
    });

    group('Value averaging', () {
      test('returns null for unconfigured field', () {
        expect(service.getAveragedValue('Power'), isNull);
      });

      test('returns null for configured field with no values', () {
        service.configureField('Power', 3);
        expect(service.getAveragedValue('Power'), isNull);
      });

      test('returns single value when only one value added', () {
        service.configureField('Power', 3);
        service.addValue('Power', 100);
        expect(service.getAveragedValue('Power'), equals(100.0));
      });

      test('calculates average of multiple values', () {
        service.configureField('Power', 5);
        service.addValue('Power', 100);
        service.addValue('Power', 200);
        service.addValue('Power', 300);
        
        final average = service.getAveragedValue('Power');
        expect(average, equals(200.0)); // (100 + 200 + 300) / 3
      });

      test('handles different value types', () {
        service.configureField('Power', 3);
        service.addValue('Power', 100);      // int
        service.addValue('Power', 150.5);    // double
        service.addValue('Power', 200);      // int
        
        final average = service.getAveragedValue('Power');
        expect(average, equals(150.16666666666666)); // (100 + 150.5 + 200) / 3
      });

      test('handles null values gracefully', () {
        service.configureField('Power', 3);
        service.addValue('Power', 100);
        service.addValue('Power', null);
        service.addValue('Power', 200);
        
        final average = service.getAveragedValue('Power');
        expect(average, equals(150.0)); // (100 + 200) / 2, null ignored
      });

      test('handles all null values', () {
        service.configureField('Power', 3);
        service.addValue('Power', null);
        service.addValue('Power', null);
        
        expect(service.getAveragedValue('Power'), isNull);
      });
    });

    group('Time-based filtering', () {
      test('filters old values based on sample period', () async {
        service.configureField('Power', 1); // 1 second window
        
        // Add initial value
        service.addValue('Power', 100);
        expect(service.getAveragedValue('Power'), equals(100.0));
        
        // Wait longer than sample period
        await Future.delayed(const Duration(milliseconds: 1100));
        
        // Add new value - old value should be filtered out
        service.addValue('Power', 200);
        expect(service.getAveragedValue('Power'), equals(200.0));
      });

      test('keeps recent values within sample period', () async {
        service.configureField('Power', 2); // 2 second window
        
        service.addValue('Power', 100);
        await Future.delayed(const Duration(milliseconds: 500));
        service.addValue('Power', 200);
        await Future.delayed(const Duration(milliseconds: 500));
        service.addValue('Power', 300);
        
        // All values should still be within 2 second window
        final average = service.getAveragedValue('Power');
        expect(average, equals(200.0)); // (100 + 200 + 300) / 3
      });

      test('handles zero sample period (no time filtering)', () {
        service.configureField('Power', 0);
        
        // Add many values over time
        for (int i = 1; i <= 10; i++) {
          service.addValue('Power', i * 10);
        }
        
        final average = service.getAveragedValue('Power');
        expect(average, equals(55.0)); // (10+20+...+100) / 10
      });
    });

    group('Multiple fields', () {
      test('handles multiple fields independently', () {
        service.configureField('Power', 3);
        service.configureField('Speed', 5);
        
        service.addValue('Power', 100);
        service.addValue('Power', 200);
        service.addValue('Speed', 10);
        service.addValue('Speed', 20);
        service.addValue('Speed', 30);
        
        expect(service.getAveragedValue('Power'), equals(150.0));
        expect(service.getAveragedValue('Speed'), equals(20.0));
      });

      test('does not mix values between fields', () {
        service.configureField('Power', 3);
        service.configureField('Speed', 3);
        
        service.addValue('Power', 1000);
        service.addValue('Speed', 10);
        
        expect(service.getAveragedValue('Power'), equals(1000.0));
        expect(service.getAveragedValue('Speed'), equals(10.0));
      });
    });

    group('Clear functionality', () {
      test('clears all data', () {
        service.configureField('Power', 3);
        service.configureField('Speed', 5);
        service.addValue('Power', 100);
        service.addValue('Speed', 50);
        
        service.clearAll();
        
        expect(service.isFieldAveraged('Power'), isFalse);
        expect(service.isFieldAveraged('Speed'), isFalse);
        expect(service.getAveragedValue('Power'), isNull);
        expect(service.getAveragedValue('Speed'), isNull);
      });
    });

    group('Edge cases', () {
      test('handles very large numbers', () {
        service.configureField('Power', 3);
        service.addValue('Power', 999999999);
        service.addValue('Power', 1000000000);
        
        final average = service.getAveragedValue('Power');
        expect(average, equals(999999999.5));
      });

      test('handles very small numbers', () {
        service.configureField('Power', 3);
        service.addValue('Power', 0.001);
        service.addValue('Power', 0.002);
        
        final average = service.getAveragedValue('Power');
        expect(average, equals(0.0015));
      });

      test('handles negative numbers', () {
        service.configureField('Power', 3);
        service.addValue('Power', -100);
        service.addValue('Power', 100);
        
        final average = service.getAveragedValue('Power');
        expect(average, equals(0.0));
      });

      test('handles empty field name', () {
        service.configureField('', 3);
        service.addValue('', 100);
        
        expect(service.isFieldAveraged(''), isTrue);
        expect(service.getAveragedValue(''), equals(100.0));
      });
    });
  });
}
