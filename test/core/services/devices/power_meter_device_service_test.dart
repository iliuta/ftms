import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:ftms/core/services/devices/power_meter_device_service.dart';

void main() {
  group('PowerMeterDeviceService', () {
    late PowerMeterDeviceService service;
    late MockBluetoothDevice mockDevice;
    late MockBuildContext mockContext;
    late List<ScanResult> mockScanResults;

    setUp(() {
      service = PowerMeterDeviceService();
      mockDevice = MockBluetoothDevice();
      mockContext = MockBuildContext();
      mockScanResults = <ScanResult>[MockScanResult(mockDevice)];
    });

    test('should be a singleton', () {
      final service1 = PowerMeterDeviceService();
      final service2 = PowerMeterDeviceService();
      expect(service1, same(service2));
    });

    test('should return correct device type name', () {
      expect(service.deviceTypeName, equals('Power Meter'));
    });

    test('should return correct list priority', () {
      expect(service.listPriority, equals(15));
    });

    test('should return bolt icon', () {
      final icon = service.getDeviceIcon(mockContext);
      expect(icon, isA<Icon>());
      
      final iconWidget = icon as Icon;
      expect(iconWidget.icon, equals(Icons.bolt));
      expect(iconWidget.color, equals(Colors.amber));
      expect(iconWidget.size, equals(16));
    });

    group('isDeviceOfThisType', () {
      test('should identify power meter device with service UUID', () {
        final powerMeterScanResults = <ScanResult>[
          MockScanResult(mockDevice, serviceUuids: ['1818']) // Power meter service UUID
        ];
        
        final isPowerMeterDevice = service.isDeviceOfThisType(mockDevice, powerMeterScanResults);
        expect(isPowerMeterDevice, isTrue);
      });

      test('should not identify device without power meter service UUID', () {
        final nonPowerMeterScanResults = <ScanResult>[
          MockScanResult(mockDevice, serviceUuids: ['180d']) // HRM service UUID
        ];
        
        final isPowerMeterDevice = service.isDeviceOfThisType(mockDevice, nonPowerMeterScanResults);
        expect(isPowerMeterDevice, isFalse);
      });

      test('should handle empty service UUIDs', () {
        final emptyScanResults = <ScanResult>[
          MockScanResult(mockDevice, serviceUuids: [])
        ];
        
        final isPowerMeterDevice = service.isDeviceOfThisType(mockDevice, emptyScanResults);
        expect(isPowerMeterDevice, isFalse);
      });

      test('should handle missing scan result for device', () {
        final differentDevice = MockBluetoothDevice(id: '11:11:11:11:11:11');
        
        final isPowerMeterDevice = service.isDeviceOfThisType(differentDevice, mockScanResults);
        expect(isPowerMeterDevice, isFalse);
      });

      test('should be case insensitive for UUID matching', () {
        final powerMeterScanResults = <ScanResult>[
          MockScanResult(mockDevice, serviceUuids: ['1818']) // lowercase
        ];
        
        final isPowerMeterDevice = service.isDeviceOfThisType(mockDevice, powerMeterScanResults);
        expect(isPowerMeterDevice, isTrue);
      });

      test('should match partial UUID in longer string', () {
        final powerMeterScanResults = <ScanResult>[
          MockScanResult(mockDevice, serviceUuids: ['00001818-0000-1000-8000-00805f9b34fb'])
        ];
        
        final isPowerMeterDevice = service.isDeviceOfThisType(mockDevice, powerMeterScanResults);
        expect(isPowerMeterDevice, isTrue);
      });
    });

    test('should connect to power meter device successfully', () async {
      final result = await service.connectToDevice(mockDevice);
      expect(result, isTrue);
    });

    test('should handle connection failure gracefully', () async {
      final failingDevice = FailingMockBluetoothDevice();
      final result = await service.connectToDevice(failingDevice);
      expect(result, isFalse);
    });

    test('should disconnect from power meter device', () async {
      await expectLater(
        service.disconnectFromDevice(mockDevice),
        completes,
      );
    });

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

    test('should have higher priority than FTMS but lower than HRM', () {
      expect(service.listPriority, lessThan(20)); // Less than FTMS (20)
      expect(service.listPriority, greaterThan(10)); // Greater than HRM (10)
    });
  });
}

class MockBluetoothDevice extends BluetoothDevice {
  MockBluetoothDevice({String id = '00:00:00:00:00:00'}) 
      : super(remoteId: DeviceIdentifier(id));

  @override
  Future<void> connect({
    Duration timeout = const Duration(seconds: 35),
    int? mtu = 512,
    bool autoConnect = false,
  }) async {
    // Simulate successful connection
    return;
  }

  @override
  Future<void> disconnect({
    int timeout = 35,
    bool queue = true,
    int androidDelay = 2000,
  }) async {
    // Simulate successful disconnection
    return;
  }
}

class FailingMockBluetoothDevice extends BluetoothDevice {
  FailingMockBluetoothDevice() : super(remoteId: const DeviceIdentifier('ff:ff:ff:ff:ff:ff'));

  @override
  Future<void> connect({
    Duration timeout = const Duration(seconds: 35),
    int? mtu = 512,
    bool autoConnect = false,
  }) async {
    throw Exception('Connection failed');
  }

  @override
  Future<void> disconnect({
    int timeout = 35,
    bool queue = true,
    int androidDelay = 2000,
  }) async {
    throw Exception('Disconnection failed');
  }
}

class MockBuildContext extends BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockScanResult extends ScanResult {
  MockScanResult(
    BluetoothDevice device, {
    List<String> serviceUuids = const [],
  }) : super(
    device: device,
    advertisementData: AdvertisementData(
      advName: 'Test Power Meter Device',
      connectable: true,
      manufacturerData: {},
      serviceData: {},
      serviceUuids: serviceUuids.map((uuid) => Guid(uuid)).toList(),
      txPowerLevel: null,
      appearance: null,
    ),
    rssi: -50,
    timeStamp: DateTime.now(),
  );
}
