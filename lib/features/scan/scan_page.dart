// This file was moved from lib/scan_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../core/utils/logger.dart';
import 'dart:io';

import 'scan_widgets.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  // Helper to detect test environment
  bool get isInTest => Platform.environment['FLUTTER_TEST'] == 'true';
  @override
  void initState() {
    super.initState();
    _printBluetoothState();
  }

  void _printBluetoothState() {
    // Listen to the adapter state stream (logging removed for production)
    FlutterBluePlus.adapterState.listen((state) {
      logger.i('Bluetooth adapter state: [0m${state.toString()}');
    });
    // Also print the last known state immediately
    logger.i('Bluetooth adapter state (now): ${FlutterBluePlus.adapterStateNow.toString()}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start scanning for FTMS devices as soon as the page is shown
    FTMS.scanForBluetoothDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Scan for devices'),
                  onPressed: () {
                    setState(() {
                      FTMS.scanForBluetoothDevices();
                    });
                  },
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.link),
                  label: const Text('Connect to Strava'),
                  onPressed: () {
                    // TODO: Implement Strava connection
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Strava connection not implemented yet'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ScanResult>>(
              stream: FTMS.scanResults,
              initialData: const [],
              builder: (c, snapshot) => scanResultsToWidget(
                  (snapshot.data ?? [])
                      .where((element) => element.device.platformName.isNotEmpty)
                      .toList(),
                  context),
            ),
          ),
        ],
      ),
    );
  }
}
