import 'package:flutter/material.dart';
import 'package:ftms/core/models/device_types.dart';
import 'model/training_session.dart';
import '../../core/config/live_data_display_config.dart';
import '../../core/services/devices/bt_device.dart';
import '../../core/services/devices/bt_device_manager.dart';
import 'widgets/training_session_chart.dart';

class TrainingSessionExpansionPanelList extends StatefulWidget {
  final List<TrainingSessionDefinition> sessions;
  final ScrollController scrollController;
  final Function(TrainingSessionDefinition)? onSessionSelected;
  final Function(TrainingSessionDefinition)? onSessionEdit;
  final Function(TrainingSessionDefinition)? onSessionDelete;

  const TrainingSessionExpansionPanelList({
    super.key,
    required this.sessions,
    required this.scrollController,
    this.onSessionSelected,
    this.onSessionEdit,
    this.onSessionDelete,
  });

  @override
  State<TrainingSessionExpansionPanelList> createState() =>
      _TrainingSessionExpansionPanelListState();
}

class _TrainingSessionExpansionPanelListState
    extends State<TrainingSessionExpansionPanelList> {
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
              title: Row(
                children: [
                  Expanded(child: Text(session.title)),
                  if (session.isCustom) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.blue, width: 1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Custom',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Text('Intervals: ${session.intervals.length}'),
              trailing: isExpanded
                  ? const Icon(Icons.expand_less)
                  : const Icon(Icons.expand_more),
            ),
            body: FutureBuilder<LiveDataDisplayConfig?>(
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
                                intervals: session.unitIntervals,
                                machineType: session.ftmsMachineType,
                                height: 120,
                                config: config,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Add edit and delete buttons for custom sessions
                          if (session.isCustom) ...[
                            TextButton.icon(
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Edit'),
                              onPressed: () {
                                if (widget.onSessionEdit != null) {
                                  widget.onSessionEdit!(session);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                              label: const Text('Delete', style: TextStyle(color: Colors.red)),
                              onPressed: () {
                                _showDeleteConfirmationDialog(context, session);
                              },
                            ),
                            const SizedBox(width: 8),
                          ],
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

  Future<LiveDataDisplayConfig?> _getConfig(DeviceType deviceType) async {
    return await LiveDataDisplayConfig.loadForFtmsMachineType(deviceType);
  }

  void _showDeleteConfirmationDialog(BuildContext context, TrainingSessionDefinition session) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Delete Training Session'),
        content: Text('Are you sure you want to delete "${session.title}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (widget.onSessionDelete != null) {
                widget.onSessionDelete!(session);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildStartSessionButton(
      BuildContext context, TrainingSessionDefinition session) {
    return StreamBuilder<List<BTDevice>>(
      stream: SupportedBTDeviceManager().connectedDevicesStream,
      initialData: SupportedBTDeviceManager().allConnectedDevices,
      builder: (context, snapshot) {
        final devices = snapshot.data ?? [];
        final ftmsDevices = devices
            .where((d) =>
                d.deviceTypeName == 'FTMS' &&
                session.ftmsMachineType == d.deviceType)
            .toList();

        final hasCompatibleDevice = ftmsDevices.isNotEmpty;

        return ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow, size: 16),
          label: Text(
            hasCompatibleDevice
                ? 'Start Session'
                : 'Fitness machine not connected',
            style: const TextStyle(fontSize: 13),
          ),
          onPressed: hasCompatibleDevice
              ? () async {
                  if (widget.onSessionSelected != null) {
                    widget.onSessionSelected!(session);
                  } else {
                    Navigator.pop(context, session);
                  }
                }
              : null,
        );
      },
    );
  }
}
