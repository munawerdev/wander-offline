import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '/config/theme/app_colors.dart';
import '/core/utils/extensions.dart';
import '/core/utils/format_utils.dart';
import '/core/utils/weather_code_utils.dart';
import '/core/widgets/section_card.dart';
import '/core/widgets/status_pill.dart';
import '/data/models/pack/weather_trend_model.dart';
import '/features/pack_detail/pack_detail_state.dart';

/// The weather tab: what this week is normally like (saved with the pack, so it
/// works offline forever), the day-by-day seasonal average, and - once the
/// device has been online - the live forecast.
class PackWeatherTab extends StatelessWidget {
  final PackDetailState state;
  final VoidCallback onRefresh;

  const PackWeatherTab({
    super.key,
    required this.state,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final weather = state.data?.weather;
    final seasonalDays = weather?.seasonal ?? const <DailyWeatherModel>[];
    final forecastDays = weather?.forecast ?? const <DailyWeatherModel>[];
    final forecastFetchedAt = weather?.forecastFetchedAt;

    return ListView(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 28.h),
      children: <Widget>[
        SectionCard(
          title: 'This week, typically',
          icon: Icons.thermostat_rounded,
          trailing: IconButton(
            onPressed: onRefresh,
            icon: Icon(Icons.refresh_rounded, size: 18.sp),
            tooltip: 'Refresh weather',
            visualDensity: VisualDensity.compact,
          ),
          children: _summaryChildren(weather),
        ),
        SectionCard(
          title: 'Day by day',
          icon: Icons.calendar_month_rounded,
          children: seasonalDays.isEmpty
              ? const <Widget>[_EmptyLine(text: 'No seasonal data yet')]
              : _dayRows(seasonalDays),
        ),
        if (weather?.hasForecast == true)
          SectionCard(
            title: 'Live forecast',
            icon: Icons.update_rounded,
            trailing: forecastFetchedAt == null
                ? null
                : Text(
                    formatRelative(forecastFetchedAt),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
            children: _dayRows(forecastDays),
          ),
      ],
    );
  }
}

/// The body of the "this week, typically" card: either the seasonal average or
/// a plain explanation of why it is missing.
List<Widget> _summaryChildren(WeatherTrendModel? weather) {
  if (weather == null || !weather.hasContent) {
    return const <Widget>[_OfflineWeatherNotice()];
  }
  return <Widget>[_SeasonalSummary(weather: weather)];
}

/// Flattens a series into rows separated by a hairline divider.
List<Widget> _dayRows(List<DailyWeatherModel> days) {
  final rows = <Widget>[];
  for (var index = 0; index < days.length; index++) {
    if (index > 0) {
      rows.add(const Divider(height: 1, thickness: 0.5));
    }
    rows.add(_DayRow(day: days[index]));
  }
  return rows;
}

/// Icon for a WMO bucket.
IconData _weatherIconFor(WeatherKind kind) {
  switch (kind) {
    case WeatherKind.clear:
      return Icons.wb_sunny_rounded;
    case WeatherKind.cloudy:
      return Icons.cloud_rounded;
    case WeatherKind.fog:
      return Icons.foggy;
    case WeatherKind.drizzle:
      return Icons.grain_rounded;
    case WeatherKind.rain:
      return Icons.water_drop_rounded;
    case WeatherKind.snow:
      return Icons.ac_unit_rounded;
    case WeatherKind.thunderstorm:
      return Icons.thunderstorm_rounded;
  }
}

/// Icon colour for a WMO bucket: theme accent while it is fair, warnings for
/// anything that will soak the traveller, and a cold blue for snow.
Color _weatherColorFor(BuildContext context, WeatherKind kind) {
  switch (kind) {
    case WeatherKind.clear:
    case WeatherKind.cloudy:
      return context.colorScheme.primary;
    case WeatherKind.snow:
      return const Color(0xFF4FC3F7);
    case WeatherKind.fog:
    case WeatherKind.drizzle:
    case WeatherKind.rain:
    case WeatherKind.thunderstorm:
      return AppColors.warning;
  }
}

class _SeasonalSummary extends StatelessWidget {
  final WeatherTrendModel weather;

  const _SeasonalSummary({required this.weather});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final wetDays = weather.wetDayCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              '${weather.averageHighC.round()}°',
              style: context.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 4.w),
            Padding(
              padding: EdgeInsets.only(bottom: 3.h),
              child: Text(
                '/ ${weather.averageLowC.round()}°',
                style: context.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          'Averaged over ${weather.seasonalYears} past years',
          style: context.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          weather.seasonalSummary,
          style: context.textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
        SizedBox(height: 10.h),
        StatusPill(
          label: wetDays > 0
              ? 'rain on $wetDays of ${weather.seasonal.length} days'
              : 'mostly dry',
          icon: wetDays > 0 ? Icons.water_drop_rounded : Icons.wb_sunny_rounded,
          color: wetDays > 0 ? AppColors.primary : AppColors.success,
        ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  final DailyWeatherModel day;

  const _DayRow({required this.day});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 7.h),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  day.weekdayLabel,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  day.dayLabel,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            _weatherIconFor(day.kind),
            size: 19.sp,
            color: _weatherColorFor(context, day.kind),
          ),
          SizedBox(width: 10.w),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  day.temperatureRangeLabel,
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (day.isWet)
                  Text(
                    '${day.precipitationMm.toStringAsFixed(1)} mm',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineWeatherNotice extends StatelessWidget {
  const _OfflineWeatherNotice();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          Icons.cloud_off_rounded,
          size: 16.sp,
          color: scheme.onSurfaceVariant,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            'Weather is not on this device yet. Connect once and tap refresh '
            '- the average is then saved and works offline forever.',
            style: context.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _EmptyLine extends StatelessWidget {
  final String text;

  const _EmptyLine({required this.text});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: context.textTheme.bodyMedium?.copyWith(
      color: context.colorScheme.onSurfaceVariant,
    ),
  );
}
