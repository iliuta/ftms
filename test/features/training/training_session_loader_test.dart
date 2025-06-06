import 'package:flutter_test/flutter_test.dart';
import 'package:fmts/features/training/training_session_loader.dart';

dynamic _enduranceRideJson = {
  "title": "Endurance Ride",
  "ftmsMachineType": "DeviceDataType.indoorBike",
  "intervals": [
    {
      "title": "Warm Up",
      "duration": 30,
      "targets": {"Instantaneous Power": 100, "Instantaneous Cadence": 80},
      "repeat": 10
    },
    {
      "title": "Main Set",
      "duration": 30,
      "targets": {"Instantaneous Power": 180, "Instantaneous Cadence": 90}
    },
    {
      "title": "Cool Down",
      "duration": 30,
      "targets": {"Instantaneous Power": 80, "Instantaneous Cadence": 70}
    }
  ]
};

void main() {
  test('TrainingSession.fromJson expands intervals with repeat field', () {
    final session = TrainingSession.fromJson(_enduranceRideJson);
    // Warm Up should be repeated 10 times, plus 2 more intervals
    expect(session.intervals.length, 12);
    for (int i = 0; i < 10; i++) {
      expect(session.intervals[i].title, 'Warm Up');
      expect(session.intervals[i].duration, 30);
      expect(session.intervals[i].targets, containsPair('Instantaneous Power', 100));
      expect(session.intervals[i].targets, containsPair('Instantaneous Cadence', 80));
    }
    expect(session.intervals[10].title, 'Main Set');
    expect(session.intervals[10].duration, 30);
    expect(session.intervals[10].targets, containsPair('Instantaneous Power', 180));
    expect(session.intervals[10].targets, containsPair('Instantaneous Cadence', 90));
    expect(session.intervals[11].title, 'Cool Down');
    expect(session.intervals[11].duration, 30);
    expect(session.intervals[11].targets, containsPair('Instantaneous Power', 80));
    expect(session.intervals[11].targets, containsPair('Instantaneous Cadence', 70));
  });
}
