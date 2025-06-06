import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:fmts/core/utils/ftms_icon_registry.dart';

void main() {
  group('ftmsIconRegistry', () {
    test('returns correct icon for known keys', () {
      expect(getFtmsIcon('heart'), Icons.favorite);
      expect(getFtmsIcon('bike'), Icons.pedal_bike);
      expect(getFtmsIcon('rowing'), Icons.rowing);
    });
    test('returns null for unknown key', () {
      expect(getFtmsIcon('unknown'), isNull);
    });
  });
}
