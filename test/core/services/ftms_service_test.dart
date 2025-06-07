import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/services/ftms_service.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class MockBluetoothDevice extends BluetoothDevice {
  MockBluetoothDevice() : super(remoteId: const DeviceIdentifier('00:00:00:00:00:00'));
}

class MockFTMS {
  static bool called = false;
  static late MachineControlPoint lastControlPoint;
  static late BluetoothDevice lastDevice;
  static Future<void> writeMachineControlPointCharacteristic(BluetoothDevice device, MachineControlPoint controlPoint) async {
    called = true;
    lastDevice = device;
    lastControlPoint = controlPoint;
  }
}

void main() {
  group('FTMSService', () {
    late FTMSService service;
    late MockBluetoothDevice device;

    setUp(() {
      device = MockBluetoothDevice();
      service = FTMSService(
        device,
        writeCharacteristic: MockFTMS.writeMachineControlPointCharacteristic,
      );
    });

    test('writeCommand calls FTMS.writeMachineControlPointCharacteristic', () async {
      await service.writeCommand(MachineControlPointOpcodeType.requestControl);
      expect(MockFTMS.called, isTrue);
      expect(MockFTMS.lastDevice, device);
      expect(MockFTMS.lastControlPoint, isNotNull);
    });
  });
}
