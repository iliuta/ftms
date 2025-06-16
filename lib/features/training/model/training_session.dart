
import 'package:ftms/core/models/device_types.dart';

import 'unit_training_interval.dart';
import 'training_interval.dart';
import 'group_training_interval.dart';
import '../../settings/model/user_settings.dart';

class TrainingSessionDefinition {
  final String title;
  final DeviceType ftmsMachineType;
  final List<UnitTrainingInterval> intervals;

  TrainingSessionDefinition({required this.title, required this.ftmsMachineType, required this.intervals});

  factory TrainingSessionDefinition.fromJson(
    Map<String, dynamic> json, {
    DeviceType? machineType,
    required UserSettings userSettings,
  }) {
    final List intervalsRaw = json['intervals'] as List;
    final List<UnitTrainingInterval> expandedIntervals = [];
    for (final e in intervalsRaw) {
      final interval = TrainingIntervalFactory.fromJsonPolymorphic(
        e,
        machineType: machineType ?? DeviceType.fromString(json['ftmsMachineType']),
        userSettings: userSettings,
      );
      expandedIntervals.addAll(interval.expand());
    }
    return TrainingSessionDefinition(
      title: json['title'],
      ftmsMachineType: DeviceType.fromString(json['ftmsMachineType']),
      intervals: expandedIntervals,
    );
  }
}

extension TrainingIntervalFactory on TrainingInterval {
  /// Only first-level can be group, second-level must be unit
  static TrainingInterval fromJsonPolymorphic(
    Map<String, dynamic> json, {
    DeviceType? machineType,
    required UserSettings userSettings,
  }) {
    if (json.containsKey('intervals')) {
      return GroupTrainingInterval.fromJson(
        json,
        machineType: machineType,
        userSettings: userSettings,
      );
    } else {
      return UnitTrainingInterval.fromJson(
        json,
        machineType: machineType,
        userSettings: userSettings,
      );
    }
  }
}