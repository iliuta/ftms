import 'package:ftms/core/models/device_types.dart';

import 'training_interval.dart';
import '../../settings/model/user_settings.dart';
import '../../../core/config/live_data_display_config.dart';
import 'target_power_strategy.dart';

class UnitTrainingInterval extends TrainingInterval {
  final String? title;
  final int duration;
  final Map<String, dynamic>? targets;
  final int? resistanceLevel;
  @override
  final int? repeat;

  UnitTrainingInterval(
      {this.title,
      required this.duration,
      this.targets,
      this.resistanceLevel,
      this.repeat});

  factory UnitTrainingInterval.fromJson(Map<String, dynamic> json) {
    return UnitTrainingInterval(
      title: json['title'],
      duration: json['duration'],
      targets: json['targets'] != null ? Map<String, dynamic>.from(json['targets']) : null,
      resistanceLevel: json['resistanceLevel'],
      repeat: json['repeat'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'duration': duration,
      'targets': targets,
      'resistanceLevel': resistanceLevel,
      'repeat': repeat,
    };
  }

  /// Creates a new instance with expanded target values.
  /// [machineType] is required to apply FTP logic for indoorBike/rower.
  /// [userSettings] is used for percentage-based targets.
  /// [config] provides field configuration including userSetting properties.
  @override
  UnitTrainingInterval expandTargets({
    required DeviceType machineType,
    UserSettings? userSettings,
    LiveDataDisplayConfig? config,
  }) {
    Map<String, dynamic>? expandedTargets;
    if (targets != null) {
      expandedTargets = Map<String, dynamic>.from(targets!);
      // Use targetPowerStrategy pattern for power target resolution
      final targetPowerStrategy = TargetPowerStrategyFactory.getStrategy(machineType);
      
      // Apply power strategy to fields that need percentage-based calculation
      // based on userSetting configuration from LiveDataDisplayConfig
      for (final fieldName in expandedTargets.keys.toList()) {
        if (_shouldApplyPowerStrategy(fieldName, config)) {
          expandedTargets[fieldName] = targetPowerStrategy.resolvePower(
              expandedTargets[fieldName], userSettings);
        }
      }
    }
    return UnitTrainingInterval(
      title: title,
      duration: duration,
      targets: expandedTargets,
      resistanceLevel: resistanceLevel,
      repeat: repeat,
    );
  }

  @override
  List<UnitTrainingInterval> expand() {
    final r = repeat ?? 1;
    return List.generate(r > 0 ? r : 1, (_) => this);
  }

  /// Helper method to determine if a field should apply power strategy
  /// based on the field's userSetting configuration in LiveDataDisplayConfig.
  /// This replaces explicit checks for 'Instantaneous Power' and 'Instantaneous Pace'
  /// with logic that checks the userSetting property from the configuration.
  bool _shouldApplyPowerStrategy(String fieldName, LiveDataDisplayConfig? config) {
    if (config == null) return false;
    
    // Find the field configuration for this field name
    try {
      final fieldConfig = config.fields.firstWhere((field) => field.name == fieldName);
      // Apply power strategy if the field has a userSetting configured
      return fieldConfig.userSetting != null;
    } catch (e) {
      // Field not found in configuration, don't apply power strategy
      return false;
    }
  }
}
