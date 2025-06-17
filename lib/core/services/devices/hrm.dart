import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'bt_device.dart';
import 'heart_rate_service.dart';

/// Service for Heart Rate Monitor (HRM) devices
class Hrm extends BTDevice {
  static final Hrm _instance = Hrm._internal();
  factory Hrm() => _instance;
  Hrm._internal();

  final HeartRateService _heartRateService = HeartRateService();

  @override
  String get deviceTypeName => 'HRM';

  @override
  int get listPriority => 10; // High priority - show HRM devices first

  @override
  Widget? getDeviceIcon(BuildContext context) {
    return const Icon(
      Icons.favorite,
      color: Colors.red,
      size: 16,
    );
  }

  @override
  bool isDeviceOfThisType(BluetoothDevice device, List<ScanResult> scanResults) {
    return HeartRateService.isHeartRateDevice(device, scanResults);
  }

  @override
  Future<bool> performConnection(BluetoothDevice device) async {
    return await _heartRateService.connectToHrmDevice(device);
  }

  @override
  Future<void> performDisconnection(BluetoothDevice device) async {
    await _heartRateService.disconnectHrmDevice();
  }

  @override
  Widget? getDevicePage(BluetoothDevice device) {
    // HRM devices don't have a dedicated page, they show data in the HRM status widget
    return null;
  }

  @override
  List<Widget> getConnectedActions(BluetoothDevice device, BuildContext context) {
    // HRM devices only show heart rate data, no "Open" button needed
    return [];
  }
}
