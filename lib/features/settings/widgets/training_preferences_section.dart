import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import 'settings_section.dart';

/// Widget for editing training-specific preferences
class TrainingPreferencesSection extends StatelessWidget {
  final AppSettings appSettings;
  final ValueChanged<AppSettings> onChanged;

  const TrainingPreferencesSection({
    super.key,
    required this.appSettings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Training Preferences',
      subtitle: 'Configure training session behavior and data recording',
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.bluetooth_connected, color: Colors.blue),
          title: const Text('Auto-Connect to Last Device'),
          subtitle: const Text('Automatically connect to your last used device'),
          value: appSettings.autoConnectToLastDevice,
          onChanged: (value) {
            onChanged(appSettings.copyWith(autoConnectToLastDevice: value));
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.pause_circle, color: Colors.orange),
          title: const Text('Auto-Pause'),
          subtitle: const Text('Automatically pause when you stop exercising'),
          value: appSettings.enableAutoPause,
          onChanged: (value) {
            onChanged(appSettings.copyWith(enableAutoPause: value));
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.file_download, color: Colors.green),
          title: const Text('Generate FIT Files'),
          subtitle: const Text('Create workout files for fitness apps'),
          value: appSettings.enableFitFileGeneration,
          onChanged: (value) {
            onChanged(appSettings.copyWith(enableFitFileGeneration: value));
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.cloud_upload, color: Colors.red),
          title: const Text('Auto-Upload to Strava'),
          subtitle: const Text('Automatically upload workouts to Strava'),
          value: appSettings.enableStravaUpload,
          onChanged: (value) {
            onChanged(appSettings.copyWith(enableStravaUpload: value));
          },
        ),
        ListTile(
          leading: const Icon(Icons.save, color: Colors.indigo),
          title: const Text('Auto-Save Interval'),
          subtitle: Text('Save workout data every ${appSettings.autoSaveInterval} seconds'),
          trailing: DropdownButton<int>(
            value: appSettings.autoSaveInterval,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 15, child: Text('15s')),
              DropdownMenuItem(value: 30, child: Text('30s')),
              DropdownMenuItem(value: 60, child: Text('1min')),
              DropdownMenuItem(value: 120, child: Text('2min')),
            ],
            onChanged: (value) {
              if (value != null) {
                onChanged(appSettings.copyWith(autoSaveInterval: value));
              }
            },
          ),
        ),
      ],
    );
  }
}
