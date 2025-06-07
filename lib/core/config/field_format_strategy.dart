import 'package:ftms/core/config/ftms_display_config.dart';
import 'package:ftms/core/config/rower_pace_format_strategy.dart';

/// Interface for field format strategies.
abstract class FieldFormatStrategy {
  /// Returns a formatted value for the given field and param.
  String format({
    required FtmsDisplayField field,
    required dynamic paramValue
  });
}

/// Registry for field format strategies.
class FieldFormatter {
  static final Map<String, FieldFormatStrategy> _strategies = {
    'rowerPaceFormatter': const RowerPaceFormatStrategy()
  };

  static FieldFormatStrategy? getStrategy(String formatterName) {
    return _strategies[formatterName];
  }
}

