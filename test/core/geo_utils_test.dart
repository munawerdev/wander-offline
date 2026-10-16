import 'package:flutter_test/flutter_test.dart';
import 'package:wander_offline/core/utils/geo_utils.dart';

void main() {
  group('distanceKm', () {
    test('is in the right ballpark for a known city pair', () {
      // Tokyo to Osaka is roughly 400 km as the crow flies.
      final distance = distanceKm(
        latitude1: 35.6762,
        longitude1: 139.6503,
        latitude2: 34.6937,
        longitude2: 135.5023,
      );

      expect(distance, greaterThan(380));
      expect(distance, lessThan(420));
    });

    test('is zero for an identical point', () {
      expect(
        distanceKm(
          latitude1: 10,
          longitude1: 20,
          latitude2: 10,
          longitude2: 20,
        ),
        closeTo(0, 1e-9),
      );
    });
  });

  group('GeoBounds.fromPoints', () {
    test('contains and pads the supplied points', () {
      final bounds = GeoBounds.fromPoints(const <GeoPoint>[
        GeoPoint(latitude: 35, longitude: 139),
        GeoPoint(latitude: 36, longitude: 140),
      ]);

      expect(bounds.minLatitude, lessThan(35));
      expect(bounds.maxLatitude, greaterThan(36));
      expect(bounds.minLongitude, lessThan(139));
      expect(bounds.maxLongitude, greaterThan(140));
      expect(bounds.centre.latitude, closeTo(35.5, 1e-9));
    });

    test('expands a single-point box to a real span', () {
      // Guards the projection against dividing by a zero span.
      final bounds = GeoBounds.fromPoints(const <GeoPoint>[
        GeoPoint(latitude: 35.6762, longitude: 139.6503),
      ]);

      expect(bounds.latitudeSpan, greaterThan(0));
      expect(bounds.longitudeSpan, greaterThan(0));
      final projected = projectToUnitSquare(
        const GeoPoint(latitude: 35.6762, longitude: 139.6503),
        bounds,
      );
      expect(projected.dx, closeTo(0.5, 1e-9));
      expect(projected.dy, closeTo(0.5, 1e-9));
    });

    test('falls back to a usable box for no points at all', () {
      final bounds = GeoBounds.fromPoints(const <GeoPoint>[]);

      expect(bounds.latitudeSpan, greaterThan(0));
      expect(bounds.longitudeSpan, greaterThan(0));
    });
  });

  group('projectToUnitSquare', () {
    final bounds = GeoBounds.fromPoints(const <GeoPoint>[
      GeoPoint(latitude: 30, longitude: 130),
      GeoPoint(latitude: 40, longitude: 140),
    ]);

    test('maps the north-west corner of the box to the origin', () {
      final offset = projectToUnitSquare(
        GeoPoint(
          latitude: bounds.maxLatitude,
          longitude: bounds.minLongitude,
        ),
        bounds,
      );

      expect(offset.dx, closeTo(0, 1e-9));
      expect(offset.dy, closeTo(0, 1e-9));
    });

    test('grows y southwards so it maps onto canvas coordinates', () {
      final north = projectToUnitSquare(
        const GeoPoint(latitude: 39, longitude: 135),
        bounds,
      );
      final south = projectToUnitSquare(
        const GeoPoint(latitude: 31, longitude: 135),
        bounds,
      );

      expect(north.dy, lessThan(south.dy));
    });

    test('grows x eastwards', () {
      final west = projectToUnitSquare(
        const GeoPoint(latitude: 35, longitude: 131),
        bounds,
      );
      final east = projectToUnitSquare(
        const GeoPoint(latitude: 35, longitude: 139),
        bounds,
      );

      expect(west.dx, lessThan(east.dx));
    });

    test('clamps points that fall outside the box', () {
      final offset = projectToUnitSquare(
        const GeoPoint(latitude: 89, longitude: 179),
        bounds,
      );

      expect(offset.dx, inInclusiveRange(0, 1));
      expect(offset.dy, inInclusiveRange(0, 1));
    });
  });

  group('bearingDegrees', () {
    test('reports due north as 0', () {
      expect(
        bearingDegrees(
          latitude1: 0,
          longitude1: 0,
          latitude2: 10,
          longitude2: 0,
        ),
        closeTo(0, 0.001),
      );
    });

    test('reports due east as 90', () {
      expect(
        bearingDegrees(
          latitude1: 0,
          longitude1: 0,
          latitude2: 0,
          longitude2: 10,
        ),
        closeTo(90, 0.001),
      );
    });
  });
}
