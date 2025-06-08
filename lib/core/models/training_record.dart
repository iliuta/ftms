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
  final double? instantaneousStrokeRate; // for rower, strokes/min
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
    this.instantaneousStrokeRate,
    this.totalStrokeCount,
  });
  
  /// Create from FTMS parameter map and calculated distance
  factory TrainingRecord.fromFtmsData({
    required DateTime timestamp,
    required int elapsedTime,
    required Map<String, dynamic> ftmsParams,
    double? calculatedDistance,
    double? resistanceLevel,
  }) {
    return TrainingRecord(
      timestamp: timestamp,
      elapsedTime: elapsedTime,
      instantaneousPower: _getScaledValue(ftmsParams, 'Instantaneous Power'),
      instantaneousSpeed: _getScaledValue(ftmsParams, 'Instantaneous Speed'),
      instantaneousCadence: _getScaledValue(ftmsParams, 'Instantaneous Cadence'),
      heartRate: _getScaledValue(ftmsParams, 'Heart Rate'),
      totalDistance: calculatedDistance,
      resistanceLevel: resistanceLevel,
      instantaneousStrokeRate: _getScaledValue(ftmsParams, 'Instantaneous Stroke Rate'),
      totalStrokeCount: _getScaledValue(ftmsParams, 'Total Stroke Count'),
    );
  }
  
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
      instantaneousStrokeRate: _getParameterValue(ftmsParams, 'Instantaneous Stroke Rate'),
      totalStrokeCount: _getParameterValue(ftmsParams, 'Total Stroke Count'),
    );
  }
  
  static double? _getParameterValue(Map<String, FtmsParameter> params, String key) {
    final param = params[key];
    if (param == null) return null;
    return param.getScaledValue().toDouble();
  }
  
  static double? _getScaledValue(Map<String, dynamic> params, String key) {
    final param = params[key];
    if (param == null) return null;
    
    // Handle FtmsParameter objects
    if (param.runtimeType.toString().contains('FtmsParameter')) {
      try {
        final scaledValue = param.getScaledValue();
        return scaledValue is num ? scaledValue.toDouble() : null;
      } catch (e) {
        // Fallback to raw value
        try {
          final value = param.value;
          return value is num ? value.toDouble() : null;
        } catch (e) {
          return null;
        }
      }
    }
    
    // Handle raw numeric values (backward compatibility)
    if (param is num) return param.toDouble();
    
    // Handle dynamic objects with value property
    if (param.hasProperty('value')) {
      final value = param.value;
      return value is num ? value.toDouble() : null;
    }
    
    return null;
  }
  
  @override
  String toString() {
    return 'TrainingRecord(time: ${elapsedTime}s, power: ${instantaneousPower}W, '
        'speed: ${instantaneousSpeed}km/h, distance: ${totalDistance}m)';
  }
}

/// Extension to add hasProperty method for dynamic objects
extension DynamicExtension on dynamic {
  bool hasProperty(String propertyName) {
    try {
      // This will throw if the property doesn't exist
      final _ = this[propertyName];
      return true;
    } catch (e) {
      try {
        // Try accessing as a property
        final value = runtimeType.toString();
        return value.contains(propertyName);
      } catch (e) {
        return false;
      }
    }
  }
}
