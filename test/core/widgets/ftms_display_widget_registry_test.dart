import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/widgets/ftms_display_widget_registry.dart';

void main() {
  group('ftmsDisplayWidgetRegistry', () {
    test('contains number and speedometer widgets', () {
      expect(ftmsDisplayWidgetRegistry.containsKey('number'), isTrue);
      expect(ftmsDisplayWidgetRegistry.containsKey('speedometer'), isTrue);
    });
  });
}
