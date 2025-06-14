import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:ftms/core/services/devices/cadence_device_service.dart';
import 'device_type_service.dart';
import 'hrm_device_service.dart';
import 'ftms_device_service.dart';

/// Manager for handling different types of Bluetooth devices
class DeviceTypeManager {
  static final DeviceTypeManager _instance = DeviceTypeManager._internal();
  factory DeviceTypeManager() => _instance;
  DeviceTypeManager._internal();

  /// List of all supported device type services
  final List<DeviceTypeService> _deviceServices = [
    HrmDeviceService(),
    CadenceDeviceService(),
    FtmsDeviceService(),
  ];

  /// Get all device services
  List<DeviceTypeService> get deviceServices => List.unmodifiable(_deviceServices);

  /// Find the primary device service for a given device
  DeviceTypeService? getDeviceService(BluetoothDevice device, List<ScanResult> scanResults) {
    // Return the first service that matches the device
    // Services are ordered by priority (HRM first, then FTMS)
    for (final service in _deviceServices) {
      if (service.isDeviceOfThisType(device, scanResults)) {
        return service;
      }
    }
    return null;
  }

  /// Get all device services that match a given device
  List<DeviceTypeService> getAllMatchingServices(BluetoothDevice device, List<ScanResult> scanResults) {
    return _deviceServices
        .where((service) => service.isDeviceOfThisType(device, scanResults))
        .toList();
  }

  /// Sort devices by their type priority
  List<ScanResult> sortDevicesByPriority(List<ScanResult> scanResults) {
    final sortedData = List<ScanResult>.from(scanResults);
    
    sortedData.sort((a, b) {
      final aService = getDeviceService(a.device, scanResults);
      final bService = getDeviceService(b.device, scanResults);
      
      // If both have services, sort by priority
      if (aService != null && bService != null) {
        final priorityComparison = aService.listPriority.compareTo(bService.listPriority);
        if (priorityComparison != 0) return priorityComparison;
      }
      
      // If only one has a service, prioritize it
      if (aService != null && bService == null) return -1;
      if (aService == null && bService != null) return 1;
      
      // If neither has a service or same priority, sort by signal strength
      return b.rssi.compareTo(a.rssi);
    });
    
    return sortedData;
  }

  /// Add a new device service (for future extensibility)
  void registerDeviceService(DeviceTypeService service) {
    _deviceServices.add(service);
    // Re-sort by priority
    _deviceServices.sort((a, b) => a.listPriority.compareTo(b.listPriority));
  }
}
