import 'package:flutter/material.dart';
import '../training/training_sessions_page.dart';
import '../settings/settings_page.dart';
import 'package:flutter_ftms/flutter_ftms.dart';

/// A burger menu widget with navigation options and device status
class BurgerMenu extends StatelessWidget {
  final BluetoothDevice? connectedDevice;

  const BurgerMenu({
    super.key,
    this.connectedDevice,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu),
      tooltip: 'Menu',
      onSelected: (String value) {
        _handleMenuSelection(context, value);
      },
      itemBuilder: (BuildContext context) => [
        // Device status header
        PopupMenuItem<String>(
          enabled: false,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      connectedDevice != null 
                        ? Icons.bluetooth_connected 
                        : Icons.bluetooth_disabled,
                      color: connectedDevice != null 
                        ? Colors.green 
                        : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Device Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  connectedDevice != null 
                    ? (connectedDevice!.platformName.isNotEmpty ? connectedDevice!.platformName : 'Unknown Device')
                    : 'No device connected',
                  style: TextStyle(
                    fontSize: 12,
                    color: connectedDevice != null 
                      ? Colors.green[700]
                      : Colors.grey[600],
                  ),
                ),
                if (connectedDevice != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'ID: ${connectedDevice!.remoteId}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
                const Divider(height: 16),
              ],
            ),
          ),
        ),
        // Navigation options
        const PopupMenuItem<String>(
          value: 'training_sessions',
          child: ListTile(
            leading: Icon(Icons.fitness_center),
            title: Text('Training Sessions'),
            dense: true,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'device_scan',
          child: ListTile(
            leading: Icon(Icons.bluetooth_searching),
            title: Text('Scan for Devices'),
            dense: true,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'settings',
          child: ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            dense: true,
          ),
        ),
        if (connectedDevice != null)
          const PopupMenuItem<String>(
            value: 'disconnect',
            child: ListTile(
              leading: Icon(Icons.bluetooth_disabled, color: Colors.red),
              title: Text('Disconnect Device', style: TextStyle(color: Colors.red)),
              dense: true,
            ),
          ),
      ],
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'training_sessions':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TrainingSessionsPage(
              connectedDevice: connectedDevice,
            ),
          ),
        );
        break;
      case 'device_scan':
        _navigateToDeviceScan(context);
        break;
      case 'settings':
        _showSettingsDialog(context);
        break;
      case 'disconnect':
        _disconnectDevice(context);
        break;
    }
  }

  void _navigateToDeviceScan(BuildContext context) {
    // Navigate back to the main page where device scanning happens
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showSettingsDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  void _disconnectDevice(BuildContext context) async {
    if (connectedDevice == null) return;
    
    try {
      await connectedDevice!.disconnect();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Disconnected from ${connectedDevice!.platformName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to disconnect: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
