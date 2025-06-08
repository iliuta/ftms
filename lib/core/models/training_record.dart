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
      instantaneousPower: _getDoubleValue(ftmsParams, 'Instantaneous Power'),
      instantaneousSpeed: _getDoubleValue(ftmsParams, 'Instantaneous Speed'),
      instantaneousCadence: _getDoubleValue(ftmsParams, 'Instantaneous Cadence'),
      heartRate: _getDoubleValue(ftmsParams, 'Heart Rate'),
      totalDistance: calculatedDistance,
      resistanceLevel: resistanceLevel,
      instantaneousStrokeRate: _getDoubleValue(ftmsParams, 'Instantaneous Stroke Rate'),
      totalStrokeCount: _getDoubleValue(ftmsParams, 'Total Stroke Count'),
    );
  }
  
  static double? _getDoubleValue(Map<String, dynamic> params, String key) {
    final param = params[key];
    if (param == null) return null;
    if (param is num) return param.toDouble();
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
