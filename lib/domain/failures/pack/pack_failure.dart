/// Failures raised by the country-pack layer.
///
/// Each mirrors the house failure shape: a single human-readable [error] plus a
/// value equality so failures can be compared in tests.
library;

class PackStorageFailure {
  final String error;

  const PackStorageFailure({required this.error});

  @override
  String toString() => 'PackStorageFailure(error: $error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackStorageFailure &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;
}

/// A pack download could not complete - usually because the device went
/// offline partway through, or an upstream API failed.
class PackDownloadFailure {
  final String error;

  const PackDownloadFailure({required this.error});

  @override
  String toString() => 'PackDownloadFailure(error: $error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackDownloadFailure &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;
}

/// The traveller asked to open a pack they have not unlocked.
class PackNotOwnedFailure {
  final String error;

  const PackNotOwnedFailure({required this.error});

  @override
  String toString() => 'PackNotOwnedFailure(error: $error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackNotOwnedFailure &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;
}

/// The requested pack does not exist in the catalogue.
class PackNotFoundFailure {
  final String error;

  const PackNotFoundFailure({required this.error});

  @override
  String toString() => 'PackNotFoundFailure(error: $error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PackNotFoundFailure &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;
}
