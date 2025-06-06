import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fmts/features/training/training_session_expansion_panel.dart';
import 'package:fmts/features/training/training_session_loader.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock AssetBundle for config loading
  setUpAll(() async {
    // Mock AssetManifest.json
    const manifest = '{"lib/config/rowing_machine.json":[],"lib/config/indoor_bike.json":[]}';
    ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (message) async {
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
    final session = TrainingSession(
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
    // Should show interval titles and durations
    expect(find.textContaining('Warmup: 60s'), findsOneWidget);
    expect(find.textContaining('Main: 300s'), findsOneWidget);
    // Should show pretty targets (label and value, not raw JSON)
    expect(find.textContaining('Stroke Rate:'), findsOneWidget);
    expect(find.textContaining('Heart rate:'), findsOneWidget);
    expect(find.textContaining('Power:'), findsOneWidget);
    // Should not show raw JSON curly braces
    expect(find.textContaining('{'), findsNothing);
    expect(find.textContaining('}'), findsNothing);
  });
}
