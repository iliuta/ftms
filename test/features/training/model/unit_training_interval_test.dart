import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/models/device_types.dart';
import 'package:ftms/features/settings/model/user_settings.dart';
import 'package:ftms/features/training/model/unit_training_interval.dart';
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
          // No userSetting
        ),
        LiveDataFieldConfig(
          name: 'Heart Rate',
          label: 'Heart Rate',
          display: 'number',
          unit: 'bpm',
          // No userSetting
        ),
      ],
    );
  }

  // Helper method to create a mock rower config
  LiveDataDisplayConfig createRowerConfig() {
    return LiveDataDisplayConfig(
      deviceType: DeviceType.rower,
      availableInDeveloperModeOnly: false,
      fields: [
        LiveDataFieldConfig(
          name: 'Instantaneous Pace',
          label: 'Pace',
          display: 'number',
          unit: 's/500m',
          userSetting: 'rowingFtp',
        ),
        LiveDataFieldConfig(
          name: 'Stroke Rate',
          label: 'Stroke Rate',
          display: 'number',
          unit: 'spm',
          // No userSetting
        ),
        LiveDataFieldConfig(
          name: 'Instantaneous Power',
          label: 'Power',
          display: 'number',
          unit: 'W',
          // No userSetting for rower power
        ),
      ],
    );
  }

  group('UnitTrainingInterval FTP percentage parsing', () {
    test('FTP percentage parsing uses user settings', () {
      // Simulate a user with FTP 250
      final userSettings = UserSettings(cyclingFtp: 250, rowingFtp: '2:00', developerMode: false);
      final config = createIndoorBikeConfig();
      final json = {
        'title': 'Test Interval',
        'duration': 60,
        'targets': {'Instantaneous Power': '120%'},
      };
      final interval = UnitTrainingInterval.fromJson(json)
          .expandTargets(
            machineType: DeviceType.indoorBike,
            userSettings: userSettings,
            config: config,
          );
      // 120% of 250 = 300
      expect(interval.targets!['Instantaneous Power'], 300);
    });

    test('FTP percentage parsing for rower resolves to seconds', () {
      final userSettings = UserSettings(cyclingFtp: 250, rowingFtp: '2:00', developerMode: false);
      final config = createRowerConfig();
      final json = {
        'title': 'Test Interval',
        'duration': 60,
        'targets': {'Instantaneous Pace': '50%'},
      };
      final interval = UnitTrainingInterval.fromJson(json)
          .expandTargets(
            machineType: DeviceType.rower,
            userSettings: userSettings,
            config: config,
          );
      // 120% of 2:00 = 144 seconds
      expect(interval.targets!['Instantaneous Pace'], 240);
    });

    test('FTP percentage parsing is ignored if userSettings is null', () {
      final config = createIndoorBikeConfig();
      final json = {
        'title': 'Test Interval',
        'duration': 60,
        'targets': {'Instantaneous Power': '120%'},
      };
      final interval = UnitTrainingInterval.fromJson(json)
          .expandTargets(
            machineType: DeviceType.indoorBike,
            userSettings: null,
            config: config,
          );
      // Should remain as string
      expect(interval.targets!['Instantaneous Power'], '120%');
    });

    test('fromJson does not expand targets', () {
      final json = {
        'title': 'Test Interval',
        'duration': 60,
        'targets': {'Instantaneous Power': '120%'},
      };
      final interval = UnitTrainingInterval.fromJson(json);
      // Should remain as string when not expanded
      expect(interval.targets!['Instantaneous Power'], '120%');
    });

    test('does not apply power strategy to fields without userSetting', () {
      final userSettings = UserSettings(cyclingFtp: 250, rowingFtp: '2:00', developerMode: false);
      final config = createIndoorBikeConfig();
      final json = {
        'title': 'Test Interval',
        'duration': 60,
        'targets': {
          'Instantaneous Power': '120%', // Should be resolved (has userSetting)
          'Instantaneous Cadence': '90%', // Should NOT be resolved (no userSetting)
          'Heart Rate': '85%', // Should NOT be resolved (no userSetting)
        },
      };
      final interval = UnitTrainingInterval.fromJson(json)
          .expandTargets(
            machineType: DeviceType.indoorBike,
            userSettings: userSettings,
            config: config,
          );
      
      // Power should be resolved: 120% of 250 = 300
      expect(interval.targets!['Instantaneous Power'], 300);
      // Cadence and Heart Rate should remain as strings (not resolved)
      expect(interval.targets!['Instantaneous Cadence'], '90%');
      expect(interval.targets!['Heart Rate'], '85%');
    });

    test('rower only applies power strategy to Instantaneous Pace', () {
      final userSettings = UserSettings(cyclingFtp: 250, rowingFtp: '2:00', developerMode: false);
      final config = createRowerConfig();
      final json = {
        'title': 'Test Interval',
        'duration': 60,
        'targets': {
          'Instantaneous Pace': '50%', // Should be resolved (has userSetting)
          'Stroke Rate': '120%', // Should NOT be resolved (no userSetting)
          'Instantaneous Power': '90%', // Should NOT be resolved (no userSetting for rower)
        },
      };
      final interval = UnitTrainingInterval.fromJson(json)
          .expandTargets(
            machineType: DeviceType.rower,
            userSettings: userSettings,
            config: config,
          );
      
      // Pace should be resolved: 50% easier = 240 seconds (2:00 * 2)
      expect(interval.targets!['Instantaneous Pace'], 240);
      // Stroke Rate and Power should remain as strings (not resolved)
      expect(interval.targets!['Stroke Rate'], '120%');
      expect(interval.targets!['Instantaneous Power'], '90%');
    });
  });
}
