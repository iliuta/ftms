import 'package:flutter_test/flutter_test.dart';
import 'package:fmts/features/training/training_session_controller.dart';
import 'package:fmts/features/training/training_session_loader.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class MockBluetoothDevice extends Mock implements BluetoothDevice {}


void main() {
  group('TrainingSessionController', () {
    late TrainingSession session;
    late MockBluetoothDevice device;

    setUp(() {
      session = TrainingSession(
        title: 'Test Session',
        ftmsMachineType: 'bike',
        intervals: <UnitTrainingInterval>[
          UnitTrainingInterval(duration: 60, title: 'Warmup', resistanceLevel: 1),
          UnitTrainingInterval(duration: 120, title: 'Main', resistanceLevel: 2),
        ],
      );
      device = MockBluetoothDevice();
    });

    test('initializes with correct intervals and duration', () {
      final controller = TrainingSessionController(session: session, ftmsDevice: device);
      expect(controller.intervals.length, 2);
      expect(controller.totalDuration, 180);
      expect(controller.currentInterval, 0);
      controller.dispose();
    });

    // More tests can be added for timer, FTMS commands, etc. with further mocking
  });
}
