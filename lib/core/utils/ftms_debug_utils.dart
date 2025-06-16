import '../models/live_data_field_value.dart';
import 'logger.dart';

void logFtmsParameterAttributes(List parameterValues) {
  logger.i('FTMS parameter attributes:');
  for (final param in parameterValues) {
    final flag = param.flag ?? 'n/a';
    final size = param.size ?? 'n/a';
    final unit = param.unit ?? 'n/a';
    final factor = param.factor ?? 'n/a';
    logger.i('  code: ${param.name.name}, value: ${param.value}, flag: $flag, size: $size, unit: $unit, factor: $factor');
  }
}

void logFtmsParameters(Map<String, LiveDataFieldValue> paramValueMap) {
  logger.i('Processed FTMS parameters:');
  for (final entry in paramValueMap.entries) {
    final param = entry.value;
    logger.i('  ${entry.key}: ${param.value} ${param.unit} (factor: ${param.factor})');
  }
}
