import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/models/device_types.dart';
import 'package:ftms/core/services/fit/distance_calculation_strategy.dart';
import 'package:ftms/core/models/live_data_field_value.dart';

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
        final param = LiveDataFieldValue(
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
      test('calculates distance correctly with Total Distance from FtmsParameter', () {
        final param = LiveDataFieldValue(
          name: 'Total Distance',
          value: 2000, // Raw value
          factor: 0.1, // Scale factor to get 200.0 meters
          unit: 'm',
        );

        final currentData = {
          'Total Distance': param,
        };

        // First call: total distance = 200m, increment = 200m
        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 2.0,
        );

        expect(distance, closeTo(200.0, 0.01));
        expect(strategy.totalDistance, closeTo(200.0, 0.01));
      });

      test('calculates distance correctly with Total Distance from numeric value', () {
        final currentData = {
          'Total Distance': 150.0, // 150 meters
        };

        // First call: total distance = 150m, increment = 150m
        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 3.0,
        );

        expect(distance, closeTo(150.0, 0.01));
        expect(strategy.totalDistance, closeTo(150.0, 0.01));
      });

      test('calculates incremental distance correctly on subsequent calls', () {
        // First call with 100m total distance
        final currentData1 = {
          'Total Distance': 100.0,
        };

        final distance1 = strategy.calculateDistanceIncrement(
          currentData: currentData1,
          previousData: null,
          timeDeltaSeconds: 1.0,
        );

        expect(distance1, closeTo(100.0, 0.01));
        expect(strategy.totalDistance, closeTo(100.0, 0.01));

        // Second call with 180m total distance (80m increment)
        final currentData2 = {
          'Total Distance': 180.0,
        };

        final distance2 = strategy.calculateDistanceIncrement(
          currentData: currentData2,
          previousData: currentData1,
          timeDeltaSeconds: 2.0,
        );

        expect(distance2, closeTo(80.0, 0.01));
        expect(strategy.totalDistance, closeTo(180.0, 0.01));
      });

      test('handles Total Distance from dynamic object', () {
        final currentData = {
          'distance': MockDynamicObject(value: 250.0), // 250 meters
        };

        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 1.5,
        );

        expect(distance, closeTo(250.0, 0.01));
        expect(strategy.totalDistance, closeTo(250.0, 0.01));
      });

      test('handles FtmsParameter objects for Total Distance', () {
        final param = LiveDataFieldValue(
          name: 'Total Distance',
          value: 3500, // Raw value
          factor: 0.1, // Scale factor to get 350.0 meters
          unit: 'm',
        );

        final currentData = {
          'Total Distance': param,
        };

        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 2.5,
        );

        expect(distance, closeTo(350.0, 0.01));
        expect(strategy.totalDistance, closeTo(350.0, 0.01));
      });

      test('handles dynamic objects for Total Distance', () {
        final currentData = {
          'totalDistance': MockDynamicObject(value: 420.0), // 420 meters
        };

        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 1.0,
        );

        expect(distance, closeTo(420.0, 0.01));
        expect(strategy.totalDistance, closeTo(420.0, 0.01));
      });

      test('tries multiple Total Distance parameter keys', () {
        final testCases = [
          {'Total Distance': 100.0},
          {'Distance': 100.0},
          {'distance': 100.0},
          {'totalDistance': 100.0},
        ];

        for (final testData in testCases) {
          final testStrategy = RowerDistanceStrategy();
          final distance = testStrategy.calculateDistanceIncrement(
            currentData: testData,
            previousData: null,
            timeDeltaSeconds: 2.0,
          );

          expect(distance, closeTo(100.0, 0.01));
        }
      });

      test('returns 0 when Total Distance is null', () {
        final currentData = <String, dynamic>{};

        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 2.0,
        );

        expect(distance, 0.0);
        expect(strategy.totalDistance, 0.0);
      });

      test('returns 0 when Total Distance is zero', () {
        final currentData = {
          'Total Distance': 0.0,
        };

        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 2.0,
        );

        expect(distance, 0.0);
        expect(strategy.totalDistance, 0.0);
      });

      test('clamps negative distance increments to 0', () {
        // Set up initial distance
        final currentData1 = {
          'Total Distance': 100.0,
        };

        strategy.calculateDistanceIncrement(
          currentData: currentData1,
          previousData: null,
          timeDeltaSeconds: 1.0,
        );

        // Now simulate a decrease in total distance (should not happen in real scenarios)
        final currentData2 = {
          'Total Distance': 80.0, // Decreased by 20m
        };

        final distance = strategy.calculateDistanceIncrement(
          currentData: currentData2,
          previousData: currentData1,
          timeDeltaSeconds: 2.0,
        );

        // Should clamp negative increment to 0
        expect(distance, 0.0);
        expect(strategy.totalDistance, 80.0); // But total distance is updated
      });

      test('accumulates total distance over multiple calls', () {
        // First call: 50m total
        final currentData1 = {
          'Total Distance': 50.0,
        };

        final distance1 = strategy.calculateDistanceIncrement(
          currentData: currentData1,
          previousData: null,
          timeDeltaSeconds: 1.0,
        );
        expect(distance1, closeTo(50.0, 0.01));
        expect(strategy.totalDistance, closeTo(50.0, 0.01));

        // Second call: 120m total (70m increment)
        final currentData2 = {
          'Total Distance': 120.0,
        };

        final distance2 = strategy.calculateDistanceIncrement(
          currentData: currentData2,
          previousData: currentData1,
          timeDeltaSeconds: 2.0,
        );
        expect(distance2, closeTo(70.0, 0.01));
        expect(strategy.totalDistance, closeTo(120.0, 0.01));
      });

      test('handles invalid dynamic objects gracefully', () {
        final currentData = {
          'Total Distance': MockInvalidDynamicObject(),
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
          'Total Distance': 'not a number',
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
        // Simulate a typical rowing scenario with progressive total distance
        
        // Start of workout
        final currentData1 = {
          'Total Distance': 0.0,
        };

        final distance1 = strategy.calculateDistanceIncrement(
          currentData: currentData1,
          previousData: null,
          timeDeltaSeconds: 1.0,
        );
        expect(distance1, 0.0);
        expect(strategy.totalDistance, 0.0);

        // After 1 minute of rowing
        final currentData2 = {
          'Total Distance': 250.0, // 250m after 1 minute
        };

        final distance2 = strategy.calculateDistanceIncrement(
          currentData: currentData2,
          previousData: currentData1,
          timeDeltaSeconds: 60.0,
        );
        expect(distance2, closeTo(250.0, 0.01));
        expect(strategy.totalDistance, closeTo(250.0, 0.01));

        // After 2 minutes of rowing
        final currentData3 = {
          'Total Distance': 520.0, // 520m total (270m increment)
        };

        final distance3 = strategy.calculateDistanceIncrement(
          currentData: currentData3,
          previousData: currentData2,
          timeDeltaSeconds: 60.0,
        );
        expect(distance3, closeTo(270.0, 0.01));
        expect(strategy.totalDistance, closeTo(520.0, 0.01));
      });
    });

    group('totalDistance', () {
      test('returns initial total distance of 0', () {
        expect(strategy.totalDistance, 0.0);
      });

      test('returns accumulated total distance', () {
        final currentData = {
          'Total Distance': 150.0,
        };

        strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 5.0,
        );

        expect(strategy.totalDistance, closeTo(150.0, 0.01));
      });
    });

    group('reset', () {
      test('resets total distance to 0', () {
        final currentData = {
          'Total Distance': 200.0,
        };

        // Build up some distance
        strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 6.0,
        );
        expect(strategy.totalDistance, closeTo(200.0, 0.01));

        // Reset and verify
        strategy.reset();
        expect(strategy.totalDistance, 0.0);
      });

      test('allows distance calculation after reset', () {
        final currentData = {
          'Total Distance': 180.0,
        };

        // Build up some distance
        strategy.calculateDistanceIncrement(
          currentData: currentData,
          previousData: null,
          timeDeltaSeconds: 2.0,
        );
        expect(strategy.totalDistance, closeTo(180.0, 0.01));

        // Reset
        strategy.reset();
        expect(strategy.totalDistance, 0.0);

        // Calculate new distance
        final newCurrentData = {
          'Total Distance': 75.0,
        };
        final newDistance = strategy.calculateDistanceIncrement(
          currentData: newCurrentData,
          previousData: null,
          timeDeltaSeconds: 1.0,
        );
        expect(newDistance, closeTo(75.0, 0.01));
        expect(strategy.totalDistance, closeTo(75.0, 0.01));
      });
    });

    group('DistanceCalculationStrategyFactory', () {
      test('creates IndoorBikeDistanceStrategy for indoorBike', () {
        final strategy = DistanceCalculationStrategyFactory.createStrategy(
          DeviceType.indoorBike,
        );
        expect(strategy, isA<IndoorBikeDistanceStrategy>());
      });

      test('creates RowerDistanceStrategy for rower', () {
        final strategy = DistanceCalculationStrategyFactory.createStrategy(
          DeviceType.rower,
        );
        expect(strategy, isA<RowerDistanceStrategy>());
      });

    });
  });
}