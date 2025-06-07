import 'training_interval.dart';
import '../../../core/config/user_settings.dart';

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
      // Only for indoorBike, convert percentage string for Instantaneous Power
      if (machineType == 'DeviceDataType.indoorBike' && userSettings != null) {
        final power = targets['Instantaneous Power'];
        if (power is String && power.endsWith('%')) {
          final percent = int.tryParse(power.replaceAll('%', ''));
          if (percent != null) {
            targets['Instantaneous Power'] = ((userSettings.cyclingFtp * percent) / 100).round();
          }
        }
      }
      // (Future: add similar logic for rower/rowingFtp here)
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
