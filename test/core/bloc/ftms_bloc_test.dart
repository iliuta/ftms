import 'package:flutter_test/flutter_test.dart';
import '../../../lib/core/bloc/ftms_bloc.dart';
import 'package:flutter_ftms/src/ftms/characteristic/data/device_data.dart';
import 'package:flutter_ftms/src/ftms/characteristic/machine/feature/machine_feature.dart';
// Import Flag and DeviceDataParameter for the fake class
import 'package:flutter_ftms/src/ftms/flag.dart';
import 'package:flutter_ftms/src/ftms/characteristic/data/device_data_parameter.dart';




void main() {
  group('FTMSBloc', () {

    test('should add and receive DeviceData', () async {
      final testData = FakeDeviceData();
      final future = expectLater(
        ftmsBloc.ftmsDeviceDataControllerStream.timeout(const Duration(seconds: 2)),
        emits(testData),
      );
      ftmsBloc.ftmsDeviceDataControllerSink.add(testData);
      await future;
    });

    test('should add and receive MachineFeature', () async {
      final testFeature = MachineFeature([0, 1, 2, 3]);
      final future = expectLater(
        ftmsBloc.ftmsMachineFeaturesControllerStream.timeout(const Duration(seconds: 2)),
        emits(testFeature),
      );
      ftmsBloc.ftmsMachineFeaturesControllerSink.add(testFeature);
      await future;
    });
  });
}

class FakeDeviceData extends DeviceData {
  FakeDeviceData() : super([0, 0, 0, 0]);
  @override
  DeviceDataType get deviceDataType => DeviceDataType.indoorBike;
  @override
  List<Flag> get allDeviceDataFlags => [];
  @override
  List<DeviceDataParameter> get allDeviceDataParameters => [];
}

