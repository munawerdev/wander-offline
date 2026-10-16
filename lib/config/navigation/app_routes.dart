class AppRoutes {
  /// Splash: restores the saved theme before the first frame of real UI.
  static const String splash = '/';

  /// Bottom-navigation shell holding the pack browser and settings tabs.
  static const String home = '/packs';

  /// One installed pack. Expects a `PackDetailInitialParams` as `extra`.
  static const String packDetail = '/pack';
}
