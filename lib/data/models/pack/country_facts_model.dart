import '/core/utils/json_utils.dart';

/// Currency metadata carried inside a country pack.
class CurrencyFactsModel {
  final String code;
  final String name;
  final String symbol;

  const CurrencyFactsModel({
    required this.code,
    required this.name,
    required this.symbol,
  });

  factory CurrencyFactsModel.fromJson(Map<String, dynamic> json) =>
      CurrencyFactsModel(
        code: jsonString(json['code'], fallback: 'USD').toUpperCase(),
        name: jsonString(json['name'], fallback: 'US dollar'),
        symbol: jsonString(json['symbol'], fallback: r'$'),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code,
    'name': name,
    'symbol': symbol,
  };

  factory CurrencyFactsModel.empty() => const CurrencyFactsModel(
    code: 'USD',
    name: 'US dollar',
    symbol: r'$',
  );

  /// `USD - US dollar` for compact list rows.
  String get label => '$code - $name';
}

/// The encyclopaedia half of a pack: the "country facts" card.
///
/// These values ship inside the pack content rather than being fetched at
/// download time, so the card is complete the moment a pack is installed and
/// never shows a hole when the device is offline.
class CountryFactsModel {
  final String capital;
  final String region;
  final String subregion;
  final int population;
  final double areaKm2;
  final CurrencyFactsModel currency;
  final List<String> languages;
  final String callingCode;
  final String drivingSide;
  final List<String> timezones;
  final String powerPlug;
  final String tapWater;
  final String visaNote;
  final String bestMonths;
  final String dailyBudget;
  final String cashVsCard;

  const CountryFactsModel({
    required this.capital,
    required this.region,
    required this.subregion,
    required this.population,
    required this.areaKm2,
    required this.currency,
    required this.languages,
    required this.callingCode,
    required this.drivingSide,
    required this.timezones,
    required this.powerPlug,
    required this.tapWater,
    required this.visaNote,
    required this.bestMonths,
    required this.dailyBudget,
    required this.cashVsCard,
  });

  factory CountryFactsModel.fromJson(Map<String, dynamic> json) =>
      CountryFactsModel(
        capital: jsonString(json['capital']),
        region: jsonString(json['region']),
        subregion: jsonString(json['subregion']),
        population: jsonInt(json['population']),
        areaKm2: jsonDouble(json['areaKm2']),
        currency: CurrencyFactsModel.fromJson(jsonMap(json['currency'])),
        languages: jsonStringList(json['languages']),
        callingCode: jsonString(json['callingCode']),
        drivingSide: jsonString(json['drivingSide'], fallback: 'right'),
        timezones: jsonStringList(json['timezones']),
        powerPlug: jsonString(json['powerPlug']),
        tapWater: jsonString(json['tapWater']),
        visaNote: jsonString(json['visaNote']),
        bestMonths: jsonString(json['bestMonths']),
        dailyBudget: jsonString(json['dailyBudget']),
        cashVsCard: jsonString(json['cashVsCard']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'capital': capital,
    'region': region,
    'subregion': subregion,
    'population': population,
    'areaKm2': areaKm2,
    'currency': currency.toJson(),
    'languages': languages,
    'callingCode': callingCode,
    'drivingSide': drivingSide,
    'timezones': timezones,
    'powerPlug': powerPlug,
    'tapWater': tapWater,
    'visaNote': visaNote,
    'bestMonths': bestMonths,
    'dailyBudget': dailyBudget,
    'cashVsCard': cashVsCard,
  };

  factory CountryFactsModel.empty() => CountryFactsModel(
    capital: '',
    region: '',
    subregion: '',
    population: 0,
    areaKm2: 0,
    currency: CurrencyFactsModel.empty(),
    languages: const <String>[],
    callingCode: '',
    drivingSide: 'right',
    timezones: const <String>[],
    powerPlug: '',
    tapWater: '',
    visaNote: '',
    bestMonths: '',
    dailyBudget: '',
    cashVsCard: '',
  );

  /// True when the content file actually carried a facts block.
  bool get hasContent => capital.isNotEmpty || population > 0;

  String get populationLabel {
    if (population <= 0) return 'Unknown';
    if (population >= 1000000) {
      final millions = population / 1000000;
      return '${millions.toStringAsFixed(1)} million';
    }
    return population.toString();
  }

  String get areaLabel => areaKm2 <= 0
      ? 'Unknown'
      : '${areaKm2.round()} km²';

  String get languagesLabel =>
      languages.isEmpty ? 'Unknown' : languages.join(', ');

  String get timezonesLabel =>
      timezones.isEmpty ? 'Unknown' : timezones.join(', ');

  /// `Left` / `Right`, capitalised for display.
  String get drivingSideLabel => drivingSide.toLowerCase() == 'left'
      ? 'Drive on the left'
      : 'Drive on the right';
}
