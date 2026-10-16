import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '/core/utils/extensions.dart';
import '/core/utils/format_utils.dart';
import '/core/widgets/section_card.dart';
import '/core/widgets/stat_tile.dart';
import '/data/models/pack/country_pack_model.dart';

/// "Why go" plus the country-facts card: the encyclopaedia half of a pack.
class PackOverviewTab extends StatelessWidget {
  final CountryPackModel pack;

  const PackOverviewTab({super.key, required this.pack});

  @override
  Widget build(BuildContext context) {
    final facts = pack.facts;

    return ListView(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 28.h),
      children: <Widget>[
        if (pack.blurb.isNotEmpty)
          SectionCard(
            title: 'Why go',
            icon: Icons.auto_awesome_rounded,
            children: <Widget>[
              Text(
                pack.blurb,
                style: context.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
          ),
        SectionCard(
          title: '${pack.name} at a glance',
          icon: Icons.public_rounded,
          children: <Widget>[
            if (facts.capital.isNotEmpty)
              StatTile(
                icon: Icons.location_city_rounded,
                label: 'Capital',
                value: facts.capital,
              ),
            if (facts.region.isNotEmpty)
              StatTile(
                icon: Icons.map_outlined,
                label: 'Region',
                value: facts.subregion.isEmpty
                    ? facts.region
                    : '${facts.region} · ${facts.subregion}',
              ),
            if (facts.population > 0)
              StatTile(
                icon: Icons.groups_rounded,
                label: 'Population',
                value: facts.populationLabel,
              ),
            if (facts.areaKm2 > 0)
              StatTile(
                icon: Icons.straighten_rounded,
                label: 'Area',
                value: facts.areaLabel,
              ),
            if (facts.languages.isNotEmpty)
              StatTile(
                icon: Icons.translate_rounded,
                label: 'Languages',
                value: facts.languagesLabel,
              ),
            StatTile(
              icon: Icons.payments_rounded,
              label: 'Currency',
              value: facts.currency.label,
            ),
            if (facts.callingCode.isNotEmpty)
              StatTile(
                icon: Icons.call_rounded,
                label: 'Calling code',
                value: facts.callingCode,
              ),
            StatTile(
              icon: Icons.directions_car_rounded,
              label: 'Driving',
              value: facts.drivingSideLabel,
            ),
            if (facts.timezones.isNotEmpty)
              StatTile(
                icon: Icons.schedule_rounded,
                label: 'Time zone',
                value: facts.timezonesLabel,
              ),
            if (facts.powerPlug.isNotEmpty)
              StatTile(
                icon: Icons.power_rounded,
                label: 'Power',
                value: facts.powerPlug,
              ),
            if (facts.tapWater.isNotEmpty)
              StatTile(
                icon: Icons.water_drop_outlined,
                label: 'Tap water',
                value: facts.tapWater,
              ),
          ],
        ),
        SectionCard(
          title: 'Before you go',
          icon: Icons.event_available_rounded,
          children: <Widget>[
            if (facts.visaNote.isNotEmpty)
              _Paragraph(label: 'Entry', body: facts.visaNote),
            if (facts.bestMonths.isNotEmpty)
              _Paragraph(label: 'Best months', body: facts.bestMonths),
            if (facts.dailyBudget.isNotEmpty)
              _Paragraph(label: 'Daily budget', body: facts.dailyBudget),
            if (facts.cashVsCard.isNotEmpty)
              _Paragraph(label: 'Cash or card', body: facts.cashVsCard),
          ],
        ),
        SectionCard(
          title: 'Inside this pack',
          icon: Icons.inventory_2_outlined,
          children: <Widget>[
            StatTile(
              icon: Icons.place_outlined,
              label: 'Hand-picked places',
              value: '${pack.landmarks.length}',
            ),
            StatTile(
              icon: Icons.holiday_village_outlined,
              label: 'Cities covered',
              value: '${pack.cities.length}',
            ),
            StatTile(
              icon: Icons.lightbulb_outline_rounded,
              label: 'Local tips',
              value: '${pack.tips.totalTips}',
            ),
            StatTile(
              icon: Icons.download_done_rounded,
              label: 'Saved on device',
              value: formatRelative(pack.installedAt),
            ),
            if (pack.refreshedAt != null)
              StatTile(
                icon: Icons.sync_rounded,
                label: 'Last refreshed',
                value: formatRelative(pack.refreshedAt!),
              ),
          ],
        ),
      ],
    );
  }
}

class _Paragraph extends StatelessWidget {
  final String label;
  final String body;

  const _Paragraph({required this.label, required this.body});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: 11.h),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: context.textTheme.bodySmall?.copyWith(
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: context.colorScheme.primary,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          body,
          style: context.textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
      ],
    ),
  );
}
