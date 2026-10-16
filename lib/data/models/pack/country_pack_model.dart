import '/core/utils/json_utils.dart';
import 'country_facts_model.dart';
import 'exchange_rates_model.dart';
import 'landmark_model.dart';
import 'local_tips_model.dart';
import 'weather_trend_model.dart';

/// The catalogue entry for a pack: everything the browser list needs, without
/// the megabytes of landmark content.
///
/// Summary data comes from the bundled content files, so the catalogue renders
/// instantly and identically whether or not the traveller is online.
class PackSummaryModel {
  final String countryCode;
  final String name;
  final String tagline;
  final String region;
  final String accentColorHex;
  final String currencyCode;
  final String primaryCity;
  final double latitude;
  final double longitude;
  final String blurb;
  final int landmarkCount;
  final int tipCount;

  const PackSummaryModel({
    required this.countryCode,
    required this.name,
    required this.tagline,
    required this.region,
    required this.accentColorHex,
    required this.currencyCode,
    required this.primaryCity,
    required this.latitude,
    required this.longitude,
    required this.blurb,
    required this.landmarkCount,
    required this.tipCount,
  });

  factory PackSummaryModel.fromJson(Map<String, dynamic> json) =>
      PackSummaryModel(
        countryCode: jsonString(json['countryCode']).toUpperCase(),
        name: jsonString(json['name']),
        tagline: jsonString(json['tagline']),
        region: jsonString(json['region']),
        accentColorHex: jsonString(json['accentColor'], fallback: '#2196F3'),
        currencyCode: jsonString(json['currencyCode'], fallback: 'USD'),
        primaryCity: jsonString(json['primaryCity']),
        latitude: jsonDouble(json['latitude']),
        longitude: jsonDouble(json['longitude']),
        blurb: jsonString(json['blurb']),
        landmarkCount: jsonMapList(json['landmarks']).length,
        tipCount: LocalTipsModel.fromJson(jsonMap(json['tips'])).totalTips,
      );

  factory PackSummaryModel.fromPack(CountryPackModel pack) => PackSummaryModel(
    countryCode: pack.countryCode,
    name: pack.name,
    tagline: pack.tagline,
    region: pack.region,
    accentColorHex: pack.accentColorHex,
    currencyCode: pack.currencyCode,
    primaryCity: pack.primaryCity,
    latitude: pack.latitude,
    longitude: pack.longitude,
    blurb: pack.blurb,
    landmarkCount: pack.landmarks.length,
    tipCount: pack.tips.totalTips,
  );

  /// Regional-indicator flag emoji derived from the ISO country code, which
  /// avoids shipping (or downloading) a single image asset per country.
  String get flagEmoji {
    if (countryCode.length != 2) return '🌍';
    const base = 0x1F1E6;
    final first = countryCode.codeUnitAt(0) - 0x41 + base;
    final second = countryCode.codeUnitAt(1) - 0x41 + base;
    return String.fromCharCodes(<int>[first, second]);
  }
}

/// A complete, self-contained country pack as persisted on the device.
class CountryPackModel {
  final String countryCode;
  final String name;
  final String tagline;
  final String region;
  final String accentColorHex;
  final String currencyCode;
  final String primaryCity;
  final double latitude;
  final double longitude;
  final String blurb;
  final CountryFactsModel facts;
  final List<LandmarkModel> landmarks;
  final LocalTipsModel tips;
  final WeatherTrendModel weather;
  final ExchangeRatesModel rates;

  /// When this copy was first installed on the device.
  final DateTime installedAt;

  /// When the volatile parts (weather / rates) were last refreshed.
  final DateTime? refreshedAt;

  const CountryPackModel({
    required this.countryCode,
    required this.name,
    required this.tagline,
    required this.region,
    required this.accentColorHex,
    required this.currencyCode,
    required this.primaryCity,
    required this.latitude,
    required this.longitude,
    required this.blurb,
    required this.facts,
    required this.landmarks,
    required this.tips,
    required this.weather,
    required this.rates,
    required this.installedAt,
    this.refreshedAt,
  });

  factory CountryPackModel.fromJson(Map<String, dynamic> json) =>
      CountryPackModel(
        countryCode: jsonString(json['countryCode']).toUpperCase(),
        name: jsonString(json['name']),
        tagline: jsonString(json['tagline']),
        region: jsonString(json['region']),
        accentColorHex: jsonString(json['accentColor'], fallback: '#2196F3'),
        currencyCode: jsonString(json['currencyCode'], fallback: 'USD'),
        primaryCity: jsonString(json['primaryCity']),
        latitude: jsonDouble(json['latitude']),
        longitude: jsonDouble(json['longitude']),
        blurb: jsonString(json['blurb']),
        facts: CountryFactsModel.fromJson(jsonMap(json['facts'])),
        landmarks: jsonMapList(json['landmarks'])
            .map(LandmarkModel.fromJson)
            .toList(),
        tips: LocalTipsModel.fromJson(jsonMap(json['tips'])),
        weather: WeatherTrendModel.fromJson(jsonMap(json['weather'])),
        rates: ExchangeRatesModel.fromJson(jsonMap(json['rates'])),
        installedAt: jsonDate(json['installedAt']) ?? DateTime.now(),
        refreshedAt: jsonDate(json['refreshedAt']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'countryCode': countryCode,
    'name': name,
    'tagline': tagline,
    'region': region,
    'accentColor': accentColorHex,
    'currencyCode': currencyCode,
    'primaryCity': primaryCity,
    'latitude': latitude,
    'longitude': longitude,
    'blurb': blurb,
    'facts': facts.toJson(),
    'landmarks': landmarks.map((LandmarkModel l) => l.toJson()).toList(),
    'tips': tips.toJson(),
    'weather': weather.toJson(),
    'rates': rates.toJson(),
    'installedAt': installedAt.toIso8601String(),
    'refreshedAt': refreshedAt?.toIso8601String(),
  };

  PackSummaryModel toSummary() => PackSummaryModel.fromPack(this);

  /// Rebuilds a pack with selected sections replaced, used when a refresh
  /// updates only the volatile parts (weather and rates).
  CountryPackModel copyWith({
    CountryFactsModel? facts,
    List<LandmarkModel>? landmarks,
    LocalTipsModel? tips,
    WeatherTrendModel? weather,
    ExchangeRatesModel? rates,
    DateTime? installedAt,
    DateTime? refreshedAt,
  }) => CountryPackModel(
    countryCode: countryCode,
    name: name,
    tagline: tagline,
    region: region,
    accentColorHex: accentColorHex,
    currencyCode: currencyCode,
    primaryCity: primaryCity,
    latitude: latitude,
    longitude: longitude,
    blurb: blurb,
    facts: facts ?? this.facts,
    landmarks: landmarks ?? this.landmarks,
    tips: tips ?? this.tips,
    weather: weather ?? this.weather,
    rates: rates ?? this.rates,
    installedAt: installedAt ?? this.installedAt,
    refreshedAt: refreshedAt ?? this.refreshedAt,
  );

  /// True once a live forecast or a rate snapshot has been fetched at least
  /// once, which is what the UI uses to decide between "offline copy" and
  /// "waiting for the first sync" copy.
  bool get hasLiveData => weather.hasContent || rates.hasRates;

  /// Cities covered by the landmark list, in first-seen order.
  List<String> get cities {
    final seen = <String>{};
    final ordered = <String>[];
    for (final landmark in landmarks) {
      if (landmark.city.isNotEmpty && seen.add(landmark.city)) {
        ordered.add(landmark.city);
      }
    }
    return ordered;
  }

  LandmarkModel? landmarkById(String id) {
    for (final landmark in landmarks) {
      if (landmark.mapKey == id) return landmark;
    }
    return null;
  }

  /// Rough on-device footprint, used by the "storage used" readout.
  int get approximateBytes => toJson().toString().length;
}

/// Where a pack download has got to.
enum PackDownloadStage {
  idle,
  facts,
  weather,
  rates,
  saving,
  completed,
  failed,
}

/// Progress for the download UI, which must show *what* is happening rather
/// than an opaque spinner, because a pack download makes several slow calls.
class PackDownloadProgress {
  final PackDownloadStage stage;
  final double fraction;
  final String message;

  const PackDownloadProgress({
    required this.stage,
    required this.fraction,
    required this.message,
  });

  factory PackDownloadProgress.idle() => const PackDownloadProgress(
    stage: PackDownloadStage.idle,
    fraction: 0,
    message: 'Not downloaded',
  );

  bool get isRunning =>
      stage != PackDownloadStage.idle &&
      stage != PackDownloadStage.completed &&
      stage != PackDownloadStage.failed;

  bool get isCompleted => stage == PackDownloadStage.completed;
  bool get isFailed => stage == PackDownloadStage.failed;

  /// Overall fraction, clamped so a progress bar can never overshoot.
  double get safeFraction => fraction.clamp(0.0, 1.0);
}
