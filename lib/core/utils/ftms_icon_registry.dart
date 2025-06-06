import 'package:flutter/material.dart';

/// Registry of available FTMS icons for use in config files and widgets.
final Map<String, IconData> ftmsIconRegistry = {
  'heart': Icons.favorite,
  'cadence': Icons.cyclone, // Placeholder for pedal/cadence
  'bike': Icons.pedal_bike,
  'rowing': Icons.rowing,
};

/// Utility to select the correct icon for FTMS display fields.
IconData? getFtmsIcon(String? icon) {
  if (icon == null) return null;
  return ftmsIconRegistry[icon];
}
