import 'package:ftms/core/models/device_types.dart';

import 'training_interval.dart';
import '../../settings/model/user_settings.dart';
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
  @override
  UnitTrainingInterval expandTargets({
    required DeviceType machineType,
    UserSettings? userSettings,
  }) {
    Map<String, dynamic>? expandedTargets;
    if (targets != null) {
      expandedTargets = Map<String, dynamic>.from(targets!);
      // Use targetPowerStrategy pattern for power target resolution
      final targetPowerStrategy = TargetPowerStrategyFactory.getStrategy(machineType);
      if (expandedTargets.containsKey('Instantaneous Power')) {
        expandedTargets['Instantaneous Power'] = targetPowerStrategy.resolvePower(
            expandedTargets['Instantaneous Power'], userSettings);
      }
      if (expandedTargets.containsKey('Instantaneous Pace')) {
        expandedTargets['Instantaneous Pace'] = targetPowerStrategy.resolvePower(
            expandedTargets['Instantaneous Pace'], userSettings);
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
}
