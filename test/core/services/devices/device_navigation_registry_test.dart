import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:ftms/core/services/devices/device_navigation_registry.dart';

void main() {
  group('DeviceNavigationRegistry', () {
    late DeviceNavigationRegistry registry;
    late MockBluetoothDevice mockDevice;

    setUp(() {
      registry = DeviceNavigationRegistry();
      registry.clear(); // Clear any previous registrations
      mockDevice = MockBluetoothDevice();
    });

    tearDown(() {
      registry.clear();
    });

    test('should be a singleton', () {
      final registry1 = DeviceNavigationRegistry();
      final registry2 = DeviceNavigationRegistry();
      expect(registry1, same(registry2));
    });

    test('should register and retrieve navigation callback', () {
      bool callbackCalled = false;
      void testCallback(BuildContext context, BluetoothDevice device) {
        callbackCalled = true;
      }

      registry.registerNavigation('FTMS', testCallback);
      
      final retrievedCallback = registry.getNavigationCallback('FTMS');
      expect(retrievedCallback, isNotNull);
      
      // Test that the callback works
      retrievedCallback!(MockBuildContext(), mockDevice);
      expect(callbackCalled, isTrue);
    });

    test('should return null for unregistered device type', () {
      final callback = registry.getNavigationCallback('UNKNOWN');
      expect(callback, isNull);
    });

    test('should overwrite existing registration', () {
      bool firstCallbackCalled = false;
      bool secondCallbackCalled = false;

      void firstCallback(BuildContext context, BluetoothDevice device) {
        firstCallbackCalled = true;
      }

      void secondCallback(BuildContext context, BluetoothDevice device) {
        secondCallbackCalled = true;
      }

      registry.registerNavigation('FTMS', firstCallback);
      registry.registerNavigation('FTMS', secondCallback);
      
      final retrievedCallback = registry.getNavigationCallback('FTMS');
      retrievedCallback!(MockBuildContext(), mockDevice);
      
      expect(firstCallbackCalled, isFalse);
      expect(secondCallbackCalled, isTrue);
    });

    test('should clear all registrations', () {
      void testCallback(BuildContext context, BluetoothDevice device) {}

      registry.registerNavigation('FTMS', testCallback);
      registry.registerNavigation('HRM', testCallback);
      
      expect(registry.getNavigationCallback('FTMS'), isNotNull);
      expect(registry.getNavigationCallback('HRM'), isNotNull);
      
      registry.clear();
      
      expect(registry.getNavigationCallback('FTMS'), isNull);
      expect(registry.getNavigationCallback('HRM'), isNull);
    });

    test('should handle multiple device types', () {
      bool ftmsCallbackCalled = false;
      bool hrmCallbackCalled = false;

      void ftmsCallback(BuildContext context, BluetoothDevice device) {
        ftmsCallbackCalled = true;
      }

      void hrmCallback(BuildContext context, BluetoothDevice device) {
        hrmCallbackCalled = true;
      }

      registry.registerNavigation('FTMS', ftmsCallback);
      registry.registerNavigation('HRM', hrmCallback);
      
      final ftmsRetrieved = registry.getNavigationCallback('FTMS');
      final hrmRetrieved = registry.getNavigationCallback('HRM');
      
      ftmsRetrieved!(MockBuildContext(), mockDevice);
      hrmRetrieved!(MockBuildContext(), mockDevice);
      
      expect(ftmsCallbackCalled, isTrue);
      expect(hrmCallbackCalled, isTrue);
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
