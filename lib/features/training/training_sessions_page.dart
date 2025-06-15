import 'package:flutter/material.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import 'training_session_loader.dart';
import 'training_session_expansion_panel.dart';
import 'training_session_progress_screen.dart';
import 'model/training_session.dart';

/// A dedicated page for browsing and selecting training sessions
class TrainingSessionsPage extends StatefulWidget {
  final BluetoothDevice? connectedDevice;

  const TrainingSessionsPage({
    super.key,
    this.connectedDevice,
  });

  @override
  State<TrainingSessionsPage> createState() => _TrainingSessionsPageState();
}

class _TrainingSessionsPageState extends State<TrainingSessionsPage> {
  List<TrainingSessionDefinition>? _sessions;
  bool _isLoading = true;
  String? _error;
  String _selectedMachineType = 'DeviceDataType.indoorBike';

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sessions = await loadTrainingSessions(_selectedMachineType);
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load training sessions: $e';
        _isLoading = false;
      });
    }
  }

  void _onMachineTypeChanged(String? newType) {
    if (newType != null && newType != _selectedMachineType) {
      setState(() {
        _selectedMachineType = newType;
      });
      _loadSessions();
    }
  }

  void _onSessionSelected(TrainingSessionDefinition session) {
    if (widget.connectedDevice == null) {
      // Show helpful dialog about connecting a device
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Device Connected'),
          content: const Text(
            'To start a training session, please connect to a compatible fitness machine first.\n\n'
            'You can scan for devices from the main page.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate back to main page for device scanning
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Scan for Devices'),
            ),
          ],
        ),
      );
      return;
    }

    // Navigate to training session progress screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TrainingSessionProgressScreen(
          session: session,
          ftmsDevice: widget.connectedDevice!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Sessions'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('Machine Type: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedMachineType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'DeviceDataType.indoorBike',
                        child: Text('Indoor Bike'),
                      ),
                      DropdownMenuItem(
                        value: 'DeviceDataType.rower',
                        child: Text('Rowing Machine'),
                      ),
                    ],
                    onChanged: _onMachineTypeChanged,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSessions,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_sessions == null || _sessions!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No training sessions found',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No training sessions available for $_selectedMachineType',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different machine type above',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return TrainingSessionExpansionPanelList(
      sessions: _sessions!,
      scrollController: ScrollController(),
      onSessionSelected: _onSessionSelected,
    );
  }
}
