abstract class AppUrl {
  AppUrl._();

  static String? get _base => 'http://192.168.18.68:3001';
  // static String? get _base => 'http://192.168.100.31:3001';
  // static String? get _base => dotenv.env['BASE_URL'];
  static String? get socketBaseUrl => _base;
  static String get _baseUrl => '$_base/api/v1';

  // Authentication endpoints
  static String get refreshToken => '$_baseUrl/refreshToken';
  static String get login => '$_baseUrl/login';
  static String get signUp => '$_baseUrl/signUp';
  static String get forgotPassword => '$_baseUrl/forgotPassword';

  // home
  static String get home => '$_baseUrl/home';

  // ---------------------------------------------------------------------------
  // WanderOffline open-data endpoints.
  //
  // Every source below is keyless and free, which is what lets the app ship
  // without a backend. Pack content itself (facts, landmarks, local tips) is
  // bundled as an asset so a downloaded pack is complete offline; only weather
  // and exchange rates are fetched, because only they go stale.
  //
  // Note: REST Countries v1-v4 were shut down upstream and v5 requires an
  // account plus an API key, so country facts are authored into the pack
  // content instead of being fetched.
  // ---------------------------------------------------------------------------

  /// Open-Meteo historical archive, used to build "what this week is normally
  /// like" averages from several past years.
  static const String weatherArchive =
      'https://archive-api.open-meteo.com/v1/archive';

  /// Open-Meteo live forecast, refreshed opportunistically while online.
  static const String weatherForecast =
      'https://api.open-meteo.com/v1/forecast';

  /// Daily fields requested from both Open-Meteo endpoints.
  static const String weatherDailyFields =
      'temperature_2m_max,temperature_2m_min,precipitation_sum,weather_code';

  /// Frankfurter (European Central Bank reference rates). Keyless and stable.
  static String exchangeRates({required String base}) =>
      'https://api.frankfurter.app/latest?from=$base';
}
