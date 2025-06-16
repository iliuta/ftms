import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/user_settings.dart';
import 'settings_section.dart';

/// Widget for editing user fitness preferences
class UserPreferencesSection extends StatelessWidget {
  final UserSettings userSettings;
  final ValueChanged<UserSettings> onChanged;

  const UserPreferencesSection({
    super.key,
    required this.userSettings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Fitness Profile',
      subtitle: 'Your personal fitness metrics for accurate training targets',
      children: [
        ListTile(
          leading: const Icon(Icons.favorite, color: Colors.red),
          title: const Text('Max Heart Rate'),
          subtitle: Text('${userSettings.maxHeartRate} bpm'),
          trailing: const Icon(Icons.edit),
          onTap: () => _editMaxHeartRate(context),
        ),
        ListTile(
          leading: const Icon(Icons.directions_bike, color: Colors.blue),
          title: const Text('Cycling FTP'),
          subtitle: Text('${userSettings.cyclingFtp} watts'),
          trailing: const Icon(Icons.edit),
          onTap: () => _editCyclingFtp(context),
        ),
        ListTile(
          leading: const Icon(Icons.rowing, color: Colors.teal),
          title: const Text('Rowing FTP'),
          subtitle: Text('${userSettings.rowingFtp} per 500m'),
          trailing: const Icon(Icons.edit),
          onTap: () => _editRowingFtp(context),
        ),
      ],
    );
  }

  Future<void> _editMaxHeartRate(BuildContext context) async {
    final controller = TextEditingController(text: userSettings.maxHeartRate.toString());
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Max Heart Rate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your maximum heart rate in beats per minute:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: const InputDecoration(
                labelText: 'Max Heart Rate',
                suffixText: 'bpm',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Typical range: 170-220 bpm',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value >= 120 && value <= 250) {
                Navigator.of(context).pop(value);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid heart rate (120-250 bpm)'),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      HapticFeedback.lightImpact();
      onChanged(UserSettings(
        maxHeartRate: result,
        cyclingFtp: userSettings.cyclingFtp,
        rowingFtp: userSettings.rowingFtp,
      ));
    }
  }

  Future<void> _editCyclingFtp(BuildContext context) async {
    final controller = TextEditingController(text: userSettings.cyclingFtp.toString());
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cycling FTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your Functional Threshold Power for cycling:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(
                labelText: 'Cycling FTP',
                suffixText: 'watts',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Typical range: 100-500 watts',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value >= 50 && value <= 1000) {
                Navigator.of(context).pop(value);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid FTP (50-1000 watts)'),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      HapticFeedback.lightImpact();
      onChanged(UserSettings(
        maxHeartRate: userSettings.maxHeartRate,
        cyclingFtp: result,
        rowingFtp: userSettings.rowingFtp,
      ));
    }
  }

  Future<void> _editRowingFtp(BuildContext context) async {
    final controller = TextEditingController(text: userSettings.rowingFtp);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rowing FTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your 500m split time for rowing FTP:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Rowing FTP',
                hintText: '2:00',
                suffixText: 'per 500m',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Format: M:SS (e.g., 1:45 or 2:20)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (_isValidRowingTime(value)) {
                Navigator.of(context).pop(value);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid time format (M:SS)'),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      HapticFeedback.lightImpact();
      onChanged(UserSettings(
        maxHeartRate: userSettings.maxHeartRate,
        cyclingFtp: userSettings.cyclingFtp,
        rowingFtp: result,
      ));
    }
  }

  bool _isValidRowingTime(String time) {
    final regex = RegExp(r'^\d+:\d{2}$');
    if (!regex.hasMatch(time)) return false;
    
    final parts = time.split(':');
    final minutes = int.tryParse(parts[0]);
    final seconds = int.tryParse(parts[1]);
    
    return minutes != null && 
           seconds != null && 
           minutes >= 0 && 
           minutes <= 10 && 
           seconds >= 0 && 
           seconds < 60;
  }
}
