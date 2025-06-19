import 'unit_training_interval.dart';
import 'package:ftms/core/models/device_types.dart';
import '../../settings/model/user_settings.dart';

abstract class TrainingInterval {
  int? get repeat;
  List<UnitTrainingInterval> expand();
  TrainingInterval expandTargets({required DeviceType machineType, UserSettings? userSettings});
  Map<String, dynamic> toJson();
}