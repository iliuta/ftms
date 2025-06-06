// This file was moved from lib/ftms_data_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../core/bloc/ftms_bloc.dart';
import '../training/training_session_loader.dart';
import '../training/training_session_expansion_panel.dart';
import '../training/training_session_progress_screen.dart';
import '../../core/utils/ftms_debug_utils.dart';

class FTMSDataTab extends StatefulWidget {
  final BluetoothDevice ftmsDevice;
  const FTMSDataTab({Key? key, required this.ftmsDevice}) : super(key: key);

  @override
  State<FTMSDataTab> createState() => FTMSDataTabState();
}

class FTMSDataTabState extends State<FTMSDataTab> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _startFTMS();
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
          // Log all FTMS parameter attributes for debugging
          final parameterValues = deviceData.getDeviceDataParameterValues();
          logFtmsParameterAttributes(parameterValues);
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Text(
                  FTMS.convertDeviceDataTypeToString(deviceData.deviceDataType),
                  textScaler: const TextScaler.linear(4),
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: parameterValues
                      .map((parameterValue) => Text(
                            parameterValue.toString(),
                            textScaler: const TextScaler.linear(2),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),
                // Start Training Button
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Load training session'),
                    onPressed: () async {
                      // Log the value of deviceData.deviceDataType
                      // ignore: avoid_print
                      print('Start Training pressed. deviceData.deviceDataType: '
                          '${deviceData.deviceDataType}');
                      final sessions = await loadTrainingSessions(deviceData.deviceDataType.toString());
                      if (sessions.isEmpty) {
                        // ignore: use_build_context_synchronously
                        showDialog(
                          context: context,
                          builder: (context) => const AlertDialog(
                            title: Text('No Training Sessions'),
                            content: Text('No training sessions found for this machine type.'),
                          ),
                        );
                        return;
                      }
                      // ignore: use_build_context_synchronously
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

