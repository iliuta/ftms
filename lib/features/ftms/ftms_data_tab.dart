// This file was moved from lib/ftms_data_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import '../../core/bloc/ftms_bloc.dart';
import '../training/training_session_loader.dart';
import '../training/training_session_expansion_panel.dart';
import '../training/training_session_progress_screen.dart';
import '../../core/utils/ftms_debug_utils.dart';
import '../../core/utils/ftms_display_config.dart';
import '../../core/utils/ftms_display_widgets.dart';

class FTMSDataTab extends StatefulWidget {
  final BluetoothDevice ftmsDevice;
  const FTMSDataTab({Key? key, required this.ftmsDevice}) : super(key: key);

  @override
  State<FTMSDataTab> createState() => FTMSDataTabState();
}

class FTMSDataTabState extends State<FTMSDataTab> {
  bool _started = false;
  FtmsDisplayConfig? _config;
  String? _configError;

  @override
  void initState() {
    super.initState();
    _startFTMS();
  }

  Future<void> _loadConfigForType(DeviceDataType type) async {
    final config = await loadFtmsDisplayConfig(type);
    setState(() {
      _config = config;
      _configError = config == null ? 'No config for this machine type' : null;
    });
  }

  void _startFTMS() async {
    if (!_started) {
      _started = true;
      await FTMS.useDeviceDataCharacteristic(
        widget.ftmsDevice,
        (DeviceData data) {
          ftmsBloc.ftmsDeviceDataControllerSink.add(data);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: StreamBuilder<DeviceData?>(
        stream: ftmsBloc.ftmsDeviceDataControllerStream,
        builder: (c, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: Text("No FTMSData found!"));
          }
          final deviceData = snapshot.data!;
          // Load config if not loaded or if type changed
          if (_config == null || _configError != null) {
            _loadConfigForType(deviceData.deviceDataType);
            if (_configError != null) {
              return Center(child: Text(_configError!));
            }
            return const Center(child: CircularProgressIndicator());
          }
          final parameterValues = deviceData.getDeviceDataParameterValues();
          logFtmsParameterAttributes(parameterValues);
          final Map<String, dynamic> paramValueMap = {
            for (final p in parameterValues)
              if (p.name != null) p.name.name: p
          };
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Text(
                  FTMS.convertDeviceDataTypeToString(deviceData.deviceDataType),
                  textScaler: const TextScaler.linear(4),
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: _config!.fields.map((field) {
                    final param = paramValueMap[field.name];
                    if (param == null) {
                      return Text('${field.label}: (not available)', style: const TextStyle(color: Colors.grey));
                    }
                  final value = param.value ?? param.toString();
                  final factor = (param.factor is num)
                      ? param.factor as num
                      : num.tryParse(param.factor?.toString() ?? '1') ?? 1;
                  final scaledValue = (value is num ? value : num.tryParse(value.toString()) ?? 0) * factor;
                  if (field.display == 'speedometer') {
                    return SpeedometerWidget(
                      value: scaledValue.toDouble(),
                      min: (field.min ?? 0).toDouble(),
                      max: (field.max ?? 100).toDouble(),
                      label: field.label,
                      unit: field.unit,
                      color: Colors.blue,
                    );
                  } else {
                    return SimpleNumberWidget(
                      label: field.label,
                      value: scaledValue,
                      unit: field.unit,
                    );
                  }
                  }).toList(),
                ),
                const SizedBox(height: 24),
                // Start Training Button
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Load training session'),
                    onPressed: () async {
                      print('Start Training pressed. deviceData.deviceDataType: '
                          '${deviceData.deviceDataType}');
                      final sessions = await loadTrainingSessions(deviceData.deviceDataType.toString());
                      if (sessions.isEmpty) {
                        showDialog(
                          context: context,
                          builder: (context) => const AlertDialog(
                            title: Text('No Training Sessions'),
                            content: Text('No training sessions found for this machine type.'),
                          ),
                        );
                        return;
                      }
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => DraggableScrollableSheet(
                          expand: false,
                          initialChildSize: 0.7,
                          minChildSize: 0.4,
                          maxChildSize: 0.95,
                          builder: (context, scrollController) {
                            return TrainingSessionExpansionPanelList(
                              sessions: sessions,
                              scrollController: scrollController,
                            );
                          },
                        ),
                      ).then((selectedSession) {
                        if (selectedSession != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TrainingSessionProgressScreen(
                                session: selectedSession,
                                ftmsDevice: widget.ftmsDevice,
                              ),
                            ),
                          );
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

