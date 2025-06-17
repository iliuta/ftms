import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Facade interface for FlutterBluePlus operations to enable testing
abstract class FlutterBluePlusFacade {
  /// Stream of Bluetooth adapter state changes
  Stream<BluetoothAdapterState> get adapterState;
  
  /// Get list of currently connected devices
  List<BluetoothDevice> get connectedDevices;
}

/// Production implementation of FlutterBluePlus facade
class FlutterBluePlusFacadeImpl implements FlutterBluePlusFacade {
  @override
  Stream<BluetoothAdapterState> get adapterState => FlutterBluePlus.adapterState;
  
  @override
  List<BluetoothDevice> get connectedDevices => FlutterBluePlus.connectedDevices;
}
