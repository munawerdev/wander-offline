import 'package:fpdart/fpdart.dart';

import '/core/utils/app_url.dart';
import '/core/utils/json_utils.dart';
import '/data/models/pack/exchange_rates_model.dart';
import '/domain/failures/network/network_failure.dart';
import '/domain/repositories/network/network_base_api_service.dart';

/// Fetches a daily exchange-rate snapshot.
///
/// Frankfurter republishes European Central Bank reference rates, needs no key,
/// and returns a flat `{base, date, rates}` object. One snapshot per pack is
/// enough: it is cached with the pack so conversions still work in airplane
/// mode, and refreshed only while the device is online.
class ExchangeRateRemoteDataSource {
  final NetworkBaseApiService _networkRepository;

  ExchangeRateRemoteDataSource(this._networkRepository);

  static const String sourceName = 'Frankfurter (ECB reference rates)';

  Future<Either<NetworkFailure, ExchangeRatesModel>> fetchLatest({
    required String base,
  }) async {
    final result = await _networkRepository.get<Map<String, dynamic>>(
      url: AppUrl.exchangeRates(base: base),
    );

    return result.map((Map<String, dynamic> json) {
      final rates = jsonDoubleMap(json['rates']);
      return ExchangeRatesModel(
        base: jsonString(json['base'], fallback: base).toUpperCase(),
        // The base is implicitly 1:1 with itself and the API omits it.
        rates: <String, double>{...rates, base.toUpperCase(): 1},
        fetchedAt: jsonDate(json['date']) ?? DateTime.now(),
        source: sourceName,
      );
    });
  }
}
