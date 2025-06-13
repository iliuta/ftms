import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Abstract service interface for different types of Bluetooth devices
abstract class DeviceTypeService {
  /// Human-readable name for this device type
  String get deviceTypeName;

  /// Priority for sorting in device lists (lower numbers appear first)
  int get listPriority;

  /// Icon to display for this device type
  Widget? getDeviceIcon(BuildContext context);

  /// Check if a device is of this type (synchronous check for sorting)
  bool isDeviceOfThisType(BluetoothDevice device, List<ScanResult> scanResults);

  /// Connect to a device of this type
  Future<bool> connectToDevice(BluetoothDevice device);

  /// Disconnect from a device of this type
  Future<void> disconnectFromDevice(BluetoothDevice device);

  /// Get the page/widget to show when the device is connected (optional)
  Widget? getDevicePage(BluetoothDevice device);

  /// Get a navigation callback for this device type (alternative to getDevicePage)
  /// This allows device services to define navigation without importing UI components
  void Function(BuildContext context, BluetoothDevice device)? getNavigationCallback() {
    return null;
  }

  /// Get action buttons for the connected device (optional)
  List<Widget> getConnectedActions(BluetoothDevice device, BuildContext context) {
    final page = getDevicePage(device);
    final navigationCallback = getNavigationCallback();
    final actions = <Widget>[];
    
    if (page != null) {
      actions.add(
        ElevatedButton(
          child: const Text("Open"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          },
        ),
      );
    } else if (navigationCallback != null) {
      actions.add(
        ElevatedButton(
          child: const Text("Open"),
          onPressed: () => navigationCallback(context, device),
        ),
      );
    }
    
    return actions;
  }
}
