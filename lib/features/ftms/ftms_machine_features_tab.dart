import 'package:flutter/material.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import 'machine_feature_widget.dart';

class FTMSMachineFeaturesTab extends StatelessWidget {
  final BluetoothDevice ftmsDevice;
  final void Function(MachineControlPointOpcodeType) writeCommand;
  const FTMSMachineFeaturesTab({super.key, required this.ftmsDevice, required this.writeCommand});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MachineFeatureWidget(ftmsDevice: ftmsDevice),
        const Divider(height: 2),
        SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: MachineControlPointOpcodeType.values
                .map(
                  (MachineControlPointOpcodeType opcodeType) => Padding(
                    padding: const EdgeInsets.all(4),
                    child: OutlinedButton(
                      onPressed: () => writeCommand(opcodeType),
                      child: Text(opcodeType.name),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

