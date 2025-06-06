import 'training_interval.dart';

class UnitTrainingInterval extends TrainingInterval {
  final String? title;
  final int duration;
  final Map<String, dynamic>? targets;
  final int? resistanceLevel;
  @override
  final int? repeat;

  UnitTrainingInterval({this.title, required this.duration, this.targets, this.resistanceLevel, this.repeat});

  factory UnitTrainingInterval.fromJson(Map<String, dynamic> json) {
    return UnitTrainingInterval(
      title: json['title'],
      duration: json['duration'],
      targets: json['targets'] != null ? Map<String, dynamic>.from(json['targets']) : null,
      resistanceLevel: json['resistanceLevel'],
      repeat: json['repeat'],
    );
  }

  @override
  List<UnitTrainingInterval> expand() {
    final r = repeat ?? 1;
    return List.generate(r > 0 ? r : 1, (_) => this);
  }
}
