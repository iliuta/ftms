import '../../../core/config/user_settings.dart';

abstract class TargetPowerStrategy {
  /// Returns the resolved power value for the given [rawValue] and [userSettings].
  /// If the strategy does not apply, returns the original [rawValue].
  dynamic resolvePower(dynamic rawValue, UserSettings? userSettings);
}

class IndoorBikeTargetPowerStrategy implements TargetPowerStrategy {
  @override
  dynamic resolvePower(dynamic rawValue, UserSettings? userSettings) {
    if (rawValue is String && rawValue.endsWith('%') && userSettings != null) {
      final percent = int.tryParse(rawValue.replaceAll('%', ''));
      if (percent != null) {
        return ((userSettings.cyclingFtp * percent) / 100).round();
      }
    }
    return rawValue;
  }
}

class RowerTargetPowerStrategy implements TargetPowerStrategy {
  @override
  dynamic resolvePower(dynamic rawValue, UserSettings? userSettings) {
    // If value is a percentage string and userSettings is provided, convert to seconds/500m pace
    // Example: '95%' means 95% of user's rowing FTP pace (in seconds/500m, lower is faster)
    if (rawValue is String && rawValue.endsWith('%') && userSettings != null) {
      final percent = int.tryParse(rawValue.replaceAll('%', ''));
      if (percent != null) {
        // Parse user's rowing FTP (e.g., '2:00' -> 120 seconds)
        final ftpParts = userSettings.rowingFtp.split(':');
        if (ftpParts.length == 2) {
          final minutes = int.tryParse(ftpParts[0]);
          final seconds = int.tryParse(ftpParts[1]);
          if (minutes != null && seconds != null) {
            final ftpSeconds = minutes * 60 + seconds;
            // Lower percentage means faster pace (e.g., 95% of 2:00 = 114s)
            final paceSeconds = (ftpSeconds * percent / 100).round();
            return paceSeconds;
          }
        }
      }
    }
    return rawValue;
  }
}

class DefaultTargetPowerStrategy implements TargetPowerStrategy {
  @override
  dynamic resolvePower(dynamic rawValue, UserSettings? userSettings) => rawValue;
}

class TargetPowerStrategyFactory {
  static TargetPowerStrategy getStrategy(String? machineType) {
    switch (machineType) {
      case 'DeviceDataType.indoorBike':
        return IndoorBikeTargetPowerStrategy();
      case 'DeviceDataType.rower':
        return RowerTargetPowerStrategy();
      default:
        return DefaultTargetPowerStrategy();
    }
  }
}
