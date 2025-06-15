import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/features/training/training_session_expansion_panel.dart';
import 'package:ftms/features/training/model/unit_training_interval.dart';
import 'package:ftms/features/training/model/training_session.dart';
import 'package:ftms/features/training/widgets/training_session_chart.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock AssetBundle for config loading
  setUpAll(() async {
    // Mock AssetManifest.json
    const manifest = '{"lib/config/rowing_machine.json":[],"lib/config/indoor_bike.json":[]}';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (message) async {
      final String key = const StringCodec().decodeMessage(message) as String;
      if (key == 'AssetManifest.json') {
        return const StringCodec().encodeMessage(manifest);
      }
      if (key == 'lib/config/rowing_machine.json') {
        return const StringCodec().encodeMessage('''{
  "fields": [
    { "name": "Instantaneous Speed", "label": "Speed", "display": "speedometer", "unit": "km/h", "min": 0, "max": 30 },
    { "name": "Stroke Rate", "label": "Stroke Rate", "display": "number", "unit": "spm", "icon": "rowing" },
    { "name": "Instantaneous Power", "label": "Power", "display": "speedometer", "unit": "W", "min": 0, "max": 1500 },
    { "name": "Heart Rate", "label": "Heart rate", "display": "number", "unit": "bpm", "icon": "heart" }
  ]
}''');
      }
      return null;
    });
  });

  testWidgets('TrainingSessionExpansionPanelList displays intervals and targets prettily', (WidgetTester tester) async {
    final session = TrainingSessionDefinition(
      title: 'Rowing Test',
      ftmsMachineType: 'DeviceDataType.rower',
      intervals: <UnitTrainingInterval>[
        UnitTrainingInterval(
          title: 'Warmup',
          duration: 60,
          targets: {'Stroke Rate': 24, 'Heart Rate': 120},
        ),
        UnitTrainingInterval(
          title: 'Main',
          duration: 300,
          targets: {'Instantaneous Power': 200},
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrainingSessionExpansionPanelList(
            sessions: [session],
            scrollController: ScrollController(),
          ),
        ),
      ),
    );
    // Expand the panel
    await tester.tap(find.byType(ExpansionPanelList));
    await tester.pumpAndSettle();
    
    // Should show the chart title
    expect(find.text('Training Intensity'), findsOneWidget);
    
    // Should show the interactive chart
    expect(find.byType(TrainingSessionChart), findsOneWidget);
    
    // Shouldn't show the start button
    expect(find.text('Start Session'), findsNothing);
    expect(find.textContaining('{'), findsNothing);
    expect(find.textContaining('}'), findsNothing);
  });
}
