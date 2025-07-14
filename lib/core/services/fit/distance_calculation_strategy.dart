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


/// Distance calculation for rowing machines using the Total Distance field from FTMS data
class RowerDistanceStrategy implements DistanceCalculationStrategy {
  double _totalDistance = 0.0;
  double _previousTotalDistance = 0.0;
  
  @override
  double calculateDistanceIncrement({
    required Map<String, dynamic> currentData,
    required Map<String, dynamic>? previousData,
    required double timeDeltaSeconds,
  }) {
    // Get the total distance directly from FTMS data
    final currentTotalDistance = _getTotalDistanceValue(currentData);
    if (currentTotalDistance == null) return 0.0;
    
    // Calculate increment as difference from previous reading
    final distanceIncrement = currentTotalDistance - _previousTotalDistance;
    
    // Update stored values
    _previousTotalDistance = currentTotalDistance;
    _totalDistance = currentTotalDistance;
    
    // Return increment (should be >= 0)
    return distanceIncrement.clamp(0.0, double.infinity);
  }
  
  double? _getTotalDistanceValue(Map<String, dynamic> data) {
    final possibleKeys = [
      'Total Distance',
      'Distance',
      'distance',
      'totalDistance',
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
    _previousTotalDistance = 0.0;
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
