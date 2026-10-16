/// Defensive JSON readers.
///
/// Pack content arrives from two untrusted places: bundled asset files that a
/// content editor can typo, and third-party APIs that change shape without
/// warning. Every field read goes through these helpers so that one missing or
/// renamed key degrades to a sensible default instead of throwing while a
/// screen is building.
library;

String jsonString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value.isEmpty ? fallback : value;
  return value.toString();
}

int jsonInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double jsonDouble(dynamic value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

bool jsonBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value.toLowerCase() == 'true';
  return fallback;
}

/// Reads a list of non-empty strings. A lone string is treated as a one-item
/// list so hand-written content can be terse when it wants to be.
List<String> jsonStringList(dynamic value) {
  if (value is String) {
    return value.isEmpty ? <String>[] : <String>[value];
  }
  if (value is List) {
    return value.map(jsonString).where((String item) => item.isNotEmpty).toList();
  }
  return <String>[];
}

Map<String, dynamic> jsonMap(dynamic value) {
  if (value is Map) {
    return value.map(
      (dynamic key, dynamic item) =>
          MapEntry<String, dynamic>(key.toString(), item),
    );
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> jsonMapList(dynamic value) {
  if (value is List) {
    return value.map(jsonMap).toList();
  }
  return <Map<String, dynamic>>[];
}

/// Reads a numeric map such as an exchange-rate table, skipping entries that
/// are not numbers rather than failing the whole payload.
Map<String, double> jsonDoubleMap(dynamic value) {
  final map = jsonMap(value);
  final result = <String, double>{};
  for (final entry in map.entries) {
    final parsed = jsonDouble(entry.value, fallback: double.nan);
    if (!parsed.isNaN) {
      result[entry.key.toUpperCase()] = parsed;
    }
  }
  return result;
}

DateTime? jsonDate(dynamic value) {
  final raw = jsonString(value);
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
