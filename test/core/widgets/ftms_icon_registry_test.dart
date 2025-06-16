import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ftms/core/widgets/live_data_icon_registry.dart';

void main() {
  group('ftmsIconRegistry', () {
    test('returns correct icon for known keys', () {
      expect(getLiveDataIcon('heart'), Icons.favorite);
      expect(getLiveDataIcon('bike'), Icons.pedal_bike);
      expect(getLiveDataIcon('rowing'), Icons.rowing);
    });
    test('returns null for unknown key', () {
      expect(getLiveDataIcon('unknown'), isNull);
    });
  });
}
