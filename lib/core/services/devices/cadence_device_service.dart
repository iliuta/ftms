import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'device_type_service.dart';

/// Service for Cadence Sensor devices (example for future extensibility)
class CadenceDeviceService extends DeviceTypeService {
  static final CadenceDeviceService _instance = CadenceDeviceService._internal();
  factory CadenceDeviceService() => _instance;
  CadenceDeviceService._internal();

  @override
  String get deviceTypeName => 'Cadence';

  @override
  int get listPriority => 30; // Lower priority than HRM and FTMS

  @override
  Widget? getDeviceIcon(BuildContext context) {
    return const Icon(
      Icons.pedal_bike,
      color: Colors.orange,
      size: 16,
    );
  }

  @override
  bool isDeviceOfThisType(BluetoothDevice device, List<ScanResult> scanResults) {
    // Look for cadence sensor service UUID
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

    // Check for cadence sensor service UUIDs
    const shortCadenceServiceUuid = "1816";

    final serviceUuids = scanResult.advertisementData.serviceUuids;
    for (final uuid in serviceUuids) {
      final uuidString = uuid.toString().toUpperCase();
      if (uuidString.contains(shortCadenceServiceUuid)) {
        return true;
      }
    }

    return false;
  }

  @override
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      // TODO: Implement cadence sensor connection logic
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
    // TODO: Create a dedicated cadence sensor page
    return null;
  }

  @override
  List<Widget> getConnectedActions(BluetoothDevice device, BuildContext context) {
    // Cadence sensors typically just provide data, no dedicated page needed
    return [];
  }
}
