import 'package:ftms/core/models/ftms_display_field.dart';
import 'field_format_strategy.dart';

/// Strategy for formatting rower pace in mm:ss/500m.
class RowerPaceFormatStrategy implements FieldFormatStrategy {
  const RowerPaceFormatStrategy();

  String _formatPace(num value) {
    if (value <= 0) return '--:--';
    final seconds = value.toDouble();
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toInt().toString().padLeft(2, '0');
    return '$minutes:$secs/500m';
  }

  @override
  String format({
    required FtmsDisplayField field,
    required dynamic paramValue
  }) {
    final value = paramValue is num ? paramValue : num.tryParse(paramValue.toString()) ?? 0;
    return _formatPace(value);
  }
}

