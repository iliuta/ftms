
import 'unit_training_interval.dart';
import 'training_interval.dart';
import 'group_training_interval.dart';

class TrainingSessionDefinition {
  final String title;
  final String ftmsMachineType;
  final List<UnitTrainingInterval> intervals;

  TrainingSessionDefinition({required this.title, required this.ftmsMachineType, required this.intervals});

  factory TrainingSessionDefinition.fromJson(Map<String, dynamic> json) {
    final List intervalsRaw = json['intervals'] as List;
    final List<UnitTrainingInterval> expandedIntervals = [];
    for (final e in intervalsRaw) {
      final interval = TrainingIntervalFactory.fromJsonPolymorphic(e);
      expandedIntervals.addAll(interval.expand());
    }
    return TrainingSessionDefinition(
      title: json['title'],
      ftmsMachineType: json['ftmsMachineType'],
      intervals: expandedIntervals,
    );
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