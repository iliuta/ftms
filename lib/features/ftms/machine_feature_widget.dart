// This file was moved from lib/machine_feature_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_ftms/flutter_ftms.dart';

import '../../core/bloc/ftms_bloc.dart';

class MachineFeatureWidget extends StatefulWidget {
  final BluetoothDevice ftmsDevice;

  const MachineFeatureWidget({super.key, required this.ftmsDevice});

  @override
  State<MachineFeatureWidget> createState() => _MachineFeatureWidgetState();
}

class _MachineFeatureWidgetState extends State<MachineFeatureWidget> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MachineFeature?>(
      stream: ftmsBloc.ftmsMachineFeaturesControllerStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Column(
            children: [
              const Text("No Machine Features found!"),
              ElevatedButton(
                  onPressed: () async {
                    MachineFeature? machineFeature = await FTMS
                        .readMachineFeatureCharacteristic(widget.ftmsDevice);
                    ftmsBloc.ftmsMachineFeaturesControllerSink
                        .add(machineFeature);
                  },
                  child: const Text("get Machine Features")),
            ],
          );
        }
        return Column(
          children: snapshot.data!
              .getFeatureFlags()
              .entries
              .toList()
              .where((element) => element.value)
              .map((entry) => Text('${entry.key.name}: ${entry.value}'))
              .toList(),
        );
      },
    );
  }
}

