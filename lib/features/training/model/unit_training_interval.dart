import 'training_interval.dart';
import '../../../core/models/user_settings.dart';
import 'target_power_strategy.dart';

class UnitTrainingInterval extends TrainingInterval {
  final String? title;
  final int duration;
  final Map<String, dynamic>? targets;
  final int? resistanceLevel;
  @override
  final int? repeat;

  UnitTrainingInterval({this.title, required this.duration, this.targets, this.resistanceLevel, this.repeat});


  /// [machineType] is required to apply FTP logic for indoorBike/rower.
  /// [userSettings] is used for percentage-based targets.
  factory UnitTrainingInterval.fromJson(
    Map<String, dynamic> json, {
    String? machineType,
    UserSettings? userSettings,
  }) {
    Map<String, dynamic>? targets;
    if (json['targets'] != null) {
      targets = Map<String, dynamic>.from(json['targets']);
      // Use strategy pattern for power target resolution
      final strategy = TargetPowerStrategyFactory.getStrategy(machineType);
      if (targets.containsKey('Instantaneous Power')) {
        targets['Instantaneous Power'] = strategy.resolvePower(targets['Instantaneous Power'], userSettings);
      }
    }
    return UnitTrainingInterval(
      title: json['title'],
      duration: json['duration'],
      targets: targets,
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
