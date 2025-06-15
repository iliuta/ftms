import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:ftms/core/services/connected_devices_service.dart';
import 'package:ftms/core/services/devices/device_type_service.dart';

// Mock classes for testing
class MockBluetoothDevice extends BluetoothDevice {
  MockBluetoothDevice({String id = '00:00:00:00:00:00', String name = 'Test Device'}) 
      : _name = name,
        super(remoteId: DeviceIdentifier(id));
  
  final String _name;
  
  @override
  String get platformName => _name;
}

class MockDeviceTypeService extends DeviceTypeService {
  @override
  String get deviceTypeName => 'Mock';

  @override
  int get listPriority => 100;

  @override
  Widget? getDeviceIcon(BuildContext context) => null;

  @override
  bool isDeviceOfThisType(BluetoothDevice device, List<ScanResult> scanResults) => true;

  @override
  Future<bool> connectToDevice(BluetoothDevice device) async => true;

  @override
  Future<void> disconnectFromDevice(BluetoothDevice device) async {}

  @override
  Widget? getDevicePage(BluetoothDevice device) => null;
}

void main() {
  group('ConnectedDevicesService', () {
    late ConnectedDevicesService service;

    setUp(() {
      service = ConnectedDevicesService();
    });

    test('should be a singleton', () {
      final service1 = ConnectedDevicesService();
      final service2 = ConnectedDevicesService();
      expect(service1, same(service2));
    });

    test('should dispose properly', () {
      expect(() => service.dispose(), returnsNormally);
    });

    test('should handle FTMS machine type operations', () {
      // Test updateDeviceFtmsMachineType with non-existent device
      expect(() => service.updateDeviceFtmsMachineType('non-existent', 'DeviceDataType.rower'), 
             returnsNormally);

      // Test that method doesn't throw errors when called multiple times with same value
      expect(() => service.updateDeviceFtmsMachineType('non-existent', 'DeviceDataType.rower'), 
             returnsNormally);
      expect(() => service.updateDeviceFtmsMachineType('non-existent', 'DeviceDataType.indoorBike'), 
             returnsNormally);
    });
  });

  group('ConnectedDevice', () {
    late MockBluetoothDevice mockDevice;
    late MockDeviceTypeService mockService;

    setUp(() {
      mockDevice = MockBluetoothDevice(name: 'Test Device');
      mockService = MockDeviceTypeService();
    });

    test('should create connected device correctly', () {
      final connectedDevice = ConnectedDevice(
        device: mockDevice,
        deviceType: 'FTMS',
        service: mockService,
        connectedAt: DateTime.now(),
      );

      expect(connectedDevice.name, equals('Test Device'));
      expect(connectedDevice.deviceType, equals('FTMS'));
      expect(connectedDevice.id, equals('00:00:00:00:00:00'));
      expect(connectedDevice.connectionState, equals(BluetoothConnectionState.connected));
    });

    test('should handle unknown device name', () {
      final unknownDevice = MockBluetoothDevice(name: '');
      final connectedDevice = ConnectedDevice(
        device: unknownDevice,
        deviceType: 'HRM',
        service: mockService,
        connectedAt: DateTime.now(),
      );

      expect(connectedDevice.name, equals('(unknown device)'));
    });

    test('should compare devices by ID', () {
      final device1 = ConnectedDevice(
        device: MockBluetoothDevice(id: '11:11:11:11:11:11'),
        deviceType: 'FTMS',
        service: mockService,
        connectedAt: DateTime.now(),
      );

      final device2 = ConnectedDevice(
        device: MockBluetoothDevice(id: '11:11:11:11:11:11'),
        deviceType: 'HRM', // Different type, same ID
        service: mockService,
        connectedAt: DateTime.now(),
      );

      final device3 = ConnectedDevice(
        device: MockBluetoothDevice(id: '22:22:22:22:22:22'),
        deviceType: 'FTMS',
        service: mockService,
        connectedAt: DateTime.now(),
      );

      expect(device1, equals(device2)); // Same device ID
      expect(device1, isNot(equals(device3))); // Different device ID
    });

    test('should handle FTMS machine type updates', () {
      final connectedDevice = ConnectedDevice(
        device: mockDevice,
        deviceType: 'FTMS',
        service: mockService,
        connectedAt: DateTime.now(),
      );

      // Initially no machine type
      expect(connectedDevice.ftmsMachineType, isNull);

      // Update machine type
      connectedDevice.updateFtmsMachineType('DeviceDataType.rower');
      expect(connectedDevice.ftmsMachineType, equals('DeviceDataType.rower'));

      // Update to different machine type
      connectedDevice.updateFtmsMachineType('DeviceDataType.indoorBike');
      expect(connectedDevice.ftmsMachineType, equals('DeviceDataType.indoorBike'));
    });

    test('should include FTMS machine type in toString', () {
      final connectedDevice = ConnectedDevice(
        device: mockDevice,
        deviceType: 'FTMS',
        service: mockService,
        connectedAt: DateTime.now(),
      );

      // Without machine type
      String result = connectedDevice.toString();
      expect(result, contains('Test Device'));
      expect(result, contains('FTMS'));
      expect(result, contains('ftmsMachineType: null'));

      // With machine type
      connectedDevice.updateFtmsMachineType('DeviceDataType.rower');
      result = connectedDevice.toString();
      expect(result, contains('ftmsMachineType: DeviceDataType.rower'));
    });
  });
}
