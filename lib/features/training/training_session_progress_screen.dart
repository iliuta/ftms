import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'model/training_session.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import '../../core/bloc/ftms_bloc.dart';
import '../../core/utils/ftms_display_config.dart';
import '../../core/utils/ftms_live_data_display_widget.dart';
import 'training_session_controller.dart';
import 'session_progress_bar.dart';
import 'training_interval_list.dart';


class TrainingSessionProgressScreen extends StatelessWidget {
  final TrainingSessionDefinition session;
  final BluetoothDevice ftmsDevice;
  const TrainingSessionProgressScreen({super.key, required this.session, required this.ftmsDevice});

  String formatHHMMSS(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}' ;
  }
  String formatMMSS(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}' ;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FtmsDisplayConfig?>(
      future: loadFtmsDisplayConfig(_normalizeMachineType(session.ftmsMachineType)),
      builder: (context, snapshot) {
        final config = snapshot.data;
        return ChangeNotifierProvider(
          create: (_) => TrainingSessionController(session: session, ftmsDevice: ftmsDevice),
          child: Consumer<TrainingSessionController>(
            builder: (context, controller, _) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (controller.sessionCompleted) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      title: const Text('Congratulations!'),
                      content: const Text('You have completed the training session.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          },
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                }
              });
              return Scaffold(
                appBar: AppBar(title: Text(session.title)),
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SessionProgressBar(
                        progress: controller.elapsed / controller.totalDuration,
                        timeLeft: controller.mainTimeLeft,
                        formatTime: formatHHMMSS,
                      ),
                      const SizedBox(height: 16),
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
                                ftmsDevice: ftmsDevice,
                                targets: controller.current.targets,
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
  const _LiveFTMSDataWidget({required this.ftmsDevice, this.targets});

  @override
  State<_LiveFTMSDataWidget> createState() => _LiveFTMSDataWidgetState();
}

class _LiveFTMSDataWidgetState extends State<_LiveFTMSDataWidget> {
  FtmsDisplayConfig? _config;
  String? _configError;

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
  }

  Future<DeviceDataType?> _getDeviceType() async {
    // Try to get the latest device data from the stream
    final snapshot = await ftmsBloc.ftmsDeviceDataControllerStream.firstWhere((d) => d != null);
    return snapshot?.deviceDataType;
  }

  bool _isWithinTarget(num? value, num? target, {num factor = 1}) {
    if (value == null || target == null) return false;
    final scaledValue = value * factor;
    final lower = target * 0.9;
    final upper = target * 1.1;
    return scaledValue >= lower && scaledValue <= upper;
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
                    final parameterValues = deviceData.getDeviceDataParameterValues();
                    final paramValueMap = {
                      for (final p in parameterValues)
                        p.name.name: p
                    };
                    return FtmsLiveDataDisplayWidget(
                      config: _config!,
                      paramValueMap: paramValueMap,
                      targets: widget.targets,
                      isWithinTarget: _isWithinTarget,
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

