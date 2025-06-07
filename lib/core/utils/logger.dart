import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger(
  level: kReleaseMode ? Level.warning : Level.debug,
);
