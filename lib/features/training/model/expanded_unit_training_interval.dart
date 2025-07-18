
/// Expanded training interval with same fields as UnitTrainingInterval
class ExpandedUnitTrainingInterval {
  final String? title;
  final int duration;
  final Map<String, dynamic>? targets;
  final int? resistanceLevel;

  ExpandedUnitTrainingInterval({
    this.title,
    required this.duration,
    this.targets,
    this.resistanceLevel,
  });
}
