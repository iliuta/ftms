import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/models/device_types.dart';
import 'package:ftms/features/settings/model/user_settings.dart';
import 'package:ftms/features/training/model/training_session.dart';
import 'package:ftms/features/training/model/unit_training_interval.dart';
import 'package:ftms/features/training/model/group_training_interval.dart';
import 'package:ftms/core/config/live_data_display_config.dart';
import 'package:ftms/core/config/live_data_field_config.dart';

void main() {
  // Helper method to create a mock indoor bike config
  LiveDataDisplayConfig createIndoorBikeConfig() {
    return LiveDataDisplayConfig(
      deviceType: DeviceType.indoorBike,
      availableInDeveloperModeOnly: false,
      fields: [
        LiveDataFieldConfig(
          name: 'Instantaneous Power',
          label: 'Power',
          display: 'number',
          unit: 'W',
          userSetting: 'cyclingFtp',
        ),
        LiveDataFieldConfig(
          name: 'Instantaneous Cadence',
          label: 'Cadence',
          display: 'number',
          unit: 'rpm',
        ),
      ],
    );
  }

  group('TrainingSessionDefinition', () {
    test('constructor creates instance with required fields', () {
      final unitInterval = UnitTrainingInterval(
        title: 'Test Interval',
        duration: 60,
        targets: {'power': '100W'},
      );
      
      final session = TrainingSessionDefinition(
        title: 'Test Session',
        ftmsMachineType: DeviceType.indoorBike,
        intervals: [unitInterval],
      );
      
      expect(session.title, equals('Test Session'));
      expect(session.ftmsMachineType, equals(DeviceType.indoorBike));
      expect(session.intervals, hasLength(1));
      expect(session.isCustom, isFalse);
      expect(session.originalSession, isNull);
    });

    test('constructor creates instance with optional fields', () {
      final unitInterval = UnitTrainingInterval(
        title: 'Test Interval',
        duration: 60,
      );
      
      final originalSession = TrainingSessionDefinition(
        title: 'Original',
        ftmsMachineType: DeviceType.indoorBike,
        intervals: [unitInterval],
      );
      
      final session = TrainingSessionDefinition(
        title: 'Test Session',
        ftmsMachineType: DeviceType.indoorBike,
        intervals: [unitInterval],
        isCustom: true,
        originalSession: originalSession,
      );
      
      expect(session.isCustom, isTrue);
      expect(session.originalSession, equals(originalSession));
    });

    test('fromJson creates instance from JSON', () {
      final json = {
        'title': 'Test Session',
        'ftmsMachineType': 'indoorBike',
        'intervals': [
          {
            'title': 'Test Interval',
            'duration': 60,
            'targets': {'Instantaneous Power': '120W'},
          }
        ],
      };
      
      final session = TrainingSessionDefinition.fromJson(json);
      
      expect(session.title, equals('Test Session'));
      expect(session.ftmsMachineType, equals(DeviceType.indoorBike));
      expect(session.intervals, hasLength(1));
      expect(session.intervals.first, isA<UnitTrainingInterval>());
      expect(session.isCustom, isFalse);
    });

    test('fromJson creates instance with custom flag', () {
      final json = {
        'title': 'Custom Session',
        'ftmsMachineType': 'rower',
        'intervals': [
          {
            'title': 'Test Interval',
            'duration': 60,
          }
        ],
      };
      
      final session = TrainingSessionDefinition.fromJson(json, isCustom: true);
      
      expect(session.title, equals('Custom Session'));
      expect(session.ftmsMachineType, equals(DeviceType.rower));
      expect(session.isCustom, isTrue);
    });

    test('fromJson handles GroupTrainingInterval', () {
      final json = {
        'title': 'Group Session',
        'ftmsMachineType': 'indoorBike',
        'intervals': [
          {
            'repeat': 3,
            'intervals': [
              {
                'title': 'Test Interval',
                'duration': 60,
                'targets': {'power': '100W'},
              }
            ],
          }
        ],
      };
      
      final session = TrainingSessionDefinition.fromJson(json);
      
      expect(session.intervals, hasLength(1));
      expect(session.intervals.first, isA<GroupTrainingInterval>());
      final groupInterval = session.intervals.first as GroupTrainingInterval;
      expect(groupInterval.repeat, equals(3));
      expect(groupInterval.intervals, hasLength(1));
    });

    test('toJson returns correct JSON representation', () {
      final unitInterval = UnitTrainingInterval(
        title: 'Test Interval',
        duration: 60,
        targets: {'power': '100W'},
      );
      
      final session = TrainingSessionDefinition(
        title: 'Test Session',
        ftmsMachineType: DeviceType.indoorBike,
        intervals: [unitInterval],
      );
      
      final json = session.toJson();
      
      expect(json['title'], equals('Test Session'));
      expect(json['ftmsMachineType'], equals('indoorBike'));
      expect(json['intervals'], hasLength(1));
      expect(json['intervals'][0]['title'], equals('Test Interval'));
      expect(json['intervals'][0]['duration'], equals(60));
      expect(json['intervals'][0]['targets']['power'], equals('100W'));
    });

    test('expand creates new instance with expanded intervals', () {
      final userSettings = UserSettings(cyclingFtp: 250, rowingFtp: '2:00', developerMode: false);
      final config = createIndoorBikeConfig();
      
      final unitInterval = UnitTrainingInterval(
        title: 'Test Interval',
        duration: 60,
        targets: {'Instantaneous Power': '120%'},
        repeat: 2,
      );
      
      final session = TrainingSessionDefinition(
        title: 'Test Session',
        ftmsMachineType: DeviceType.indoorBike,
        intervals: [unitInterval],
        isCustom: true,
      );
      
      final expanded = session.expand(
        userSettings: userSettings,
        config: config,
      );
      
      expect(expanded.title, equals('Test Session'));
      expect(expanded.ftmsMachineType, equals(DeviceType.indoorBike));
      expect(expanded.isCustom, isTrue);
      expect(expanded.originalSession, equals(session));
      
      // Should have 2 expanded intervals (repeat: 2)
      expect(expanded.unitIntervals, hasLength(2));
      expect(expanded.unitIntervals.first.targets!['Instantaneous Power'], equals(300)); // 120% of 250
    });

    test('expand handles GroupTrainingInterval', () {
      final userSettings = UserSettings(cyclingFtp: 250, rowingFtp: '2:00', developerMode: false);
      final config = createIndoorBikeConfig();
      
      final unitInterval = UnitTrainingInterval(
        title: 'Test Interval',
        duration: 60,
        targets: {'Instantaneous Power': '120%'},
      );
      
      final groupInterval = GroupTrainingInterval(
        intervals: [unitInterval],
        repeat: 3,
      );
      
      final session = TrainingSessionDefinition(
        title: 'Test Session',
        ftmsMachineType: DeviceType.indoorBike,
        intervals: [groupInterval],
      );
      
      final expanded = session.expand(
        userSettings: userSettings,
        config: config,
      );
      
      // Should have 3 expanded intervals (group repeat: 3)
      expect(expanded.unitIntervals, hasLength(3));
      expect(expanded.unitIntervals.first.targets!['Instantaneous Power'], equals(300)); // 120% of 250
    });

    test('expand sets originalSession to null for non-custom sessions', () {
      final userSettings = UserSettings(cyclingFtp: 250, rowingFtp: '2:00', developerMode: false);
      
      final unitInterval = UnitTrainingInterval(
        title: 'Test Interval',
        duration: 60,
      );
      
      final session = TrainingSessionDefinition(
        title: 'Test Session',
        ftmsMachineType: DeviceType.indoorBike,
        intervals: [unitInterval],
        isCustom: false,
      );
      
      final expanded = session.expand(userSettings: userSettings);
      
      expect(expanded.originalSession, isNull);
    });

    test('unitIntervals returns intervals cast to UnitTrainingInterval', () {
      final unitInterval1 = UnitTrainingInterval(
        title: 'Test 1',
        duration: 60,
      );
      
      final unitInterval2 = UnitTrainingInterval(
        title: 'Test 2',
        duration: 90,
      );
      
      final userSettings = UserSettings(cyclingFtp: 250, rowingFtp: '2:00', developerMode: false);
      
      // Create a session and expand it to get UnitTrainingInterval list
      final session = TrainingSessionDefinition(
        title: 'Test Session',
        ftmsMachineType: DeviceType.indoorBike,
        intervals: [unitInterval1, unitInterval2],
      );
      
      final expandedSession = session.expand(userSettings: userSettings);
      final unitIntervals = expandedSession.unitIntervals;
      
      expect(unitIntervals, hasLength(2));
      expect(unitIntervals[0].title, equals('Test 1'));
      expect(unitIntervals[1].title, equals('Test 2'));
    });

    test('copy creates deep copy with same values', () {
      final unitInterval = UnitTrainingInterval(
        title: 'Test Interval',
        duration: 60,
        targets: {'power': '100W'},
      );
      
      final originalSession = TrainingSessionDefinition(
        title: 'Original',
        ftmsMachineType: DeviceType.indoorBike,
        intervals: [unitInterval],
      );
      
      final session = TrainingSessionDefinition(
        title: 'Test Session',
        ftmsMachineType: DeviceType.indoorBike,
        intervals: [unitInterval],
        isCustom: true,
        originalSession: originalSession,
      );
      
      final copied = session.copy();
      
      expect(copied.title, equals(session.title));
      expect(copied.ftmsMachineType, equals(session.ftmsMachineType));
      expect(copied.isCustom, equals(session.isCustom));
      expect(copied.intervals, hasLength(session.intervals.length));
      expect((copied.intervals.first as UnitTrainingInterval).title, equals((session.intervals.first as UnitTrainingInterval).title));
      expect(copied.originalSession, isNotNull);
      expect(copied.originalSession!.title, equals(session.originalSession!.title));
      
      // Verify it's a deep copy (different object references)
      expect(copied, isNot(same(session)));
      expect(copied.intervals, isNot(same(session.intervals)));
      expect(copied.intervals.first, isNot(same(session.intervals.first)));
      expect(copied.originalSession, isNot(same(session.originalSession)));
    });

    test('copy creates independent copy that can be modified', () {
      final unitInterval = UnitTrainingInterval(
        title: 'Original Interval',
        duration: 60,
        targets: {'power': '100W'},
      );
      
      final session = TrainingSessionDefinition(
        title: 'Original Session',
        ftmsMachineType: DeviceType.indoorBike,
        intervals: [unitInterval],
      );
      
      final copied = session.copy();
      
      // Modify the original interval targets
      (session.intervals.first as UnitTrainingInterval).targets!['power'] = '200W';
      
      // The copy should remain unchanged
      expect((copied.intervals.first as UnitTrainingInterval).targets!['power'], equals('100W'));
      expect((session.intervals.first as UnitTrainingInterval).targets!['power'], equals('200W'));
    });

    test('copy handles null originalSession', () {
      final unitInterval = UnitTrainingInterval(
        title: 'Test Interval',
        duration: 60,
      );
      
      final session = TrainingSessionDefinition(
        title: 'Test Session',
        ftmsMachineType: DeviceType.indoorBike,
        intervals: [unitInterval],
        originalSession: null,
      );
      
      final copied = session.copy();
      
      expect(copied.originalSession, isNull);
      expect(copied.title, equals('Test Session'));
      expect(copied.intervals, hasLength(1));
    });

    test('copy handles empty intervals list', () {
      final session = TrainingSessionDefinition(
        title: 'Empty Session',
        ftmsMachineType: DeviceType.indoorBike,
        intervals: [],
      );
      
      final copied = session.copy();
      
      expect(copied.intervals, isEmpty);
      expect(copied.title, equals('Empty Session'));
      expect(copied.ftmsMachineType, equals(DeviceType.indoorBike));
    });

    test('copy handles mixed interval types', () {
      final unitInterval = UnitTrainingInterval(
        title: 'Unit',
        duration: 60,
        targets: {'power': '100W'},
      );
      
      final groupInterval = GroupTrainingInterval(
        intervals: [unitInterval],
        repeat: 2,
      );
      
      final session = TrainingSessionDefinition(
        title: 'Mixed Session',
        ftmsMachineType: DeviceType.indoorBike,
        intervals: [unitInterval, groupInterval],
      );
      
      final copied = session.copy();
      
      expect(copied.intervals, hasLength(2));
      expect(copied.intervals[0], isA<UnitTrainingInterval>());
      expect(copied.intervals[1], isA<GroupTrainingInterval>());
      
      // Verify deep copy
      expect(copied.intervals[0], isNot(same(session.intervals[0])));
      expect(copied.intervals[1], isNot(same(session.intervals[1])));
    });
  });
}
