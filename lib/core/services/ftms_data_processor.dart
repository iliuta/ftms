import 'package:flutter_ftms/flutter_ftms.dart';
import '../config/ftms_display_config.dart';
import '../models/ftms_parameter.dart';
import 'value_averaging_service.dart';
import 'heart_rate_service.dart';

/// Service for processing FTMS device data with averaging capabilities.
/// Can be used by both FTMSDataTab and training sessions.
class FtmsDataProcessor {
  final ValueAveragingService _averagingService = ValueAveragingService();
  final HeartRateService _heartRateService = HeartRateService();
  bool _isConfigured = false;

  /// Configure the processor with display config to set up averaging fields
  void configure(FtmsDisplayConfig config) {
    if (_isConfigured) return; // Avoid reconfiguring
    
    for (final field in config.fields) {
      if (field.samplePeriodSeconds != null) {
        _averagingService.configureField(field.name, field.samplePeriodSeconds!);
      }
    }
    _isConfigured = true;
  }

  /// Process raw FTMS device data and return paramValueMap with averaging applied
  Map<String, FtmsParameter> processDeviceData(DeviceData deviceData) {
    final parameterValues = deviceData.getDeviceDataParameterValues();
    
    // Create initial param value map using FtmsParameter model
    final Map<String, FtmsParameter> rawParamValueMap = {
      for (final p in parameterValues)
        p.name.name: FtmsParameter.fromDeviceDataParameterValue(p)
    };
    
    // Process values for averaging and create final param value map
    final Map<String, FtmsParameter> paramValueMap = {};
    for (final entry in rawParamValueMap.entries) {
      final fieldName = entry.key;
      final param = entry.value;
      
      // Add raw value to averaging service
      _averagingService.addValue(fieldName, param.value);
      
      // Use averaged value if configured, otherwise use raw value
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
    
    // Override heart rate with HRM data if available
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
        paramValueMap['Heart Rate'] = FtmsParameter(
          name: 'Heart Rate',
          value: _heartRateService.currentHeartRate!.toDouble(),
          unit: 'bpm',
          factor: 1,
        );
      }
    }
    
    return paramValueMap;
  }

  /// Reset the processor state (useful for testing or switching devices)
  void reset() {
    _isConfigured = false;
    // Clear the averaging service data when resetting
    _averagingService.clearAll();
  }
}
