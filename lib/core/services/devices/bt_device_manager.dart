import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:ftms/core/services/devices/cadence.dart';
import 'bt_device.dart';
import 'hrm.dart';
import 'ftms.dart';

/// Manager for handling different types of Bluetooth devices
class SupportedBTDeviceManager {
  static final SupportedBTDeviceManager _instance = SupportedBTDeviceManager._internal();
  factory SupportedBTDeviceManager() => _instance;
  SupportedBTDeviceManager._internal();

  /// List of all supported device type services
  final List<BTDevice> _supportedBTDevices = [
    Hrm(),
    Cadence(),
    Ftms(),
  ];

  /// Get all device services
  List<BTDevice> get deviceServices => List.unmodifiable(_supportedBTDevices);

  /// Find the primary device service for a given device
  BTDevice? getBTDevice(BluetoothDevice device, List<ScanResult> scanResults) {
    // Return the first btDevice that matches the device
    // Services are ordered by priority (HRM first, then FTMS)
    for (final btDevice in _supportedBTDevices) {
      if (btDevice.isDeviceOfThisType(device, scanResults)) {
        return btDevice;
      }
    }
    return null;
  }

  /// Get all device services that match a given device
  List<BTDevice> getAllMatchingBTDevices(BluetoothDevice device, List<ScanResult> scanResults) {
    return _supportedBTDevices
        .where((service) => service.isDeviceOfThisType(device, scanResults))
        .toList();
  }

  /// Sort devices by their type priority
  List<ScanResult> sortBTDevicesByPriority(List<ScanResult> scanResults) {
    final sortedData = List<ScanResult>.from(scanResults);
    
    sortedData.sort((a, b) {
      final aService = getBTDevice(a.device, scanResults);
      final bService = getBTDevice(b.device, scanResults);
      
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

}
