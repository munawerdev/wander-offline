import 'package:material_ui/material_ui.dart';

/// Parses a `#RRGGBB` or `#AARRGGBB` string out of pack content.
///
/// Content authors write accent colours by hand, so anything unparseable falls
/// back to [fallback] rather than throwing during a build.
Color colorFromHex(String hex, {Color fallback = const Color(0xFF2196F3)}) {
  var value = hex.trim();
  if (value.isEmpty) return fallback;
  if (value.startsWith('#')) {
    value = value.substring(1);
  }
  if (value.length == 6) {
    value = 'FF$value';
  }
  if (value.length != 8) return fallback;
  final parsed = int.tryParse(value, radix: 16);
  if (parsed == null) return fallback;
  return Color(parsed);
}

/// Picks a readable foreground colour for text drawn on [background] using the
/// WCAG relative-luminance formula. Keeps pack accent colours, which range from
/// Thai red to Italian green, legible in both light and dark themes.
Color readableOn(Color background) {
  final luminance = background.computeLuminance();
  return luminance > 0.5 ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF);
}
