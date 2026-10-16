import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wander_offline/data/datasources/pack/curated_pack_data_source.dart';
import 'package:wander_offline/data/models/pack/country_pack_model.dart';

/// Locks in the quality of the hand-written content that ships with the app.
///
/// The pack files are the product: a typo in a schema key or a landmark pin
/// dropped on the wrong continent would ship silently, because the models are
/// deliberately tolerant of missing fields. These tests are the guard rail that
/// the defensive parsing cannot provide.
///
/// Coordinates are checked against a generous national bounding box, which
/// catches the realistic failure - a landmark rendered in the sea or the wrong
/// hemisphere - without being so tight that it fails on legitimate variation.
const Map<String, List<double>> countryBoundingBoxes = <String, List<double>>{
  // ISO code: [minLat, maxLat, minLon, maxLon]
  'JP': <double>[24.0, 46.0, 122.0, 146.5],
  'IT': <double>[35.4, 47.2, 6.6, 18.6],
  'TH': <double>[5.6, 20.5, 97.3, 105.7],
  'VN': <double>[8.0, 23.5, 102.0, 110.0],
  // Mainland only: Madeira and the Azores sit outside this box on purpose.
  'PT': <double>[36.8, 42.2, -9.6, -6.1],
  // Morocco proper, excluding Western Sahara.
  'MA': <double>[27.6, 36.0, -13.2, -0.9],
  'TR': <double>[35.8, 42.2, 25.6, 44.9],
  'PE': <double>[-18.4, 0.0, -81.4, -68.6],
};

const Set<String> requiredTopLevelKeys = <String>{
  'countryCode',
  'name',
  'tagline',
  'region',
  'accentColor',
  'currencyCode',
  'primaryCity',
  'latitude',
  'longitude',
  'blurb',
  'facts',
  'landmarks',
  'tips',
};

const Set<String> requiredLandmarkKeys = <String>{
  'id',
  'name',
  'city',
  'category',
  'latitude',
  'longitude',
  'whyVisit',
  'description',
  'bestTime',
  'entryFee',
  'tip',
};

const List<String> requiredTipSections = <String>[
  'currency',
  'tipping',
  'scams',
  'transport',
  'etiquette',
];

Map<String, dynamic> loadContent(String countryCode) {
  final file = File('assets/content/${countryCode.toLowerCase()}.json');
  if (!file.existsSync()) {
    throw StateError('Missing bundled pack content: ${file.path}');
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  for (final entry in countryBoundingBoxes.entries) {
    final code = entry.key;
    final box = entry.value;

    group('$code pack content', () {
      late final Map<String, dynamic> content = loadContent(code);

      test('declares exactly the expected top-level keys', () {
        expect(content.keys.toSet(), requiredTopLevelKeys);
        expect(content['countryCode'], code);
        expect((content['name'] as String).trim(), isNotEmpty);
        expect((content['tagline'] as String).length, lessThanOrEqualTo(70));
        expect((content['blurb'] as String).length, greaterThan(120));
        expect(
          (content['accentColor'] as String),
          matches(RegExp(r'^#[0-9A-Fa-f]{6}$')),
        );
      });

      test('ships eight landmarks with unique ids', () {
        final landmarks = content['landmarks'] as List<dynamic>;
        expect(landmarks.length, 8);

        final ids = landmarks
            .map((dynamic raw) => (raw as Map<String, dynamic>)['id'] as String)
            .toList();
        expect(ids.toSet().length, ids.length, reason: 'duplicate landmark ids');
      });

      test('keeps every landmark inside the country bounding box', () {
        final landmarks = content['landmarks'] as List<dynamic>;
        final minLat = box[0];
        final maxLat = box[1];
        final minLon = box[2];
        final maxLon = box[3];

        for (final raw in landmarks) {
          final landmark = raw as Map<String, dynamic>;
          final latitude = (landmark['latitude'] as num).toDouble();
          final longitude = (landmark['longitude'] as num).toDouble();

          expect(
            latitude,
            inInclusiveRange(minLat, maxLat),
            reason: '${landmark['name']} latitude is outside $code',
          );
          expect(
            longitude,
            inInclusiveRange(minLon, maxLon),
            reason: '${landmark['name']} longitude is outside $code',
          );
        }
      });

      test('fills every landmark field with plain single-line text', () {
        final landmarks = content['landmarks'] as List<dynamic>;

        for (final raw in landmarks) {
          final landmark = raw as Map<String, dynamic>;
          expect(landmark.keys.toSet(), requiredLandmarkKeys);

          for (final key in requiredLandmarkKeys) {
            if (key == 'latitude' || key == 'longitude') continue;
            final value = landmark[key] as String;
            expect(
              value.trim(),
              isNotEmpty,
              reason: '${landmark['name']} has an empty $key',
            );
            expect(
              value.contains('\n'),
              isFalse,
              reason: '${landmark['name']} $key contains a newline',
            );
          }
        }
      });

      test('spreads landmarks over at least three cities', () {
        final landmarks = content['landmarks'] as List<dynamic>;
        final cities = landmarks
            .map((dynamic raw) => (raw as Map<String, dynamic>)['city'] as String)
            .toSet();
        expect(cities.length, greaterThanOrEqualTo(3));
      });

      test('fills all five local tip sections', () {
        final tips = content['tips'] as Map<String, dynamic>;

        for (final section in requiredTipSections) {
          final items = tips[section] as List<dynamic>;
          expect(
            items.length,
            greaterThanOrEqualTo(2),
            reason: '$code tips.$section is too thin',
          );
        }

        final emergency = tips['emergency'] as Map<String, dynamic>;
        expect((emergency['police'] as String).trim(), isNotEmpty);
        expect((emergency['ambulance'] as String).trim(), isNotEmpty);
      });

      test('carries complete country facts', () {
        final facts = content['facts'] as Map<String, dynamic>;

        expect((facts['capital'] as String).trim(), isNotEmpty);
        expect(facts['population'] as int, greaterThan(0));
        expect((facts['areaKm2'] as num).toDouble(), greaterThan(0));
        expect((facts['currency'] as Map<String, dynamic>)['code'], isNotEmpty);
        expect((facts['currency'] as Map<String, dynamic>)['symbol'], isNotEmpty);
        expect((facts['languages'] as List<dynamic>), isNotEmpty);
        expect((facts['callingCode'] as String), startsWith('+'));
        expect((facts['visaNote'] as String).length, greaterThan(60));
        expect((facts['dailyBudget'] as String).trim(), isNotEmpty);
      });

      test('parses cleanly through the real model', () {
        final pack = CountryPackModel.fromJson(content);

        expect(pack.countryCode, code);
        expect(pack.landmarks.length, 8);
        expect(pack.cities.length, greaterThanOrEqualTo(3));
        expect(pack.facts.hasContent, isTrue);
        expect(pack.tips.hasContent, isTrue);
        expect(pack.rates.hasRates, isFalse);
        expect(pack.weather.hasContent, isFalse);
      });
    });
  }

  test('bounding boxes and the catalogue cannot drift apart', () {
    // Without this, adding a country to the catalogue but forgetting its
    // bounding box would silently skip the coordinate check for that country,
    // and the per-country groups above would never run.
    expect(
      countryBoundingBoxes.keys.toSet(),
      CuratedPackDataSource.curatedCountryCodes.toSet(),
      reason: 'add the new code to countryBoundingBoxes as well',
    );
  });

  test('every catalogue code has a bundled content file', () {
    for (final code in CuratedPackDataSource.curatedCountryCodes) {
      expect(
        File('assets/content/${code.toLowerCase()}.json').existsSync(),
        isTrue,
        reason: 'no content file for $code',
      );
    }
  });
}
