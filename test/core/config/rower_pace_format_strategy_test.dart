import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/config/rower_pace_format_strategy.dart';
import 'package:ftms/core/models/ftms_display_field.dart';

void main() {
  group('RowerPaceFormatStrategy', () {
    final strategy = const RowerPaceFormatStrategy();
    final field = FtmsDisplayField(
      name: 'Instantaneous Pace',
      label: 'Pace',
      display: 'number',
      formatter: 'rowerPaceFormatter',
      unit: 's/500m',
    );

    test('formats valid pace', () {
      expect(strategy.format(field: field, paramValue: 125), '02:05/500m');
      expect(strategy.format(field: field, paramValue: 60), '01:00/500m');
      expect(strategy.format(field: field, paramValue: 0), '--:--');
      expect(strategy.format(field: field, paramValue: -10), '--:--');
    });

    test('formats pace from string param', () {
      expect(strategy.format(field: field, paramValue: '90'), '01:30/500m');
    });

    test('formats pace with non-numeric param', () {
      expect(strategy.format(field: field, paramValue: 'not_a_number'), '--:--');
    });
  });
}
