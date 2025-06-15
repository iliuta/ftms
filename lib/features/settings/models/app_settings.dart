import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/logger.dart';

/// Application-wide settings and preferences
class AppSettings {
  final bool isDarkMode;
  final String temperatureUnit; // 'celsius' or 'fahrenheit'
  final String distanceUnit; // 'metric' or 'imperial'
  final bool enableHapticFeedback;
  final bool enableNotifications;
  final bool autoConnectToLastDevice;
  final bool keepScreenOn;
  final bool enableAutoPause;
  final bool enableFitFileGeneration;
  final bool enableStravaUpload;
  final int autoSaveInterval; // seconds

  const AppSettings({
    this.isDarkMode = false,
    this.temperatureUnit = 'celsius',
    this.distanceUnit = 'metric',
    this.enableHapticFeedback = true,
    this.enableNotifications = true,
    this.autoConnectToLastDevice = true,
    this.keepScreenOn = true,
    this.enableAutoPause = false,
    this.enableFitFileGeneration = true,
    this.enableStravaUpload = false,
    this.autoSaveInterval = 30,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      isDarkMode: json['isDarkMode'] as bool? ?? false,
      temperatureUnit: json['temperatureUnit'] as String? ?? 'celsius',
      distanceUnit: json['distanceUnit'] as String? ?? 'metric',
      enableHapticFeedback: json['enableHapticFeedback'] as bool? ?? true,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      autoConnectToLastDevice: json['autoConnectToLastDevice'] as bool? ?? true,
      keepScreenOn: json['keepScreenOn'] as bool? ?? true,
      enableAutoPause: json['enableAutoPause'] as bool? ?? false,
      enableFitFileGeneration: json['enableFitFileGeneration'] as bool? ?? true,
      enableStravaUpload: json['enableStravaUpload'] as bool? ?? false,
      autoSaveInterval: json['autoSaveInterval'] as int? ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isDarkMode': isDarkMode,
      'temperatureUnit': temperatureUnit,
      'distanceUnit': distanceUnit,
      'enableHapticFeedback': enableHapticFeedback,
      'enableNotifications': enableNotifications,
      'autoConnectToLastDevice': autoConnectToLastDevice,
      'keepScreenOn': keepScreenOn,
      'enableAutoPause': enableAutoPause,
      'enableFitFileGeneration': enableFitFileGeneration,
      'enableStravaUpload': enableStravaUpload,
      'autoSaveInterval': autoSaveInterval,
    };
  }

  AppSettings copyWith({
    bool? isDarkMode,
    String? temperatureUnit,
    String? distanceUnit,
    bool? enableHapticFeedback,
    bool? enableNotifications,
    bool? autoConnectToLastDevice,
    bool? keepScreenOn,
    bool? enableAutoPause,
    bool? enableFitFileGeneration,
    bool? enableStravaUpload,
    int? autoSaveInterval,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      autoConnectToLastDevice: autoConnectToLastDevice ?? this.autoConnectToLastDevice,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      enableAutoPause: enableAutoPause ?? this.enableAutoPause,
      enableFitFileGeneration: enableFitFileGeneration ?? this.enableFitFileGeneration,
      enableStravaUpload: enableStravaUpload ?? this.enableStravaUpload,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
    );
  }

  static const String _prefsKey = 'app_settings';

  /// Load settings from SharedPreferences, falling back to defaults
  static Future<AppSettings> loadDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      
      if (jsonString != null) {
        logger.d('Loading app settings from SharedPreferences');
        final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        return AppSettings.fromJson(jsonMap);
      } else {
        logger.d('No saved app settings found, loading defaults from asset');
        return await _loadFromAsset();
      }
    } catch (e) {
      logger.w('Failed to load app settings from SharedPreferences, falling back to defaults: $e');
      try {
        return await _loadFromAsset();
      } catch (assetError) {
        logger.e('Failed to load default app settings from asset: $assetError');
        return const AppSettings(); // Use hardcoded defaults
      }
    }
  }

  static Future<AppSettings> _loadFromAsset() async {
    try {
      final jsonString = await rootBundle.loadString('lib/config/default_app_settings.json');
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return AppSettings.fromJson(jsonMap);
    } catch (e) {
      logger.w('Asset not found, using hardcoded defaults: $e');
      return const AppSettings();
    }
  }

  /// Save settings to SharedPreferences
  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(toJson());
      await prefs.setString(_prefsKey, jsonString);
      logger.d('App settings saved to SharedPreferences');
    } catch (e) {
      logger.e('Failed to save app settings: $e');
      throw Exception('Failed to save app settings: $e');
    }
  }

  @override
  String toString() {
    return 'AppSettings{isDarkMode: $isDarkMode, temperatureUnit: $temperatureUnit, distanceUnit: $distanceUnit, enableHapticFeedback: $enableHapticFeedback, enableNotifications: $enableNotifications, autoConnectToLastDevice: $autoConnectToLastDevice, keepScreenOn: $keepScreenOn, enableAutoPause: $enableAutoPause, enableFitFileGeneration: $enableFitFileGeneration, enableStravaUpload: $enableStravaUpload, autoSaveInterval: $autoSaveInterval}';
  }
}
