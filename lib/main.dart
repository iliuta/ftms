
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ftms/flutter_ftms.dart';

import 'features/scan/scan_page.dart';
import 'features/scan/scan_widgets.dart';
import 'features/common/burger_menu.dart';

void main() {
  // Set log level for production
  FlutterBluePlus.setLogLevel(LogLevel.info);
  
  // Initialize device navigation callbacks to avoid circular dependencies
  initializeDeviceNavigation();
  
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
    _findConnectedFtmsDevice();
    
    // Check for connected devices periodically
    _startPeriodicCheck();
  }

  void _startPeriodicCheck() {
    // Check every 5 seconds for connected FTMS devices
    Stream.periodic(const Duration(seconds: 5)).listen((_) {
      if (mounted) {
        _findConnectedFtmsDevice();
      }
    });
  }

  Future<void> _findConnectedFtmsDevice() async {
    try {
      final connectedDevices = FlutterBluePlus.connectedDevices;
      _updateConnectedFtmsDevice(connectedDevices);
    } catch (e) {
      // Handle error silently
    }
  }

  void _updateConnectedFtmsDevice(List<BluetoothDevice> devices) async {
    BluetoothDevice? ftmsDevice;
    
    for (final device in devices) {
      try {
        final isFtms = await FTMS.isBluetoothDeviceFTMSDevice(device);
        if (isFtms) {
          ftmsDevice = device;
          break;
        }
      } catch (e) {
        // Continue checking other devices
      }
    }
    
    if (mounted && _connectedFtmsDevice != ftmsDevice) {
      setState(() {
        _connectedFtmsDevice = ftmsDevice;
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

