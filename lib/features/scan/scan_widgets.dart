// This file was moved from lib/scan_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../ftms/ftms_page.dart';
import '../../core/services/heart_rate_service.dart';
import '../../core/services/cadence_service.dart';
import '../../core/services/devices/device_type_manager.dart';
import '../../core/services/devices/device_navigation_registry.dart';
import '../../core/services/connected_devices_service.dart';

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

  // Get connected devices
  final connectedDevices = connectedDevicesService.connectedDevices;
  
  // Create a set of connected device IDs for quick lookup
  final connectedDeviceIds = connectedDevices.map((d) => d.device.remoteId.str).toSet();
  
  // Filter out scan results that are already connected to avoid duplicates
  final availableDevices = data.where((scanResult) => 
    !connectedDeviceIds.contains(scanResult.device.remoteId.str)
  ).toList();
  
  // Sort available devices by device type priority
  final sortedAvailableDevices = deviceTypeManager.sortDevicesByPriority(availableDevices);
  
  // Create a combined list: connected devices first, then available devices
  final List<Widget> deviceWidgets = [];
  
  // Add connected devices first
  for (final connectedDevice in connectedDevices) {
    deviceWidgets.add(
      ListTile(
        title: Row(
          children: [
            connectedDevice.service.getDeviceIcon(context) ?? Container(),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                connectedDevice.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            // Connected indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Connected',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(connectedDevice.device.remoteId.str),
        leading: const SizedBox(
          width: 40,
          child: Center(
            child: Icon(Icons.bluetooth_connected, color: Colors.green),
          ),
        ),
        trailing: getButtonForConnectedDevice(connectedDevice, context),
      ),
    );
  }
  
  // Add available devices
  for (final scanResult in sortedAvailableDevices) {
    final deviceService = deviceTypeManager.getDeviceService(scanResult.device, data);
    deviceWidgets.add(
      ListTile(
        title: Row(
          children: [
            if (deviceService != null) ...[
              deviceService.getDeviceIcon(context) ?? Container(),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                scanResult.device.platformName.isEmpty
                    ? "(unknown device)"
                    : scanResult.device.platformName,
              ),
            ),
          ],
        ),
        subtitle: Text(scanResult.device.remoteId.str),
        leading: SizedBox(
          width: 40,
          child: Center(
            child: Text(scanResult.rssi.toString()),
          ),
        ),
        trailing: getButtonForBluetoothDevice(scanResult.device, context, data),
      ),
    );
  }

  return Column(children: deviceWidgets);
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
                
                debugPrint('🔍 Device service for ${device.platformName}: ${deviceService?.deviceTypeName ?? 'null'}');

                if (deviceService != null) {
                  debugPrint('✅ Using primary device service: ${deviceService.deviceTypeName} for ${device.platformName}');
                  // Try to connect using the appropriate device service
                  final success = await deviceService.connectToDevice(device);
                  if (success && context.mounted) {
                    // Add to connected devices service
                    debugPrint('📱 Adding device via primary path: ${device.platformName}');
                    await connectedDevicesService.addConnectedDevice(device, scanResults);
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Connected to ${deviceService.deviceTypeName}: ${device.platformName}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                      Text('Unsupported device ${device.platformName}'),
                      backgroundColor: Colors.red,
                    ),
                  );
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
                      // Remove from connected devices service first
                      connectedDevicesService.removeConnectedDevice(device.remoteId.str);
                      
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

                      // Also disconnect from Cadence if connected
                      final cadenceService = CadenceService();
                      await cadenceService.disconnectCadenceDevice();

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

/// Button for actions on already connected devices
Widget getButtonForConnectedDevice(ConnectedDevice connectedDevice, BuildContext context) {
  return SizedBox(
    width: 250,
    child: Wrap(
      spacing: 2,
      alignment: WrapAlignment.end,
      direction: Axis.horizontal,
      children: [
        // Get actions from the device service
        ...connectedDevice.service.getConnectedActions(connectedDevice.device, context),
        OutlinedButton(
          child: const Text("Disconnect"),
          onPressed: () async {
            // Disconnect using the device service
            await connectedDevice.service.disconnectFromDevice(connectedDevice.device);
            
            // Remove from connected devices service
            connectedDevicesService.removeConnectedDevice(connectedDevice.device.remoteId.str);

            // Disable wakelock when disconnecting
            WakelockPlus.disable();
          },
        ),
      ],
    ),
  );
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
