import 'package:flutter_test/flutter_test.dart';
import 'package:fmts/features/training/training_session_controller.dart';

import 'package:fmts/features/training/training_session_loader.dart';
import 'package:flutter_ftms/flutter_ftms.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'dart:io';
import 'package:fit_tool/fit_tool.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fmts/features/training/fit_file_utils.dart';

class MockBluetoothDevice extends Mock implements BluetoothDevice {}

// Helper to convert DateTime to FIT epoch seconds (since 1989-12-31 00:00:00 UTC)



void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('TrainingSessionController', () {
    late TrainingSession session;
    late MockBluetoothDevice device;

    setUp(() {
      session = TrainingSession(
        title: 'Test Session',
        ftmsMachineType: 'bike',
        intervals: [
          TrainingInterval(duration: 60, title: 'Warmup', resistanceLevel: 1),
          TrainingInterval(duration: 120, title: 'Main', resistanceLevel: 2),
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
