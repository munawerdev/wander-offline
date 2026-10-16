import 'package:flutter_test/flutter_test.dart';
import 'package:wander_offline/data/datasources/pack/curated_pack_data_source.dart';
import 'package:wander_offline/data/models/pack/country_pack_model.dart';

/// Exercises the real asset pipeline rather than the file system.
///
/// `test/content/pack_content_test.dart` reads the JSON off disk, which validates
/// the content but not the wiring. These tests go through `rootBundle`, so they
/// fail if `assets/content/` is ever dropped from `pubspec.yaml` - the failure
/// mode that would otherwise only show up as an empty catalogue on a device.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CuratedPackDataSource', () {
    final dataSource = CuratedPackDataSource();

    test('loads every catalogue pack through the asset bundle', () async {
      final catalogue = await dataSource.loadCatalogue();

      expect(catalogue.length, CuratedPackDataSource.curatedCountryCodes.length);
      expect(
        catalogue
            .map((Map<String, dynamic> content) => content['countryCode'])
            .toSet(),
        CuratedPackDataSource.curatedCountryCodes.toSet(),
      );
    });

    test('caches a pack so repeated reads do not re-decode the asset', () async {
      final first = await dataSource.loadPack('JP');
      final second = await dataSource.loadPack('jp');

      expect(first, isNotNull);
      expect(identical(first, second), isTrue);
    });

    test('returns null for a country with no bundled content', () async {
      expect(await dataSource.loadPack('ZZ'), isNull);
    });

    test('builds asset paths from the country code', () {
      expect(
        CuratedPackDataSource.assetPathFor('JP'),
        'assets/content/jp.json',
      );
    });
  });

  group('asset content through the models', () {
    final dataSource = CuratedPackDataSource();

    test('every bundled pack parses into a usable pack', () async {
      for (final code in CuratedPackDataSource.curatedCountryCodes) {
        final content = await dataSource.loadPack(code);
        expect(content, isNotNull, reason: '$code did not load');

        final pack = CountryPackModel.fromJson(content!);
        expect(pack.countryCode, code);
        expect(pack.landmarks.length, 8);
        expect(pack.cities.length, greaterThanOrEqualTo(3));
        expect(pack.facts.hasContent, isTrue);
        expect(pack.tips.hasContent, isTrue);
        expect(pack.blurb.length, greaterThan(120));
      }
    });

    test('summaries report the counts the browser renders', () async {
      final summaries = (await dataSource.loadCatalogue())
          .map(PackSummaryModel.fromJson)
          .toList();

      for (final summary in summaries) {
        expect(summary.landmarkCount, 8);
        expect(summary.tipCount, greaterThanOrEqualTo(15));
        expect(summary.name, isNotEmpty);
        expect(summary.tagline, isNotEmpty);
        expect(summary.accentColorHex, startsWith('#'));
        expect(summary.flagEmoji.length, greaterThan(1));
      }

      // One summary per bundled file, and each carries its own country's name.
      expect(summaries.length, CuratedPackDataSource.curatedCountryCodes.length);
      for (final summary in summaries) {
        final content = await dataSource.loadPack(summary.countryCode);
        expect(summary.name, content!['name']);
      }
    });
  });
}
