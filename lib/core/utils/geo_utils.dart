import 'dart:math' as math;
import 'dart:ui' show Offset;

/// A latitude/longitude pair, kept separate from any data model so the
/// geometry helpers stay independent of JSON parsing.
class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint({required this.latitude, required this.longitude});

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';
}

/// A latitude/longitude window, used to frame the offline schematic map.
class GeoBounds {
  final double minLatitude;
  final double maxLatitude;
  final double minLongitude;
  final double maxLongitude;

  const GeoBounds({
    required this.minLatitude,
    required this.maxLatitude,
    required this.minLongitude,
    required this.maxLongitude,
  });

  /// Builds a bounding box around [points], padded by [paddingFraction] of the
  /// span so pins never sit flush against the frame. A degenerate span (a
  /// single point, or points on one line) is expanded to a minimum size so the
  /// projection never divides by zero.
  factory GeoBounds.fromPoints(
    List<GeoPoint> points, {
    double paddingFraction = 0.12,
    double minimumSpan = 0.02,
  }) {
    if (points.isEmpty) {
      return GeoBounds(
        minLatitude: -minimumSpan,
        maxLatitude: minimumSpan,
        minLongitude: -minimumSpan,
        maxLongitude: minimumSpan,
      );
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLon = points.first.longitude;
    var maxLon = points.first.longitude;

    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLon = math.min(minLon, point.longitude);
      maxLon = math.max(maxLon, point.longitude);
    }

    var latSpan = maxLat - minLat;
    var lonSpan = maxLon - minLon;

    if (latSpan < minimumSpan) {
      final centre = (minLat + maxLat) / 2;
      minLat = centre - minimumSpan / 2;
      maxLat = centre + minimumSpan / 2;
      latSpan = minimumSpan;
    }
    if (lonSpan < minimumSpan) {
      final centre = (minLon + maxLon) / 2;
      minLon = centre - minimumSpan / 2;
      maxLon = centre + minimumSpan / 2;
      lonSpan = minimumSpan;
    }

    final latPad = latSpan * paddingFraction;
    final lonPad = lonSpan * paddingFraction;

    return GeoBounds(
      minLatitude: minLat - latPad,
      maxLatitude: maxLat + latPad,
      minLongitude: minLon - lonPad,
      maxLongitude: maxLon + lonPad,
    );
  }

  double get latitudeSpan => maxLatitude - minLatitude;
  double get longitudeSpan => maxLongitude - minLongitude;

  GeoPoint get centre => GeoPoint(
    latitude: (minLatitude + maxLatitude) / 2,
    longitude: (minLongitude + maxLongitude) / 2,
  );
}

/// Great-circle distance in kilometres between two points.
///
/// Uses the haversine formula on a spherical earth (mean radius 6371 km). Good
/// to a few metres over the distances a landmark list cares about.
double distanceKm({
  required double latitude1,
  required double longitude1,
  required double latitude2,
  required double longitude2,
}) {
  const earthRadiusKm = 6371.0;
  final dLat = _toRadians(latitude2 - latitude1);
  final dLon = _toRadians(longitude2 - longitude1);
  final lat1 = _toRadians(latitude1);
  final lat2 = _toRadians(latitude2);

  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.sin(dLon / 2) * math.sin(dLon / 2) * math.cos(lat1) * math.cos(lat2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

/// Projects [point] into a 0..1 unit square covering [bounds], with x growing
/// east and y growing **down** so the result maps directly onto canvas
/// coordinates.
///
/// This is an equirectangular (plate carree) projection: accurate enough to
/// show how landmarks sit relative to each other inside one country, and it
/// needs no map tiles, no network and no GPU, which is exactly what the
/// offline fallback view requires.
Offset projectToUnitSquare(GeoPoint point, GeoBounds bounds) {
  final lonSpan = bounds.longitudeSpan;
  final latSpan = bounds.latitudeSpan;

  final x = lonSpan == 0 ? 0.5 : (point.longitude - bounds.minLongitude) / lonSpan;
  final y = latSpan == 0 ? 0.5 : (bounds.maxLatitude - point.latitude) / latSpan;

  return Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));
}

/// Compass bearing from point 1 to point 2, in degrees clockwise from north.
double bearingDegrees({
  required double latitude1,
  required double longitude1,
  required double latitude2,
  required double longitude2,
}) {
  final lat1 = _toRadians(latitude1);
  final lat2 = _toRadians(latitude2);
  final dLon = _toRadians(longitude2 - longitude1);

  final y = math.sin(dLon) * math.cos(lat2);
  final x =
      math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

  final degrees = math.atan2(y, x) * 180 / math.pi;
  return (degrees + 360) % 360;
}

double _toRadians(double degrees) => degrees * math.pi / 180;
