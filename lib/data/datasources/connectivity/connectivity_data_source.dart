import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper over `connectivity_plus` so the rest of the app depends on a
/// tiny surface that is easy to fake in tests.
class ConnectivityDataSource {
  final Connectivity _connectivity;

  ConnectivityDataSource(this._connectivity);

  /// True when at least one transport (wifi, mobile, ethernet, vpn) is up.
  ///
  /// Note this reports link state, not reachability: a captive-portal wifi
  /// still counts as online. Callers must therefore treat a failed request as
  /// the real authority and fall back to cache.
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return hasTransport(results);
  }

  Stream<bool> get onStatusChanged =>
      _connectivity.onConnectivityChanged.map(hasTransport);

  static bool hasTransport(List<ConnectivityResult> results) =>
      results.any((ConnectivityResult result) => result != ConnectivityResult.none);
}
