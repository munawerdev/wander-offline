import 'settings_initial_params.dart';

class SettingsState {
  final bool isDarkMode;
  final int installedCount;
  final int installedBytes;

  /// Label of the action currently running, so exactly one row can show a
  /// spinner.
  final String? busyLabel;

  SettingsState({
    required this.isDarkMode,
    required this.installedCount,
    required this.installedBytes,
    this.busyLabel,
  });

  factory SettingsState.initial({
    required SettingsInitialParams initialParams,
  }) => SettingsState(isDarkMode: false, installedCount: 0, installedBytes: 0);

  bool get isBusy => busyLabel != null;

  bool isBusyWith(String label) => busyLabel == label;

  SettingsState copyWith({
    bool? isDarkMode,
    int? installedCount,
    int? installedBytes,
    String? busyLabel,
  }) => SettingsState(
    isDarkMode: isDarkMode ?? this.isDarkMode,
    installedCount: installedCount ?? this.installedCount,
    installedBytes: installedBytes ?? this.installedBytes,
    busyLabel: busyLabel ?? this.busyLabel,
  );

  /// Clears the in-flight label. `copyWith` cannot set a null, so this rebuilds
  /// explicitly.
  SettingsState withoutBusy() => SettingsState(
    isDarkMode: isDarkMode,
    installedCount: installedCount,
    installedBytes: installedBytes,
  );
}
