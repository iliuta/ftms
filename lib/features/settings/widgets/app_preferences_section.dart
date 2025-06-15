import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import 'settings_section.dart';

/// Widget for editing general app preferences
class AppPreferencesSection extends StatelessWidget {
  final AppSettings appSettings;
  final ValueChanged<AppSettings> onChanged;

  const AppPreferencesSection({
    super.key,
    required this.appSettings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'App Preferences',
      subtitle: 'Customize the app appearance and behavior',
      children: [
        SwitchListTile(
          secondary: Icon(
            appSettings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: appSettings.isDarkMode ? Colors.indigo : Colors.amber,
          ),
          title: const Text('Dark Mode'),
          subtitle: Text(appSettings.isDarkMode ? 'Dark theme enabled' : 'Light theme enabled'),
          value: appSettings.isDarkMode,
          onChanged: (value) {
            onChanged(appSettings.copyWith(isDarkMode: value));
          },
        ),
        ListTile(
          leading: const Icon(Icons.straighten, color: Colors.orange),
          title: const Text('Distance Unit'),
          subtitle: Text(appSettings.distanceUnit == 'metric' ? 'Kilometers' : 'Miles'),
          trailing: DropdownButton<String>(
            value: appSettings.distanceUnit,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'metric', child: Text('Metric')),
              DropdownMenuItem(value: 'imperial', child: Text('Imperial')),
            ],
            onChanged: (value) {
              if (value != null) {
                onChanged(appSettings.copyWith(distanceUnit: value));
              }
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.thermostat, color: Colors.red),
          title: const Text('Temperature Unit'),
          subtitle: Text(appSettings.temperatureUnit == 'celsius' ? 'Celsius (°C)' : 'Fahrenheit (°F)'),
          trailing: DropdownButton<String>(
            value: appSettings.temperatureUnit,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'celsius', child: Text('°C')),
              DropdownMenuItem(value: 'fahrenheit', child: Text('°F')),
            ],
            onChanged: (value) {
              if (value != null) {
                onChanged(appSettings.copyWith(temperatureUnit: value));
              }
            },
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.vibration, color: Colors.purple),
          title: const Text('Haptic Feedback'),
          subtitle: const Text('Feel vibrations for button presses'),
          value: appSettings.enableHapticFeedback,
          onChanged: (value) {
            onChanged(appSettings.copyWith(enableHapticFeedback: value));
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.notifications, color: Colors.blue),
          title: const Text('Notifications'),
          subtitle: const Text('Receive app notifications'),
          value: appSettings.enableNotifications,
          onChanged: (value) {
            onChanged(appSettings.copyWith(enableNotifications: value));
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.screen_lock_landscape, color: Colors.green),
          title: const Text('Keep Screen On'),
          subtitle: const Text('Prevent screen from sleeping during workouts'),
          value: appSettings.keepScreenOn,
          onChanged: (value) {
            onChanged(appSettings.copyWith(keepScreenOn: value));
          },
        ),
      ],
    );
  }
}
