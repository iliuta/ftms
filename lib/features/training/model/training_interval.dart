import 'unit_training_interval.dart';

abstract class TrainingInterval {
  int? get repeat;
  List<UnitTrainingInterval> expand();
}