import 'package:flutter_test/flutter_test.dart';
import 'package:wander_offline/data/models/pack/exchange_rates_model.dart';

void main() {
  final snapshot = ExchangeRatesModel(
    base: 'USD',
    rates: const <String, double>{'JPY': 158.02, 'THB': 33.415, 'EUR': 0.88865},
    fetchedAt: DateTime(2026, 10, 16),
    source: 'Frankfurter (ECB reference rates)',
  );

  group('currencies', () {
    test('always includes the base and sorts alphabetically', () {
      expect(snapshot.currencies, <String>['EUR', 'JPY', 'THB', 'USD']);
    });
  });

  group('rateFor', () {
    test('treats the base currency as 1:1', () {
      expect(snapshot.rateFor('USD'), 1);
      expect(snapshot.rateFor('usd'), 1);
    });

    test('is case-insensitive and null for anything unknown', () {
      expect(snapshot.rateFor('jpy'), 158.02);
      expect(snapshot.rateFor('XYZ'), isNull);
    });
  });

  group('convert', () {
    test('goes from the base currency to a foreign one', () {
      final converted = snapshot.convert(amount: 100, from: 'USD', to: 'JPY');
      expect(converted, closeTo(15802, 0.001));
    });

    test('goes back from a foreign currency to the base', () {
      final converted = snapshot.convert(amount: 15802, from: 'JPY', to: 'USD');
      expect(converted, closeTo(100, 0.001));
    });

    test('cross-converts between two foreign currencies', () {
      final converted = snapshot.convert(amount: 15802, from: 'JPY', to: 'THB');
      expect(converted, closeTo(3341.5, 0.001));
    });

    test('returns null rather than a wrong number when a rate is missing', () {
      expect(snapshot.convert(amount: 10, from: 'USD', to: 'XYZ'), isNull);
      expect(snapshot.convert(amount: 10, from: 'XYZ', to: 'USD'), isNull);
    });

    test('returns null for an empty snapshot', () {
      final empty = ExchangeRatesModel.empty();
      expect(empty.rateFor('USD'), 1);
      expect(empty.convert(amount: 10, from: 'USD', to: 'JPY'), isNull);
    });
  });

  group('isStale', () {
    final now = DateTime(2026, 10, 16, 12);

    test('is false for a fresh snapshot', () {
      final fresh = ExchangeRatesModel(
        base: 'USD',
        rates: const <String, double>{'JPY': 158.02},
        fetchedAt: now.subtract(const Duration(hours: 2)),
        source: 'test',
      );
      expect(fresh.isStale(), isFalse);
    });

    test('is true once the tolerance has passed', () {
      final old = ExchangeRatesModel(
        base: 'USD',
        rates: const <String, double>{'JPY': 158.02},
        fetchedAt: now.subtract(const Duration(days: 4)),
        source: 'test',
      );
      expect(old.isStale(), isTrue);
    });
  });

  test('normalises keys and base on the way in from JSON', () {
    final parsed = ExchangeRatesModel.fromJson(<String, dynamic>{
      'base': 'usd',
      'rates': <String, dynamic>{'jpy': 158.02, 'thb': 'not a number'},
      'fetchedAt': '2026-10-16T00:00:00.000',
      'source': 'test',
    });

    expect(parsed.base, 'USD');
    expect(parsed.rates.containsKey('JPY'), isTrue);
    // Non-numeric rates are dropped rather than poisoning the table.
    expect(parsed.rates.containsKey('THB'), isFalse);
  });
}
