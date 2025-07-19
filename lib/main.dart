
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:ftms/core/utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';

import 'features/scan/scan_page.dart';
import 'features/scan/scan_widgets.dart';
import 'features/common/burger_menu.dart';
import 'core/services/devices/bt_device.dart';
import 'core/services/devices/bt_device_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set log level for production
  FlutterBluePlus.setLogLevel(LogLevel.info);
  
  // Initialize device navigation callbacks to avoid circular dependencies
  initializeDeviceNavigation();
  
  // Initialize the new device management system
  logger.i('🚀 Initializing BTDevice system...');
  await SupportedBTDeviceManager().initialize();
  
  logger.i('🚀 Looking for already connected devices...');
  await SupportedBTDeviceManager().identifyAndConnectExistingDevices();
  
  logger.i('🚀 Starting app with ${SupportedBTDeviceManager().allConnectedDevices.length} connected devices');

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
    SupportedBTDeviceManager().connectedDevicesStream.listen((devices) {
      _updateConnectedFtmsDevice(devices);
    });

    // Get initial connected device if any
    _updateConnectedFtmsDevice(SupportedBTDeviceManager().allConnectedDevices);
  }

  void _updateConnectedFtmsDevice(List<BTDevice> devices) {
    // Find the first FTMS device
    final ftmsDevice = SupportedBTDeviceManager().getConnectedFtmsDevice();
    
    final newFtmsDevice = ftmsDevice?.connectedDevice;
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              icon: const Icon(
                Icons.coffee,
                color: Colors.brown,
                size: 24,
              ),
              label: const Text(
                'Buy me a coffee',
                style: TextStyle(
                  color: Colors.brown,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () async {
                final Uri url = Uri.parse('https://coff.ee/iliuta');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not open the link'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
      body: const ScanPage(),
    );
  }
}

