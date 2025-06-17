import 'package:flutter_ftms/flutter_ftms.dart';

/// Facade interface for FTMS operations to enable testing
abstract class FtmsFacade {
  /// Check if a Bluetooth device is an FTMS device
  Future<bool> isBluetoothDeviceFTMSDevice(BluetoothDevice device);
}

/// Production implementation of FTMS facade
class FtmsFacadeImpl implements FtmsFacade {
  @override
  Future<bool> isBluetoothDeviceFTMSDevice(BluetoothDevice device) {
    return FTMS.isBluetoothDeviceFTMSDevice(device);
  }
}
