import 'package:ftms/core/models/device_types.dart';

import 'expanded_unit_training_interval.dart';
import 'unit_training_interval.dart';
import 'training_session.dart';

/// Expanded training session definition with ExpandedTrainingInterval list
class ExpandedTrainingSessionDefinition {
  final String title;
  final DeviceType ftmsMachineType;
  final List<ExpandedUnitTrainingInterval> intervals;
  final bool isCustom;
  final TrainingSessionDefinition? originalSession;

  ExpandedTrainingSessionDefinition({
    required this.title,
    required this.ftmsMachineType,
    required this.intervals,
    this.isCustom = false,
    this.originalSession,
  });

  /// Returns the intervals as UnitTrainingInterval list.
  /// This is safe to call only on expanded sessions.
  List<UnitTrainingInterval> get unitIntervals {
    return intervals.cast<UnitTrainingInterval>();
  }
}
