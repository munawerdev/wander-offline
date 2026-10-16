/// Mapping for the WMO weather interpretation codes that Open-Meteo returns in
/// its `weather_code` daily field.
///
/// Reference: https://open-meteo.com/en/docs (WMO Weather interpretation codes)
enum WeatherKind { clear, cloudy, fog, drizzle, rain, snow, thunderstorm }

/// Broad bucket for a WMO code, used to pick an icon and a colour.
WeatherKind weatherKindForCode(int code) {
  if (code == 0) return WeatherKind.clear;
  if (code == 1 || code == 2 || code == 3) return WeatherKind.cloudy;
  if (code == 45 || code == 48) return WeatherKind.fog;
  if (code >= 51 && code <= 57) return WeatherKind.drizzle;
  if (code >= 61 && code <= 67) return WeatherKind.rain;
  if (code >= 71 && code <= 77) return WeatherKind.snow;
  if (code >= 80 && code <= 82) return WeatherKind.rain;
  if (code == 85 || code == 86) return WeatherKind.snow;
  if (code == 95 || code == 96 || code == 99) return WeatherKind.thunderstorm;
  // Anything outside the published WMO range (0-99) is treated as unknown
  // rather than guessed at, so a changed upstream value cannot masquerade as a
  // thunderstorm.
  return WeatherKind.cloudy;
}

/// Human-readable description for a WMO code.
String weatherLabelForCode(int code) {
  switch (code) {
    case 0:
      return 'Clear sky';
    case 1:
      return 'Mainly clear';
    case 2:
      return 'Partly cloudy';
    case 3:
      return 'Overcast';
    case 45:
      return 'Fog';
    case 48:
      return 'Freezing fog';
    case 51:
      return 'Light drizzle';
    case 53:
      return 'Drizzle';
    case 55:
      return 'Heavy drizzle';
    case 56:
    case 57:
      return 'Freezing drizzle';
    case 61:
      return 'Light rain';
    case 63:
      return 'Rain';
    case 65:
      return 'Heavy rain';
    case 66:
    case 67:
      return 'Freezing rain';
    case 71:
      return 'Light snow';
    case 73:
      return 'Snow';
    case 75:
      return 'Heavy snow';
    case 77:
      return 'Snow grains';
    case 80:
      return 'Light showers';
    case 81:
      return 'Showers';
    case 82:
      return 'Violent showers';
    case 85:
    case 86:
      return 'Snow showers';
    case 95:
      return 'Thunderstorm';
    case 96:
    case 99:
      return 'Thunderstorm with hail';
    default:
      return 'Mixed conditions';
  }
}

/// Short weekday label without pulling in a locale, e.g. `Mon`.
String shortWeekdayLabel(DateTime date) {
  const labels = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return labels[(date.weekday - 1) % 7];
}
