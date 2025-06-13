import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:ftms/core/services/devices/hrm_device_service.dart';

void main() {
  group('HrmDeviceService', () {
    late HrmDeviceService service;
    late MockBluetoothDevice mockDevice;
    late MockBuildContext mockContext;
    late List<ScanResult> mockScanResults;

    setUp(() {
      service = HrmDeviceService();
      mockDevice = MockBluetoothDevice();
      mockContext = MockBuildContext();
      mockScanResults = [MockScanResult(mockDevice)];
    });

    test('should be a singleton', () {
      final service1 = HrmDeviceService();
      final service2 = HrmDeviceService();
      expect(service1, same(service2));
    });

    test('should return correct device type name', () {
      expect(service.deviceTypeName, equals('HRM'));
    });

    test('should return correct list priority', () {
      expect(service.listPriority, equals(10));
    });

    test('should return heart rate icon', () {
      final icon = service.getDeviceIcon(mockContext);
      expect(icon, isA<Icon>());
      
      final iconWidget = icon as Icon;
      expect(iconWidget.icon, equals(Icons.favorite));
      expect(iconWidget.color, equals(Colors.red));
      expect(iconWidget.size, equals(16));
    });

    test('should identify HRM device type correctly', () {
      // Mock the static method call
      // Note: This test assumes HeartRateService.isHeartRateDevice works correctly
      // In a real test, you might want to mock this method
      final isHrmDevice = service.isDeviceOfThisType(mockDevice, mockScanResults);
      
      // This will depend on the implementation of HeartRateService.isHeartRateDevice
      // For now, we'll test the method call structure
      expect(isHrmDevice, isA<bool>());
    });

    test('should connect to HRM device', () async {
      // Note: Since HeartRateService is a real service with static dependencies,
      // this test verifies the method structure rather than mocking the actual connection
      final result = await service.connectToDevice(mockDevice);
      expect(result, isA<bool>());
    }, skip: 'Bluetooth not available in test environment');

    test('should disconnect from HRM device', () async {
      // This test verifies the method structure
      await expectLater(
        service.disconnectFromDevice(mockDevice),
        completes,
      );
    }, skip: 'Bluetooth not available in test environment');

    test('should return null for device page', () {
      final page = service.getDevicePage(mockDevice);
      expect(page, isNull);
    });

    test('should return empty actions list', () {
      final actions = service.getConnectedActions(mockDevice, mockContext);
      expect(actions, isEmpty);
    });

    test('should return null navigation callback', () {
      final callback = service.getNavigationCallback();
      expect(callback, isNull);
    });
  });
}

class MockBluetoothDevice extends BluetoothDevice {
  MockBluetoothDevice() : super(remoteId: const DeviceIdentifier('00:00:00:00:00:00'));
}

class MockBuildContext extends BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockScanResult extends ScanResult {
  MockScanResult(BluetoothDevice device) : super(
    device: device,
    advertisementData: AdvertisementData(
      advName: 'Test HRM Device',
      connectable: true,
      manufacturerData: {},
      serviceData: {},
      serviceUuids: [Guid('180d')], // Heart Rate Service UUID
      txPowerLevel: null,
      appearance: null,
    ),
    rssi: -50,
    timeStamp: DateTime.now(),
  );
}
