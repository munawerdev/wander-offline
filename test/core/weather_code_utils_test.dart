import 'package:flutter_test/flutter_test.dart';
import 'package:wander_offline/core/utils/weather_code_utils.dart';

void main() {
  group('weatherKindForCode', () {
    test('maps clear and cloud codes', () {
      expect(weatherKindForCode(0), WeatherKind.clear);
      expect(weatherKindForCode(1), WeatherKind.cloudy);
      expect(weatherKindForCode(3), WeatherKind.cloudy);
    });

    test('maps fog, drizzle, rain, snow and thunder', () {
      expect(weatherKindForCode(45), WeatherKind.fog);
      expect(weatherKindForCode(53), WeatherKind.drizzle);
      expect(weatherKindForCode(63), WeatherKind.rain);
      expect(weatherKindForCode(75), WeatherKind.snow);
      expect(weatherKindForCode(95), WeatherKind.thunderstorm);
    });

    test('treats showers as rain and snow showers as snow', () {
      expect(weatherKindForCode(81), WeatherKind.rain);
      expect(weatherKindForCode(86), WeatherKind.snow);
    });

    test('falls back to cloudy for an unknown code', () {
      expect(weatherKindForCode(1234), WeatherKind.cloudy);
    });
  });

  group('weatherLabelForCode', () {
    test('names the common codes', () {
      expect(weatherLabelForCode(0), 'Clear sky');
      expect(weatherLabelForCode(63), 'Rain');
      expect(weatherLabelForCode(95), 'Thunderstorm');
    });

    test('always returns something readable', () {
      expect(weatherLabelForCode(-1), isNotEmpty);
      expect(weatherLabelForCode(1234), 'Mixed conditions');
    });
  });

  group('shortWeekdayLabel', () {
    test('labels Monday through Sunday', () {
      // 2026-10-12 is a Monday.
      final monday = DateTime(2026, 10, 12);
      expect(monday.weekday, DateTime.monday);
      expect(shortWeekdayLabel(monday), 'Mon');
      expect(
        shortWeekdayLabel(monday.add(const Duration(days: 6))),
        'Sun',
      );
    });
  });
}
