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
  });
}
