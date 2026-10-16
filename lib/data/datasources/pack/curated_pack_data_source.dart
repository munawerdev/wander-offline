import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Loads the hand-written pack content that ships inside the app bundle.
///
/// Landmarks and local tips are authored content, not API output - they are the
/// reason someone buys a pack instead of opening a search engine in a browser.
/// Bundling them means the catalogue renders with no network at all, and a
/// content fix is an ordinary app release rather than a server deploy.
class CuratedPackDataSource {
  /// Country codes that have bundled content. This order is the catalogue
  /// order shown in the pack browser: the three launch packs first, then the
  /// countries added after them.
  ///
  /// Adding a country is this list plus one `assets/content/<code>.json` file.
  /// `test/content/pack_content_test.dart` then enforces the content quality and
  /// fails if the two ever drift apart.
  static const List<String> curatedCountryCodes = <String>[
    'JP',
    'IT',
    'TH',
    'VN',
    'PT',
    'MA',
    'TR',
    'PE',
  ];

  final Map<String, Map<String, dynamic>> _cache =
      <String, Map<String, dynamic>>{};

  /// Reads one bundled pack file.
  ///
  /// Returns null **only** when [countryCode] is not part of the catalogue. A
  /// known pack whose asset cannot be read or parsed throws instead, because that
  /// is a genuine failure and must not be disguised.
  ///
  /// This matters in practice: a previous version swallowed the error and
  /// returned null, which made "the asset bundle does not contain this file" look
  /// identical to "this country has no content". The result was an empty
  /// catalogue with no explanation - which is exactly what a hot reload produces
  /// after `assets/content/` is first added to `pubspec.yaml`, because a reload
  /// does not re-bundle assets. Throwing here lets the repository surface a
  /// visible error with a retry instead.
  Future<Map<String, dynamic>?> loadPack(String countryCode) async {
    final code = countryCode.toUpperCase();
    final cached = _cache[code];
    if (cached != null) return cached;
    if (!curatedCountryCodes.contains(code)) return null;

    final raw = await rootBundle.loadString(assetPathFor(code));

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw FormatException(
        'Bundled pack content for $code is not a JSON object',
      );
    }

    final content = Map<String, dynamic>.from(decoded);
    _cache[code] = content;
    return content;
  }

  /// Every bundled pack, in catalogue order. Throws if a catalogue entry fails
  /// to load, rather than quietly returning a shorter list.
  ///
  /// Loaded concurrently because each read is an async asset round trip, and the
  /// browser blocks on all of them before it can render anything.
  Future<List<Map<String, dynamic>>> loadCatalogue() async {
    final loaded = await Future.wait(curatedCountryCodes.map(loadPack));
    return loaded.whereType<Map<String, dynamic>>().toList();
  }

  static String assetPathFor(String countryCode) =>
      'assets/content/${countryCode.toLowerCase()}.json';
}
