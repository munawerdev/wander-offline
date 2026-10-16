import 'package:flutter_bloc/flutter_bloc.dart';

import '/config/response/api_response.dart';
import '/core/show/show.dart';
import '/data/models/pack/country_pack_model.dart';
import '/domain/failures/network/network_failure.dart';
import '/domain/failures/pack/pack_failure.dart';
import '/domain/repositories/pack/pack_base_api_service.dart';
import 'pack_detail_initial_params.dart';
import 'pack_detail_navigator.dart';
import 'pack_detail_state.dart';

/// Drives one open pack: loading it from local storage, the currency
/// converter, landmark focus, and optional refreshes.
///
/// Everything here reads from Hive. The only network call is [refresh], which
/// the traveller triggers deliberately.
class PackDetailCubit extends Cubit<PackDetailState> {
  final PackDetailInitialParams initialParams;
  final PackBaseApiService packRepository;
  final PackDetailNavigator navigator;
  final Show show;

  PackDetailCubit(
    this.initialParams,
    this.packRepository,
    this.navigator,
    this.show,
  ) : super(PackDetailState.initial(initialParams: initialParams));

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) {
      emit(state.copyWith(pack: ApiResponse<CountryPackModel>.loading()));
    }

    final result = await packRepository.installedPack(state.countryCode);

    NetworkFailure? failure;
    CountryPackModel? loaded;
    result.fold(
      (PackNotFoundFailure left) => failure = NetworkFailure(
        error: left.error,
        type: NetworkFailureType.notFound,
      ),
      (CountryPackModel right) => loaded = right,
    );

    if (loaded == null) {
      emit(
        state.copyWith(
          pack: ApiResponse<CountryPackModel>.error(
            failure ?? const NetworkFailure(error: 'Pack unavailable'),
          ),
        ),
      );
      return;
    }

    final pack = loaded!;
    final currencies = pack.rates.currencies;

    // Default the converter to "my money -> the local money", falling back to
    // the base currency when the traveller's currency is not in the table.
    final from = currencies.contains('USD') ? 'USD' : pack.rates.base;
    final to = currencies.contains(pack.currencyCode)
        ? pack.currencyCode
        : (currencies.isEmpty ? from : currencies.first);

    emit(
      state.copyWith(
        pack: ApiResponse<CountryPackModel>.completed(pack),
        fromCurrency: state.fromCurrency.isEmpty ? from : state.fromCurrency,
        toCurrency: state.toCurrency.isEmpty ? to : state.toCurrency,
      ),
    );
  }

  void setTab(int index) => emit(state.copyWith(tabIndex: index));

  void setAmount(String text) => emit(state.copyWith(amountText: text));

  void setFromCurrency(String code) =>
      emit(state.copyWith(fromCurrency: code.toUpperCase()));

  void setToCurrency(String code) =>
      emit(state.copyWith(toCurrency: code.toUpperCase()));

  void swapCurrencies() => emit(
    state.copyWith(fromCurrency: state.toCurrency, toCurrency: state.fromCurrency),
  );

  /// Focuses a landmark, or clears the focus when the same one is tapped twice.
  void selectLandmark(String landmarkId) => emit(
    state.withLandmark(
      state.selectedLandmarkId == landmarkId ? null : landmarkId,
    ),
  );

  void clearLandmark() => emit(state.withLandmark(null));

  void toggleMapMode() =>
      emit(state.copyWith(showSchematicMap: !state.showSchematicMap));

  /// Refreshes the volatile sections while online.
  Future<void> refresh() async {
    if (state.isRefreshing) return;
    emit(state.copyWith(isRefreshing: true));

    final result = await packRepository.refresh(countryCode: state.countryCode);

    var updated = false;
    String? errorMessage;
    result.fold(
      (PackDownloadFailure left) => errorMessage = left.error,
      (CountryPackModel right) => updated = true,
    );

    if (isClosed) return;
    emit(state.copyWith(isRefreshing: false));

    if (updated) {
      show.showSuccessSnackBar('Weather and rates are up to date');
      await load(showLoading: false);
    } else if (errorMessage != null) {
      show.showErrorSnackBar(errorMessage!);
    }
  }

  void openBack() => navigator.openBack();
}
