import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Registry for device-specific navigation callbacks
/// This helps avoid circular dependencies between device services and UI components
class DeviceNavigationRegistry {
  static final DeviceNavigationRegistry _instance = DeviceNavigationRegistry._internal();
  factory DeviceNavigationRegistry() => _instance;
  DeviceNavigationRegistry._internal();

  final Map<String, void Function(BuildContext context, BluetoothDevice device)> _navigationCallbacks = {};

  /// Register a navigation callback for a specific device type
  void registerNavigation(String deviceType, void Function(BuildContext context, BluetoothDevice device) callback) {
    _navigationCallbacks[deviceType] = callback;
  }

  /// Get navigation callback for a device type
  void Function(BuildContext context, BluetoothDevice device)? getNavigationCallback(String deviceType) {
    return _navigationCallbacks[deviceType];
  }

  /// Clear all registered callbacks (useful for testing)
  void clear() {
    _navigationCallbacks.clear();
  }
}
