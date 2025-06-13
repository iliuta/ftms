// This file was moved from lib/scan_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../core/utils/logger.dart';
import '../../core/services/strava_service.dart';
import '../../core/widgets/hrm_status_widget.dart';
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
  final StravaService _stravaService = StravaService();
  bool _isConnectingStrava = false;
  String? _stravaStatus;
  
  @override
  void initState() {
    super.initState();
    _printBluetoothState();
    _checkStravaStatus();
  }
  
  Future<void> _checkStravaStatus() async {
    final status = await _stravaService.getAuthStatus();
    setState(() {
      if (status != null) {
        _stravaStatus = 'Connected as ${status['athleteName']}';
      } else {
        _stravaStatus = null;
      }
    });
  }
  
  Future<void> _handleStravaConnection() async {
    if (_isConnectingStrava) return;
    
    setState(() {
      _isConnectingStrava = true;
    });
    
    try {
      // Show initial feedback with detailed instructions
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Opening Strava authorization...'),
                SizedBox(height: 4),
                Text('Complete the login in browser and authorize the app', 
                     style: TextStyle(fontSize: 12)),
              ],
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
      
      final success = await _stravaService.authenticate();
      
      if (success) {
        await _checkStravaStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully connected to Strava!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Strava authentication was not completed'),
                  SizedBox(height: 4),
                  Text('Complete the login in the browser to connect to Strava', 
                       style: TextStyle(fontSize: 12)),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      logger.e('Error connecting to Strava: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error connecting to Strava: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isConnectingStrava = false;
      });
    }
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
    _scanForDevices();
  }

  void _scanForDevices() {
    final List<Guid> withServices = [
      Guid.fromString("00001826"), // FTMS Service UUID
      Guid.fromString("0000180D"), // Heart Rate Service UUID
    ];
    
    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10),
      withServices: withServices,
    );
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
                      _scanForDevices();
                    });
                  },
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: _isConnectingStrava 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_stravaStatus != null ? Icons.check_circle : Icons.link),
                  label: Text(_stravaStatus != null ? 'Connected to Strava' : 'Connect to Strava'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _stravaStatus != null ? Colors.green : null,
                    foregroundColor: _stravaStatus != null ? Colors.white : null,
                  ),
                  onPressed: _isConnectingStrava ? null : _handleStravaConnection,
                ),
              ],
            ),
          ),
          if (_stravaStatus != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      _stravaStatus!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      // Capture the ScaffoldMessengerState before async operations
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      await _stravaService.signOut();
                      await _checkStravaStatus();
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('Disconnected from Strava')),
                        );
                      }
                    },
                    child: const Icon(
                      Icons.logout,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          // HRM Status Widget
          const HrmStatusWidget(),
          Expanded(
            child: StreamBuilder<List<ScanResult>>(
              stream: FlutterBluePlus.scanResults,
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
