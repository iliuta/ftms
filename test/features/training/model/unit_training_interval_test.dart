import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/models/device_types.dart';
import 'package:ftms/features/settings/model/user_settings.dart';
import 'package:ftms/features/training/model/unit_training_interval.dart';

void main() {
  group('UnitTrainingInterval FTP percentage parsing', () {
    test('FTP percentage parsing uses user settings', () {
      // Simulate a user with FTP 250
      final userSettings = UserSettings(maxHeartRate: 190, cyclingFtp: 250, rowingFtp: '2:00');
      final json = {
        'title': 'Test Interval',
        'duration': 60,
        'targets': {'Instantaneous Power': '120%'},
      };
      final interval = UnitTrainingInterval.fromJson(
        json,
        machineType: DeviceType.indoorBike,
        userSettings: userSettings,
      );
      // 120% of 250 = 300
      expect(interval.targets!['Instantaneous Power'], 300);
    });

    test('FTP percentage parsing for rower resolves to seconds', () {
      final userSettings = UserSettings(maxHeartRate: 190, cyclingFtp: 250, rowingFtp: '2:00');
      final json = {
        'title': 'Test Interval',
        'duration': 60,
        'targets': {'Instantaneous Power': '120%'},
      };
      final interval = UnitTrainingInterval.fromJson(
        json,
        machineType: DeviceType.rower,
        userSettings: userSettings,
      );
      // 120% of 2:00 = 144 seconds
      expect(interval.targets!['Instantaneous Power'], 144);
    });

    test('FTP percentage parsing is ignored if userSettings is null', () {
      final json = {
        'title': 'Test Interval',
        'duration': 60,
        'targets': {'Instantaneous Power': '120%'},
      };
      final interval = UnitTrainingInterval.fromJson(
        json,
        machineType: DeviceType.indoorBike,
        userSettings: null,
      );
      // Should remain as string
      expect(interval.targets!['Instantaneous Power'], '120%');
    });
  });
}
