// This file was moved from lib/ftms_service.dart
import 'package:flutter_ftms/flutter_ftms.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class FTMSService {
  final BluetoothDevice ftmsDevice;

  FTMSService(this.ftmsDevice);

  Future<void> writeCommand(MachineControlPointOpcodeType opcodeType, {int? resistanceLevel}) async {
    MachineControlPoint? controlPoint;
    switch (opcodeType) {
      case MachineControlPointOpcodeType.requestControl:
        controlPoint = MachineControlPoint.requestControl();
        break;
      case MachineControlPointOpcodeType.reset:
        controlPoint = MachineControlPoint.reset();
        break;
      case MachineControlPointOpcodeType.setTargetSpeed:
        controlPoint = MachineControlPoint.setTargetSpeed(speed: 12);
        break;
      case MachineControlPointOpcodeType.setTargetInclination:
        controlPoint = MachineControlPoint.setTargetInclination(inclination: 23);
        break;
      case MachineControlPointOpcodeType.setTargetResistanceLevel:
        controlPoint = MachineControlPoint.setTargetResistanceLevel(resistanceLevel: resistanceLevel ?? 3);
        break;
      case MachineControlPointOpcodeType.setTargetPower:
        controlPoint = MachineControlPoint.setTargetPower(power: 34);
        break;
      case MachineControlPointOpcodeType.setTargetHeartRate:
        controlPoint = MachineControlPoint.setTargetHeartRate(heartRate: 45);
        break;
      case MachineControlPointOpcodeType.startOrResume:
        controlPoint = MachineControlPoint.startOrResume();
        break;
      case MachineControlPointOpcodeType.stopOrPause:
        controlPoint = MachineControlPoint.stopOrPause(pause: true);
        break;
      default:
        throw 'MachineControlPointOpcodeType $opcodeType is not implemented in this example';
    }

    await FTMS.writeMachineControlPointCharacteristic(ftmsDevice, controlPoint);
  }
}
