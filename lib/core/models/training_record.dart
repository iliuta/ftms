import 'ftms_parameter.dart';

/// Model for a single training data record
class TrainingRecord {
  final DateTime timestamp;
  final double? instantaneousPower; // Watts
  final double? instantaneousSpeed; // km/h
  final double? instantaneousCadence; // rpm
  final double? heartRate; // bpm
  final double? totalDistance; // meters (calculated)
  final double? elevation; // meters (usually 0 for indoor)
  final int elapsedTime; // seconds since start
  final double? resistanceLevel;
  final double? strokeRate; // for rower, strokes/min
  final double? totalStrokeCount; // for rower
  
  const TrainingRecord({
    required this.timestamp,
    required this.elapsedTime,
    this.instantaneousPower,
    this.instantaneousSpeed,
    this.instantaneousCadence,
    this.heartRate,
    this.totalDistance,
    this.elevation = 0.0,
    this.resistanceLevel,
    this.strokeRate,
    this.totalStrokeCount,
  });
  
  /// Create from FTMS parameter map (with proper types) and calculated distance
  factory TrainingRecord.fromFtmsParameters({
    required DateTime timestamp,
    required int elapsedTime,
    required Map<String, FtmsParameter> ftmsParams,
    double? calculatedDistance,
    double? resistanceLevel,
  }) {
    return TrainingRecord(
      timestamp: timestamp,
      elapsedTime: elapsedTime,
      instantaneousPower: _getParameterValue(ftmsParams, 'Instantaneous Power'),
      instantaneousSpeed: _getParameterValue(ftmsParams, 'Instantaneous Speed'),
      instantaneousCadence: _getParameterValue(ftmsParams, 'Instantaneous Cadence'),
      heartRate: _getParameterValue(ftmsParams, 'Heart Rate'),
      totalDistance: calculatedDistance,
      resistanceLevel: resistanceLevel,
      strokeRate: _getParameterValue(ftmsParams, 'Stroke Rate'),
      totalStrokeCount: _getParameterValue(ftmsParams, 'Total Stroke Count'),
    );
  }
  
  static double? _getParameterValue(Map<String, FtmsParameter> params, String key) {
    final param = params[key];
    if (param == null) return null;
    return param.getScaledValue().toDouble();
  }
  
  @override
  String toString() {
    return 'TrainingRecord(time: ${elapsedTime}s, power: ${instantaneousPower}W, '
        'speed: ${instantaneousSpeed}km/h, distance: ${totalDistance}m)';
  }
}
