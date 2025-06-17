import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:ftms/core/services/devices/bt_device_manager.dart';
import 'package:ftms/core/services/devices/bt_device.dart';
import 'package:ftms/core/services/devices/flutter_blue_plus_facade.dart';
import 'package:ftms/core/services/devices/ftms_facade.dart';

// Generate mocks for testing
@GenerateNiceMocks([
  MockSpec<FlutterBluePlusFacade>(),
  MockSpec<FtmsFacade>(),
  MockSpec<BTDevice>(),
  MockSpec<BluetoothDevice>(),
  MockSpec<BluetoothService>(),
])
import 'bt_device_manager_test.mocks.dart';

void main() {
  group('SupportedBTDeviceManager', () {
    late SupportedBTDeviceManager deviceManager;
    late MockFlutterBluePlusFacade mockFlutterBluePlus;
    late MockFtmsFacade mockFtmsFacade;
    late MockBTDevice mockHrmDevice;
    late MockBTDevice mockCadenceDevice;
    late MockBTDevice mockFtmsDevice;
    late MockBluetoothDevice mockBluetoothDevice1;
    late MockBluetoothDevice mockBluetoothDevice2;
    late StreamController<BluetoothAdapterState> adapterStateController;

    setUp(() {
      // Set up mock facades
      mockFlutterBluePlus = MockFlutterBluePlusFacade();
      mockFtmsFacade = MockFtmsFacade();

      // Set up adapter state controller
      adapterStateController = StreamController<BluetoothAdapterState>.broadcast();
      when(mockFlutterBluePlus.adapterState).thenAnswer((_) => adapterStateController.stream);
      when(mockFlutterBluePlus.connectedDevices).thenReturn([]);

      // Set up mock devices
      mockHrmDevice = MockBTDevice();
      mockCadenceDevice = MockBTDevice();
      mockFtmsDevice = MockBTDevice();

      // Configure mock device properties
      when(mockHrmDevice.deviceTypeName).thenReturn('HRM');
      when(mockHrmDevice.listPriority).thenReturn(1);
      when(mockCadenceDevice.deviceTypeName).thenReturn('Cadence');
      when(mockCadenceDevice.listPriority).thenReturn(2);
      when(mockFtmsDevice.deviceTypeName).thenReturn('FTMS');
      when(mockFtmsDevice.listPriority).thenReturn(3);

      // Set up mock Bluetooth devices
      mockBluetoothDevice1 = MockBluetoothDevice();
      mockBluetoothDevice2 = MockBluetoothDevice();
      when(mockBluetoothDevice1.platformName).thenReturn('Test Device 1');
      when(mockBluetoothDevice1.remoteId).thenReturn(const DeviceIdentifier('11:22:33:44:55:66'));
      when(mockBluetoothDevice2.platformName).thenReturn('Test Device 2');
      when(mockBluetoothDevice2.remoteId).thenReturn(const DeviceIdentifier('AA:BB:CC:DD:EE:FF'));

      // Configure mock connection state streams
      when(mockBluetoothDevice1.connectionState).thenAnswer(
        (_) => Stream.fromIterable([BluetoothConnectionState.connected]),
      );
      when(mockBluetoothDevice2.connectionState).thenAnswer(
        (_) => Stream.fromIterable([BluetoothConnectionState.connected]),
      );

      // Create device manager with injected dependencies
      deviceManager = SupportedBTDeviceManager.forTesting(
        flutterBluePlusFacade: mockFlutterBluePlus,
        ftmsFacade: mockFtmsFacade,
        supportedDevices: [mockHrmDevice, mockCadenceDevice, mockFtmsDevice],
      );
    });

    tearDown(() {
      adapterStateController.close();
      SupportedBTDeviceManager.resetInstance();
    });

    group('Singleton Pattern', () {
      test('should return the same instance', () {
        SupportedBTDeviceManager.resetInstance();
        final instance1 = SupportedBTDeviceManager();
        final instance2 = SupportedBTDeviceManager();
        expect(instance1, same(instance2));
      });
    });

    group('Initialization', () {
      test('should initialize device services', () async {
        await deviceManager.initialize();

        verify(mockHrmDevice.setDeviceManager(deviceManager)).called(1);
        verify(mockCadenceDevice.setDeviceManager(deviceManager)).called(1);
        verify(mockFtmsDevice.setDeviceManager(deviceManager)).called(1);
      });

      test('should listen to adapter state changes', () async {
        await deviceManager.initialize();
        
        verify(mockFlutterBluePlus.adapterState).called(1);
      });

      test('should clear devices when Bluetooth is turned off', () async {
        // Add a mock device first
        deviceManager.addConnectedDevice('test-device', mockHrmDevice);
        expect(deviceManager.allConnectedDevices.length, equals(1));

        await deviceManager.initialize();

        // Simulate Bluetooth turning off
        adapterStateController.add(BluetoothAdapterState.off);
        await Future.delayed(Duration.zero); // Allow stream to process

        expect(deviceManager.allConnectedDevices.length, equals(0));
      });
    });

    group('Device Management', () {
      test('should add connected device to registry', () {
        final deviceId = 'test-device-id';
        
        deviceManager.addConnectedDevice(deviceId, mockHrmDevice);
        
        expect(deviceManager.allConnectedDevices.length, equals(1));
        expect(deviceManager.allConnectedDevices.first, equals(mockHrmDevice));
      });

      test('should remove connected device from registry', () {
        final deviceId = 'test-device-id';
        
        deviceManager.addConnectedDevice(deviceId, mockHrmDevice);
        expect(deviceManager.allConnectedDevices.length, equals(1));
        
        deviceManager.removeConnectedDevice(deviceId);
        expect(deviceManager.allConnectedDevices.length, equals(0));
      });

      test('should notify listeners when devices change', () async {
        List<BTDevice>? capturedDevices;
        final subscription = deviceManager.connectedDevicesStream.listen((devices) {
          capturedDevices = devices;
        });

        deviceManager.addConnectedDevice('test-device', mockHrmDevice);
        await Future.delayed(Duration.zero); // Allow stream to process

        expect(capturedDevices, isNotNull);
        expect(capturedDevices!.length, equals(1));
        expect(capturedDevices!.first, equals(mockHrmDevice));

        await subscription.cancel();
      });
    });

    group('Device Type Detection', () {
      test('should return first matching device service', () {
        when(mockHrmDevice.isDeviceOfThisType(mockBluetoothDevice1, []))
            .thenReturn(true);
        when(mockCadenceDevice.isDeviceOfThisType(mockBluetoothDevice1, []))
            .thenReturn(false);
        when(mockFtmsDevice.isDeviceOfThisType(mockBluetoothDevice1, []))
            .thenReturn(false);

        final result = deviceManager.getBTDevice(mockBluetoothDevice1, []);

        expect(result, equals(mockHrmDevice));
      });

      test('should return null when no device service matches', () {
        when(mockHrmDevice.isDeviceOfThisType(mockBluetoothDevice1, []))
            .thenReturn(false);
        when(mockCadenceDevice.isDeviceOfThisType(mockBluetoothDevice1, []))
            .thenReturn(false);
        when(mockFtmsDevice.isDeviceOfThisType(mockBluetoothDevice1, []))
            .thenReturn(false);

        final result = deviceManager.getBTDevice(mockBluetoothDevice1, []);

        expect(result, isNull);
      });

      test('should return all matching device services', () {
        when(mockHrmDevice.isDeviceOfThisType(mockBluetoothDevice1, []))
            .thenReturn(true);
        when(mockCadenceDevice.isDeviceOfThisType(mockBluetoothDevice1, []))
            .thenReturn(true);
        when(mockFtmsDevice.isDeviceOfThisType(mockBluetoothDevice1, []))
            .thenReturn(false);

        final result = deviceManager.getAllMatchingBTDevices(mockBluetoothDevice1, []);

        expect(result.length, equals(2));
        expect(result, contains(mockHrmDevice));
        expect(result, contains(mockCadenceDevice));
      });
    });

    group('Device Sorting', () {
      test('should sort devices by priority', () {
        final scanResult1 = _createMockScanResult(mockBluetoothDevice1, -50);
        final scanResult2 = _createMockScanResult(mockBluetoothDevice2, -60);
        final scanResults = [scanResult1, scanResult2];

        // Device 1 matches FTMS (priority 3), Device 2 matches HRM (priority 1)
        when(mockHrmDevice.isDeviceOfThisType(mockBluetoothDevice1, scanResults))
            .thenReturn(false);
        when(mockCadenceDevice.isDeviceOfThisType(mockBluetoothDevice1, scanResults))
            .thenReturn(false);
        when(mockFtmsDevice.isDeviceOfThisType(mockBluetoothDevice1, scanResults))
            .thenReturn(true);

        when(mockHrmDevice.isDeviceOfThisType(mockBluetoothDevice2, scanResults))
            .thenReturn(true);
        when(mockCadenceDevice.isDeviceOfThisType(mockBluetoothDevice2, scanResults))
            .thenReturn(false);
        when(mockFtmsDevice.isDeviceOfThisType(mockBluetoothDevice2, scanResults))
            .thenReturn(false);

        final sorted = deviceManager.sortBTDevicesByPriority(scanResults);

        expect(sorted.first.device, equals(mockBluetoothDevice2)); // HRM first (priority 1)
        expect(sorted.last.device, equals(mockBluetoothDevice1)); // FTMS last (priority 3)
      });

      test('should sort by signal strength when priorities are equal', () {
        final scanResult1 = _createMockScanResult(mockBluetoothDevice1, -50); // Stronger signal
        final scanResult2 = _createMockScanResult(mockBluetoothDevice2, -70); // Weaker signal
        final scanResults = [scanResult1, scanResult2];

        // Both devices match HRM (same priority)
        when(mockHrmDevice.isDeviceOfThisType(any, scanResults))
            .thenReturn(true);
        when(mockCadenceDevice.isDeviceOfThisType(any, scanResults))
            .thenReturn(false);
        when(mockFtmsDevice.isDeviceOfThisType(any, scanResults))
            .thenReturn(false);

        final sorted = deviceManager.sortBTDevicesByPriority(scanResults);

        expect(sorted.first.device, equals(mockBluetoothDevice1)); // Stronger signal first
        expect(sorted.last.device, equals(mockBluetoothDevice2)); // Weaker signal last
      });
    });

    group('Device Connection', () {
      test('should connect to device using appropriate service', () async {
        when(mockHrmDevice.isDeviceOfThisType(mockBluetoothDevice1, []))
            .thenReturn(true);
        when(mockHrmDevice.connectToDevice(mockBluetoothDevice1))
            .thenAnswer((_) async => true);

        final result = await deviceManager.connectToDevice(mockBluetoothDevice1, []);

        expect(result, isTrue);
        verify(mockHrmDevice.connectToDevice(mockBluetoothDevice1)).called(1);
      });

      test('should return false when no matching service found', () async {
        when(mockHrmDevice.isDeviceOfThisType(mockBluetoothDevice1, []))
            .thenReturn(false);
        when(mockCadenceDevice.isDeviceOfThisType(mockBluetoothDevice1, []))
            .thenReturn(false);
        when(mockFtmsDevice.isDeviceOfThisType(mockBluetoothDevice1, []))
            .thenReturn(false);

        final result = await deviceManager.connectToDevice(mockBluetoothDevice1, []);

        expect(result, isFalse);
      });
    });

    group('Existing Device Identification', () {
      test('should identify and connect to already connected devices', () async {
        when(mockFlutterBluePlus.connectedDevices)
            .thenReturn([mockBluetoothDevice1, mockBluetoothDevice2]);
        when(mockFtmsFacade.isBluetoothDeviceFTMSDevice(any))
            .thenAnswer((_) async => false);
        when(mockBluetoothDevice1.discoverServices())
            .thenAnswer((_) async => []);
        when(mockBluetoothDevice2.discoverServices())
            .thenAnswer((_) async => []);

        await deviceManager.identifyAndConnectExistingDevices();

        verify(mockFlutterBluePlus.connectedDevices).called(1);
        verify(mockFtmsFacade.isBluetoothDeviceFTMSDevice(mockBluetoothDevice1)).called(1);
        verify(mockFtmsFacade.isBluetoothDeviceFTMSDevice(mockBluetoothDevice2)).called(1);
      });

      test('should connect FTMS device when identified', () async {
        when(mockFlutterBluePlus.connectedDevices)
            .thenReturn([mockBluetoothDevice1]);
        when(mockFtmsFacade.isBluetoothDeviceFTMSDevice(mockBluetoothDevice1))
            .thenAnswer((_) async => true);
        when(mockFtmsDevice.connectToDevice(mockBluetoothDevice1))
            .thenAnswer((_) async => true);

        await deviceManager.identifyAndConnectExistingDevices();

        verify(mockFtmsDevice.connectToDevice(mockBluetoothDevice1)).called(1);
      });

      test('should connect HRM device when service is identified', () async {
        final mockHrmService = MockBluetoothService();
        when(mockHrmService.uuid).thenReturn(Guid('180d')); // Heart Rate Service UUID

        when(mockFlutterBluePlus.connectedDevices)
            .thenReturn([mockBluetoothDevice1]);
        when(mockFtmsFacade.isBluetoothDeviceFTMSDevice(mockBluetoothDevice1))
            .thenAnswer((_) async => false);
        when(mockBluetoothDevice1.discoverServices())
            .thenAnswer((_) async => [mockHrmService]);
        when(mockHrmDevice.connectToDevice(mockBluetoothDevice1))
            .thenAnswer((_) async => true);

        await deviceManager.identifyAndConnectExistingDevices();

        verify(mockHrmDevice.connectToDevice(mockBluetoothDevice1)).called(1);
      });
    });

    group('Device Queries', () {
      test('should return first connected FTMS device', () {
        deviceManager.addConnectedDevice('ftms-1', mockFtmsDevice);
        deviceManager.addConnectedDevice('hrm-1', mockHrmDevice);

        final ftmsDevice = deviceManager.getConnectedFtmsDevice();

        expect(ftmsDevice, equals(mockFtmsDevice));
      });

      test('should return null when no FTMS device connected', () {
        deviceManager.addConnectedDevice('hrm-1', mockHrmDevice);

        final ftmsDevice = deviceManager.getConnectedFtmsDevice();

        expect(ftmsDevice, isNull);
      });

      test('should return all connected devices of specific type', () {
        final mockHrmDevice2 = MockBTDevice();
        when(mockHrmDevice2.deviceTypeName).thenReturn('HRM');

        deviceManager.addConnectedDevice('hrm-1', mockHrmDevice);
        deviceManager.addConnectedDevice('hrm-2', mockHrmDevice2);
        deviceManager.addConnectedDevice('ftms-1', mockFtmsDevice);

        final hrmDevices = deviceManager.getConnectedDevicesOfType('HRM');

        expect(hrmDevices.length, equals(2));
        expect(hrmDevices, contains(mockHrmDevice));
        expect(hrmDevices, contains(mockHrmDevice2));
      });
    });

    group('Error Handling', () {
      test('should handle FTMS identification errors gracefully', () async {
        when(mockFlutterBluePlus.connectedDevices)
            .thenReturn([mockBluetoothDevice1]);
        when(mockFtmsFacade.isBluetoothDeviceFTMSDevice(mockBluetoothDevice1))
            .thenThrow(Exception('FTMS check failed'));
        when(mockBluetoothDevice1.discoverServices())
            .thenAnswer((_) async => []);

        // Should not throw
        await deviceManager.identifyAndConnectExistingDevices();

        verify(mockBluetoothDevice1.discoverServices()).called(1);
      });

      test('should handle service discovery errors gracefully', () async {
        when(mockFlutterBluePlus.connectedDevices)
            .thenReturn([mockBluetoothDevice1]);
        when(mockFtmsFacade.isBluetoothDeviceFTMSDevice(mockBluetoothDevice1))
            .thenAnswer((_) async => false);
        when(mockBluetoothDevice1.discoverServices())
            .thenThrow(Exception('Service discovery failed'));

        // Should not throw
        await deviceManager.identifyAndConnectExistingDevices();

        verify(mockFtmsFacade.isBluetoothDeviceFTMSDevice(mockBluetoothDevice1)).called(1);
      });
    });
  });
}

// Helper function to create mock ScanResult
ScanResult _createMockScanResult(BluetoothDevice device, int rssi) {
  return ScanResult(
    device: device,
    advertisementData: AdvertisementData(
      advName: device.platformName,
      connectable: true,
      manufacturerData: {},
      serviceData: {},
      serviceUuids: [],
      txPowerLevel: null,
      appearance: null,
    ),
    rssi: rssi,
    timeStamp: DateTime.now(),
  );
}
