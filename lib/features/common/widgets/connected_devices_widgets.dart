import 'package:flutter/material.dart';
import '../../../core/services/connected_devices_service.dart';

/// Widget that displays the current connected devices status
class ConnectedDevicesStatusWidget extends StatelessWidget {
  final bool showDeviceCount;
  final bool showDeviceTypes;
  final bool showDeviceNames;
  final Widget? leading;
  final TextStyle? textStyle;
  final MainAxisAlignment mainAxisAlignment;

  const ConnectedDevicesStatusWidget({
    super.key,
    this.showDeviceCount = true,
    this.showDeviceTypes = false,
    this.showDeviceNames = false,
    this.leading,
    this.textStyle,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectedDevice>>(
      stream: connectedDevicesService.devicesStream,
      initialData: connectedDevicesService.connectedDevices,
      builder: (context, snapshot) {
        final devices = snapshot.data ?? [];
        
        if (devices.isEmpty) {
          return Row(
            mainAxisAlignment: mainAxisAlignment,
            children: [
              if (leading != null) leading!,
              Text(
                'No devices connected',
                style: textStyle ?? Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          );
        }

        final children = <Widget>[];
        
        if (leading != null) {
          children.add(leading!);
        }

        if (showDeviceCount) {
          children.add(
            Text(
              '${devices.length} device${devices.length > 1 ? 's' : ''} connected',
              style: textStyle ?? Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        if (showDeviceTypes) {
          final types = devices.map((d) => d.deviceType).toSet().toList();
          types.sort();
          
          children.add(
            Text(
              'Types: ${types.join(', ')}',
              style: textStyle ?? Theme.of(context).textTheme.bodySmall,
            ),
          );
        }

        if (showDeviceNames) {
          for (final device in devices) {
            children.add(
              Chip(
                avatar: device.service.getDeviceIcon(context),
                label: Text(
                  '${device.name} (${device.deviceType})',
                  style: const TextStyle(fontSize: 12),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            );
          }
        }

        return Wrap(
          spacing: 8,
          runSpacing: 4,
          children: children,
        );
      },
    );
  }
}

/// Compact connected devices indicator for app bars
class ConnectedDevicesIndicator extends StatelessWidget {
  const ConnectedDevicesIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectedDevice>>(
      stream: connectedDevicesService.devicesStream,
      initialData: connectedDevicesService.connectedDevices,
      builder: (context, snapshot) {
        final devices = snapshot.data ?? [];
        
        if (devices.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${devices.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// List widget showing all connected devices with actions
class ConnectedDevicesList extends StatelessWidget {
  final bool showDisconnectButton;
  final bool showDeviceActions;

  const ConnectedDevicesList({
    super.key,
    this.showDisconnectButton = true,
    this.showDeviceActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectedDevice>>(
      stream: connectedDevicesService.devicesStream,
      initialData: connectedDevicesService.connectedDevices,
      builder: (context, snapshot) {
        final devices = snapshot.data ?? [];
        
        if (devices.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bluetooth_disabled,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No devices connected',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Scan for and connect to devices to see them here',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: device.service.getDeviceIcon(context),
                title: Text(device.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type: ${device.deviceType}'),
                    Text(
                      'Connected: ${_formatDuration(DateTime.now().difference(device.connectedAt))}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showDeviceActions) ...[
                      ...device.service.getConnectedActions(device.device, context),
                      const SizedBox(width: 8),
                    ],
                    if (showDisconnectButton)
                      IconButton(
                        icon: const Icon(Icons.bluetooth_connected),
                        onPressed: () async {
                          try {
                            await device.service.disconnectFromDevice(device.device);
                            connectedDevicesService.removeConnectedDevice(device.id);
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
                        },
                        tooltip: 'Disconnect',
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
