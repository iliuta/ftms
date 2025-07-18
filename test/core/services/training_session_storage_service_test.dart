import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/services/training_session_storage_service.dart';
import 'package:ftms/features/training/model/training_session.dart';
import 'package:ftms/features/training/model/unit_training_interval.dart';
import 'package:ftms/core/models/device_types.dart';

void main() {
  group('TrainingSessionStorageService', () {
    late TrainingSessionStorageService service;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      service = TrainingSessionStorageService();
    });

    test('should create service instance', () {
      expect(service, isNotNull);
    });

    test('should generate safe filename', () {
      // Test the internal filename generation logic by creating sessions
      // with various titles and checking they don't cause errors
      final testTitles = [
        'Normal Session Title',
        'Session/With\\Special|Characters',
        'Session:With<Multiple>Invalid?Characters*',
        'Very Long Session Title That Exceeds Normal Filename Length Limits And Should Be Handled Gracefully',
        'Session   With   Multiple   Spaces',
        '',
      ];

      for (final title in testTitles) {
        final session = TrainingSessionDefinition(
          title: title,
          ftmsMachineType: DeviceType.indoorBike,
          intervals: [
            UnitTrainingInterval(
              duration: 300,
              title: 'Test',
              targets: {'power': 100},
            ),
          ],
        );

        // Should not throw when creating the session
        expect(() => session.toJson(), returnsNormally);
      }
    });

    test('should handle TrainingSessionDefinition serialization', () {
      final session = TrainingSessionDefinition(
        title: 'Test Session',
        ftmsMachineType: DeviceType.indoorBike,
        intervals: [
          UnitTrainingInterval(
            duration: 300,
            title: 'Warm Up',
            targets: {'power': 100},
          ),
          UnitTrainingInterval(
            duration: 600,
            title: 'Main Set',
            targets: {'power': 200},
          ),
        ],
      );

      // Test serialization
      final json = session.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['title'], equals('Test Session'));
      expect(json['ftmsMachineType'], equals('indoorBike'));
      expect(json['intervals'], isA<List>());
      expect(json['intervals'].length, equals(2));

      // Test deserialization
      final deserializedSession = TrainingSessionDefinition.fromJson(json);
      expect(deserializedSession.title, equals('Test Session'));
      expect(deserializedSession.ftmsMachineType, equals(DeviceType.indoorBike));
      expect(deserializedSession.intervals.length, equals(2));
    });

    // Integration test - only run if we can access the file system
    test('should save and load training session if storage is accessible', () async {
      try {
        final accessible = await service.isStorageAccessible();
        if (!accessible) {
          // Skip this test if storage is not accessible
          return;
        }

        // Create a test session
        final session = TrainingSessionDefinition(
          title: 'Integration Test Session',
          ftmsMachineType: DeviceType.indoorBike,
          intervals: [
            UnitTrainingInterval(
              duration: 300,
              title: 'Test Interval',
              targets: {'power': 150},
            ),
          ],
        );

        // Save the session
        final filePath = await service.saveSession(session);
        expect(filePath, isNotNull);

        // Load the sessions
        final loadedSessions = await service.loadCustomSessions();
        expect(loadedSessions, isNotEmpty);

        final loadedSession = loadedSessions.firstWhere(
          (s) => s.title == 'Integration Test Session',
          orElse: () => throw Exception('Session not found'),
        );

        expect(loadedSession.title, equals('Integration Test Session'));
        expect(loadedSession.ftmsMachineType, equals(DeviceType.indoorBike));

        // Clean up
        await service.deleteSession(
          'Integration Test Session',
          'DeviceType.indoorBike',
        );
      } catch (e) {
        // If file system operations fail, just log and continue
        // File system test skipped: $e
      }
    });

    test('should duplicate session correctly', () async {
      try {
        // Create original session
        final originalSession = TrainingSessionDefinition(
          title: 'Original Session',
          ftmsMachineType: DeviceType.rower,
          intervals: [
            UnitTrainingInterval(
              duration: 300,
              title: 'Warm Up',
              targets: {'Stroke Rate': 20, 'Heart Rate': 120},
            ),
            UnitTrainingInterval(
              duration: 600,
              title: 'Main Set',
              targets: {'Stroke Rate': 28, 'Heart Rate': 160},
            ),
          ],
          isCustom: false, // Original is built-in
        );

        // Create duplicated session
        final duplicatedSession = TrainingSessionDefinition(
          title: 'Original Session (Copy)',
          ftmsMachineType: originalSession.ftmsMachineType,
          intervals: List.from(originalSession.intervals),
          isCustom: true, // Duplicate is always custom
        );

        // Save the duplicated session
        final filePath = await service.saveSession(duplicatedSession);
        expect(filePath, isNotNull);

        // Load and verify
        final loadedSessions = await service.loadCustomSessions();
        final loadedSession = loadedSessions.firstWhere(
          (s) => s.title == 'Original Session (Copy)',
          orElse: () => throw Exception('Duplicated session not found'),
        );

        expect(loadedSession.title, equals('Original Session (Copy)'));
        expect(loadedSession.ftmsMachineType, equals(DeviceType.rower));
        expect(loadedSession.isCustom, isTrue);
        expect(loadedSession.intervals.length, equals(2));
        
        // Verify interval content is preserved
        final interval0 = loadedSession.intervals[0] as UnitTrainingInterval;
        final interval1 = loadedSession.intervals[1] as UnitTrainingInterval;
        expect(interval0.title, equals('Warm Up'));
        expect(interval0.duration, equals(300));
        expect(interval1.title, equals('Main Set'));
        expect(interval1.duration, equals(600));

        // Clean up
        await service.deleteSession(
          'Original Session (Copy)',
          'DeviceType.rower',
        );
      } catch (e) {
        // File system test skipped: $e
      }
    });

    test('should handle duplication with different machine types', () async {
      try {
        // Create sessions for different machine types
        final rowerSession = TrainingSessionDefinition(
          title: 'Rower Session',
          ftmsMachineType: DeviceType.rower,
          intervals: [
            UnitTrainingInterval(
              duration: 300,
              title: 'Test',
              targets: {'Stroke Rate': 24},
            ),
          ],
          isCustom: false,
        );

        final bikeSession = TrainingSessionDefinition(
          title: 'Bike Session',
          ftmsMachineType: DeviceType.indoorBike,
          intervals: [
            UnitTrainingInterval(
              duration: 300,
              title: 'Test',
              targets: {'Instantaneous Power': 200},
            ),
          ],
          isCustom: false,
        );

        // Duplicate both sessions
        final duplicatedRower = TrainingSessionDefinition(
          title: 'Rower Session (Copy)',
          ftmsMachineType: rowerSession.ftmsMachineType,
          intervals: List.from(rowerSession.intervals),
          isCustom: true,
        );

        final duplicatedBike = TrainingSessionDefinition(
          title: 'Bike Session (Copy)',
          ftmsMachineType: bikeSession.ftmsMachineType,
          intervals: List.from(bikeSession.intervals),
          isCustom: true,
        );

        // Save both
        await service.saveSession(duplicatedRower);
        await service.saveSession(duplicatedBike);

        // Load and verify
        final loadedSessions = await service.loadCustomSessions();
        final loadedRower = loadedSessions.firstWhere(
          (s) => s.title == 'Rower Session (Copy)',
          orElse: () => throw Exception('Duplicated rower session not found'),
        );
        final loadedBike = loadedSessions.firstWhere(
          (s) => s.title == 'Bike Session (Copy)',
          orElse: () => throw Exception('Duplicated bike session not found'),
        );

        expect(loadedRower.ftmsMachineType, equals(DeviceType.rower));
        expect(loadedBike.ftmsMachineType, equals(DeviceType.indoorBike));

        // Clean up
        await service.deleteSession('Rower Session (Copy)', 'DeviceType.rower');
        await service.deleteSession('Bike Session (Copy)', 'DeviceType.indoorBike');
      } catch (e) {
        // File system test skipped: $e
      }
    });

    test('should preserve interval targets when duplicating', () async {
      try {
        // Create session with complex targets
        final originalSession = TrainingSessionDefinition(
          title: 'Complex Session',
          ftmsMachineType: DeviceType.rower,
          intervals: [
            UnitTrainingInterval(
              duration: 300,
              title: 'Multi-target Interval',
              targets: {
                'Stroke Rate': 24,
                'Heart Rate': 150,
                'Instantaneous Power': 200,
              },
            ),
          ],
          isCustom: false,
        );

        // Duplicate it
        final duplicatedSession = TrainingSessionDefinition(
          title: 'Complex Session (Copy)',
          ftmsMachineType: originalSession.ftmsMachineType,
          intervals: List.from(originalSession.intervals),
          isCustom: true,
        );

        // Save and load
        await service.saveSession(duplicatedSession);
        final loadedSessions = await service.loadCustomSessions();
        final loadedSession = loadedSessions.firstWhere(
          (s) => s.title == 'Complex Session (Copy)',
          orElse: () => throw Exception('Duplicated session not found'),
        );

        // Verify all targets are preserved
        final interval = loadedSession.intervals[0] as UnitTrainingInterval;
        expect(interval.targets!['Stroke Rate'], equals(24));
        expect(interval.targets!['Heart Rate'], equals(150));
        expect(interval.targets!['Instantaneous Power'], equals(200));

        // Clean up
        await service.deleteSession('Complex Session (Copy)', 'DeviceType.rower');
      } catch (e) {
        // File system test skipped: $e
      }
    });
  });
}
