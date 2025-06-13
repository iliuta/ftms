import 'package:flutter/material.dart';
import '../../core/services/heart_rate_service.dart';

/// Widget to display current HRM connection status and heart rate
class HrmStatusWidget extends StatefulWidget {
  const HrmStatusWidget({super.key});

  @override
  State<HrmStatusWidget> createState() => _HrmStatusWidgetState();
}

class _HrmStatusWidgetState extends State<HrmStatusWidget> {
  final HeartRateService _heartRateService = HeartRateService();
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int?>(
      stream: _heartRateService.heartRateStream,
      builder: (context, snapshot) {
        if (!_heartRateService.isHrmConnected) {
          return Container(); // Hidden when no HRM is connected
        }
        
        final heartRate = snapshot.data;
        final deviceName = _heartRateService.connectedDeviceName ?? 'Unknown HRM';
        
        return Card(
          margin: const EdgeInsets.all(8.0),
          color: Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'HRM Connected: $deviceName',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      if (heartRate != null)
                        Text(
                          'Heart Rate: $heartRate bpm',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        Text(
                          'Waiting for heart rate data...',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () async {
                    // Capture the ScaffoldMessenger before async operation
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    await _heartRateService.disconnectHrmDevice();
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('HRM disconnected'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  tooltip: 'Disconnect HRM',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
