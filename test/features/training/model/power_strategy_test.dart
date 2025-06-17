import 'package:flutter_test/flutter_test.dart';
import 'package:ftms/core/models/device_types.dart';
import 'package:ftms/features/settings/model/user_settings.dart';
import 'package:ftms/features/training/model/target_power_strategy.dart';

void main() {
  final userSettings = UserSettings(maxHeartRate: 190, cyclingFtp: 250, rowingFtp: '2:00');

  group('IndoorBikeTargetPowerStrategy', () {
    final strategy = IndoorBikeTargetPowerStrategy();

    test('resolves percentage string to absolute power', () {
      expect(strategy.resolvePower('120%', userSettings), 300); // 120% of 250
      expect(strategy.resolvePower('100%', userSettings), 250);
      expect(strategy.resolvePower('0%', userSettings), 0);
    });

    test('returns original value for non-percentage string', () {
      expect(strategy.resolvePower('foo', userSettings), 'foo');
      expect(strategy.resolvePower('120', userSettings), '120');
    });

    test('returns original value if userSettings is null', () {
      expect(strategy.resolvePower('120%', null), '120%');
    });

    test('returns original value for non-string', () {
      expect(strategy.resolvePower(123, userSettings), 123);
      expect(strategy.resolvePower(null, userSettings), null);
    });
  });

  group('RowerTargetPowerStrategy', () {
    final strategy = RowerTargetPowerStrategy();

    test('resolves percentage string to pace in seconds (100%)', () {
      expect(strategy.resolvePower('100%', userSettings), 120); // 2:00 = 120s
    });
    test('resolves percentage string to pace in seconds (<100%)', () {
      expect(strategy.resolvePower('95%', userSettings), 114); // 95% of 120s
    });
    test('resolves percentage string to pace in seconds (>100%)', () {
      expect(strategy.resolvePower('120%', userSettings), 144); // 120% of 120s
    });
    test('returns original value for non-percentage string', () {
      expect(strategy.resolvePower('foo', userSettings), 'foo');
      expect(strategy.resolvePower('120', userSettings), '120');
    });
    test('returns original value if userSettings is null', () {
      expect(strategy.resolvePower('120%', null), '120%');
    });
    test('returns original value for non-string', () {
      expect(strategy.resolvePower(123, userSettings), 123);
      expect(strategy.resolvePower(null, userSettings), null);
    });
    test('returns original value if rowingFtp is not parseable', () {
      final badSettings = UserSettings(maxHeartRate: 190, cyclingFtp: 250, rowingFtp: 'bad');
      expect(strategy.resolvePower('95%', badSettings), '95%');
    });
    test('returns original value if rowingFtp is missing colon', () {
      final badSettings = UserSettings(maxHeartRate: 190, cyclingFtp: 250, rowingFtp: '200');
      expect(strategy.resolvePower('95%', badSettings), '95%');
    });
    test('returns original value if rowingFtp has non-numeric', () {
      final badSettings = UserSettings(maxHeartRate: 190, cyclingFtp: 250, rowingFtp: '2:xx');
      expect(strategy.resolvePower('95%', badSettings), '95%');
    });
  });

  group('DefaultTargetPowerStrategy', () {
    final strategy = DefaultTargetPowerStrategy();

    test('returns original value', () {
      expect(strategy.resolvePower('120%', userSettings), '120%');
      expect(strategy.resolvePower(123, userSettings), 123);
    });
  });

  group('TargetPowerStrategyFactory', () {
    test('returns correct strategy for indoorBike', () {
      final s = TargetPowerStrategyFactory.getStrategy(DeviceType.indoorBike);
      expect(s, isA<IndoorBikeTargetPowerStrategy>());
    });
    test('returns correct strategy for rower', () {
      final s = TargetPowerStrategyFactory.getStrategy(DeviceType.rower);
      expect(s, isA<RowerTargetPowerStrategy>());
    });
  });
}
