import 'package:ftms/core/config/live_data_int_format_strategy.dart';
import 'package:ftms/core/config/live_data_rower_pace_format_strategy.dart';
import 'package:ftms/core/config/live_data_field_config.dart';

/// Interface for field format strategies.
abstract class LiveDataFieldFormatStrategy {
  /// Returns a formatted value for the given field and param.
  String format({
    required LiveDataFieldConfig field,
    required dynamic paramValue
  });
}

/// Registry for field format strategies.
class LiveDataFieldFormatter {
  static final Map<String, LiveDataFieldFormatStrategy> _strategies = {
    'rowerPaceFormatter': const LiveDataRowerPaceFormatStrategy(),
    'intFormatter': const LiveDataIntFormatStrategy()
  };

  static LiveDataFieldFormatStrategy? getStrategy(String formatterName) {
    return _strategies[formatterName];
  }
}

