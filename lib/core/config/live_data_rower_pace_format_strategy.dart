import 'package:ftms/core/config/live_data_field_config.dart';
import 'live_data_field_format_strategy.dart';

/// Strategy for formatting rower pace in mm:ss/500m.
class LiveDataRowerPaceFormatStrategy implements LiveDataFieldFormatStrategy {
  const LiveDataRowerPaceFormatStrategy();

  String _formatPace(num value) {
    if (value <= 0) return '--:--';
    final seconds = value.toDouble();
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toInt().toString().padLeft(2, '0');
    return '$minutes:$secs/500m';
  }

  @override
  String format({
    required LiveDataFieldConfig field,
    required dynamic paramValue
  }) {
    final value = paramValue is num ? paramValue : num.tryParse(paramValue.toString()) ?? 0;
    return _formatPace(value);
  }
}

