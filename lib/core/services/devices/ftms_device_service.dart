import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import 'package:ftms/core/models/device_types.dart';
import 'device_type_service.dart';
import 'device_navigation_registry.dart';
import '../connected_devices_service.dart';
import '../../bloc/ftms_bloc.dart';

/// Service for FTMS (Fitness Machine Service) devices
class FtmsDeviceService extends DeviceTypeService {
  static final FtmsDeviceService _instance = FtmsDeviceService._internal();
  factory FtmsDeviceService() => _instance;
  FtmsDeviceService._internal();

  @override
  String get deviceTypeName => 'FTMS';

  @override
  int get listPriority => 20; // Medium priority - show after HRM devices

  @override
  Widget? getDeviceIcon(BuildContext context) {
    return const Icon(
      Icons.fitness_center,
      color: Colors.blue,
      size: 16,
    );
  }

  // This is an approximation since the actual check is async
  // We'll use this for synchronous operations like sorting
  @override
  bool isDeviceOfThisType(BluetoothDevice device, List<ScanResult> scanResults) {
    // Look for common FTMS service UUIDs in advertisement data
    final scanResult = scanResults.firstWhere(
      (result) => result.device.remoteId == device.remoteId,
      orElse: () => ScanResult(
        device: device,
        advertisementData: AdvertisementData(
          advName: '',
          connectable: false,
          manufacturerData: {},
          serviceData: {},
          serviceUuids: [],
          txPowerLevel: null,
          appearance: null,
        ),
        rssi: 0,
        timeStamp: DateTime.now(),
      ),
    );

    // Check for common FTMS service UUIDs
    const shortFtmsServiceUuid = "1826";

    // Check in service UUIDs if available
    final serviceUuids = scanResult.advertisementData.serviceUuids;
    for (final uuid in serviceUuids) {
      final uuidString = uuid.toString().toUpperCase();
      if (uuidString.contains(shortFtmsServiceUuid)) {
        return true;
      }
    }

    // Check in manufacturer data as fallback
    // This is less reliable but some devices advertise this way
    return false;
  }

  /// Asynchronous check if a device is an FTMS device
  /// This is more accurate but can't be used for sorting
  Future<bool> isFtmsDevice(BluetoothDevice device) {
    return FTMS.isBluetoothDeviceFTMSDevice(device);
  }

  @override
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await FTMS.connectToFTMSDevice(device);
      
      // Start listening to device data to detect machine type
      startMachineTypeDetection(device);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Start listening to FTMS device data to detect and store machine type
  void startMachineTypeDetection(BluetoothDevice device) {
    // Listen to FTMS data stream to detect machine type
    FTMS.useDeviceDataCharacteristic(
      device,
      (DeviceData data) {
        // Extract machine type from device data
        final machineType = DeviceType.fromFtms(data.deviceDataType);
        
        // Update the connected device with the detected machine type
        final connectedDevicesService = ConnectedDevicesService();
        connectedDevicesService.updateDeviceFtmsMachineType(device.remoteId.str, machineType);
        
        // Also forward to the global FTMS bloc for other consumers
        ftmsBloc.ftmsDeviceDataControllerSink.add(data);
      },
    );
  }

  @override
  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    await FTMS.disconnectFromFTMSDevice(device);
  }

  @override
  Widget? getDevicePage(BluetoothDevice device) {
    // Return null since we use navigation callback instead to avoid circular dependencies
    return null;
  }

  @override
  void Function(BuildContext context, BluetoothDevice device)? getNavigationCallback() {
    return DeviceNavigationRegistry().getNavigationCallback('FTMS');
  }

  @override
  List<Widget> getConnectedActions(BluetoothDevice device, BuildContext context) {
    // Use the parent class implementation which will check for navigation callback
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
