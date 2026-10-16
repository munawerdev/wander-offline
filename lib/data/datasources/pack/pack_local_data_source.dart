import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '/data/models/pack/country_pack_model.dart';

/// Hive-backed store for installed packs and app metadata.
///
/// Two boxes are used:
///
///  * [packBoxName] holds one JSON string per installed country, keyed by ISO
///    country code. Storing JSON rather than a generated Hive adapter keeps the
///    project free of code generation, and means an old pack written by an
///    earlier app version still parses via the models' defensive `fromJson`.
///  * [metaBoxName] holds small key/value settings: which packs are unlocked,
///    whether the free pick has been used, preview windows, and preferences.
class PackLocalDataSource {
  static const String packBoxName = 'wander_pack_data';
  static const String metaBoxName = 'wander_pack_meta';

  late final Box<String> _packs;
  late final Box<String> _meta;

  /// Opens both boxes. Must complete before any other method is called, so it
  /// runs during dependency-injection start-up.
  Future<void> init() async {
    await Hive.initFlutter();
    _packs = await Hive.openBox<String>(packBoxName);
    _meta = await Hive.openBox<String>(metaBoxName);
  }

  bool get isReady => _packs.isOpen && _meta.isOpen;

  // ---------------------------------------------------------------------------
  // Installed packs
  // ---------------------------------------------------------------------------

  Future<void> savePack(CountryPackModel pack) =>
      _packs.put(pack.countryCode.toUpperCase(), jsonEncode(pack.toJson()));

  Future<CountryPackModel?> readPack(String countryCode) async {
    final raw = _packs.get(countryCode.toUpperCase());
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return CountryPackModel.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      // A corrupt entry should not brick the browser; treat it as absent.
      return null;
    }
  }

  Future<List<CountryPackModel>> readAllPacks() async {
    final result = <CountryPackModel>[];
    for (final key in _packs.keys) {
      final pack = await readPack(key.toString());
      if (pack != null) result.add(pack);
    }
    return result;
  }

  Future<List<String>> installedCountryCodes() async =>
      _packs.keys.map((dynamic key) => key.toString().toUpperCase()).toList();

  Future<bool> containsPack(String countryCode) async =>
      _packs.containsKey(countryCode.toUpperCase());

  Future<void> deletePack(String countryCode) =>
      _packs.delete(countryCode.toUpperCase());

  Future<void> deleteAllPacks() => _packs.clear();

  /// Rough on-device footprint of all installed packs, for the storage readout.
  Future<int> installedBytes() async {
    var total = 0;
    for (final key in _packs.keys) {
      total += (_packs.get(key) ?? '').length;
    }
    return total;
  }

  // ---------------------------------------------------------------------------
  // Metadata
  // ---------------------------------------------------------------------------

  String? readMeta(String key) {
    final value = _meta.get(key);
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<void> writeMeta(String key, String value) => _meta.put(key, value);

  Future<void> deleteMeta(String key) => _meta.delete(key);

  List<String> readStringList(String key) {
    final raw = readMeta(key);
    if (raw == null) return <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((dynamic item) => item.toString()).toList();
      }
    } catch (_) {
      return <String>[];
    }
    return <String>[];
  }

  Future<void> writeStringList(String key, Iterable<String> values) =>
      writeMeta(key, jsonEncode(values.toList()));

  bool readFlag(String key, {bool fallback = false}) {
    final raw = readMeta(key);
    if (raw == null) return fallback;
    return raw.toLowerCase() == 'true';
  }

  Future<void> writeFlag(String key, {required bool value}) =>
      writeMeta(key, value.toString());

  Future<void> clearAll() async {
    await _packs.clear();
    await _meta.clear();
  }
}
