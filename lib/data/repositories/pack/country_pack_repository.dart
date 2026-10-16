import 'package:fpdart/fpdart.dart';

import '/data/datasources/pack/curated_pack_data_source.dart';
import '/data/datasources/pack/exchange_rate_remote_data_source.dart';
import '/data/datasources/pack/pack_local_data_source.dart';
import '/data/datasources/pack/weather_remote_data_source.dart';
import '/data/models/pack/country_pack_model.dart';
import '/data/models/pack/exchange_rates_model.dart';
import '/data/models/pack/weather_trend_model.dart';
import '/domain/failures/network/network_failure.dart';
import '/domain/failures/pack/pack_failure.dart';
import '/domain/repositories/pack/pack_base_api_service.dart';

/// Cache-first implementation of the country-pack contract.
///
/// The split of responsibility is the whole point of the architecture:
///
///  * curated content (facts, landmarks, local tips) is read from the bundled
///    asset and written straight into Hive, so installing a pack needs no
///    network at all;
///  * weather and rates are the only volatile sections, so they are fetched on a
///    best-effort basis and a failure never blocks an install.
///
/// That means a traveller who taps "download" on airport wifi with one bar of
/// signal still ends up with a usable pack, and the weather and rates fill in on
/// the next refresh instead of showing an error screen.
class CountryPackRepository implements PackBaseApiService {
  /// Reference currency for the stored rate table. USD is used because it is
  /// the most widely recognised anchor, and the pack's own currency is always
  /// part of the returned table.
  static const String rateBase = 'USD';

  final CuratedPackDataSource _curatedDataSource;
  final PackLocalDataSource _localDataSource;
  final WeatherRemoteDataSource _weatherDataSource;
  final ExchangeRateRemoteDataSource _exchangeRateDataSource;

  CountryPackRepository(
    this._curatedDataSource,
    this._localDataSource,
    this._weatherDataSource,
    this._exchangeRateDataSource,
  );

  @override
  Future<Either<PackStorageFailure, List<PackSummaryModel>>> catalogue() async {
    try {
      final content = await _curatedDataSource.loadCatalogue();
      return right(
        content.map(PackSummaryModel.fromJson).toList(),
      );
    } catch (error) {
      return left(
        PackStorageFailure(error: 'Could not read the pack catalogue: $error'),
      );
    }
  }

  @override
  Future<Either<PackNotFoundFailure, CountryPackModel>> installedPack(
    String countryCode,
  ) async {
    final code = countryCode.toUpperCase();
    try {
      final pack = await _localDataSource.readPack(code);
      if (pack == null) {
        return left(PackNotFoundFailure(error: '$code is not installed'));
      }
      return right(pack);
    } catch (error) {
      return left(
        PackNotFoundFailure(error: 'Could not read $code locally: $error'),
      );
    }
  }

  @override
  Future<Either<PackStorageFailure, List<String>>> installedCountryCodes() async {
    try {
      return right(await _localDataSource.installedCountryCodes());
    } catch (error) {
      return left(
        PackStorageFailure(error: 'Could not list installed packs: $error'),
      );
    }
  }

  @override
  Future<Either<PackStorageFailure, int>> installedBytes() async {
    try {
      return right(await _localDataSource.installedBytes());
    } catch (error) {
      return left(
        PackStorageFailure(error: 'Could not measure pack storage: $error'),
      );
    }
  }

  @override
  Future<Either<PackDownloadFailure, CountryPackModel>> download({
    required String countryCode,
    void Function(PackDownloadProgress progress)? onProgress,
  }) async {
    final code = countryCode.toUpperCase();
    try {
      _report(
        onProgress,
        PackDownloadStage.facts,
        0.08,
        'Unpacking country facts, places and tips',
      );

      final content = await _curatedDataSource.loadPack(code);
      if (content == null) {
        const message = 'No pack content is bundled for this country';
        _report(onProgress, PackDownloadStage.failed, 0, message);
        return left(const PackDownloadFailure(error: message));
      }

      final curated = CountryPackModel.fromJson(content);

      _report(
        onProgress,
        PackDownloadStage.weather,
        0.3,
        'Averaging ${WeatherRemoteDataSource.defaultSeasonalYears} years of '
            'weather for this week',
      );
      final weather = await _loadWeather(
        latitude: curated.latitude,
        longitude: curated.longitude,
      );

      _report(
        onProgress,
        PackDownloadStage.rates,
        0.72,
        'Fetching exchange rates',
      );
      final rates = await _loadRates();

      _report(onProgress, PackDownloadStage.saving, 0.94, 'Saving for offline use');

      final completed = curated.copyWith(
        weather: weather,
        rates: rates,
        refreshedAt: (weather.hasContent || rates.hasRates)
            ? DateTime.now()
            : null,
      );
      await _localDataSource.savePack(completed);

      _report(
        onProgress,
        PackDownloadStage.completed,
        1,
        weather.hasContent
            ? 'Ready offline'
            : 'Saved offline - weather will fill in when you are online',
      );
      return right(completed);
    } catch (error) {
      final message = 'Could not install $code: $error';
      _report(onProgress, PackDownloadStage.failed, 0, message);
      return left(PackDownloadFailure(error: message));
    }
  }

  @override
  Future<Either<PackDownloadFailure, CountryPackModel>> refresh({
    required String countryCode,
    void Function(PackDownloadProgress progress)? onProgress,
  }) async {
    final code = countryCode.toUpperCase();
    try {
      final existing = await _localDataSource.readPack(code);
      if (existing == null) {
        return left(PackDownloadFailure(error: '$code is not installed'));
      }

      _report(
        onProgress,
        PackDownloadStage.weather,
        0.3,
        'Checking the seven-day forecast',
      );
      final forecast = await _loadForecast(
        latitude: existing.latitude,
        longitude: existing.longitude,
      );

      _report(
        onProgress,
        PackDownloadStage.rates,
        0.7,
        'Updating exchange rates',
      );
      final rates = await _loadRates();

      // The seasonal series is expensive to rebuild and never goes stale in a
      // meaningful way, so only the live forecast is replaced here.
      final weather = forecast.isEmpty
          ? existing.weather
          : WeatherTrendModel(
              timezone: existing.weather.timezone,
              seasonal: existing.weather.seasonal,
              forecast: forecast,
              seasonalYears: existing.weather.seasonalYears,
              seasonalFetchedAt: existing.weather.seasonalFetchedAt,
              forecastFetchedAt: DateTime.now(),
            );

      final refreshed = existing.copyWith(
        weather: weather,
        rates: rates.hasRates ? rates : existing.rates,
        refreshedAt: DateTime.now(),
      );

      _report(onProgress, PackDownloadStage.saving, 0.94, 'Saving updates');
      await _localDataSource.savePack(refreshed);
      _report(onProgress, PackDownloadStage.completed, 1, 'Up to date');
      return right(refreshed);
    } catch (error) {
      return left(
        PackDownloadFailure(error: 'Could not refresh $code: $error'),
      );
    }
  }

  @override
  Future<Either<PackStorageFailure, bool>> delete(String countryCode) async {
    final code = countryCode.toUpperCase();
    try {
      await _localDataSource.deletePack(code);
      return right(true);
    } catch (error) {
      return left(PackStorageFailure(error: 'Could not delete $code: $error'));
    }
  }

  /// Seasonal average plus live forecast, or an empty trend when the network is
  /// unusable. A failure here is intentionally not fatal.
  Future<WeatherTrendModel> _loadWeather({
    required double latitude,
    required double longitude,
  }) async {
    final result = await _weatherDataSource.fetchTrend(
      latitude: latitude,
      longitude: longitude,
    );
    var trend = WeatherTrendModel.empty();
    result.fold(
      (NetworkFailure failure) {},
      (WeatherTrendModel value) => trend = value,
    );
    return trend;
  }

  Future<List<DailyWeatherModel>> _loadForecast({
    required double latitude,
    required double longitude,
  }) async {
    final result = await _weatherDataSource.fetchForecast(
      latitude: latitude,
      longitude: longitude,
    );
    var days = const <DailyWeatherModel>[];
    result.fold(
      (NetworkFailure failure) {},
      (List<DailyWeatherModel> value) => days = value,
    );
    return days;
  }

  Future<ExchangeRatesModel> _loadRates() async {
    final result = await _exchangeRateDataSource.fetchLatest(base: rateBase);
    var rates = ExchangeRatesModel.empty();
    result.fold(
      (NetworkFailure failure) {},
      (ExchangeRatesModel value) => rates = value,
    );
    return rates;
  }

  void _report(
    void Function(PackDownloadProgress progress)? onProgress,
    PackDownloadStage stage,
    double fraction,
    String message,
  ) {
    if (onProgress == null) return;
    onProgress(
      PackDownloadProgress(stage: stage, fraction: fraction, message: message),
    );
  }
}
