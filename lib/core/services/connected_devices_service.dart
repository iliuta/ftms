import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import 'package:ftms/core/models/device_types.dart';
import '../utils/logger.dart';
import 'devices/device_type_manager.dart';
import 'devices/device_type_service.dart';
import 'devices/ftms_device_service.dart';

/// Model representing a connected device with its metadata
class ConnectedDevice {
  final BluetoothDevice device;
  final String deviceType;
  final DeviceTypeService service;
  final DateTime connectedAt;
  BluetoothConnectionState connectionState;
  DeviceType? ftmsMachineType;

  ConnectedDevice({
    required this.device,
    required this.deviceType,
    required this.service,
    required this.connectedAt,
    this.connectionState = BluetoothConnectionState.connected,
    this.ftmsMachineType,
  });

  String get name => device.platformName.isEmpty ? '(unknown device)' : device.platformName;
  String get id => device.remoteId.str;

  /// Update the FTMS machine type for this device
  void updateFtmsMachineType(DeviceType deviceType) {
    ftmsMachineType = deviceType;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectedDevice &&
          runtimeType == other.runtimeType &&
          device.remoteId == other.device.remoteId;

  @override
  int get hashCode => device.remoteId.hashCode;

  @override
  String toString() => 'ConnectedDevice(name: $name, type: $deviceType, state: $connectionState, ftmsMachineType: $ftmsMachineType)';
}

/// Service for managing all connected Bluetooth devices throughout the application lifetime
class ConnectedDevicesService {
  static final ConnectedDevicesService _instance = ConnectedDevicesService._internal();
  factory ConnectedDevicesService() => _instance;
  ConnectedDevicesService._internal();

  final DeviceTypeManager _deviceTypeManager = DeviceTypeManager();
  final Map<String, ConnectedDevice> _connectedDevices = {};
  final StreamController<List<ConnectedDevice>> _devicesController = 
      StreamController<List<ConnectedDevice>>.broadcast();
  
  Timer? _periodicCheck;
  final List<StreamSubscription> _connectionSubscriptions = [];

  /// Stream of connected devices updates
  Stream<List<ConnectedDevice>> get devicesStream => _devicesController.stream;

  /// Current list of connected devices
  List<ConnectedDevice> get connectedDevices => List.unmodifiable(_connectedDevices.values);


  /// Initialize the service and start monitoring
  Future<void> initialize() async {
    logger.i('Initializing ConnectedDevicesService...');
    
    // Check for already connected devices
    await _updateConnectedDevices();
    
    // Start periodic checking
    _startPeriodicCheck();
    
    // Listen to adapter state changes
    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.off) {
        _clearAllDevices();
      }
    });
    
    logger.i('ConnectedDevicesService initialized with ${_connectedDevices.length} devices');
  }

  /// Manually add a device when connection is established
  Future<void> addConnectedDevice(BluetoothDevice device, List<ScanResult> scanResults) async {
    logger.i('🔄 addConnectedDevice called for ${device.platformName}');
    
    final deviceService = _deviceTypeManager.getDeviceService(device, scanResults);
    if (deviceService == null) {
      logger.w('❌ No device service found for ${device.platformName}');
      return;
    }
    
    logger.i('✅ Found device service: ${deviceService.deviceTypeName} for ${device.platformName}');

    final connectedDevice = ConnectedDevice(
      device: device,
      deviceType: deviceService.deviceTypeName,
      service: deviceService,
      connectedAt: DateTime.now(),
    );

    _connectedDevices[device.remoteId.str] = connectedDevice;
    logger.i('📱 Device added to _connectedDevices map: ${device.remoteId.str}');
    
    // Subscribe to connection state changes
    _subscribeToDeviceConnection(connectedDevice);
    logger.i('🔔 Subscribed to connection state changes');
    
    _notifyDevicesChanged();
    logger.i('✅ Added connected device: ${connectedDevice.name} (${connectedDevice.deviceType}) - Total devices: ${_connectedDevices.length}');
  }

  /// Manually add a device with known type and service
  void _addConnectedDeviceWithService(BluetoothDevice device, String deviceType, DeviceTypeService service) {
    logger.i('🔄 addConnectedDeviceWithService called for ${device.platformName} type: $deviceType');
    
    final connectedDevice = ConnectedDevice(
      device: device,
      deviceType: deviceType,
      service: service,
      connectedAt: DateTime.now(),
    );

    _connectedDevices[device.remoteId.str] = connectedDevice;
    logger.i('📱 Device added to _connectedDevices map: ${device.remoteId.str}');
    
    // Subscribe to connection state changes
    _subscribeToDeviceConnection(connectedDevice);
    logger.i('🔔 Subscribed to connection state changes');
    
    _notifyDevicesChanged();
    logger.i('✅ Added connected device: ${connectedDevice.name} (${connectedDevice.deviceType}) - Total devices: ${_connectedDevices.length}');
  }

  /// Remove a device when disconnected
  void removeConnectedDevice(String deviceId) {
    final removedDevice = _connectedDevices.remove(deviceId);
    if (removedDevice != null) {
      _notifyDevicesChanged();
      logger.i('Removed connected device: ${removedDevice.name} (${removedDevice.deviceType})');
    }
  }

  /// Update connection state for a device
  void updateDeviceConnectionState(String deviceId, BluetoothConnectionState state) {
    final device = _connectedDevices[deviceId];
    if (device != null) {
      device.connectionState = state;
      
      if (state == BluetoothConnectionState.disconnected) {
        removeConnectedDevice(deviceId);
      } else {
        _notifyDevicesChanged();
      }
    }
  }



  /// Update the FTMS machine type for a connected device
  void updateDeviceFtmsMachineType(String deviceId, DeviceType machineType) {
    final device = _connectedDevices[deviceId];
    if (device != null && device.deviceType == 'FTMS') {
      // Only update and log if the machine type has actually changed
      if (device.ftmsMachineType != machineType) {
        device.updateFtmsMachineType(machineType);
        _notifyDevicesChanged();
        logger.i('Updated FTMS machine type for ${device.name}: $machineType');
      }
    }
  }

  void _startPeriodicCheck() {
    _periodicCheck?.cancel();
    _periodicCheck = Timer.periodic(const Duration(seconds: 5), (_) {
      _updateConnectedDevices();
    });
  }

  Future<void> _updateConnectedDevices() async {
    try {
      final connectedBtDevices = FlutterBluePlus.connectedDevices;
      final currentDeviceIds = _connectedDevices.keys.toSet();
      final actualDeviceIds = connectedBtDevices.map((d) => d.remoteId.str).toSet();

      // Remove devices that are no longer connected
      final disconnectedIds = currentDeviceIds.difference(actualDeviceIds);
      for (final deviceId in disconnectedIds) {
        removeConnectedDevice(deviceId);
      }

      // Add newly connected devices (that we might have missed)
      final newDeviceIds = actualDeviceIds.difference(currentDeviceIds);
      for (final deviceId in newDeviceIds) {
        final device = connectedBtDevices.firstWhere((d) => d.remoteId.str == deviceId);
        
        logger.i('🔍 Found newly connected device: ${device.platformName} (${device.remoteId.str})');
        
        // For already-connected devices, we don't have advertisement data
        // so we need to use async methods to identify device types
        await _identifyAndAddConnectedDevice(device);
      }
    } catch (e) {
      logger.e('Error updating connected devices: $e');
    }
  }

  void _subscribeToDeviceConnection(ConnectedDevice connectedDevice) {
    final subscription = connectedDevice.device.connectionState.listen((state) {
      updateDeviceConnectionState(connectedDevice.id, state);
    });
    
    _connectionSubscriptions.add(subscription);
  }

  void _clearAllDevices() {
    _connectedDevices.clear();
    _notifyDevicesChanged();
    logger.i('Cleared all connected devices');
  }

  void _notifyDevicesChanged() {
    _devicesController.add(connectedDevices);
  }

  /// Dispose of the service
  void dispose() {
    _periodicCheck?.cancel();
    for (final subscription in _connectionSubscriptions) {
      subscription.cancel();
    }
    _connectionSubscriptions.clear();
    _devicesController.close();
    logger.i('ConnectedDevicesService disposed');
  }

  /// Identify the type of an already-connected device and add it to our tracking
  Future<void> _identifyAndAddConnectedDevice(BluetoothDevice device) async {
    logger.i('🔄 Identifying device type for ${device.platformName}...');
    
    // Check each supported device service type
    
    // 1. Check if it's an FTMS device
    try {
      final isFtmsDevice = await FTMS.isBluetoothDeviceFTMSDevice(device);
      if (isFtmsDevice) {
        logger.i('✅ Device confirmed as FTMS via async check');
        final ftmsService = _deviceTypeManager.deviceServices
            .whereType<FtmsDeviceService>()
            .first;
        
        _addConnectedDeviceWithService(device, 'FTMS', ftmsService);
        
        // Start machine type detection for automatically discovered FTMS devices
        ftmsService.startMachineTypeDetection(device);
        return;
      }
    } catch (e) {
      logger.w('❌ Error checking FTMS device: $e');
    }
    
    // 2. Check if it's an HRM or Cadence device using service discovery
    try {
      final services = await device.discoverServices();
      
      // Check for Heart Rate service UUID (0x180D)
      final hasHrmService = services.any((service) => 
          service.uuid.toString().toUpperCase().contains('180D'));
      
      if (hasHrmService) {
        logger.i('✅ Device identified as HRM via service discovery');
        final hrmService = _deviceTypeManager.deviceServices
            .firstWhere((s) => s.deviceTypeName == 'HRM');
        
        _addConnectedDeviceWithService(device, 'HRM', hrmService);
        return;
      }
      
      // Check for Cycling Speed and Cadence service UUID (0x1816)
      final hasCadenceService = services.any((service) => 
          service.uuid.toString().toUpperCase().contains('1816'));
      
      if (hasCadenceService) {
        logger.i('✅ Device identified as Cadence via service discovery');
        final cadenceService = _deviceTypeManager.deviceServices
            .firstWhere((s) => s.deviceTypeName == 'Cadence');
        
        _addConnectedDeviceWithService(device, 'Cadence', cadenceService);
        return;
      }
      
    } catch (e) {
      logger.w('❌ Error during service discovery for ${device.platformName}: $e');
    }
    
    // 3. If device is not one of the supported types, don't add it
    logger.i('ℹ️ Device ${device.platformName} is not a supported device type (FTMS, HRM, or Cadence), ignoring');
  }
}

/// Global instance for easy access
final connectedDevicesService = ConnectedDevicesService();
