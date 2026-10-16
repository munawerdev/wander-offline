import '/config/response/api_response.dart';
import '/config/response/status.dart';
import '/data/models/pack/country_pack_model.dart';
import 'pack_browser_initial_params.dart';

/// Which slice of the catalogue the traveller is looking at.
enum PackFilter { all, offline }

/// A catalogue entry merged with local state.
///
/// There is deliberately no ownership dimension: every pack is free, so the only
/// thing that varies between packs is whether this device has downloaded it.
class PackCardState {
  final PackSummaryModel summary;
  final bool isInstalled;

  const PackCardState({required this.summary, required this.isInstalled});

  String get countryCode => summary.countryCode;
  String get name => summary.name;
}

class PackBrowserState {
  final ApiResponse<List<PackCardState>> catalogue;
  final PackFilter filter;
  final bool isOnline;

  /// Country code currently downloading, if any.
  final String? activeDownloadCode;
  final PackDownloadProgress? downloadProgress;
  final int installedBytes;

  PackBrowserState({
    required this.catalogue,
    required this.filter,
    required this.isOnline,
    required this.installedBytes,
    this.activeDownloadCode,
    this.downloadProgress,
  });

  factory PackBrowserState.initial({
    required PackBrowserInitialParams initialParams,
  }) => PackBrowserState(
    catalogue: ApiResponse<List<PackCardState>>.initial(<PackCardState>[]),
    filter: PackFilter.all,
    isOnline: true,
    installedBytes: 0,
  );

  /// Safe catalogue access. `ApiResponse` leaves `data` unset for the loading,
  /// initial and error states, so reading it directly would throw.
  List<PackCardState> get cards =>
      catalogue.status == Status.completed
      ? catalogue.data
      : const <PackCardState>[];

  List<PackCardState> get visibleCards {
    switch (filter) {
      case PackFilter.all:
        return cards;
      case PackFilter.offline:
        return cards.where((PackCardState card) => card.isInstalled).toList();
    }
  }

  int get installedCount =>
      cards.where((PackCardState card) => card.isInstalled).length;

  bool get isDownloading => activeDownloadCode != null;

  bool isDownloadingCode(String countryCode) =>
      activeDownloadCode?.toUpperCase() == countryCode.toUpperCase();

  /// Fraction for the download bar, 0 when nothing is running.
  double get downloadFraction => downloadProgress?.safeFraction ?? 0;

  PackCardState? cardFor(String countryCode) {
    final code = countryCode.toUpperCase();
    for (final card in cards) {
      if (card.countryCode == code) return card;
    }
    return null;
  }

  PackBrowserState copyWith({
    ApiResponse<List<PackCardState>>? catalogue,
    PackFilter? filter,
    bool? isOnline,
    int? installedBytes,
    String? activeDownloadCode,
    PackDownloadProgress? downloadProgress,
  }) => PackBrowserState(
    catalogue: catalogue ?? this.catalogue,
    filter: filter ?? this.filter,
    isOnline: isOnline ?? this.isOnline,
    installedBytes: installedBytes ?? this.installedBytes,
    activeDownloadCode: activeDownloadCode ?? this.activeDownloadCode,
    downloadProgress: downloadProgress ?? this.downloadProgress,
  );

  /// Clears the download indicator. `copyWith` cannot express "set to null", so
  /// this rebuilds the state explicitly.
  PackBrowserState withoutDownload() => PackBrowserState(
    catalogue: catalogue,
    filter: filter,
    isOnline: isOnline,
    installedBytes: installedBytes,
  );
}
