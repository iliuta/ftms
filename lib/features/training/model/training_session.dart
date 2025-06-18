import 'package:ftms/core/models/device_types.dart';

import 'unit_training_interval.dart';
import 'training_interval.dart';
import 'group_training_interval.dart';
import '../../settings/model/user_settings.dart';

class TrainingSessionDefinition {
  final String title;
  final DeviceType ftmsMachineType;
  final List<TrainingInterval> intervals;

  TrainingSessionDefinition({required this.title, required this.ftmsMachineType, required this.intervals});

  /// Constructor for expanded sessions with UnitTrainingInterval list
  TrainingSessionDefinition._expanded({
    required this.title,
    required this.ftmsMachineType,
    required List<UnitTrainingInterval> expandedIntervals,
  }) : intervals = expandedIntervals;

  factory TrainingSessionDefinition.fromJson(Map<String, dynamic> json) {
    final List intervalsRaw = json['intervals'] as List;
    final List<TrainingInterval> intervals = intervalsRaw
        .map((e) => TrainingIntervalFactory.fromJsonPolymorphic(e))
        .toList();
    
    return TrainingSessionDefinition(
      title: json['title'],
      ftmsMachineType: DeviceType.fromString(json['ftmsMachineType']),
      intervals: intervals,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'ftmsMachineType': ftmsMachineType.name,
      'intervals': intervals.map((interval) => interval.toJson()).toList(),
    };
  }

  /// Creates a new instance with expanded intervals and target values.
  /// This expands group intervals into their constituent unit intervals
  /// and resolves percentage-based targets using the provided user settings.
  TrainingSessionDefinition expand({required UserSettings userSettings}) {
    final List<UnitTrainingInterval> expandedIntervals = [];
    
    for (final interval in intervals) {
      if (interval is GroupTrainingInterval) {
        // First expand targets, then expand repetitions
        final expandedTargetsInterval = interval.expandTargets(
          machineType: ftmsMachineType,
          userSettings: userSettings,
        );
        expandedIntervals.addAll(expandedTargetsInterval.expand());
      } else if (interval is UnitTrainingInterval) {
        // Expand targets and then repetitions
        final expandedTargetsInterval = interval.expandTargets(
          machineType: ftmsMachineType,
          userSettings: userSettings,
        );
        expandedIntervals.addAll(expandedTargetsInterval.expand());
      }
    }
    
    return TrainingSessionDefinition._expanded(
      title: title,
      ftmsMachineType: ftmsMachineType,
      expandedIntervals: expandedIntervals,
    );
  }

  /// Returns the intervals as UnitTrainingInterval list.
  /// This is safe to call only on expanded sessions.
  List<UnitTrainingInterval> get unitIntervals {
    return intervals.cast<UnitTrainingInterval>();
  }
}

extension TrainingIntervalFactory on TrainingInterval {
  /// Only first-level can be group, second-level must be unit
  static TrainingInterval fromJsonPolymorphic(Map<String, dynamic> json) {
    if (json.containsKey('intervals')) {
      return GroupTrainingInterval.fromJson(json);
    } else {
      return UnitTrainingInterval.fromJson(json);
    }
  }
}