import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:ftms/core/services/devices/device_type_manager.dart';
import 'package:ftms/core/services/devices/device_type_service.dart';

void main() {
  group('DeviceTypeManager', () {
    late DeviceTypeManager manager;
    late MockBluetoothDevice mockDevice;
    late List<ScanResult> mockScanResults;

    setUp(() {
      manager = DeviceTypeManager();
      mockDevice = MockBluetoothDevice();
      mockScanResults = <ScanResult>[MockScanResult(mockDevice)];
    });

    test('should be a singleton', () {
      final manager1 = DeviceTypeManager();
      final manager2 = DeviceTypeManager();
      expect(manager1, same(manager2));
    });

    test('should return device services list', () {
      final services = manager.deviceServices;
      expect(services, isNotEmpty);
      expect(services.length, equals(2)); // HRM and FTMS services
    });

    test('should return immutable device services list', () {
      final services = manager.deviceServices;
      expect(() => services.add(MockDeviceTypeService()), throwsUnsupportedError);
    });

    test('should find primary device service', () {
      final service = manager.getDeviceService(mockDevice, mockScanResults);
      expect(service, isNotNull);
      expect(service!.deviceTypeName, equals('HRM')); // HRM has higher priority
    });

    test('should return null when no service matches', () {
      final nonMatchingDevice = MockBluetoothDevice(id: '11:11:11:11:11:11');
      // Create scan results that include the device but with no matching service UUIDs
      final nonMatchingScanResults = <ScanResult>[MockScanResult(nonMatchingDevice, serviceUuids: ['ffff'])];
      
      final service = manager.getDeviceService(nonMatchingDevice, nonMatchingScanResults);
      expect(service, isNull);
    });

    test('should get all matching services', () {
      // Create a device that matches multiple services
      final multiServiceDevice = MockBluetoothDevice(id: '22:22:22:22:22:22');
      final multiServiceScanResults = <ScanResult>[
        MockScanResult(
          multiServiceDevice, 
          serviceUuids: ['180d', '1826'] // Both HRM and FTMS UUIDs
        )
      ];
      
      final services = manager.getAllMatchingServices(multiServiceDevice, multiServiceScanResults);
      expect(services, hasLength(2));
      expect(services.map((s) => s.deviceTypeName), containsAll(['HRM', 'FTMS']));
    });

    test('should return empty list when no services match', () {
      final nonMatchingDevice = MockBluetoothDevice(id: '11:11:11:11:11:11');
      // Create scan results that include the device but with no matching service UUIDs
      final nonMatchingScanResults = <ScanResult>[MockScanResult(nonMatchingDevice, serviceUuids: ['ffff'])];
      
      final services = manager.getAllMatchingServices(nonMatchingDevice, nonMatchingScanResults);
      expect(services, isEmpty);
    });

    group('sortDevicesByPriority', () {
      test('should sort devices by service priority', () {
        final hrmDevice = MockBluetoothDevice(id: '11:11:11:11:11:11');
        final ftmsDevice = MockBluetoothDevice(id: '22:22:22:22:22:22');
        final unknownDevice = MockBluetoothDevice(id: '33:33:33:33:33:33');
        
        final scanResults = <ScanResult>[
          MockScanResult(ftmsDevice, serviceUuids: ['1826'], rssi: -40),
          MockScanResult(unknownDevice, serviceUuids: [], rssi: -30),
          MockScanResult(hrmDevice, serviceUuids: ['180d'], rssi: -50),
        ];
        
        final sorted = manager.sortDevicesByPriority(scanResults);
        
        expect(sorted[0].device.remoteId.str, equals('11:11:11:11:11:11')); // HRM first
        expect(sorted[1].device.remoteId.str, equals('22:22:22:22:22:22')); // FTMS second
        expect(sorted[2].device.remoteId.str, equals('33:33:33:33:33:33')); // Unknown last
      });

      test('should sort by signal strength when no services match', () {
        final device1 = MockBluetoothDevice(id: '11:11:11:11:11:11');
        final device2 = MockBluetoothDevice(id: '22:22:22:22:22:22');
        
        final scanResults = <ScanResult>[
          MockScanResult(device1, serviceUuids: ['ffff'], rssi: -60), // Non-matching service
          MockScanResult(device2, serviceUuids: ['eeee'], rssi: -40), // Non-matching service
        ];
        
        final sorted = manager.sortDevicesByPriority(scanResults);
        
        expect(sorted[0].device.remoteId.str, equals('22:22:22:22:22:22')); // Better signal first
        expect(sorted[1].device.remoteId.str, equals('11:11:11:11:11:11'));
      });

      test('should sort by signal strength when same priority', () {
        final ftmsDevice1 = MockBluetoothDevice(id: '11:11:11:11:11:11');
        final ftmsDevice2 = MockBluetoothDevice(id: '22:22:22:22:22:22');
        
        final scanResults = <ScanResult>[
          MockScanResult(ftmsDevice1, serviceUuids: ['1826'], rssi: -60),
          MockScanResult(ftmsDevice2, serviceUuids: ['1826'], rssi: -40),
        ];
        
        final sorted = manager.sortDevicesByPriority(scanResults);
        
        expect(sorted[0].device.remoteId.str, equals('22:22:22:22:22:22')); // Better signal first
        expect(sorted[1].device.remoteId.str, equals('11:11:11:11:11:11'));
      });
    });

    group('registerDeviceService', () {
      test('should add new device service', () {
        final initialCount = manager.deviceServices.length;
        final newService = MockDeviceTypeService();
        
        manager.registerDeviceService(newService);
        
        expect(manager.deviceServices.length, equals(initialCount + 1));
        expect(manager.deviceServices, contains(newService));
      });

      test('should sort services by priority after registration', () {
        final highPriorityService = MockDeviceTypeService(priority: 5);
        final lowPriorityService = MockDeviceTypeService(priority: 50);
        
        manager.registerDeviceService(lowPriorityService);
        manager.registerDeviceService(highPriorityService);
        
        final services = manager.deviceServices;
        final highPriorityIndex = services.indexOf(highPriorityService);
        final lowPriorityIndex = services.indexOf(lowPriorityService);
        
        expect(highPriorityIndex, lessThan(lowPriorityIndex));
      });
    });
  });
}

class MockBluetoothDevice extends BluetoothDevice {
  MockBluetoothDevice({String id = '00:00:00:00:00:00'}) 
      : super(remoteId: DeviceIdentifier(id));
}

class MockScanResult extends ScanResult {
  MockScanResult(
    BluetoothDevice device, {
    List<String> serviceUuids = const ['180d'], // Default to HRM service UUID
    super.rssi = -50,
  }) : super(
    device: device,
    advertisementData: AdvertisementData(
      advName: 'Test Device',
      connectable: true,
      manufacturerData: {},
      serviceData: {},
      serviceUuids: serviceUuids.map((uuid) => Guid(uuid)).toList(),
      txPowerLevel: null,
      appearance: null,
    ),
    timeStamp: DateTime.now(),
  );
}

class MockDeviceTypeService extends DeviceTypeService {
  final int priority;
  final String name;

  MockDeviceTypeService({
    this.priority = 100,
    this.name = 'Mock Device',
  });

  @override
  String get deviceTypeName => name;

  @override
  int get listPriority => priority;

  @override
  Widget? getDeviceIcon(BuildContext context) => const Icon(Icons.device_unknown);

  @override
  bool isDeviceOfThisType(BluetoothDevice device, List<ScanResult> scanResults) => false;

  @override
  Future<bool> connectToDevice(BluetoothDevice device) async => true;

  @override
  Future<void> disconnectFromDevice(BluetoothDevice device) async {}

  @override
  Widget? getDevicePage(BluetoothDevice device) => null;
}
