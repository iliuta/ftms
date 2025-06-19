import 'package:ftms/core/config/live_data_field_config.dart';
import 'package:ftms/core/config/live_data_field_format_strategy.dart';

class LiveDataIntFormatStrategy  implements LiveDataFieldFormatStrategy {
  const LiveDataIntFormatStrategy();
  @override
  String format({
    required LiveDataFieldConfig field,
    required dynamic paramValue
  }) {
    final value = paramValue is num ? paramValue : num.tryParse(paramValue.toString()) ?? 0;
    return value.toStringAsFixed(0);
  }
}
