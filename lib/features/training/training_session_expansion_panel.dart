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

  const TrainingSessionExpansionPanelList({
    super.key,
    required this.sessions,
    required this.scrollController,
    this.onSessionSelected,
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
              title: Text(session.title),
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

  Future<LiveDataDisplayConfig?> _getConfig(DeviceType deviceType) async {
    return await LiveDataDisplayConfig.loadForFtmsMachineType(deviceType);
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
