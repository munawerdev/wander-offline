import '/core/utils/json_utils.dart';

/// An exchange-rate snapshot keyed off a single base currency.
///
/// Frankfurter returns `{"base":"USD","date":"...","rates":{"JPY":158.02,...}}`
/// where every value is "how many units of this currency per 1 base". Rates are
/// stored inside the pack, so a traveller who downloaded while on hotel Wi-Fi
/// still gets a realistic conversion in airplane mode.
class ExchangeRatesModel {
  final String base;
  final Map<String, double> rates;
  final DateTime fetchedAt;
  final String source;

  const ExchangeRatesModel({
    required this.base,
    required this.rates,
    required this.fetchedAt,
    required this.source,
  });

  factory ExchangeRatesModel.fromJson(Map<String, dynamic> json) =>
      ExchangeRatesModel(
        base: jsonString(json['base'], fallback: 'USD').toUpperCase(),
        rates: jsonDoubleMap(json['rates']),
        fetchedAt: jsonDate(json['fetchedAt']) ?? DateTime.now(),
        source: jsonString(json['source']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'base': base,
    'rates': rates,
    'fetchedAt': fetchedAt.toIso8601String(),
    'source': source,
  };

  factory ExchangeRatesModel.empty() => ExchangeRatesModel(
    base: 'USD',
    rates: const <String, double>{},
    fetchedAt: DateTime.now(),
    source: '',
  );

  bool get hasRates => rates.isNotEmpty;

  /// Alphabetical list of selectable currencies, always including the base.
  List<String> get currencies {
    final codes = <String>{base, ...rates.keys}.toList()..sort();
    return codes;
  }

  /// How many units of [code] one unit of [base] buys.
  double? rateFor(String code) {
    final upper = code.toUpperCase();
    if (upper == base) return 1;
    return rates[upper];
  }

  /// Converts [amount] between any two currencies present in the snapshot.
  ///
  /// Returns null when either currency is missing, so the UI can say "rate
  /// unavailable" rather than silently showing a wrong number.
  double? convert({
    required double amount,
    required String from,
    required String to,
  }) {
    final fromRate = rateFor(from);
    final toRate = rateFor(to);
    if (fromRate == null || toRate == null || fromRate == 0) return null;
    return amount / fromRate * toRate;
  }

  /// True when the snapshot is old enough that the UI should flag it as stale.
  bool isStale({Duration tolerance = const Duration(hours: 48)}) =>
      DateTime.now().difference(fetchedAt) > tolerance;
}
