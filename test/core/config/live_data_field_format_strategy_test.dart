import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/config/live_data_field_format_strategy.dart';
import 'package:ftms/core/config/live_data_rower_pace_format_strategy.dart';
import 'package:ftms/core/config/live_data_field_config.dart';

class DummyParam {
  final int value;
  final num factor;
  DummyParam(this.value, {this.factor = 1});
  @override
  String toString() => value.toString();
}

void main() {
  group('FieldFormatter', () {
    test('getStrategy returns correct strategy for known formatter', () {
      final strategy = LiveDataFieldFormatter.getStrategy('rowerPaceFormatter');
      expect(strategy, isA<LiveDataRowerPaceFormatStrategy>());
    });

    test('getStrategy returns null for unknown formatter', () {
      final strategy = LiveDataFieldFormatter.getStrategy('unknownFormatter');
      expect(strategy, isNull);
    });

    test('rowerPaceFormatter formats pace correctly', () {
      final field = LiveDataFieldConfig(
        name: 'Instantaneous Pace',
        label: 'Pace',
        display: 'number',
        formatter: 'rowerPaceFormatter',
        unit: 's/500m',
      );
      final param = DummyParam(120);
      final strategy = LiveDataFieldFormatter.getStrategy('rowerPaceFormatter');
      final formatted = strategy!.format(field: field, paramValue: param.value);
      expect(formatted, '02:00/500m');
    });
  });
}
