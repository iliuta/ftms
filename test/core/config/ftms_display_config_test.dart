import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/config/ftms_display_config.dart';

void main() {
  group('FtmsDisplayConfig', () {
    test('can parse from JSON', () {
      final json = {
        'fields': [
          {
            'name': 'Speed',
            'label': 'Speed',
            'display': 'number',
            'unit': 'km/h',
            'min': 0,
            'max': 60,
            'icon': 'bike'
          }
        ]
      };
      final config = FtmsDisplayConfig.fromJson(json);
      expect(config.fields.length, 1);
      expect(config.fields.first.name, 'Speed');
      expect(config.fields.first.icon, 'bike');
    });
  });
}
