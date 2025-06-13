// This file was moved from lib/scan_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../ftms/ftms_page.dart';
import '../../core/services/heart_rate_service.dart';
import '../../core/services/devices/device_type_manager.dart';
import '../../core/services/devices/device_navigation_registry.dart';

/// Button for scanning Bluetooth devices
Widget scanBluetoothButton(bool? isScanning) {
  if (isScanning == null) {
    return Container();
  }
  return ElevatedButton(
    onPressed:
        isScanning ? null : () async => await FTMS.scanForBluetoothDevices(),
    child:
        isScanning ? const Text("Scanning...") : const Text("Scan for devices"),
  );
}

/// Widget to display scan results as a list of FTMS devices
Widget scanResultsToWidget(List<ScanResult> data, BuildContext context) {
  final deviceTypeManager = DeviceTypeManager();

  // Sort data by device type priority
  final sortedData = deviceTypeManager.sortDevicesByPriority(data);

  return Column(
    children: sortedData
        .map(
          (d) => ListTile(
            title: Builder(builder: (c) {
              final deviceService =
                  deviceTypeManager.getDeviceService(d.device, data);
              return Row(
                children: [
                  if (deviceService != null) ...[
                    deviceService.getDeviceIcon(context) ?? Container(),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      d.device.platformName.isEmpty
                          ? "(unknown device)"
                          : d.device.platformName,
                    ),
                  ),
                ],
              );
            }),
            subtitle: Text(d.device.remoteId.str),
            leading: SizedBox(
              width: 40,
              child: Center(
                child: Text(d.rssi.toString()),
              ),
            ),
            trailing: getButtonForBluetoothDevice(d.device, context, data),
          ),
        )
        .toList(),
  );
}

/// Button for connecting/disconnecting to a Bluetooth device and opening FTMS page
Widget getButtonForBluetoothDevice(BluetoothDevice device, BuildContext context,
    List<ScanResult> scanResults) {
  final deviceTypeManager = DeviceTypeManager();

  return StreamBuilder<BluetoothConnectionState>(
      stream: device.connectionState,
      builder: (c, snapshot) {
        if (!snapshot.hasData) {
          return const Text("...");
        }
        var deviceState = snapshot.data!;
        switch (deviceState) {
          case BluetoothConnectionState.disconnected:
            return ElevatedButton(
              child: const Text("Connect"),
              onPressed: () async {
                final snackBar = SnackBar(
                  content: Text('Connecting to ${device.platformName}...'),
                  duration: const Duration(seconds: 2),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);

                // Get the primary device service for this device
                final deviceService =
                    deviceTypeManager.getDeviceService(device, scanResults);

                if (deviceService != null) {
                  // Try to connect using the appropriate device service
                  final success = await deviceService.connectToDevice(device);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Connected to ${deviceService.deviceTypeName}: ${device.platformName}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Failed to connect to ${device.platformName}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Failed to connect to ${device.platformName}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            );
          case BluetoothConnectionState.connected:
            return SizedBox(
              width: 250,
              child: Wrap(
                spacing: 2,
                alignment: WrapAlignment.end,
                direction: Axis.horizontal,
                children: [
                  // Get actions from device services
                  ...() {
                    final matchingServices = deviceTypeManager
                        .getAllMatchingServices(device, scanResults);
                    final actions = <Widget>[];

                    for (final service in matchingServices) {
                      actions
                          .addAll(service.getConnectedActions(device, context));
                    }

                    // Fallback: if no services provide actions, check if it's an FTMS device
                    if (actions.isEmpty) {
                      actions.add(
                        FutureBuilder<bool>(
                          future: FTMS.isBluetoothDeviceFTMSDevice(device),
                          initialData: false,
                          builder: (c, snapshot) => (snapshot.data ?? false)
                              ? ElevatedButton(
                                  child: const Text("Open"),
                                  onPressed: () async {
                                    // Enable wakelock when device is selected
                                    try {
                                      await WakelockPlus.enable();
                                    } catch (e) {
                                      // Wakelock not supported on this platform
                                      debugPrint('Wakelock not supported: $e');
                                    }

                                    if (!context.mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => FTMSPage(
                                                ftmsDevice: device,
                                              )),
                                    );
                                  },
                                )
                              : Container(),
                        ),
                      );
                    }

                    return actions;
                  }(),
                  OutlinedButton(
                    child: const Text("Disconnect"),
                    onPressed: () async {
                      // Disconnect using all matching services
                      final matchingServices = deviceTypeManager
                          .getAllMatchingServices(device, scanResults);
                      for (final service in matchingServices) {
                        await service.disconnectFromDevice(device);
                      }

                      // Fallback disconnection for FTMS
                      await FTMS.disconnectFromFTMSDevice(device);

                      // Also disconnect from HRM if connected
                      final heartRateService = HeartRateService();
                      await heartRateService.disconnectHrmDevice();

                      // Disable wakelock when disconnecting
                      WakelockPlus.disable();
                    },
                  )
                ],
              ),
            );
          default:
            return Text(deviceState.name);
        }
      });
}

/// Initialize device navigation callbacks
/// This should be called once during app initialization to register navigation callbacks
/// and avoid circular dependencies between device services and UI components
void initializeDeviceNavigation() {
  final registry = DeviceNavigationRegistry();
  
  // Register FTMS navigation callback
  registry.registerNavigation('FTMS', (context, device) async {
    // Enable wakelock when device is selected
    try {
      await WakelockPlus.enable();
    } catch (e) {
      // Wakelock not supported on this platform
      debugPrint('Wakelock not supported: $e');
    }

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FTMSPage(ftmsDevice: device),
      ),
    );
  });
}
