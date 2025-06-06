import 'training_interval.dart';
import 'unit_training_interval.dart';

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