import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'device_type_service.dart';
import '../cadence_service.dart';

/// Service for Cadence Sensor devices (example for future extensibility)
class CadenceDeviceService extends DeviceTypeService {
  static final CadenceDeviceService _instance = CadenceDeviceService._internal();
  factory CadenceDeviceService() => _instance;
  CadenceDeviceService._internal();

  final CadenceService _cadenceService = CadenceService();

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
    return CadenceService.isCadenceDevice(device, scanResults);
  }

  @override
  Future<bool> connectToDevice(BluetoothDevice device) async {
    return await _cadenceService.connectToCadenceDevice(device);
  }

  @override
  Future<void> disconnectFromDevice(BluetoothDevice device) async {
    await _cadenceService.disconnectCadenceDevice();
  }

  @override
  Widget? getDevicePage(BluetoothDevice device) {
    // Cadence devices don't have a dedicated page, they show data in the cadence status widget
    return null;
  }

  @override
  List<Widget> getConnectedActions(BluetoothDevice device, BuildContext context) {
    // Cadence devices only show cadence data, no "Open" button needed
    return [];
  }
}
