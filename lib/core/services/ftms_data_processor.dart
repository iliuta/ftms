import 'package:flutter_ftms/flutter_ftms.dart';
import '../config/live_data_display_config.dart';
import '../models/live_data_field_value.dart';
import 'value_averaging_service.dart';
import 'heart_rate_service.dart';
import 'cadence_service.dart';

/// Service for processing FTMS device data with averaging capabilities.
/// Can be used by both FTMSDataTab and training sessions.
class FtmsDataProcessor {
  final ValueAveragingService _averagingService = ValueAveragingService();
  final HeartRateService _heartRateService = HeartRateService();
  final CadenceService _cadenceService = CadenceService();
  bool _isConfigured = false;

  /// Configure the processor with display config to set up averaging fields
  void configure(LiveDataDisplayConfig config) {
    if (_isConfigured) return; // Avoid reconfiguring
    
    for (final field in config.fields) {
      if (field.samplePeriodSeconds != null) {
        _averagingService.configureField(field.name, field.samplePeriodSeconds!);
      }
    }
    _isConfigured = true;
  }

  /// Process raw FTMS device data and return paramValueMap with averaging applied
  Map<String, LiveDataFieldValue> processDeviceData(DeviceData deviceData) {
    final parameterValues = deviceData.getDeviceDataParameterValues();
    
    // Create initial param value map using FtmsParameter model
    final Map<String, LiveDataFieldValue> rawParamValueMap = {
      for (final p in parameterValues)
        p.name.name: LiveDataFieldValue.fromDeviceDataParameterValue(p)
    };
    
    // Process values for averaging and create final param value map
    final Map<String, LiveDataFieldValue> paramValueMap = {};
    for (final entry in rawParamValueMap.entries) {
      final fieldName = entry.key;
      final param = entry.value;
      
      // Add raw value to averaging service
      _averagingService.addValue(fieldName, param.value);
      
      // Use averaged value if configured, otherwise use raw value
      _useAveragedValueIfConfigured(fieldName, paramValueMap, param);
    }
    
    // Override heart rate with HRM data if available
    _overrideHeartRateFromHRMIfAvailable(paramValueMap);
    
    // Override cadence with cadence sensor data if available
    _overrideCadenceFromCadenceSensorIfAvailable(paramValueMap);
    
    return paramValueMap;
  }

  void _useAveragedValueIfConfigured(String fieldName, Map<String, LiveDataFieldValue> paramValueMap, LiveDataFieldValue param) {
    if (_averagingService.isFieldAveraged(fieldName)) {
      final averagedValue = _averagingService.getAveragedValue(fieldName);
      if (averagedValue != null) {
        // Create a new parameter with averaged value
        paramValueMap[fieldName] = param.copyWith(value: averagedValue);
      } else {
        paramValueMap[fieldName] = param;
      }
    } else {
      paramValueMap[fieldName] = param;
    }
  }

  void _overrideHeartRateFromHRMIfAvailable(Map<String, LiveDataFieldValue> paramValueMap) {
    if (_heartRateService.isHrmConnected && _heartRateService.currentHeartRate != null) {
      // Check if Heart Rate field exists in the configuration
      if (paramValueMap.containsKey('Heart Rate')) {
        // Replace with HRM data, keeping the same configuration as the FTMS heart rate field
        final originalHeartRateParam = paramValueMap['Heart Rate']!;
        paramValueMap['Heart Rate'] = originalHeartRateParam.copyWith(
          value: _heartRateService.currentHeartRate!.toDouble(),
        );
      } else {
        // Add HRM heart rate data if not present in FTMS data
        paramValueMap['Heart Rate'] = LiveDataFieldValue(
          name: 'Heart Rate',
          value: _heartRateService.currentHeartRate!.toDouble(),
          unit: 'bpm',
          factor: 1,
        );
      }
    }
  }

  void _overrideCadenceFromCadenceSensorIfAvailable(Map<String, LiveDataFieldValue> paramValueMap) {
    if (_cadenceService.isCadenceConnected && _cadenceService.currentCadence != null) {
      // Check if Instantaneous Cadence field exists in the configuration
      if (paramValueMap.containsKey('Instantaneous Cadence')) {
        // Replace with cadence sensor data, but use factor 1 since cadence sensor already provides correct RPM
        final originalCadenceParam = paramValueMap['Instantaneous Cadence']!;
        paramValueMap['Instantaneous Cadence'] = originalCadenceParam.copyWith(
          value: _cadenceService.currentCadence!.toDouble(),
          factor: 1, // Always use factor 1 for cadence sensor data
        );
      } else {
        // Add cadence sensor data if not present in FTMS data
        paramValueMap['Instantaneous Cadence'] = LiveDataFieldValue(
          name: 'Instantaneous Cadence',
          value: _cadenceService.currentCadence!.toDouble(),
          unit: 'rpm',
          factor: 1,
        );
      }
    }
  }

  /// Reset the processor state (useful for testing or switching devices)
  void reset() {
    _isConfigured = false;
    // Clear the averaging service data when resetting
    _averagingService.clearAll();
  }
}
