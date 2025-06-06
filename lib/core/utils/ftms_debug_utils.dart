// This file was moved from lib/ftms_debug_utils.dart
import 'package:flutter_ftms/flutter_ftms.dart';

void logFtmsParameterAttributes(List parameterValues) {
  // ignore: avoid_print
  //print('FTMS parameter attributes:');
  for (final param in parameterValues) {
    // Try to access flag, size, unit, factor if available
    final flag = param.flag ?? 'n/a';
    final size = param.size ?? 'n/a';
    final unit = param.unit ?? 'n/a';
    final factor = param.factor ?? 'n/a';
    // ignore: avoid_print
    //print('  code: ${param.name.name}, value: ${param.value}, flag: $flag, size: $size, unit: $unit, factor: $factor');
  }
}
