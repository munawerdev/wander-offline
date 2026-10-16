import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wander_offline/core/utils/color_utils.dart';

void main() {
  group('colorFromHex', () {
    test('parses a six-digit hex from pack content', () {
      expect(colorFromHex('#BC002D'), const Color(0xFFBC002D));
      expect(colorFromHex('BC002D'), const Color(0xFFBC002D));
    });

    test('parses an eight-digit hex with alpha', () {
      expect(colorFromHex('#80BC002D'), const Color(0x80BC002D));
    });

    test('falls back instead of throwing on bad content', () {
      const fallback = Color(0xFF123456);
      expect(colorFromHex('', fallback: fallback), fallback);
      expect(colorFromHex('nonsense', fallback: fallback), fallback);
      expect(colorFromHex('#12345', fallback: fallback), fallback);
      expect(colorFromHex('#ZZZZZZ', fallback: fallback), fallback);
    });
  });

  group('readableOn', () {
    test('uses white text on dark backgrounds', () {
      expect(readableOn(const Color(0xFF000000)), const Color(0xFFFFFFFF));
      // Japanese flag red is dark enough to need white text.
      expect(readableOn(const Color(0xFFBC002D)), const Color(0xFFFFFFFF));
    });

    test('uses near-black text on light backgrounds', () {
      expect(readableOn(const Color(0xFFFFFFFF)), const Color(0xFF1A1A1A));
    });
  });
}
