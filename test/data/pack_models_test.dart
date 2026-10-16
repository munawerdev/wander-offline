import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wander_offline/data/models/pack/country_facts_model.dart';
import 'package:wander_offline/data/models/pack/country_pack_model.dart';
import 'package:wander_offline/data/models/pack/landmark_model.dart';
import 'package:wander_offline/data/models/pack/weather_trend_model.dart';

/// A miniature pack that follows exactly the schema the bundled content files
/// use, so the models are tested against the real shape rather than an invented
/// one.
Map<String, dynamic> buildContentJson() => <String, dynamic>{
  'countryCode': 'jp',
  'name': 'Japan',
  'tagline': 'Bullet trains and ¥300 ramen',
  'region': 'East Asia',
  'accentColor': '#BC002D',
  'currencyCode': 'JPY',
  'primaryCity': 'Tokyo',
  'latitude': 36.2048,
  'longitude': 138.2529,
  'blurb': 'Cheap temples, fast trains.',
  'facts': <String, dynamic>{
    'capital': 'Tokyo',
    'region': 'East Asia',
    'subregion': 'Eastern Asia',
    'population': 123300000,
    'areaKm2': 377975,
    'currency': <String, dynamic>{
      'code': 'jpy',
      'name': 'Japanese yen',
      'symbol': '¥',
    },
    'languages': <String>['Japanese'],
    'callingCode': '+81',
    'drivingSide': 'left',
    'timezones': <String>['UTC+09:00'],
    'powerPlug': 'Type A/B, 100V',
    'tapWater': 'Safe to drink',
    'visaNote': 'Visa free for most Western passports.',
    'bestMonths': 'Late March to May.',
    'dailyBudget': '¥8,000-13,000 per day.',
    'cashVsCard': 'Cash heavy outside the big chains.',
  },
  'landmarks': <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'jp-senso-ji',
      'name': 'Sensō-ji',
      'city': 'Tokyo',
      'category': 'temple',
      'latitude': 35.7148,
      'longitude': 139.7967,
      'whyVisit': 'Go at dawn and you get it to yourself.',
      'description': 'Tokyos oldest temple, founded in 645.',
      'bestTime': 'Before 8am',
      'entryFee': 'Free',
      'tip': 'The approach street is empty before 7am.',
    },
    <String, dynamic>{
      'id': 'jp-kinkaku-ji',
      'name': 'Kinkaku-ji',
      'city': 'Kyoto',
      'category': 'temple',
      'latitude': 35.0394,
      'longitude': 135.7292,
      'whyVisit': 'Gold leaf over a reflecting pond.',
      'description': 'A Zen temple rebuilt in 1955.',
      'bestTime': 'Opening time',
      'entryFee': '¥500',
      'tip': 'Buy the ticket at the gate, not from touts.',
    },
  ],
  'tips': <String, dynamic>{
    'currency': <String>['Carry cash.'],
    'tipping': <String>['Not expected.'],
    'scams': <String>['Bar covers in nightlife districts.'],
    'transport': <String>['Get an IC card.'],
    'etiquette': <String>['Do not eat while walking.'],
    'emergency': <String, dynamic>{
      'police': '110',
      'ambulance': '119',
      'notes': 'English support is limited.',
    },
  },
};

void main() {
  group('CountryPackModel', () {
    test('parses the bundled content shape', () {
      final pack = CountryPackModel.fromJson(buildContentJson());

      expect(pack.countryCode, 'JP');
      expect(pack.name, 'Japan');
      expect(pack.currencyCode, 'JPY');
      expect(pack.landmarks.length, 2);
      expect(pack.facts.currency.code, 'JPY');
      expect(pack.tips.totalTips, 5);
      expect(pack.tips.emergency.ambulance, '119');
    });

    test('defaults weather and rates to empty when the asset omits them', () {
      final pack = CountryPackModel.fromJson(buildContentJson());

      expect(pack.weather.hasContent, isFalse);
      expect(pack.rates.hasRates, isFalse);
      expect(pack.hasLiveData, isFalse);
    });

    test('lists distinct cities in first-seen order', () {
      final pack = CountryPackModel.fromJson(buildContentJson());
      expect(pack.cities, <String>['Tokyo', 'Kyoto']);
    });

    test('finds landmarks by their map key', () {
      final pack = CountryPackModel.fromJson(buildContentJson());
      expect(pack.landmarkById('jp-kinkaku-ji')?.city, 'Kyoto');
      expect(pack.landmarkById('nope'), isNull);
    });

    test('survives a JSON round trip, including landmarks and facts', () {
      final pack = CountryPackModel.fromJson(buildContentJson());
      final restored = CountryPackModel.fromJson(
        jsonDecode(jsonEncode(pack.toJson())) as Map<String, dynamic>,
      );

      expect(restored.landmarks.length, pack.landmarks.length);
      expect(restored.landmarks.first.name, 'Sensō-ji');
      expect(restored.facts.population, 123300000);
      expect(restored.tips.transport, <String>['Get an IC card.']);
    });

    test('copyWith replaces only the sections it is given', () {
      final pack = CountryPackModel.fromJson(buildContentJson());
      final updated = pack.copyWith(weather: WeatherTrendModel.empty());

      expect(updated.name, pack.name);
      expect(updated.landmarks.length, pack.landmarks.length);
      expect(updated.weather.hasContent, isFalse);
    });

    test('copes with an empty map instead of throwing', () {
      final pack = CountryPackModel.fromJson(<String, dynamic>{});
      expect(pack.countryCode, isEmpty);
      expect(pack.landmarks, isEmpty);
      expect(pack.facts.population, 0);
    });
  });

  group('PackSummaryModel', () {
    test('counts landmarks and tips from raw content', () {
      final summary = PackSummaryModel.fromJson(buildContentJson());
      expect(summary.landmarkCount, 2);
      expect(summary.tipCount, 5);
      expect(summary.currencyCode, 'JPY');
    });

    test('derives a flag emoji from the ISO code', () {
      expect(PackSummaryModel.fromJson(buildContentJson()).flagEmoji, '🇯🇵');
      expect(
        PackSummaryModel.fromJson(<String, dynamic>{'countryCode': 'IT'})
            .flagEmoji,
        '🇮🇹',
      );
    });

    test('falls back to a globe for a malformed code', () {
      expect(
        PackSummaryModel.fromJson(<String, dynamic>{'countryCode': 'X'})
            .flagEmoji,
        '🌍',
      );
    });

    test('can be built from a full pack', () {
      final pack = CountryPackModel.fromJson(buildContentJson());
      final summary = PackSummaryModel.fromPack(pack);
      expect(summary.name, pack.name);
      expect(summary.landmarkCount, 2);
    });
  });

  group('CountryFactsModel', () {
    test('formats population and language lists for display', () {
      final facts = CountryFactsModel.fromJson(
        buildContentJson()['facts'] as Map<String, dynamic>,
      );

      expect(facts.populationLabel, '123.3 million');
      expect(facts.areaLabel, contains('km²'));
      expect(facts.languagesLabel, 'Japanese');
      expect(facts.drivingSideLabel, 'Drive on the left');
      expect(facts.hasContent, isTrue);
    });

    test('reports missing data rather than inventing it', () {
      final facts = CountryFactsModel.empty();
      expect(facts.populationLabel, 'Unknown');
      expect(facts.languagesLabel, 'Unknown');
      expect(facts.hasContent, isFalse);
    });

    test('capitalises the driving side label for right-hand traffic', () {
      final facts = CountryFactsModel.fromJson(<String, dynamic>{
        'drivingSide': 'right',
      });
      expect(facts.drivingSideLabel, 'Drive on the right');
    });
  });

  group('LandmarkModel', () {
    test('builds a readable label from a category slug', () {
      const base = LandmarkModel(
        id: 'x',
        name: 'X',
        city: 'Y',
        category: 'neighbourhood',
        latitude: 0,
        longitude: 0,
        whyVisit: '',
        description: '',
        bestTime: '',
        entryFee: '',
        tip: '',
      );

      expect(base.categoryLabel, 'Neighbourhood');
      expect(
        LandmarkModel.fromJson(<String, dynamic>{'category': 'viewpoint'})
            .categoryLabel,
        'Viewpoint',
      );
    });

    test('falls back to a generated map key when no id is present', () {
      final landmark = LandmarkModel.fromJson(<String, dynamic>{
        'name': 'Somewhere',
        'latitude': 1.5,
        'longitude': 2.5,
      });
      expect(landmark.mapKey, 'Somewhere@1.5,2.5');
    });
  });

  group('DailyWeatherModel.fromOpenMeteoDaily', () {
    test('zips the parallel arrays Open-Meteo returns', () {
      final days = DailyWeatherModel.fromOpenMeteoDaily(<String, dynamic>{
        'time': <String>['2026-10-17', '2026-10-18'],
        'temperature_2m_max': <double>[23.4, 22.3],
        'temperature_2m_min': <double>[15.4, 12.2],
        'precipitation_sum': <double>[0.0, 18.0],
        'weather_code': <int>[1, 61],
      });

      expect(days.length, 2);
      expect(days.first.date, DateTime(2026, 10, 17));
      expect(days.first.tempMaxC, 23.4);
      expect(days.first.conditionLabel, 'Mainly clear');
      expect(days.first.isWet, isFalse);
      expect(days[1].isWet, isTrue);
    });

    test('tolerates arrays shorter than the time series', () {
      final days = DailyWeatherModel.fromOpenMeteoDaily(<String, dynamic>{
        'time': <String>['2026-10-17', '2026-10-18'],
        'temperature_2m_max': <double>[23.4],
      });

      expect(days.length, 2);
      expect(days[1].tempMaxC, 0);
      expect(days[1].weatherCode, 0);
    });

    test('returns nothing when there is no time series', () {
      expect(
        DailyWeatherModel.fromOpenMeteoDaily(<String, dynamic>{}),
        isEmpty,
      );
    });
  });

  group('WeatherTrendModel', () {
    final seasonal = <DailyWeatherModel>[
      DailyWeatherModel(
        date: DateTime(2026, 10, 17),
        tempMaxC: 20,
        tempMinC: 12,
        precipitationMm: 0,
        weatherCode: 1,
      ),
      DailyWeatherModel(
        date: DateTime(2026, 10, 18),
        tempMaxC: 24,
        tempMinC: 14,
        precipitationMm: 5,
        weatherCode: 61,
      ),
    ];

    test('leads with the live forecast when one exists', () {
      final trend = WeatherTrendModel(
        timezone: 'auto',
        seasonal: seasonal,
        forecast: <DailyWeatherModel>[
          DailyWeatherModel(
            date: DateTime(2026, 10, 17),
            tempMaxC: 30,
            tempMinC: 20,
            precipitationMm: 0,
            weatherCode: 0,
          ),
        ],
        seasonalYears: 3,
      );

      expect(trend.hasForecast, isTrue);
      expect(trend.primarySeries.length, 1);
      expect(trend.primarySeries.first.tempMaxC, 30);
    });

    test('falls back to the seasonal average when there is no forecast', () {
      final trend = WeatherTrendModel(
        timezone: 'auto',
        seasonal: seasonal,
        forecast: const <DailyWeatherModel>[],
        seasonalYears: 3,
      );

      expect(trend.hasForecast, isFalse);
      expect(trend.primarySeries.length, 2);
      expect(trend.averageHighC, 22);
      expect(trend.averageLowC, 13);
      expect(trend.wetDayCount, 1);
      expect(trend.seasonalSummary, contains('rain on 1 of 2 days'));
    });
  });
}
