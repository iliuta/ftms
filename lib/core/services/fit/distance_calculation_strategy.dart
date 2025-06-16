import 'package:ftms/core/models/device_types.dart';

import '../../models/live_data_field_value.dart';

/// Abstract base class for distance calculation strategies
abstract class DistanceCalculationStrategy {
  /// Calculate distance increment based on current data and time elapsed
  /// Returns distance in meters
  double calculateDistanceIncrement({
    required Map<String, dynamic> currentData,
    required Map<String, dynamic>? previousData,
    required double timeDeltaSeconds,
  });
  
  /// Get the total calculated distance so far
  double get totalDistance;
  
  /// Reset the distance calculation
  void reset();
}

/// Distance calculation for indoor bikes using speed
class IndoorBikeDistanceStrategy implements DistanceCalculationStrategy {
  double _totalDistance = 0.0;
  
  @override
  double calculateDistanceIncrement({
    required Map<String, dynamic> currentData,
    required Map<String, dynamic>? previousData,
    required double timeDeltaSeconds,
  }) {
    // Get speed in km/h from FTMS data
    final speedKmh = _getSpeedValue(currentData);
    if (speedKmh == null || speedKmh <= 0) return 0.0;
    
    // Convert km/h to m/s and calculate distance
    final speedMs = speedKmh / 3.6;
    final distanceIncrement = speedMs * timeDeltaSeconds;
    
    _totalDistance += distanceIncrement;
    return distanceIncrement;
  }
  
  double? _getSpeedValue(Map<String, dynamic> data) {
    // Try different possible speed parameter names
    final possibleKeys = [
      'Instantaneous Speed',
      'Speed',
      'speed',
    ];
    
    for (final key in possibleKeys) {
      final param = data[key];
      if (param != null) {
        // Handle FtmsParameter objects - use scaled value
        if (param is LiveDataFieldValue) {
          return param.getScaledValue().toDouble();
        }
        // Handle raw numeric values
        if (param is num) return param.toDouble();
        // Handle dynamic objects with value property
        try {
          final value = param.value;
          if (value is num) return value.toDouble();
        } catch (e) {
          // Ignore if not an FtmsParameter or dynamic object
        }
      }
    }
    return null;
  }
  
  @override
  double get totalDistance => _totalDistance;
  
  @override
  void reset() {
    _totalDistance = 0.0;
  }
}

/// Distance calculation for rowing machines using stroke rate and estimated distance per stroke
class RowerDistanceStrategy implements DistanceCalculationStrategy {
  double _totalDistance = 0.0;
  static const double _baseDistancePerStroke = 10.0; // meters per stroke (average)
  
  @override
  double calculateDistanceIncrement({
    required Map<String, dynamic> currentData,
    required Map<String, dynamic>? previousData,
    required double timeDeltaSeconds,
  }) {
    // For rowers, we can estimate distance based on stroke rate and power
    final strokeRate = _getStrokeRateValue(currentData);
    final power = _getPowerValue(currentData);
    
    if (strokeRate == null || strokeRate <= 0) return 0.0;
    
    // Calculate strokes in this time period
    final strokesPerSecond = strokeRate / 60.0;
    final strokesInPeriod = strokesPerSecond * timeDeltaSeconds;
    
    // Adjust distance per stroke based on power
    double distancePerStroke = _baseDistancePerStroke;
    if (power != null && power > 0) {
      // Higher power = longer strokes
      // This is a simplified model - real calculation would be more complex
      final powerFactor = (power / 150.0).clamp(0.5, 2.0); // Normalize around 150W
      distancePerStroke *= powerFactor;
    }
    
    final distanceIncrement = strokesInPeriod * distancePerStroke;
    _totalDistance += distanceIncrement;
    return distanceIncrement;
  }
  
  double? _getStrokeRateValue(Map<String, dynamic> data) {
    final possibleKeys = [
      'Instantaneous Stroke Rate',
      'Stroke Rate',
      'strokeRate',
    ];
    
    for (final key in possibleKeys) {
      final param = data[key];
      if (param != null) {
        // Handle FtmsParameter objects - use scaled value
        if (param is LiveDataFieldValue) {
          return param.getScaledValue().toDouble();
        }
        // Handle raw numeric values
        if (param is num) return param.toDouble();
        // Handle dynamic objects with value property
        try {
          final value = param.value;
          if (value is num) return value.toDouble();
        } catch (e) {
          // Ignore if not an FtmsParameter or dynamic object
        }
      }
    }
    return null;
  }
  
  double? _getPowerValue(Map<String, dynamic> data) {
    final possibleKeys = [
      'Instantaneous Power',
      'Power',
      'power',
    ];
    
    for (final key in possibleKeys) {
      final param = data[key];
      if (param != null) {
        // Handle FtmsParameter objects - use scaled value
        if (param is LiveDataFieldValue) {
          return param.getScaledValue().toDouble();
        }
        // Handle raw numeric values
        if (param is num) return param.toDouble();
        // Handle dynamic objects with value property
        try {
          final value = param.value;
          if (value is num) return value.toDouble();
        } catch (e) {
          // Ignore if not an FtmsParameter or dynamic object
        }
      }
    }
    return null;
  }
  
  @override
  double get totalDistance => _totalDistance;
  
  @override
  void reset() {
    _totalDistance = 0.0;
  }
}

/// Factory for creating appropriate distance calculation strategy
class DistanceCalculationStrategyFactory {
  static DistanceCalculationStrategy createStrategy(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.indoorBike:
        return IndoorBikeDistanceStrategy();
      case DeviceType.rower:
        return RowerDistanceStrategy();
    }
  }
}
