import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'model/training_session.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import '../../core/bloc/ftms_bloc.dart';
import '../../core/config/ftms_display_config.dart';
import '../../core/widgets/ftms_live_data_display_widget.dart';
import '../../core/services/ftms_data_processor.dart';
import 'training_session_controller.dart';
import 'session_progress_bar.dart';
import 'training_interval_list.dart';

class TrainingSessionProgressScreen extends StatefulWidget {
  final TrainingSessionDefinition session;
  final BluetoothDevice ftmsDevice;

  const TrainingSessionProgressScreen(
      {super.key, required this.session, required this.ftmsDevice});

  @override
  State<TrainingSessionProgressScreen> createState() => _TrainingSessionProgressScreenState();
}

class _TrainingSessionProgressScreenState extends State<TrainingSessionProgressScreen> {
  bool _congratulationsDialogShown = false;
  bool _pauseSnackBarShown = false;

  String formatHHMMSS(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String formatMMSS(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FtmsDisplayConfig?>(
      future:
          loadFtmsDisplayConfig(_normalizeMachineType(widget.session.ftmsMachineType)),
      builder: (context, snapshot) {
        final config = snapshot.data;
        return ChangeNotifierProvider(
          create: (_) => TrainingSessionController(
              session: widget.session, ftmsDevice: widget.ftmsDevice),
          child: Consumer<TrainingSessionController>(
            builder: (context, controller, _) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // Handle completion dialog
                if (controller.sessionCompleted && !_congratulationsDialogShown) {
                  _congratulationsDialogShown = true;
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      title: const Text('Congratulations!'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                              'You have completed the training session.'),
                          if (controller.lastGeneratedFitFile != null) ...[
                            if (controller.stravaUploadAttempted) ...[
                              const SizedBox(height: 16),
                              if (controller.stravaUploadSuccessful) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: Colors.green, size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                        'Successfully uploaded to Strava!'),
                                  ],
                                ),
                                if (controller.stravaActivityId != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Activity ID: ${controller.stravaActivityId}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                ],
                              ] else if (controller.stravaActivityId != null) ...[
                                // Show success if we have an activity ID, even if the flag wasn't set properly
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: Colors.green, size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                        'Successfully uploaded to Strava!'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Activity ID: ${controller.stravaActivityId}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    const Icon(Icons.info_outline,
                                        color: Colors.orange, size: 20),
                                    const SizedBox(width: 8),
                                    const Text('Strava upload in progress or failed'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Make sure you\'re connected to Strava in settings',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                              ],
                            ] else ...[
                              const SizedBox(height: 8),
                              const Text(
                                  'You can manually upload this file to Strava or other fitness apps.'),
                            ],
                          ],
                        ],
                      ),
                      actions: [
                        if (controller.lastGeneratedFitFile != null)
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Close'),
                          ),
                      ],
                    ),
                  );
                }
                
                // Handle pause SnackBar
                if (controller.sessionPaused && !_pauseSnackBarShown && !controller.sessionCompleted) {
                  _pauseSnackBarShown = true;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.pause_circle, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Session Paused - Press Resume to continue'),
                        ],
                      ),
                      backgroundColor: Colors.orange,
                      duration: const Duration(days: 1), // Keep it visible until manually dismissed
                      action: SnackBarAction(
                        label: 'Resume',
                        textColor: Colors.white,
                        onPressed: () {
                          controller.resumeSession();
                        },
                      ),
                    ),
                  );
                } else if (!controller.sessionPaused && _pauseSnackBarShown) {
                  _pauseSnackBarShown = false;
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                }
              });
              return Scaffold(
                appBar: AppBar(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.session.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (controller.sessionPaused) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.pause_circle,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const Text(
                          'PAUSED',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    if (!controller.sessionCompleted) ...[
                      IconButton(
                        onPressed: controller.sessionPaused 
                            ? controller.resumeSession 
                            : controller.pauseSession,
                        icon: Icon(controller.sessionPaused 
                            ? Icons.play_arrow 
                            : Icons.pause),
                        tooltip: controller.sessionPaused ? 'Resume' : 'Pause',
                        color: controller.sessionPaused 
                            ? Colors.green 
                            : Colors.orange,
                      ),
                      IconButton(
                        onPressed: () {
                          // Show confirmation dialog before stopping
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Stop Training Session'),
                              content: const Text(
                                  'Are you sure you want to stop the training session? This action cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    controller.stopSession();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Stop'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.stop),
                        tooltip: 'Stop Session',
                        color: Colors.red,
                      ),
                    ],
                  ],
                  toolbarHeight: 56,
                ),
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SessionProgressBar(
                        progress: controller.elapsed / controller.totalDuration,
                        timeLeft: controller.mainTimeLeft,
                        elapsed: controller.elapsed,
                        formatTime: formatHHMMSS,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TrainingIntervalList(
                                intervals: controller.intervals,
                                currentInterval: controller.currentInterval,
                                intervalElapsed: controller.intervalElapsed,
                                intervalTimeLeft: controller.intervalTimeLeft,
                                formatMMSS: formatMMSS,
                                config: config,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3,
                              child: _LiveFTMSDataWidget(
                                ftmsDevice: widget.ftmsDevice,
                                targets: controller.current.targets,
                                machineType: widget.session.ftmsMachineType,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  DeviceDataType _normalizeMachineType(String machineType) {
    switch (machineType) {
      case 'DeviceDataType.rower':
      case 'rower':
        return DeviceDataType.rower;
      case 'DeviceDataType.indoorBike':
      case 'indoorBike':
        return DeviceDataType.indoorBike;
      default:
        return DeviceDataType.indoorBike;
    }
  }
}

class _LiveFTMSDataWidget extends StatefulWidget {
  final BluetoothDevice ftmsDevice;
  final Map<String, dynamic>? targets;
  final String machineType;

  const _LiveFTMSDataWidget(
      {required this.ftmsDevice, this.targets, required this.machineType});

  @override
  State<_LiveFTMSDataWidget> createState() => _LiveFTMSDataWidgetState();
}

class _LiveFTMSDataWidgetState extends State<_LiveFTMSDataWidget> {
  FtmsDisplayConfig? _config;
  String? _configError;
  final FtmsDataProcessor _dataProcessor = FtmsDataProcessor();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final type = await _getDeviceType();
    if (type == null) return;
    final config = await loadFtmsDisplayConfig(type);
    setState(() {
      _config = config;
      _configError = config == null ? 'No config for this machine type' : null;
    });

    // Configure data processor for averaging
    if (config != null) {
      _dataProcessor.configure(config);
    }
  }

  Future<DeviceDataType?> _getDeviceType() async {
    // Try to get the latest device data from the stream
    final snapshot = await ftmsBloc.ftmsDeviceDataControllerStream
        .firstWhere((d) => d != null);
    return snapshot?.deviceDataType;
  }

  @override
  Widget build(BuildContext context) {
    if (_configError != null) {
      return Text(_configError!, style: const TextStyle(color: Colors.red));
    }
    if (_config == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SizedBox.expand(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: StreamBuilder<DeviceData?>(
                  stream: ftmsBloc.ftmsDeviceDataControllerStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('No FTMS data'),
                      );
                    }
                    final deviceData = snapshot.data!;

                    // Process device data with averaging
                    final paramValueMap =
                        _dataProcessor.processDeviceData(deviceData);

                    return FtmsLiveDataDisplayWidget(
                      config: _config!,
                      paramValueMap: paramValueMap,
                      targets: widget.targets,
                      machineType: widget.machineType,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
