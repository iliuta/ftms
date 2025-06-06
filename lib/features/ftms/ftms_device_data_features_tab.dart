// This file was moved from lib/ftms_device_data_features_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../core/bloc/ftms_bloc.dart';

class FTMSDeviceDataFeaturesTab extends StatefulWidget {
  final BluetoothDevice ftmsDevice;
  const FTMSDeviceDataFeaturesTab({Key? key, required this.ftmsDevice}) : super(key: key);

  @override
  State<FTMSDeviceDataFeaturesTab> createState() => FTMSDeviceDataFeaturesTabState();
}

class FTMSDeviceDataFeaturesTabState extends State<FTMSDeviceDataFeaturesTab> {
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
          return Column(
            children: [
              Text(
                "Device Data Features",
                textScaler: const TextScaler.linear(3),
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
              Column(
                children: snapshot.data!
                    .getDeviceDataFeatures()
                    .entries
                    .toList()
                    .map((entry) =>
                        Text('${entry.key.name}: ${entry.value}'))
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
