import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'device_type_service.dart';

/// Service for Power Meter devices (example for future extensibility)
class PowerMeterDeviceService extends DeviceTypeService {
  static final PowerMeterDeviceService _instance = PowerMeterDeviceService._internal();
  factory PowerMeterDeviceService() => _instance;
  PowerMeterDeviceService._internal();

  @override
  String get deviceTypeName => 'Power Meter';

  @override
  int get listPriority => 15; // Higher priority than FTMS, lower than HRM

  @override
  Widget? getDeviceIcon(BuildContext context) {
    return const Icon(
      Icons.bolt,
      color: Colors.amber,
      size: 16,
    );
  }

  @override
  bool isDeviceOfThisType(BluetoothDevice device, List<ScanResult> scanResults) {
    // Look for power meter service UUID
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

    // Check for power meter service UUIDs
    const shortPowerServiceUuid = "1818";

    final serviceUuids = scanResult.advertisementData.serviceUuids;
    for (final uuid in serviceUuids) {
      final uuidString = uuid.toString().toUpperCase();
      if (uuidString.contains(shortPowerServiceUuid)) {
        return true;
      }
    }

    return false;
  }

  @override
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      // TODO: Implement power meter connection logic
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    await device.disconnect();
  }

  @override
  Widget? getDevicePage(BluetoothDevice device) {
    // TODO: Create a dedicated power meter page
    return null;
  }

  @override
  List<Widget> getConnectedActions(BluetoothDevice device, BuildContext context) {
    // Power meters typically just provide data, no dedicated page needed
    return [];
  }
}
