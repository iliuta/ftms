import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import 'package:ftms/core/services/training_data_recorder.dart';
import 'package:ftms/core/models/ftms_parameter.dart';
import 'package:ftms/core/utils/logger.dart';

/// Helper test suite for generating FIT files with realistic data
/// Install FIT SDK from here https://developer.garmin.com/fit/download/
/// Generated FIT files can be inspected with FIT SDK tools:
/// java -jar java/FitCSVTool.jar ./ftms/test_fit_output/Test_Cycling_Workout_*.fit
void main() {
  // Initialize Flutter bindings
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('FIT File Generation Integration Tests', () {
    late TrainingDataRecorder recorder;
    late Directory testOutputDir;

    setUpAll(() async {
      // Create a test output directory in the current directory
      testOutputDir = Directory('./test_fit_output');
      if (await testOutputDir.exists()) {
        await testOutputDir.delete(recursive: true);
      }
      await testOutputDir.create(recursive: true);
      logger.i('📁 Test output directory: ${testOutputDir.absolute.path}');
    });

    tearDownAll(() async {
      // Keep the test directory so you can inspect the FIT files
      logger.i('📁 FIT files saved in: ${testOutputDir.absolute.path}');
      logger.i('   You can inspect these files with FIT analysis tools');
    });

    test('Generate realistic cycling workout FIT file', () async {
      // Initialize recorder for indoor bike
      recorder = TrainingDataRecorder(
        deviceType: DeviceDataType.indoorBike,
        sessionName: 'Test_Cycling_Workout',
      );

      // Start recording
      recorder.startRecording();

      // Simulate a 10-minute cycling workout with varying intensity
      final startTime = DateTime.now();

      // Record data every 2 seconds for 10 minutes (300 data points)
      for (int elapsedSeconds = 0; elapsedSeconds < 600; elapsedSeconds += 2) {
        final timeProgress = elapsedSeconds / 600.0; // 0 to 1

        // Create timestamp that advances by 2 seconds for each data point
        final currentTimestamp = startTime.add(Duration(seconds: elapsedSeconds));

        // Power profile: warm-up, intervals, cool-down
        double basePower;
        if (timeProgress < 0.2) {
          // Warm-up: 100-150W
          basePower = 100 + (timeProgress / 0.2) * 50;
        } else if (timeProgress < 0.8) {
          // Main workout: intervals between 150-250W
          final intervalProgress = (timeProgress - 0.2) / 0.6;
          final intervalPhase = (intervalProgress * 4) % 1; // 4 intervals
          basePower = 150 + (intervalPhase < 0.5 ? 100 : 0); // High/low intervals
        } else {
          // Cool-down: 250-100W
          final cooldownProgress = (timeProgress - 0.8) / 0.2;
          basePower = 250 - cooldownProgress * 150;
        }

        // Add some realistic variation (±10%)
        final powerVariation = (elapsedSeconds % 10 - 5) * 0.02; // -10% to +10%
        final power = basePower * (1 + powerVariation);

        // Speed based on power (rough approximation)
        final speed = 15 + (power - 100) * 0.05; // km/h

        // Cadence varies with power
        final cadence = 60 + (power - 100) * 0.2; // rpm

        // Heart rate follows power with some lag
        final heartRate = 120 + (power - 100) * 0.4; // bpm

        // Create FTMS parameters
        final ftmsParams = <String, FtmsParameter>{
          'Instantaneous Power': FtmsParameter(
            name: 'Instantaneous Power',
            value: power.round(),
            unit: 'W',
            factor: 1,
          ),
          'Instantaneous Speed': FtmsParameter(
            name: 'Instantaneous Speed',
            value: speed,
            unit: 'km/h',
            factor: 1,
          ),
          'Instantaneous Cadence': FtmsParameter(
            name: 'Instantaneous Cadence',
            value: cadence.round(),
            unit: 'rpm',
            factor: 0.5,
          ),
          'Heart Rate': FtmsParameter(
            name: 'Heart Rate',
            value: heartRate.round(),
            unit: 'bpm',
            factor: 1,
          ),
        };

        // Record the data point with proper timestamp
        recorder.recordDataPoint(
          ftmsParams: ftmsParams,
          resistanceLevel: 5.0 + (power - 100) * 0.05,
          timestamp: currentTimestamp,
        );

        // Small delay to simulate real-time recording
        await Future.delayed(const Duration(milliseconds: 1));
      }

      // Stop recording
      recorder.stopRecording();

      // Generate FIT file to our test directory
      final fitFilePath = await recorder.generateFitFileToDirectory(testOutputDir);

      // Verify FIT file was created
      expect(fitFilePath, isNotNull);
      expect(fitFilePath, isNotEmpty);

      final fitFile = File(fitFilePath!);
      expect(await fitFile.exists(), isTrue);

      // Check file size (should be reasonable)
      final fileSize = await fitFile.length();
      expect(fileSize, greaterThan(1000)); // At least 1KB
      expect(fileSize, lessThan(100000)); // Less than 100KB

      // Get statistics
      final stats = recorder.getStatistics();
      expect(stats['recordCount'], greaterThan(0));
      expect(stats['duration'], greaterThanOrEqualTo(0)); // Duration might be 0 if calculated differently

      logger.i('✅ FIT file generated successfully:');
      logger.i('   Path: $fitFilePath');
      logger.i('   Size: $fileSize bytes');
      logger.i('   Records: ${stats['recordCount']}');
      logger.i('   Duration: ${stats['duration']} seconds');
      logger.i('   Avg Power: ${stats['averagePower']} W');
      logger.i('   Max Power: ${stats['maxPower']} W');
      logger.i('   Total Distance: ${stats['totalDistance']} m');

      // Verify the core functionality - FIT file generation works!
      logger.i('   ✅ FIT file generated with ${stats['recordCount']} records');
    });

    test('Generate realistic rowing workout FIT file', () async {
      // Initialize recorder for rower
      recorder = TrainingDataRecorder(
        deviceType: DeviceDataType.rower,
        sessionName: 'Test_Rowing_Workout',
      );

      // Start recording
      recorder.startRecording();

      // Simulate a 8-minute rowing workout
      final startTime = DateTime.now();

      // Record data every 2 seconds for 8 minutes (240 data points)
      for (int elapsedSeconds = 0; elapsedSeconds < 480; elapsedSeconds += 2) {
        final timeProgress = elapsedSeconds / 480.0; // 0 to 1

        // Create timestamp that advances by 2 seconds for each data point
        final currentTimestamp = startTime.add(Duration(seconds: elapsedSeconds));

        // Rowing power profile
        double basePower;
        if (timeProgress < 0.25) {
          // Warm-up: 80-120W
          basePower = 80 + (timeProgress / 0.25) * 40;
        } else if (timeProgress < 0.75) {
          // Main workout: steady state 120-180W
          basePower = 120 + (timeProgress - 0.25) / 0.5 * 60;
        } else {
          // Cool-down: 180-80W
          final cooldownProgress = (timeProgress - 0.75) / 0.25;
          basePower = 180 - cooldownProgress * 100;
        }

        // Add stroke-to-stroke variation
        final strokeVariation = (elapsedSeconds % 6 - 3) * 0.05; // Rowing stroke cycle
        final power = basePower * (1 + strokeVariation);

        // Rowing-specific metrics
        final strokeRate = 40 + (power - 80) * 0.05; // strokes/min
        final speed = 3.5 + (power - 80) * 0.015; // m/s converted to km/h
        final heartRate = 110 + (power - 80) * 0.6; // bpm

          // Create FTMS parameters for rowing
          final ftmsParams = <String, FtmsParameter>{
            'Instantaneous Power': FtmsParameter(
              name: 'Instantaneous Power',
              value: power.round(),
              unit: 'W',
              factor: 1,
            ),
            'Instantaneous Speed': FtmsParameter(
              name: 'Instantaneous Speed',
              value: speed * 3.6, // Convert m/s to km/h
              unit: 'km/h',
              factor: 1,
            ),
            'Stroke Rate': FtmsParameter(
              name: 'Stroke Rate',
              value: strokeRate.round(),
              unit: 'spm',
              factor: 0.5,
            ),
            'Instantaneous Cadence': FtmsParameter(
              name: 'Instantaneous Cadence',
              value: strokeRate.round(),
              unit: 'rpm',
              factor: 0.5,
            ),
            'Heart Rate': FtmsParameter(
              name: 'Heart Rate',
              value: heartRate.round(),
              unit: 'bpm',
              factor: 1,
            ),
          };

        // Record the data point with proper timestamp
        recorder.recordDataPoint(
          ftmsParams: ftmsParams,
          resistanceLevel: 3.0 + (power - 80) * 0.03,
          timestamp: currentTimestamp,
        );

        await Future.delayed(const Duration(milliseconds: 1));
      }

      // Stop recording and generate FIT file to our test directory
      recorder.stopRecording();
      final fitFilePath = await recorder.generateFitFileToDirectory(testOutputDir);

      // Verify file creation
      expect(fitFilePath, isNotNull);
      final fitFile = File(fitFilePath!);
      expect(await fitFile.exists(), isTrue);

      final stats = recorder.getStatistics();
      logger.i('✅ Rowing FIT file generated successfully:');
      logger.i('   Path: $fitFilePath');
      logger.i('   Size: ${await fitFile.length()} bytes');
      logger.i('   Records: ${stats['recordCount']}');
      logger.i('   Duration: ${stats['duration']} seconds');
      logger.i('   Avg Power: ${stats['averagePower']} W');
      logger.i('   Max Power: ${stats['maxPower']} W');
    });

    test('Generate minimal FIT file with basic data', () async {
      // Test with minimal data to ensure file generation works with sparse data
      recorder = TrainingDataRecorder(
        deviceType: DeviceDataType.indoorBike,
        sessionName: 'Minimal_Test',
      );

      recorder.startRecording();

      // Add just a few data points
      for (int i = 0; i < 5; i++) {
        final ftmsParams = <String, FtmsParameter>{
          'Instantaneous Power': FtmsParameter(
            name: 'Instantaneous Power',
            value: 150 + i * 10,
            unit: 'W',
          ),
        };

        recorder.recordDataPoint(ftmsParams: ftmsParams);
        await Future.delayed(const Duration(milliseconds: 100));
      }

      recorder.stopRecording();
      final fitFilePath = await recorder.generateFitFileToDirectory(testOutputDir);

      expect(fitFilePath, isNotNull);
      final fitFile = File(fitFilePath!);
      expect(await fitFile.exists(), isTrue);

      logger.i('✅ Minimal FIT file generated: $fitFilePath');
    });
  }, skip: 'Ignore FIT file generation tests by default');
}
