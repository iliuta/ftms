import 'package:ftms/core/models/device_types.dart';

import 'training_interval.dart';
import 'unit_training_interval.dart';
import '../../settings/model/user_settings.dart';
import '../../../core/config/live_data_display_config.dart';

class GroupTrainingInterval extends TrainingInterval {
  @override
  final int? repeat;
  final List<UnitTrainingInterval> intervals;

  GroupTrainingInterval({required this.intervals, this.repeat});

  factory GroupTrainingInterval.fromJson(Map<String, dynamic> json) {
    return GroupTrainingInterval(
      repeat: json['repeat'],
      intervals: (json['intervals'] as List)
          .map((e) => UnitTrainingInterval.fromJson(e))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'repeat': repeat,
      'intervals': intervals.map((interval) => interval.toJson()).toList(),
    };
  }

  /// Creates a new instance with expanded target values in all sub-intervals.
  @override
  GroupTrainingInterval expandTargets({
    required DeviceType machineType,
    UserSettings? userSettings,
    LiveDataDisplayConfig? config,
  }) {
    return GroupTrainingInterval(
      repeat: repeat,
      intervals: intervals
          .map((interval) => interval.expandTargets(
                machineType: machineType,
                userSettings: userSettings,
                config: config,
              ))
          .toList(),
    );
  }

  @override
  List<UnitTrainingInterval> expand() {
    final r = repeat ?? 1;
    final flat = <UnitTrainingInterval>[];
    for (int i = 0; i < (r > 0 ? r : 1); i++) {
      for (final interval in intervals) {
        flat.addAll(interval.expand());
      }
    }
    return flat;
  }
}