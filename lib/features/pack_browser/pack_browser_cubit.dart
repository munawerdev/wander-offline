import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '/config/response/api_response.dart';
import '/core/show/show.dart';
import '/data/datasources/connectivity/connectivity_data_source.dart';
import '/data/models/pack/country_pack_model.dart';
import '/domain/failures/network/network_failure.dart';
import '/domain/failures/pack/pack_failure.dart';
import '/domain/repositories/pack/pack_base_api_service.dart';
import '/features/pack_detail/pack_detail_initial_params.dart';
import 'pack_browser_initial_params.dart';
import 'pack_browser_navigator.dart';
import 'pack_browser_state.dart';

/// Drives the pack browser: the catalogue list and the download pipeline.
///
/// Every pack is free, so there is no ownership to reconcile. The cubit merges
/// just two sources of truth - the bundled catalogue and what is on this device -
/// which is also why there is no paywall to route to.
class PackBrowserCubit extends Cubit<PackBrowserState> {
  final PackBrowserInitialParams initialParams;
  final PackBaseApiService packRepository;
  final ConnectivityDataSource connectivityDataSource;
  final PackBrowserNavigator navigator;
  final Show show;

  late final StreamSubscription<bool> _connectivitySubscription;

  PackBrowserCubit(
    this.initialParams,
    this.packRepository,
    this.connectivityDataSource,
    this.navigator,
    this.show,
  ) : super(PackBrowserState.initial(initialParams: initialParams)) {
    _connectivitySubscription = connectivityDataSource.onStatusChanged.listen(
      _onConnectivityChanged,
    );
  }

  @override
  Future<void> close() async {
    await _connectivitySubscription.cancel();
    return super.close();
  }

  /// Reloads the catalogue and re-merges local state.
  Future<void> load({bool showLoading = true}) async {
    if (showLoading) {
      emit(
        state.copyWith(catalogue: ApiResponse<List<PackCardState>>.loading()),
      );
    }

    final catalogueResult = await packRepository.catalogue();
    final installedResult = await packRepository.installedCountryCodes();
    final bytesResult = await packRepository.installedBytes();
    final online = await _safeIsOnline();

    NetworkFailure? failure;
    var summaries = const <PackSummaryModel>[];
    catalogueResult.fold(
      (PackStorageFailure left) => failure = NetworkFailure(error: left.error),
      (List<PackSummaryModel> right) => summaries = right,
    );

    if (failure != null) {
      emit(
        state.copyWith(
          catalogue: ApiResponse<List<PackCardState>>.error(failure!),
          isOnline: online,
        ),
      );
      return;
    }

    var installed = const <String>[];
    installedResult.fold(
      (PackStorageFailure left) {},
      (List<String> right) => installed = right,
    );

    var bytes = 0;
    bytesResult.fold((PackStorageFailure left) {}, (int right) => bytes = right);

    final installedCodes = installed
        .map((String code) => code.toUpperCase())
        .toSet();

    final cards = summaries
        .map(
          (PackSummaryModel summary) => PackCardState(
            summary: summary,
            isInstalled: installedCodes.contains(summary.countryCode),
          ),
        )
        .toList();

    emit(
      state.copyWith(
        catalogue: ApiResponse<List<PackCardState>>.completed(cards),
        isOnline: online,
        installedBytes: bytes,
      ),
    );
  }

  void setFilter(PackFilter filter) => emit(state.copyWith(filter: filter));

  /// Opens a pack, downloading it first when it is not on the device yet.
  Future<void> openDetails(String countryCode) async {
    final code = countryCode.toUpperCase();
    final card = state.cardFor(code);
    if (card == null) return;

    if (!card.isInstalled) {
      final installed = await download(code);
      if (!installed) return;
    }

    await navigator.openPackDetail(PackDetailInitialParams(countryCode: code));
  }

  /// Installs a pack. Returns true when it ended up installed.
  Future<bool> download(String countryCode) async {
    final code = countryCode.toUpperCase();
    if (state.cardFor(code) == null) return false;

    emit(
      state.copyWith(
        activeDownloadCode: code,
        downloadProgress: const PackDownloadProgress(
          stage: PackDownloadStage.facts,
          fraction: 0,
          message: 'Starting download',
        ),
      ),
    );

    final result = await packRepository.download(
      countryCode: code,
      onProgress: _onProgress,
    );

    var installedName = code;
    String? errorMessage;
    CountryPackModel? installedPack;
    result.fold(
      (PackDownloadFailure left) => errorMessage = left.error,
      (CountryPackModel right) {
        installedPack = right;
        installedName = right.name;
      },
    );

    if (isClosed) return installedPack != null;

    emit(state.withoutDownload());

    if (installedPack != null) {
      show.showSuccessSnackBar('$installedName is ready offline');
    } else if (errorMessage != null) {
      show.showErrorSnackBar(errorMessage!);
    }

    await load(showLoading: false);
    return installedPack != null;
  }

  /// Refreshes only the volatile parts of an installed pack.
  Future<void> refreshPack(String countryCode) async {
    final code = countryCode.toUpperCase();

    emit(
      state.copyWith(
        activeDownloadCode: code,
        downloadProgress: const PackDownloadProgress(
          stage: PackDownloadStage.weather,
          fraction: 0.15,
          message: 'Refreshing offline data',
        ),
      ),
    );

    final result = await packRepository.refresh(
      countryCode: code,
      onProgress: _onProgress,
    );

    var updatedName = code;
    String? errorMessage;
    CountryPackModel? updated;
    result.fold(
      (PackDownloadFailure left) => errorMessage = left.error,
      (CountryPackModel right) {
        updated = right;
        updatedName = right.name;
      },
    );

    if (isClosed) return;

    emit(state.withoutDownload());

    if (updated != null) {
      show.showSuccessSnackBar(
        updated!.hasLiveData
            ? '$updatedName updated'
            : 'Still offline - kept the saved $updatedName data',
      );
    } else if (errorMessage != null) {
      show.showErrorSnackBar(errorMessage!);
    }

    await load(showLoading: false);
  }

  Future<void> deletePack(String countryCode) async {
    final code = countryCode.toUpperCase();
    final result = await packRepository.delete(code);

    result.fold(
      (PackStorageFailure left) => show.showErrorSnackBar(left.error),
      (bool right) => show.showSuccessSnackBar(
        'Removed $code from this device - download it again any time',
      ),
    );

    await load(showLoading: false);
  }

  void _onProgress(PackDownloadProgress progress) {
    if (isClosed) return;
    emit(state.copyWith(downloadProgress: progress));
  }

  void _onConnectivityChanged(bool isOnline) {
    if (isClosed) return;
    emit(state.copyWith(isOnline: isOnline));
  }

  /// Connectivity is a hint for the banner only. Downloads always attempt the
  /// network and treat a failed request as the real authority, so a captive
  /// portal or a false negative here cannot block a download.
  Future<bool> _safeIsOnline() async {
    try {
      return await connectivityDataSource.isOnline();
    } catch (_) {
      return true;
    }
  }
}
