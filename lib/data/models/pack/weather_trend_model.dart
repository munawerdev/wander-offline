import '/core/utils/json_utils.dart';
import '/core/utils/weather_code_utils.dart';

/// One day in a weather series.
class DailyWeatherModel {
  final DateTime date;
  final double tempMaxC;
  final double tempMinC;
  final double precipitationMm;
  final int weatherCode;

  const DailyWeatherModel({
    required this.date,
    required this.tempMaxC,
    required this.tempMinC,
    required this.precipitationMm,
    required this.weatherCode,
  });

  factory DailyWeatherModel.fromJson(Map<String, dynamic> json) =>
      DailyWeatherModel(
        date: jsonDate(json['date']) ?? DateTime.now(),
        tempMaxC: jsonDouble(json['tempMaxC']),
        tempMinC: jsonDouble(json['tempMinC']),
        precipitationMm: jsonDouble(json['precipitationMm']),
        weatherCode: jsonInt(json['weatherCode']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'date': date.toIso8601String(),
    'tempMaxC': tempMaxC,
    'tempMinC': tempMinC,
    'precipitationMm': precipitationMm,
    'weatherCode': weatherCode,
  };

  /// Parses the parallel arrays Open-Meteo returns under `daily`.
  ///
  /// The API sends `{"time": [...], "temperature_2m_max": [...], ...}` so the
  /// series has to be zipped by index. Mismatched or short arrays are tolerated
  /// by stopping at the shortest one.
  static List<DailyWeatherModel> fromOpenMeteoDaily(Map<String, dynamic> daily) {
    final times = jsonStringList(daily['time']);
    if (times.isEmpty) return <DailyWeatherModel>[];

    final maxes = _doubleList(daily['temperature_2m_max']);
    final mins = _doubleList(daily['temperature_2m_min']);
    final precipitation = _doubleList(daily['precipitation_sum']);
    final codes = _intList(daily['weather_code']);

    final result = <DailyWeatherModel>[];
    for (var index = 0; index < times.length; index++) {
      final date = DateTime.tryParse(times[index]);
      if (date == null) continue;
      result.add(
        DailyWeatherModel(
          date: date,
          tempMaxC: _at(maxes, index),
          tempMinC: _at(mins, index),
          precipitationMm: _at(precipitation, index),
          weatherCode: _atInt(codes, index),
        ),
      );
    }
    return result;
  }

  String get conditionLabel => weatherLabelForCode(weatherCode);
  WeatherKind get kind => weatherKindForCode(weatherCode);
  String get weekdayLabel => shortWeekdayLabel(date);
  String get dayLabel => '${date.day}/${date.month}';

  /// `18° / 9°` for compact series rows.
  String get temperatureRangeLabel =>
      '${tempMaxC.round()}° / ${tempMinC.round()}°';

  bool get isWet => precipitationMm >= 1;
}

/// A seven-day weather view for a pack.
///
/// [seasonal] holds "what this week is normally like", averaged from several
/// years of historical records. It is computed once at download time and stays
/// valid forever offline. [forecast] holds the live seven-day outlook and is
/// refreshed opportunistically whenever the device is online and the pack is
/// already owned.
class WeatherTrendModel {
  final String timezone;
  final List<DailyWeatherModel> seasonal;
  final List<DailyWeatherModel> forecast;
  final int seasonalYears;
  final DateTime? seasonalFetchedAt;
  final DateTime? forecastFetchedAt;

  const WeatherTrendModel({
    required this.timezone,
    required this.seasonal,
    required this.forecast,
    required this.seasonalYears,
    this.seasonalFetchedAt,
    this.forecastFetchedAt,
  });

  factory WeatherTrendModel.fromJson(Map<String, dynamic> json) =>
      WeatherTrendModel(
        timezone: jsonString(json['timezone']),
        seasonal: jsonMapList(json['seasonal'])
            .map(DailyWeatherModel.fromJson)
            .toList(),
        forecast: jsonMapList(json['forecast'])
            .map(DailyWeatherModel.fromJson)
            .toList(),
        seasonalYears: jsonInt(json['seasonalYears']),
        seasonalFetchedAt: jsonDate(json['seasonalFetchedAt']),
        forecastFetchedAt: jsonDate(json['forecastFetchedAt']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'timezone': timezone,
    'seasonal': seasonal
        .map((DailyWeatherModel day) => day.toJson())
        .toList(),
    'forecast': forecast
        .map((DailyWeatherModel day) => day.toJson())
        .toList(),
    'seasonalYears': seasonalYears,
    'seasonalFetchedAt': seasonalFetchedAt?.toIso8601String(),
    'forecastFetchedAt': forecastFetchedAt?.toIso8601String(),
  };

  factory WeatherTrendModel.empty() => const WeatherTrendModel(
    timezone: '',
    seasonal: <DailyWeatherModel>[],
    forecast: <DailyWeatherModel>[],
    seasonalYears: 0,
  );

  bool get hasContent => seasonal.isNotEmpty || forecast.isNotEmpty;
  bool get hasForecast => forecast.isNotEmpty;

  /// The series the UI should lead with: live forecast when we have one,
  /// otherwise the seasonal average.
  List<DailyWeatherModel> get primarySeries =>
      forecast.isNotEmpty ? forecast : seasonal;

  double get averageHighC => _average(
    seasonal.map((DailyWeatherModel day) => day.tempMaxC).toList(),
  );

  double get averageLowC => _average(
    seasonal.map((DailyWeatherModel day) => day.tempMinC).toList(),
  );

  double get totalPrecipitationMm => seasonal.fold<double>(
    0,
    (double sum, DailyWeatherModel day) => sum + day.precipitationMm,
  );

  /// How many of the seven typical days see meaningful rain.
  int get wetDayCount =>
      seasonal.where((DailyWeatherModel day) => day.isWet).length;

  /// One-line summary such as `Typically 22° / 14°, rain on 3 of 7 days`.
  String get seasonalSummary {
    if (seasonal.isEmpty) return 'No seasonal data';
    return 'Typically ${averageHighC.round()}° / ${averageLowC.round()}, '
        'rain on $wetDayCount of ${seasonal.length} days';
  }
}

double _average(List<double> values) {
  if (values.isEmpty) return 0;
  final total = values.fold<double>(0, (double sum, double v) => sum + v);
  return total / values.length;
}

List<double> _doubleList(dynamic value) {
  if (value is! List) return <double>[];
  return value.map(jsonDouble).toList();
}

List<int> _intList(dynamic value) {
  if (value is! List) return <int>[];
  return value.map(jsonInt).toList();
}

double _at(List<double> values, int index) =>
    index < values.length ? values[index] : 0;

int _atInt(List<int> values, int index) =>
    index < values.length ? values[index] : 0;
