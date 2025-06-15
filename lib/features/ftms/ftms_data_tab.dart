// This file was moved from lib/ftms_data_tab.dart
import 'package:flutter/material.dart';
import '../../core/utils/logger.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../core/bloc/ftms_bloc.dart';
import '../training/training_session_loader.dart';
import '../training/training_session_expansion_panel.dart';
import '../training/training_session_progress_screen.dart';
import '../../core/utils/ftms_debug_utils.dart';
import '../../core/config/ftms_display_config.dart';
import '../../core/widgets/ftms_live_data_display_widget.dart';
import '../../core/services/ftms_data_processor.dart';

class FTMSDataTab extends StatefulWidget {
  final BluetoothDevice ftmsDevice;
  const FTMSDataTab({super.key, required this.ftmsDevice});

  @override
  State<FTMSDataTab> createState() => FTMSDataTabState();
}

class FTMSDataTabState extends State<FTMSDataTab> {
  bool _started = false;
  FtmsDisplayConfig? _config;
  String? _configError;
  final FtmsDataProcessor _dataProcessor = FtmsDataProcessor();

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
    
    // Configure data processor for averaging
    if (config != null) {
      _dataProcessor.configure(config);
    }
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
          
          // Process device data with averaging
          final paramValueMap = _dataProcessor.processDeviceData(deviceData);
          
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Text(
                  FTMS.convertDeviceDataTypeToString(deviceData.deviceDataType),
                  textScaler: const TextScaler.linear(4),
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
                FtmsLiveDataDisplayWidget(
                  config: _config!,
                  paramValueMap: paramValueMap,
                  defaultColor: Colors.blue,
                  machineType: deviceData.deviceDataType.toString(),
                ),
                const SizedBox(height: 24),
                // Start Training Button
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Load training session'),
                    onPressed: () async {
                      logger.i('Start Training pressed. deviceData.deviceDataType: '
                          '${deviceData.deviceDataType}');
                      // Load training sessions (default user settings are now loaded inside the loader)
                      final sessions = await loadTrainingSessions(
                        deviceData.deviceDataType.toString(),
                      );
                      if (sessions.isEmpty) {
                        if (!context.mounted) return;
                        showDialog(
                          context: context,
                          builder: (context) => const AlertDialog(
                            title: Text('No Training Sessions'),
                            content: Text('No training sessions found for this machine type.'),
                          ),
                        );
                        return;
                      }
                      if (!context.mounted) return;
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
                        if (selectedSession != null && context.mounted) {
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

