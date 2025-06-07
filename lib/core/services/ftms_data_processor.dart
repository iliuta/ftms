import 'package:flutter_ftms/flutter_ftms.dart';
import '../config/ftms_display_config.dart';
import 'value_averaging_service.dart';

/// Service for processing FTMS device data with averaging capabilities.
/// Can be used by both FTMSDataTab and training sessions.
class FtmsDataProcessor {
  final ValueAveragingService _averagingService = ValueAveragingService();
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
  Map<String, dynamic> processDeviceData(DeviceData deviceData) {
    final parameterValues = deviceData.getDeviceDataParameterValues();
    
    // Create initial param value map
    final Map<String, dynamic> rawParamValueMap = {
      for (final p in parameterValues)
        p.name.name: p
    };
    
    // Process values for averaging and create final param value map
    final Map<String, dynamic> paramValueMap = {};
    for (final entry in rawParamValueMap.entries) {
      final fieldName = entry.key;
      final param = entry.value;
      
      // Add raw value to averaging service
      _averagingService.addValue(fieldName, param.value);
      
      // Use averaged value if configured, otherwise use raw value
      if (_averagingService.isFieldAveraged(fieldName)) {
        final averagedValue = _averagingService.getAveragedValue(fieldName);
        // Create a modified parameter with averaged value
        paramValueMap[fieldName] = _createAveragedParameter(param, averagedValue);
      } else {
        paramValueMap[fieldName] = param;
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

  /// Creates a parameter with averaged value while preserving other properties
  dynamic _createAveragedParameter(dynamic originalParam, num? averagedValue) {
    if (originalParam == null || averagedValue == null) {
      return originalParam;
    }
    
    // Create a new parameter object with the averaged value
    // This assumes the parameter has a 'value' property that can be modified
    if (originalParam.runtimeType.toString().contains('Parameter')) {
      // For FTMS parameter objects, we need to create a wrapper that behaves the same
      // but returns the averaged value
      return _AveragedParameterWrapper(originalParam, averagedValue);
    }
    
    return originalParam;
  }
}

/// Wrapper class to provide averaged values while maintaining parameter interface
class _AveragedParameterWrapper {
  final dynamic _originalParam;
  final num _averagedValue;
  
  _AveragedParameterWrapper(this._originalParam, this._averagedValue);
  
  // Delegate all properties except 'value' to the original parameter
  dynamic get name => _originalParam.name;
  dynamic get unit => _originalParam.unit;
  dynamic get scaleFactor => _originalParam.scaleFactor;
  dynamic get factor => _originalParam.factor;
  dynamic get flag => _originalParam.flag;
  dynamic get size => _originalParam.size;
  
  // Return the averaged value instead of the original
  num get value => _averagedValue;
  
  // Maintain toString behavior
  @override
  String toString() => _averagedValue.toString();
  
  // Handle any other method calls by delegating to the original
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #value) {
      return _averagedValue;
    }
    return _originalParam.noSuchMethod(invocation);
  }
}
