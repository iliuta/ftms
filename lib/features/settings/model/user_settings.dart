import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ftms/core/utils/logger.dart';

class UserSettings {
  final int maxHeartRate;
  final int cyclingFtp;
  final String rowingFtp;

  const UserSettings({
    required this.maxHeartRate,
    required this.cyclingFtp,
    required this.rowingFtp,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      maxHeartRate: json['maxHeartRate'] as int,
      cyclingFtp: json['cyclingFtp'] as int,
      rowingFtp: json['rowingFtp'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxHeartRate': maxHeartRate,
      'cyclingFtp': cyclingFtp,
      'rowingFtp': rowingFtp,
    };
  }

  static const String _prefsKey = 'user_settings';

  static Future<UserSettings> loadDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      
      if (jsonString != null) {
        logger.d('Loading user settings from SharedPreferences');
        final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        return UserSettings.fromJson(jsonMap);
      } else {
        logger.d('No saved user settings found, loading defaults from asset');
        return await _loadFromAsset();
      }
    } catch (e) {
      logger.w('Failed to load user settings from SharedPreferences, falling back to asset: $e');
      try {
        return await _loadFromAsset();
      } catch (assetError) {
        logger.e('Failed to load default user settings from asset: $assetError');
        // Return sensible defaults if all else fails
        return const UserSettings(
          maxHeartRate: 180,
          cyclingFtp: 250,
          rowingFtp: '2:00',
        );
      }
    }
  }

  static Future<UserSettings> _loadFromAsset() async {
    logger.d('Loading default user settings from asset: lib/config/default_user_settings.json');
    final jsonString = await rootBundle.loadString('lib/config/default_user_settings.json');
    logger.d('Loaded user settings JSON: $jsonString');
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    logger.d('Parsed user settings map: $jsonMap');
    final settings = UserSettings.fromJson(jsonMap);
    logger.d('Created UserSettings: maxHeartRate=[1m${settings.maxHeartRate}[0m, cyclingFtp=[1m${settings.cyclingFtp}[0m, rowingFtp=[1m${settings.rowingFtp}[0m');
    return settings;
  }

  /// Save settings to SharedPreferences
  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(toJson());
      await prefs.setString(_prefsKey, jsonString);
      logger.d('User settings saved to SharedPreferences');
    } catch (e) {
      logger.e('Failed to save user settings: $e');
      throw Exception('Failed to save user settings: $e');
    }
  }
}
