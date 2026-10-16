import 'package:fpdart/fpdart.dart';

import '/data/models/pack/country_pack_model.dart';
import '/domain/failures/pack/pack_failure.dart';

/// Reading, installing and refreshing country packs.
///
/// Cache-first by contract: [installedPack] and [installedCountryCodes] never
/// touch the network, and [download] always succeeds for a known country even
/// with no connection, because the editorial half of a pack ships in the app
/// bundle. Only [refresh] is network-dependent, and it is optional.
abstract class PackBaseApiService {
  /// Every pack the app knows about, sourced from bundled content so the
  /// browser renders identically online and offline.
  Future<Either<PackStorageFailure, List<PackSummaryModel>>> catalogue();

  /// A pack as installed on this device, read straight from local storage.
  Future<Either<PackNotFoundFailure, CountryPackModel>> installedPack(
    String countryCode,
  );

  /// Country codes installed on this device.
  Future<Either<PackStorageFailure, List<String>>> installedCountryCodes();

  /// Installs a pack. Bundled content is always written; weather and rates are
  /// fetched opportunistically and a failure there does not fail the install.
  Future<Either<PackDownloadFailure, CountryPackModel>> download({
    required String countryCode,
    void Function(PackDownloadProgress progress)? onProgress,
  });

  /// Refreshes the volatile sections of an installed pack (live forecast and
  /// exchange rates). Returns the pack unchanged when the network is unusable.
  Future<Either<PackDownloadFailure, CountryPackModel>> refresh({
    required String countryCode,
    void Function(PackDownloadProgress progress)? onProgress,
  });

  /// Removes an installed pack from the device.
  Future<Either<PackStorageFailure, bool>> delete(String countryCode);

  /// Total bytes used by installed packs.
  Future<Either<PackStorageFailure, int>> installedBytes();
}
