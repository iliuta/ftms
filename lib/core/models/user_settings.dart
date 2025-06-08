import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
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

  static Future<UserSettings> loadDefault() async {
    try {
      logger.d('Loading default user settings from asset: lib/config/default_user_settings.json');
      final jsonString = await rootBundle.loadString('lib/config/default_user_settings.json');
      logger.d('Loaded user settings JSON: $jsonString');
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      logger.d('Parsed user settings map: $jsonMap');
      final settings = UserSettings.fromJson(jsonMap);
      logger.d('Created UserSettings: maxHeartRate=[1m${settings.maxHeartRate}[0m, cyclingFtp=[1m${settings.cyclingFtp}[0m, rowingFtp=[1m${settings.rowingFtp}[0m');
      return settings;
    } catch (e, stack) {
      logger.e('Failed to load default user settings', error: e, stackTrace: stack);
      throw Exception('Failed to load default user settings: $e');
    }
  }
}
