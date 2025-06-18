import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/user_settings.dart';
import 'settings_section.dart';

/// Widget for editing user fitness preferences
class UserPreferencesSection extends StatefulWidget {
  final UserSettings userSettings;
  final ValueChanged<UserSettings> onChanged;

  const UserPreferencesSection({
    super.key,
    required this.userSettings,
    required this.onChanged,
  });

  @override
  State<UserPreferencesSection> createState() => _UserPreferencesSectionState();
}

class _UserPreferencesSectionState extends State<UserPreferencesSection> {
  String? _editingField;
  late TextEditingController _maxHeartRateController;
  late TextEditingController _cyclingFtpController;
  late TextEditingController _rowingFtpController;

  @override
  void initState() {
    super.initState();
    _maxHeartRateController = TextEditingController(text: widget.userSettings.maxHeartRate.toString());
    _cyclingFtpController = TextEditingController(text: widget.userSettings.cyclingFtp.toString());
    _rowingFtpController = TextEditingController(text: widget.userSettings.rowingFtp);
  }

  @override
  void didUpdateWidget(UserPreferencesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userSettings != widget.userSettings) {
      _maxHeartRateController.text = widget.userSettings.maxHeartRate.toString();
      _cyclingFtpController.text = widget.userSettings.cyclingFtp.toString();
      _rowingFtpController.text = widget.userSettings.rowingFtp;
    }
  }

  @override
  void dispose() {
    _maxHeartRateController.dispose();
    _cyclingFtpController.dispose();
    _rowingFtpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Fitness Profile',
      subtitle: 'Your personal fitness metrics for accurate training targets',
      children: [
        _buildMaxHeartRateField(),
        _buildCyclingFtpField(),
        _buildRowingFtpField(),
      ],
    );
  }

  Widget _buildMaxHeartRateField() {
    final isEditing = _editingField == 'maxHeartRate';
    
    return ListTile(
      leading: const Icon(Icons.favorite, color: Colors.red),
      title: const Text('Max Heart Rate'),
      subtitle: isEditing
          ? Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextField(
                controller: _maxHeartRateController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: const InputDecoration(
                  hintText: 'Enter heart rate',
                  suffixText: 'bpm',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                autofocus: true,
                onSubmitted: (value) => _saveMaxHeartRate(),
              ),
            )
          : Text('${widget.userSettings.maxHeartRate} bpm'),
      trailing: isEditing
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: _saveMaxHeartRate,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: _cancelEditing,
                ),
              ],
            )
          : IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _startEditing('maxHeartRate'),
            ),
      onTap: isEditing ? null : () => _startEditing('maxHeartRate'),
    );
  }

  Widget _buildCyclingFtpField() {
    final isEditing = _editingField == 'cyclingFtp';
    
    return ListTile(
      leading: const Icon(Icons.directions_bike, color: Colors.blue),
      title: const Text('Cycling FTP'),
      subtitle: isEditing
          ? Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextField(
                controller: _cyclingFtpController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: const InputDecoration(
                  hintText: 'Enter FTP',
                  suffixText: 'watts',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                autofocus: true,
                onSubmitted: (value) => _saveCyclingFtp(),
              ),
            )
          : Text('${widget.userSettings.cyclingFtp} watts'),
      trailing: isEditing
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: _saveCyclingFtp,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: _cancelEditing,
                ),
              ],
            )
          : IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _startEditing('cyclingFtp'),
            ),
      onTap: isEditing ? null : () => _startEditing('cyclingFtp'),
    );
  }

  Widget _buildRowingFtpField() {
    final isEditing = _editingField == 'rowingFtp';
    
    return ListTile(
      leading: const Icon(Icons.rowing, color: Colors.teal),
      title: const Text('Rowing FTP'),
      subtitle: isEditing
          ? Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextField(
                controller: _rowingFtpController,
                decoration: const InputDecoration(
                  hintText: 'Enter time (M:SS)',
                  suffixText: 'per 500m',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                autofocus: true,
                onSubmitted: (value) => _saveRowingFtp(),
              ),
            )
          : Text('${widget.userSettings.rowingFtp} per 500m'),
      trailing: isEditing
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: _saveRowingFtp,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: _cancelEditing,
                ),
              ],
            )
          : IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _startEditing('rowingFtp'),
            ),
      onTap: isEditing ? null : () => _startEditing('rowingFtp'),
    );
  }

  void _startEditing(String field) {
    setState(() {
      _editingField = field;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingField = null;
    });
    // Reset controllers to original values
    _maxHeartRateController.text = widget.userSettings.maxHeartRate.toString();
    _cyclingFtpController.text = widget.userSettings.cyclingFtp.toString();
    _rowingFtpController.text = widget.userSettings.rowingFtp;
  }

  void _saveMaxHeartRate() {
    final value = int.tryParse(_maxHeartRateController.text);
    if (value != null && value >= 120 && value <= 250) {
      widget.onChanged(UserSettings(
        maxHeartRate: value,
        cyclingFtp: widget.userSettings.cyclingFtp,
        rowingFtp: widget.userSettings.rowingFtp,
      ));
      HapticFeedback.lightImpact();
      setState(() {
        _editingField = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid heart rate (120-250 bpm)'),
        ),
      );
    }
  }

  void _saveCyclingFtp() {
    final value = int.tryParse(_cyclingFtpController.text);
    if (value != null && value >= 50 && value <= 1000) {
      widget.onChanged(UserSettings(
        maxHeartRate: widget.userSettings.maxHeartRate,
        cyclingFtp: value,
        rowingFtp: widget.userSettings.rowingFtp,
      ));
      HapticFeedback.lightImpact();
      setState(() {
        _editingField = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid FTP (50-1000 watts)'),
        ),
      );
    }
  }

  void _saveRowingFtp() {
    final value = _rowingFtpController.text.trim();
    if (_isValidRowingTime(value)) {
      widget.onChanged(UserSettings(
        maxHeartRate: widget.userSettings.maxHeartRate,
        cyclingFtp: widget.userSettings.cyclingFtp,
        rowingFtp: value,
      ));
      HapticFeedback.lightImpact();
      setState(() {
        _editingField = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid time format (M:SS)'),
        ),
      );
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
