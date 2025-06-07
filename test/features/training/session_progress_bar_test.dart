import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/features/training/session_progress_bar.dart';

void main() {
  testWidgets('SessionProgressBar displays progress and formatted time', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionProgressBar(
            progress: 0.5,
            timeLeft: 90,
            formatTime: (s) => '01:30',
          ),
        ),
      ),
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('01:30'), findsOneWidget);
  });
}
