import 'package:ftms/core/models/device_types.dart';

import 'unit_training_interval.dart';
import 'training_interval.dart';
import 'group_training_interval.dart';
import '../../settings/model/user_settings.dart';
import '../../../core/config/live_data_display_config.dart';

class TrainingSessionDefinition {
  final String title;
  final DeviceType ftmsMachineType;
  final List<TrainingInterval> intervals;
  final bool isCustom;
  /// The original non-expanded session definition for editing purposes
  final TrainingSessionDefinition? originalSession;

  TrainingSessionDefinition({
    required this.title, 
    required this.ftmsMachineType, 
    required this.intervals,
    this.isCustom = false,
    this.originalSession,
  });

  /// Constructor for expanded sessions with UnitTrainingInterval list
  TrainingSessionDefinition._expanded({
    required this.title,
    required this.ftmsMachineType,
    required List<UnitTrainingInterval> expandedIntervals,
    this.isCustom = false,
    this.originalSession,
  }) : intervals = expandedIntervals;

  factory TrainingSessionDefinition.fromJson(Map<String, dynamic> json, {bool isCustom = false}) {
    final List intervalsRaw = json['intervals'] as List;
    final List<TrainingInterval> intervals = intervalsRaw
        .map((e) => TrainingIntervalFactory.fromJsonPolymorphic(e))
        .toList();
    
    return TrainingSessionDefinition(
      title: json['title'],
      ftmsMachineType: DeviceType.fromString(json['ftmsMachineType']),
      intervals: intervals,
      isCustom: isCustom,
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
  TrainingSessionDefinition expand({
    required UserSettings userSettings,
    LiveDataDisplayConfig? config,
  }) {
    final List<UnitTrainingInterval> expandedIntervals = [];
    
    for (final interval in intervals) {
      // Both GroupTrainingInterval and UnitTrainingInterval have expandTargets method
      final expandedTargetsInterval = interval.expandTargets(
        machineType: ftmsMachineType,
        userSettings: userSettings,
        config: config,
      );
      expandedIntervals.addAll(expandedTargetsInterval.expand());
    }
    
    return TrainingSessionDefinition._expanded(
      title: title,
      ftmsMachineType: ftmsMachineType,
      expandedIntervals: expandedIntervals,
      isCustom: isCustom,
      originalSession: isCustom ? this : null, // Keep reference to original for custom sessions
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