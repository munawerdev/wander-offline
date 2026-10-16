import 'package:flutter_bloc/flutter_bloc.dart';

import '/config/support/support_config.dart';
import '/core/services/external_link_service.dart';
import '/core/show/show.dart';
import '/data/datasources/theme/theme_data_source.dart';
import '/domain/failures/pack/pack_failure.dart';
import '/domain/repositories/pack/pack_base_api_service.dart';
import '/domain/usecases/theme/update_theme_use_case.dart';
import 'settings_initial_params.dart';
import 'settings_state.dart';

/// Settings: offline storage, appearance, the data sources, and the optional tip
/// jar that keeps the app free.
class SettingsCubit extends Cubit<SettingsState> {
  static const String clearPacksLabel = 'clear-packs';

  final SettingsInitialParams initialParams;
  final PackBaseApiService packRepository;
  final ThemeDataSources themeDataSource;
  final UpdateThemeUseCase updateThemeUseCase;
  final ExternalLinkService externalLinkService;
  final Show show;

  SettingsCubit(
    this.initialParams,
    this.packRepository,
    this.themeDataSource,
    this.updateThemeUseCase,
    this.externalLinkService,
    this.show,
  ) : super(SettingsState.initial(initialParams: initialParams));

  Future<void> load() async {
    final installedResult = await packRepository.installedCountryCodes();
    final bytesResult = await packRepository.installedBytes();

    var installed = const <String>[];
    installedResult.fold(
      (PackStorageFailure left) {},
      (List<String> right) => installed = right,
    );

    var bytes = 0;
    bytesResult.fold((PackStorageFailure left) {}, (int right) => bytes = right);

    emit(
      state.copyWith(
        installedCount: installed.length,
        installedBytes: bytes,
        isDarkMode: themeDataSource.state,
      ),
    );
  }

  Future<void> setDarkMode({required bool value}) async {
    await updateThemeUseCase.execute(value);
    emit(state.copyWith(isDarkMode: value));
  }

  /// Opens the tip jar.
  ///
  /// Nothing is gated behind this: the app behaves identically whether or not
  /// anyone ever taps it, which is the whole point of leaving it optional.
  Future<void> openSupportPage() async {
    if (SupportConfig.hasPlaceholderUrl) {
      show.showErrorSnackBar(
        'Set your own page in SupportConfig.donationUrl first',
      );
      return;
    }

    final opened = await externalLinkService.open(SupportConfig.donationUrl);

    if (isClosed) return;
    if (!opened) {
      show.showErrorSnackBar("Couldn't open a browser for the support page");
    }
  }

  /// Removes every downloaded pack. The packs are free, so this is purely about
  /// reclaiming space - re-downloading costs nothing.
  Future<void> clearInstalledPacks() async {
    if (state.isBusy) return;
    emit(state.copyWith(busyLabel: clearPacksLabel));

    final installedResult = await packRepository.installedCountryCodes();
    var installed = const <String>[];
    installedResult.fold(
      (PackStorageFailure left) {},
      (List<String> right) => installed = right,
    );

    var failures = 0;
    for (final code in installed) {
      final result = await packRepository.delete(code);
      result.fold((PackStorageFailure left) => failures++, (bool right) {});
    }

    if (isClosed) return;
    emit(state.withoutBusy());

    if (failures > 0) {
      show.showErrorSnackBar('Could not remove $failures pack(s)');
    } else {
      show.showSuccessSnackBar(
        installed.isEmpty
            ? 'No packs were downloaded'
            : 'Removed ${installed.length} pack(s) from this device',
      );
    }

    await load();
  }
}
