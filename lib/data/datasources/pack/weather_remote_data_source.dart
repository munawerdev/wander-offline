import 'package:fpdart/fpdart.dart';

import '/core/utils/app_url.dart';
import '/core/utils/json_utils.dart';
import '/data/models/pack/weather_trend_model.dart';
import '/domain/failures/network/network_failure.dart';
import '/domain/repositories/network/network_base_api_service.dart';

/// Fetches weather trends from Open-Meteo (keyless, no account required).
///
/// Two different questions are answered here:
///
///  * "What is this week normally like?" - averaged from several past years of
///    archive data. Computed once at download time and then valid forever,
///    which is what makes the weather screen useful offline.
///  * "What is the forecast for the next seven days?" - live data, refreshed
///    opportunistically while the device is online.
class WeatherRemoteDataSource {
  final NetworkBaseApiService _networkRepository;

  WeatherRemoteDataSource(this._networkRepository);

  /// Number of past years averaged into the seasonal series.
  static const int defaultSeasonalYears = 3;

  /// Length of the seasonal and forecast windows.
  static const int windowDays = 7;

  /// Historical data lags real time by a few days upstream, so the archive
  /// window always stops well before today.
  static const int archiveSafetyDays = 7;

  /// Builds the full weather section for a pack.
  ///
  /// The seasonal series is mandatory: without it the weather screen would have
  /// nothing to show offline. The live forecast is best-effort, so a failure
  /// there still returns a usable trend.
  Future<Either<NetworkFailure, WeatherTrendModel>> fetchTrend({
    required double latitude,
    required double longitude,
    int seasonalYears = defaultSeasonalYears,
    DateTime? today,
  }) async {
    final reference = _dateOnly(today ?? DateTime.now());

    final seasonalResult = await fetchSeasonalAverage(
      latitude: latitude,
      longitude: longitude,
      reference: reference,
      years: seasonalYears,
    );

    NetworkFailure? seasonalFailure;
    var seasonalDays = const <DailyWeatherModel>[];
    seasonalResult.fold(
      (NetworkFailure failure) => seasonalFailure = failure,
      (List<DailyWeatherModel> days) => seasonalDays = days,
    );

    if (seasonalFailure != null || seasonalDays.isEmpty) {
      return left(
        seasonalFailure ??
            const NetworkFailure(
              error: 'Weather archive returned no usable data',
              type: NetworkFailureType.badResponse,
            ),
      );
    }

    final forecastResult = await fetchForecast(
      latitude: latitude,
      longitude: longitude,
      today: reference,
    );

    var forecastDays = const <DailyWeatherModel>[];
    forecastResult.fold(
      (NetworkFailure _) => forecastDays = const <DailyWeatherModel>[],
      (List<DailyWeatherModel> days) => forecastDays = days,
    );

    final now = DateTime.now();
    return right(
      WeatherTrendModel(
        timezone: 'auto',
        seasonal: seasonalDays,
        forecast: forecastDays,
        seasonalYears: seasonalYears,
        seasonalFetchedAt: now,
        forecastFetchedAt: forecastDays.isEmpty ? null : now,
      ),
    );
  }

  /// Averages the same seven calendar days across [years] past years.
  ///
  /// The returned dates are the upcoming week (so the UI can label rows
  /// Mon-Sun), while the temperatures are the historical averages for those
  /// calendar days.
  Future<Either<NetworkFailure, List<DailyWeatherModel>>>
  fetchSeasonalAverage({
    required double latitude,
    required double longitude,
    required DateTime reference,
    int years = defaultSeasonalYears,
  }) async {
    final perYear = <List<DailyWeatherModel>>[];
    NetworkFailure? firstFailure;

    for (var offset = 1; offset <= years; offset++) {
      final start = _shiftYears(reference, -offset);
      final end = start.add(const Duration(days: windowDays - 1));
      if (DateTime.now().difference(end).inDays < archiveSafetyDays) {
        continue;
      }

      final result = await _fetchArchiveWindow(
        latitude: latitude,
        longitude: longitude,
        start: start,
        end: end,
      );
      result.fold(
        (NetworkFailure failure) => firstFailure ??= failure,
        (List<DailyWeatherModel> days) {
          if (days.isNotEmpty) perYear.add(days);
        },
      );
    }

    if (perYear.isEmpty) {
      return left(
        firstFailure ??
            const NetworkFailure(
              error: 'No historical weather available for this location',
              type: NetworkFailureType.badResponse,
            ),
      );
    }

    return right(_averageAcrossYears(perYear, reference));
  }

  /// Live seven-day forecast. Failure is expected when offline.
  Future<Either<NetworkFailure, List<DailyWeatherModel>>> fetchForecast({
    required double latitude,
    required double longitude,
    DateTime? today,
  }) => _request(
    url: AppUrl.weatherForecast,
    queryParams: <String, dynamic>{
      'forecast_days': windowDays,
      'timezone': 'auto',
      ..._baseParams(latitude: latitude, longitude: longitude, date: today),
    },
  );

  Future<Either<NetworkFailure, List<DailyWeatherModel>>> _fetchArchiveWindow({
    required double latitude,
    required double longitude,
    required DateTime start,
    required DateTime end,
  }) => _request(
    url: AppUrl.weatherArchive,
    queryParams: <String, dynamic>{
      'start_date': isoDate(start),
      'end_date': isoDate(end),
      'timezone': 'auto',
      ..._baseParams(latitude: latitude, longitude: longitude),
    },
  );

  Future<Either<NetworkFailure, List<DailyWeatherModel>>> _request({
    required String url,
    required Map<String, dynamic> queryParams,
  }) async {
    final result = await _networkRepository.get<Map<String, dynamic>>(
      url: url,
      queryParams: queryParams,
    );
    return result.map(
      (Map<String, dynamic> json) =>
          DailyWeatherModel.fromOpenMeteoDaily(jsonMap(json['daily'])),
    );
  }

  Map<String, dynamic> _baseParams({
    required double latitude,
    required double longitude,
    DateTime? date,
  }) => <String, dynamic>{
    'latitude': latitude,
    'longitude': longitude,
    'daily': AppUrl.weatherDailyFields,
    if (date != null) 'start_date': isoDate(date),
    if (date != null) 'end_date': isoDate(date.add(const Duration(days: windowDays - 1))),
  };
}

/// `2026-10-16`, the only date format Open-Meteo accepts.
String isoDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Shifts a date by whole years, clamping 29 February onto a valid day.
DateTime _shiftYears(DateTime date, int years) {
  final targetYear = date.year + years;
  final lastDayOfMonth = DateTime(targetYear, date.month + 1, 0).day;
  final day = date.day > lastDayOfMonth ? lastDayOfMonth : date.day;
  return DateTime(targetYear, date.month, day);
}

/// Averages parallel per-year series into one series dated to [reference].
List<DailyWeatherModel> _averageAcrossYears(
  List<List<DailyWeatherModel>> perYear,
  DateTime reference,
) {
  final result = <DailyWeatherModel>[];

  for (var index = 0; index < WeatherRemoteDataSource.windowDays; index++) {
    final samples = perYear
        .where((List<DailyWeatherModel> year) => index < year.length)
        .map((List<DailyWeatherModel> year) => year[index])
        .toList();
    if (samples.isEmpty) continue;

    result.add(
      DailyWeatherModel(
        date: reference.add(Duration(days: index)),
        tempMaxC: _mean(
          samples.map((DailyWeatherModel day) => day.tempMaxC).toList(),
        ),
        tempMinC: _mean(
          samples.map((DailyWeatherModel day) => day.tempMinC).toList(),
        ),
        precipitationMm: _mean(
          samples.map((DailyWeatherModel day) => day.precipitationMm).toList(),
        ),
        weatherCode: _modeCode(
          samples.map((DailyWeatherModel day) => day.weatherCode).toList(),
        ),
      ),
    );
  }

  return result;
}

double _mean(List<double> values) {
  if (values.isEmpty) return 0;
  return values.fold<double>(0, (double sum, double v) => sum + v) /
      values.length;
}

/// Most frequent code, which keeps "snow" from being averaged into "drizzle".
int _modeCode(List<int> codes) {
  if (codes.isEmpty) return 0;
  final counts = <int, int>{};
  for (final code in codes) {
    counts[code] = (counts[code] ?? 0) + 1;
  }
  var best = codes.first;
  var bestCount = 0;
  for (final entry in counts.entries) {
    if (entry.value > bestCount) {
      best = entry.key;
      bestCount = entry.value;
    }
  }
  return best;
}
