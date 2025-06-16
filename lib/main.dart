
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'features/scan/scan_page.dart';
import 'features/scan/scan_widgets.dart';
import 'features/common/burger_menu.dart';
import 'core/services/devices/connected_devices_service.dart';

void main() {
  // Set log level for production
  FlutterBluePlus.setLogLevel(LogLevel.info);
  
  // Initialize device navigation callbacks to avoid circular dependencies
  initializeDeviceNavigation();
  
  // Initialize connected devices service
  connectedDevicesService.initialize();

  runApp(const MyApp());
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness machines',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const FlutterFTMSApp(),
    );
  }
}

class FlutterFTMSApp extends StatefulWidget {
  const FlutterFTMSApp({super.key});

  @override
  State<FlutterFTMSApp> createState() => _FlutterFTMSAppState();
}

class _FlutterFTMSAppState extends State<FlutterFTMSApp> {
  BluetoothDevice? _connectedFtmsDevice;

  @override
  void initState() {
    super.initState();
    
    // Listen to connected devices changes
    connectedDevicesService.devicesStream.listen((devices) {
      _updateConnectedFtmsDevice(devices);
    });

    // Get initial connected device if any
    _updateConnectedFtmsDevice(connectedDevicesService.connectedDevices);
  }

  void _updateConnectedFtmsDevice(List<ConnectedDevice> devices) {
    // Find the first FTMS device
    ConnectedDevice? ftmsDevice;
    try {
      ftmsDevice = devices.firstWhere((device) => device.deviceTypeName == 'FTMS');
    } catch (e) {
      ftmsDevice = null;
    }
    
    final newFtmsDevice = ftmsDevice?.device;
    if (mounted && _connectedFtmsDevice != newFtmsDevice) {
      setState(() {
        _connectedFtmsDevice = newFtmsDevice;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fitness machines"),
        leading: BurgerMenu(connectedDevice: _connectedFtmsDevice),
      ),
      body: const ScanPage(),
    );
  }
}

