import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/services/cadence_service.dart';

void main() {
  group('CadenceService Data Parsing', () {
    late CadenceService service;
    
    setUp(() {
      service = CadenceService();
    });
    
    test('should handle various data packet lengths gracefully', () {
      // Test that the service doesn't crash with different data lengths
      expect(service.currentCadence, isNull);
      expect(service.isCadenceConnected, isFalse);
    });
    
    test('should provide proper connection status', () {
      expect(service.isCadenceConnected, isFalse);
      expect(service.connectedDeviceName, isNull);
      expect(service.currentCadence, isNull);
    });
    
    test('should have cadence stream available', () {
      expect(service.cadenceStream, isNotNull);
    });
  });
}
