import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import 'package:ftms/core/services/fit/distance_calculation_strategy.dart';
import 'package:ftms/core/models/ftms_parameter.dart';

/// Mock class for testing dynamic object handling
class MockDynamicObject {
  final dynamic value;

  MockDynamicObject({required this.value});
}

/// Mock class for testing invalid dynamic object handling
class MockInvalidDynamicObject {
  // This object will throw when accessing .value
  dynamic get value => throw Exception('Invalid object');
}

void main() {
  group('IndoorBikeDistanceStrategy', () {
    late IndoorBikeDistanceStrategy strategy;

    setUp(() {
      strategy = IndoorBikeDistanceStrategy();
    });

    group('calculateDistanceIncrement', () {
      test(
          'calculates distance correctly with valid speed from FtmsParameter', () {
        final param = FtmsParameter(
          name: 'Instantaneous Speed',
          value: 360, // Raw value
          factor: 0.1, // Scale factor to get 36.0 km/h
          unit: 'km/h',
        );

        final currentData = {
          'Instantaneous Speed': param,
        };

        // 36 km/h = 10 m/s, so in 2 seconds = 20 meters
        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 2.0,
        );

        expect(distance, closeTo(20.0, 0.01));
        expect(strategy.totalDistance, closeTo(20.0, 0.01));
      });

      test(
          'calculates distance correctly with valid speed from numeric value', () {
        final currentData = {
          'Speed': 18.0, // 18 km/h
        };

        // 18 km/h = 5 m/s, so in 3 seconds = 15 meters
        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 3.0,
        );

        expect(distance, closeTo(15.0, 0.01));
        expect(strategy.totalDistance, closeTo(15.0, 0.01));
      });

      test('calculates distance correctly with speed from dynamic object', () {
        final currentData = {
          'speed': MockDynamicObject(value: 21.6), // 21.6 km/h
        };

        // 21.6 km/h = 6 m/s, so in 1.5 seconds = 9 meters
        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 1.5,
        );

        expect(distance, closeTo(9.0, 0.01));
        expect(strategy.totalDistance, closeTo(9.0, 0.01));
      });

      test('tries multiple speed parameter keys', () {
        // Test that it finds speed under different key names
        final testCases = [
          {'Instantaneous Speed': 36.0},
          {'Speed': 36.0},
          {'speed': 36.0},
        ];

        for (final testData in testCases) {
          final testStrategy = IndoorBikeDistanceStrategy();
          final distance = testStrategy.calculateDistanceIncrement(
            currentData: testData,
            previousData: null,
            timeDeltaSeconds: 1.0,
          );

          // 36 km/h = 10 m/s, so in 1 second = 10 meters
          expect(distance, closeTo(10.0, 0.01));
        }
      });

      test('returns 0 when speed is null', () {
        final currentData = <String, dynamic>{};

        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 2.0,
        );

        expect(distance, 0.0);
        expect(strategy.totalDistance, 0.0);
      });

      test('returns 0 when speed is zero', () {
        final currentData = {
          'Instantaneous Speed': 0.0,
        };

        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 2.0,
        );

        expect(distance, 0.0);
        expect(strategy.totalDistance, 0.0);
      });

      test('returns 0 when speed is negative', () {
        final currentData = {
          'Instantaneous Speed': -10.0,
        };

        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 2.0,
        );

        expect(distance, 0.0);
        expect(strategy.totalDistance, 0.0);
      });

      test('accumulates total distance over multiple calls', () {
        final currentData = {
          'Instantaneous Speed': 36.0, // 36 km/h = 10 m/s
        };

        // First call: 1 second = 10 meters
        final distance1 = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 1.0,
        );
        expect(distance1, closeTo(10.0, 0.01));
        expect(strategy.totalDistance, closeTo(10.0, 0.01));

        // Second call: 2 seconds = 20 meters
        final distance2 = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 2.0,
        );
        expect(distance2, closeTo(20.0, 0.01));
        expect(strategy.totalDistance, closeTo(30.0, 0.01));
      });

      test('handles invalid dynamic object gracefully', () {
        final currentData = {
          'speed': MockInvalidDynamicObject(),
        };

        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 2.0,
        );

        expect(distance, 0.0);
        expect(strategy.totalDistance, 0.0);
      });

      test('handles non-numeric values gracefully', () {
        final currentData = {
          'Instantaneous Speed': 'not a number',
        };

        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 2.0,
        );

        expect(distance, 0.0);
        expect(strategy.totalDistance, 0.0);
      });
    });

    group('totalDistance', () {
      test('returns initial total distance of 0', () {
        expect(strategy.totalDistance, 0.0);
      });

      test('returns accumulated total distance', () {
        final currentData = {
          'Instantaneous Speed': 18.0, // 18 km/h = 5 m/s
        };

        strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 2.0,
        );

        expect(strategy.totalDistance, closeTo(10.0, 0.01));
      });
    });

    group('reset', () {
      test('resets total distance to 0', () {
        final currentData = {
          'Instantaneous Speed': 36.0, // 36 km/h = 10 m/s
        };

        // Build up some distance
        strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 3.0,
        );
        expect(strategy.totalDistance, closeTo(30.0, 0.01));

        // Reset and verify
        strategy.reset();
        expect(strategy.totalDistance, 0.0);
      });

      test('allows distance calculation after reset', () {
        final currentData = {
          'Instantaneous Speed': 72.0, // 72 km/h = 20 m/s
        };

        // Build up some distance
        strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 1.0,
        );
        expect(strategy.totalDistance, closeTo(20.0, 0.01));

        // Reset
        strategy.reset();
        expect(strategy.totalDistance, 0.0);

        // Calculate new distance
        final newDistance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 0.5,
        );
        expect(newDistance, closeTo(10.0, 0.01));
        expect(strategy.totalDistance, closeTo(10.0, 0.01));
      });
    });
  });

  group('RowerDistanceStrategy', () {
    late RowerDistanceStrategy strategy;

    setUp(() {
      strategy = RowerDistanceStrategy();
    });

    group('calculateDistanceIncrement', () {
      test('calculates distance correctly with stroke rate only', () {
        final currentData = {
          'Instantaneous Stroke Rate': 30.0, // 30 strokes per minute
        };

        // 30 SPM = 0.5 strokes per second
        // In 2 seconds = 1 stroke
        // 1 stroke * 10m (base distance) = 10 meters
        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 2.0,
        );

        expect(distance, closeTo(10.0, 0.01));
        expect(strategy.totalDistance, closeTo(10.0, 0.01));
      });

      test('calculates distance correctly with stroke rate and power', () {
        final currentData = {
          'Stroke Rate': 24.0, // 24 strokes per minute
          'Power': 150.0, // 150W (reference power)
        };

        // 24 SPM = 0.4 strokes per second
        // In 3 seconds = 1.2 strokes
        // Power factor = 150/150 = 1.0 (no adjustment)
        // 1.2 strokes * 10m = 12 meters
        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 3.0,
        );

        expect(distance, closeTo(12.0, 0.01));
        expect(strategy.totalDistance, closeTo(12.0, 0.01));
      });

      test('adjusts distance based on power - high power', () {
        final currentData = {
          'strokeRate': 30.0, // 30 strokes per minute
          'power': 300.0, // 300W (high power)
        };

        // 30 SPM = 0.5 strokes per second
        // In 2 seconds = 1 stroke
        // Power factor = 300/150 = 2.0 (max clamp)
        // 1 stroke * 10m * 2.0 = 20 meters
        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 2.0,
        );

        expect(distance, closeTo(20.0, 0.01));
        expect(strategy.totalDistance, closeTo(20.0, 0.01));
      });

      test('adjusts distance based on power - low power', () {
        final currentData = {
          'Instantaneous Stroke Rate': 30.0, // 30 strokes per minute
          'Instantaneous Power': 75.0, // 75W (low power)
        };

        // 30 SPM = 0.5 strokes per second
        // In 2 seconds = 1 stroke
        // Power factor = 75/150 = 0.5 (min clamp)
        // 1 stroke * 10m * 0.5 = 5 meters
        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 2.0,
        );

        expect(distance, closeTo(5.0, 0.01));
        expect(strategy.totalDistance, closeTo(5.0, 0.01));
      });

      test('handles FtmsParameter objects for stroke rate and power', () {
        final strokeRateParam = FtmsParameter(
          name: 'Instantaneous Stroke Rate',
          value: 240, // Raw value
          factor: 0.1, // Scale factor to get 24.0 SPM
          unit: 'spm',
        );

        final powerParam = FtmsParameter(
          name: 'Instantaneous Power',
          value: 1800, // Raw value
          factor: 0.1, // Scale factor to get 180.0W
          unit: 'W',
        );

        final currentData = {
          'Instantaneous Stroke Rate': strokeRateParam,
          'Instantaneous Power': powerParam,
        };

        // 24 SPM = 0.4 strokes per second
        // In 2.5 seconds = 1 stroke
        // Power factor = 180/150 = 1.2
        // 1 stroke * 10m * 1.2 = 12 meters
        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 2.5,
        );

        expect(distance, closeTo(12.0, 0.01));
        expect(strategy.totalDistance, closeTo(12.0, 0.01));
      });

      test('handles dynamic objects for stroke rate and power', () {
        final currentData = {
          'strokeRate': MockDynamicObject(value: 36.0), // 36 SPM
          'power': MockDynamicObject(value: 225.0), // 225W
        };

        // 36 SPM = 0.6 strokes per second
        // In 1 second = 0.6 strokes
        // Power factor = 225/150 = 1.5
        // 0.6 strokes * 10m * 1.5 = 9 meters
        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 1.0,
        );

        expect(distance, closeTo(9.0, 0.01));
        expect(strategy.totalDistance, closeTo(9.0, 0.01));
      });

      test('tries multiple stroke rate parameter keys', () {
        final testCases = [
          {'Instantaneous Stroke Rate': 30.0},
          {'Stroke Rate': 30.0},
          {'strokeRate': 30.0},
        ];

        for (final testData in testCases) {
          final testStrategy = RowerDistanceStrategy();
          final distance = testStrategy.calculateDistanceIncrement(
            currentData: testData,
            previousData: null,
            timeDeltaSeconds: 2.0,
          );

          // 30 SPM = 0.5 strokes per second
          // In 2 seconds = 1 stroke * 10m = 10 meters
          expect(distance, closeTo(10.0, 0.01));
        }
      });

      test('tries multiple power parameter keys', () {
        final baseData = {'Stroke Rate': 30.0}; // 30 SPM
        final powerKeys = ['Instantaneous Power', 'Power', 'power'];

        for (final powerKey in powerKeys) {
          final testStrategy = RowerDistanceStrategy();
          final testData = Map<String, dynamic>.from(baseData);
          testData[powerKey] = 300.0; // High power for 2.0 factor

          final distance = testStrategy.calculateDistanceIncrement(
            currentData: testData,
            previousData: null,
            timeDeltaSeconds: 2.0,
          );

          // 30 SPM = 0.5 strokes per second
          // In 2 seconds = 1 stroke * 10m * 2.0 = 20 meters
          expect(distance, closeTo(20.0, 0.01));
        }
      });

      test('returns 0 when stroke rate is null', () {
        final currentData = <String, dynamic>{};

        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 2.0,
        );

        expect(distance, 0.0);
        expect(strategy.totalDistance, 0.0);
      });

      test('returns 0 when stroke rate is zero', () {
        final currentData = {
          'Stroke Rate': 0.0,
        };

        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 2.0,
        );

        expect(distance, 0.0);
        expect(strategy.totalDistance, 0.0);
      });

      test('returns 0 when stroke rate is negative', () {
        final currentData = {
          'Stroke Rate': -10.0,
        };

        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 2.0,
        );

        expect(distance, 0.0);
        expect(strategy.totalDistance, 0.0);
      });

      test('ignores power when it is zero or negative', () {
        final currentData = {
          'Stroke Rate': 24.0, // 24 SPM
          'Power': 0.0, // Zero power
        };

        // Should use base distance per stroke (no power adjustment)
        // 24 SPM = 0.4 strokes per second
        // In 2.5 seconds = 1 stroke * 10m = 10 meters
        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 2.5,
        );

        expect(distance, closeTo(10.0, 0.01));
        expect(strategy.totalDistance, closeTo(10.0, 0.01));
      });

      test('accumulates total distance over multiple calls', () {
        final currentData = {
          'Stroke Rate': 30.0, // 30 SPM
          'Power': 150.0, // 150W (no power adjustment)
        };

        // First call: 2 seconds = 1 stroke * 10m = 10 meters
        final distance1 = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 2.0,
        );
        expect(distance1, closeTo(10.0, 0.01));
        expect(strategy.totalDistance, closeTo(10.0, 0.01));

        // Second call: 4 seconds = 2 strokes * 10m = 20 meters
        final distance2 = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 4.0,
        );
        expect(distance2, closeTo(20.0, 0.01));
        expect(strategy.totalDistance, closeTo(30.0, 0.01));
      });

      test('handles invalid dynamic objects gracefully', () {
        final currentData = {
          'strokeRate': MockInvalidDynamicObject(),
          'power': MockInvalidDynamicObject(),
        };

        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 2.0,
        );

        expect(distance, 0.0);
        expect(strategy.totalDistance, 0.0);
      });

      test('handles non-numeric values gracefully', () {
        final currentData = {
          'Stroke Rate': 'not a number',
          'Power': 'also not a number',
        };

        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 2.0,
        );

        expect(distance, 0.0);
        expect(strategy.totalDistance, 0.0);
      });

      test('calculates realistic rowing scenario', () {
        // Simulate a typical rowing scenario
        final currentData = {
          'Instantaneous Stroke Rate': 28.0, // 28 SPM (typical training rate)
          'Instantaneous Power': 200.0, // 200W (moderate effort)
        };

        // 28 SPM = 0.467 strokes per second
        // In 60 seconds = 28 strokes
        // Power factor = 200/150 = 1.33 (clamped to 1.33)
        // 28 strokes * 10m * 1.33 = 373.3 meters
        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 60.0,
        );

        expect(distance, closeTo(373.3, 1.0));
        expect(strategy.totalDistance, closeTo(373.3, 1.0));
      });
    });

    group('totalDistance', () {
      test('returns initial total distance of 0', () {
        expect(strategy.totalDistance, 0.0);
      });

      test('returns accumulated total distance', () {
        final currentData = {
          'Stroke Rate': 24.0, // 24 SPM
        };

        strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 5.0, // 2 strokes * 10m = 20m
        );

        expect(strategy.totalDistance, closeTo(20.0, 0.01));
      });
    });

    group('reset', () {
      test('resets total distance to 0', () {
        final currentData = {
          'Stroke Rate': 30.0, // 30 SPM
        };

        // Build up some distance
        strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 6.0, // 3 strokes * 10m = 30m
        );
        expect(strategy.totalDistance, closeTo(30.0, 0.01));

        // Reset and verify
        strategy.reset();
        expect(strategy.totalDistance, 0.0);
      });

      test('allows distance calculation after reset', () {
        final currentData = {
          'Stroke Rate': 36.0, // 36 SPM
          'Power': 180.0, // 180W
        };

        // Build up some distance
        strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 2.0,
        );
        expect(strategy.totalDistance,
            closeTo(14.4, 0.01)); // 1.2 strokes * 10m * 1.2

        // Reset
        strategy.reset();
        expect(strategy.totalDistance, 0.0);

        // Calculate new distance
        final newDistance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 1.0,
        );
        expect(newDistance, closeTo(7.2, 0.01)); // 0.6 strokes * 10m * 1.2
        expect(strategy.totalDistance, closeTo(7.2, 0.01));
      });
    });

    group('DistanceCalculationStrategyFactory', () {
      test('creates IndoorBikeDistanceStrategy for indoorBike', () {
        final strategy = DistanceCalculationStrategyFactory.createStrategy(
          DeviceDataType.indoorBike,
        );
        expect(strategy, isA<IndoorBikeDistanceStrategy>());
      });

      test('creates RowerDistanceStrategy for rower', () {
        final strategy = DistanceCalculationStrategyFactory.createStrategy(
          DeviceDataType.rower,
        );
        expect(strategy, isA<RowerDistanceStrategy>());
      });

      test('creates IndoorBikeDistanceStrategy for unknown device type', () {
        // Test with a device type that's not explicitly handled
        final strategy = DistanceCalculationStrategyFactory.createStrategy(
          DeviceDataType.crossTrainer,
        );
        expect(strategy, isA<IndoorBikeDistanceStrategy>());
      });
    });
  });
}