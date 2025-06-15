import 'package:flutter/material.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import 'model/training_session.dart';
import '../../core/config/ftms_display_config.dart';
import 'widgets/training_session_chart.dart';

class TrainingSessionExpansionPanelList extends StatefulWidget {
  final List<TrainingSessionDefinition> sessions;
  final ScrollController scrollController;
  final Function(TrainingSessionDefinition)? onSessionSelected;
  final bool
      showStartButton; // Controls whether to show the Start Session button

  const TrainingSessionExpansionPanelList({
    super.key,
    required this.sessions,
    required this.scrollController,
    this.onSessionSelected,
    this.showStartButton = false, // Default to false (hidden)
  });

  @override
  State<TrainingSessionExpansionPanelList> createState() =>
      _TrainingSessionExpansionPanelListState();
}

class _TrainingSessionExpansionPanelListState
    extends State<TrainingSessionExpansionPanelList> {
  final Map<String, FtmsDisplayConfig?> _configCache = {};
  late List<bool> _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = List<bool>.filled(widget.sessions.length, false);
  }

  @override
  void didUpdateWidget(covariant TrainingSessionExpansionPanelList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessions.length != widget.sessions.length) {
      _expanded = List<bool>.filled(widget.sessions.length, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      child: ExpansionPanelList(
        expansionCallback: (int index, bool isExpanded) {
          setState(() {
            _expanded[index] = !_expanded[index];
          });
        },
        children: List.generate(widget.sessions.length, (idx) {
          final session = widget.sessions[idx];
          return ExpansionPanel(
            headerBuilder: (context, isExpanded) => ListTile(
              title: Text(session.title),
              subtitle: Text('Intervals: ${session.intervals.length}'),
              trailing: isExpanded
                  ? const Icon(Icons.expand_less)
                  : const Icon(Icons.expand_more),
            ),
            body: FutureBuilder<FtmsDisplayConfig?>(
              future: _getConfig(session.ftmsMachineType),
              builder: (context, snapshot) {
                final config = snapshot.data;
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Add the visual chart
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Training Intensity',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              TrainingSessionChart(
                                intervals: session.intervals,
                                machineType: session.ftmsMachineType,
                                height: 120,
                                config: config,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (widget
                          .showStartButton) // Only show button when enabled
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _buildStartSessionButton(context, session),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
            isExpanded: _expanded[idx],
            canTapOnHeader: true,
          );
        }),
      ),
    );
  }

  Future<FtmsDisplayConfig?> _getConfig(String machineType) async {
    if (_configCache.containsKey(machineType)) {
      return _configCache[machineType];
    }
    // Map string to DeviceDataType
    DeviceDataType? type;
    switch (machineType) {
      case 'DeviceDataType.rower':
        type = DeviceDataType.rower;
        break;
      case 'DeviceDataType.indoorBike':
        type = DeviceDataType.indoorBike;
        break;
      default:
        type = null;
    }
    if (type == null) return null;
    final config = await loadFtmsDisplayConfig(type);
    _configCache[machineType] = config;
    return config;
  }

  Widget _buildStartSessionButton(
      BuildContext context, TrainingSessionDefinition session) {
    // Compatible device connected - show enabled button
    return ElevatedButton.icon(
      icon: const Icon(Icons.play_arrow, size: 16),
      label: const Text('Start Session', style: TextStyle(fontSize: 13)),
      onPressed: () async {
        if (widget.onSessionSelected != null) {
          widget.onSessionSelected!(session);
        } else {
          Navigator.pop(context, session);
        }
      },
    );
  }
}
