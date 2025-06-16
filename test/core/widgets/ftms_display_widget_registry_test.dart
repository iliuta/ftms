import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/widgets/live_data_field_widget_registry.dart';

void main() {
  group('ftmsDisplayWidgetRegistry', () {
    test('contains number and speedometer widgets', () {
      expect(liveDataFieldWidgetRegistry.containsKey('number'), isTrue);
      expect(liveDataFieldWidgetRegistry.containsKey('speedometer'), isTrue);
    });
  });
}
