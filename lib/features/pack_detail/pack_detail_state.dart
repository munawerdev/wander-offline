import '/config/response/api_response.dart';
import '/config/response/status.dart';
import '/data/models/pack/country_pack_model.dart';
import '/data/models/pack/exchange_rates_model.dart';
import '/data/models/pack/landmark_model.dart';
import '/data/models/pack/weather_trend_model.dart';
import '/domain/failures/network/network_failure.dart';
import 'pack_detail_initial_params.dart';

/// State for one open pack.
///
/// The displayed numbers (converted amount, symbols, the weather series) are
/// derived getters rather than duplicated fields, so the converter can never
/// disagree with the stored rate table.
class PackDetailState {
  final String countryCode;
  final ApiResponse<CountryPackModel> pack;
  final int tabIndex;
  final bool isRefreshing;

  /// Raw text from the converter's amount field, kept as a string so partial
  /// input like "12." does not get mangled while typing.
  final String amountText;
  final String fromCurrency;
  final String toCurrency;

  final String? selectedLandmarkId;
  final bool showSchematicMap;

  PackDetailState({
    required this.countryCode,
    required this.pack,
    required this.tabIndex,
    required this.isRefreshing,
    required this.amountText,
    required this.fromCurrency,
    required this.toCurrency,
    this.selectedLandmarkId,
    this.showSchematicMap = false,
  });

  factory PackDetailState.initial({
    required PackDetailInitialParams initialParams,
  }) => PackDetailState(
    countryCode: initialParams.countryCode.toUpperCase(),
    pack: ApiResponse<CountryPackModel>.initial(
      CountryPackModel.fromJson(<String, dynamic>{}),
    ),
    tabIndex: 0,
    isRefreshing: false,
    amountText: '100',
    fromCurrency: 'USD',
    toCurrency: '',
  );

  /// The loaded pack, or null while loading / after an error.
  CountryPackModel? get data =>
      pack.status == Status.completed ? pack.data : null;

  NetworkFailure? get error =>
      pack.status == Status.error ? pack.error : null;

  bool get isLoading => pack.status == Status.loading;

  ExchangeRatesModel? get rates => data?.rates;

  /// The series the weather tab should lead with.
  List<DailyWeatherModel> get weatherDays =>
      data?.weather.primarySeries ?? const <DailyWeatherModel>[];

  List<LandmarkModel> get landmarks => data?.landmarks ?? const <LandmarkModel>[];

  double? get amount {
    final parsed = double.tryParse(amountText.trim());
    if (parsed == null) return null;
    return parsed;
  }

  /// Converted value, or null when the amount is unparseable or a rate is
  /// missing. The UI shows an explicit "rate unavailable" line rather than a
  /// misleading zero.
  double? get convertedAmount {
    final value = amount;
    final table = rates;
    if (value == null || table == null || !table.hasRates) return null;
    if (fromCurrency.isEmpty || toCurrency.isEmpty) return null;
    return table.convert(amount: value, from: fromCurrency, to: toCurrency);
  }

  /// Units of [fromCurrency] per 1 [toCurrency], for the rate caption.
  double? get unitRate {
    final table = rates;
    if (table == null || !table.hasRates) return null;
    if (fromCurrency.isEmpty || toCurrency.isEmpty) return null;
    return table.convert(amount: 1, from: fromCurrency, to: toCurrency);
  }

  String get fromSymbol => data?.facts.currency.symbol ?? '';
  String get toSymbol => data?.facts.currency.symbol ?? '';

  LandmarkModel? get selectedLandmark {
    final id = selectedLandmarkId;
    if (id == null) return null;
    for (final landmark in landmarks) {
      if (landmark.mapKey == id) return landmark;
    }
    return null;
  }

  PackDetailState copyWith({
    ApiResponse<CountryPackModel>? pack,
    int? tabIndex,
    bool? isRefreshing,
    String? amountText,
    String? fromCurrency,
    String? toCurrency,
    String? selectedLandmarkId,
    bool? showSchematicMap,
  }) => PackDetailState(
    countryCode: countryCode,
    pack: pack ?? this.pack,
    tabIndex: tabIndex ?? this.tabIndex,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    amountText: amountText ?? this.amountText,
    fromCurrency: fromCurrency ?? this.fromCurrency,
    toCurrency: toCurrency ?? this.toCurrency,
    selectedLandmarkId: selectedLandmarkId ?? this.selectedLandmarkId,
    showSchematicMap: showSchematicMap ?? this.showSchematicMap,
  );

  /// Selects or clears the focused landmark. `copyWith` cannot set a null, so
  /// clearing goes through here.
  PackDetailState withLandmark(String? landmarkId) => PackDetailState(
    countryCode: countryCode,
    pack: pack,
    tabIndex: tabIndex,
    isRefreshing: isRefreshing,
    amountText: amountText,
    fromCurrency: fromCurrency,
    toCurrency: toCurrency,
    selectedLandmarkId: landmarkId,
    showSchematicMap: showSchematicMap,
  );
}
