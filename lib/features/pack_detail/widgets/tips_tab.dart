import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '/config/theme/app_colors.dart';
import '/core/utils/extensions.dart';
import '/core/widgets/section_card.dart';
import '/core/widgets/stat_tile.dart';
import '/features/pack_detail/pack_detail_state.dart';

/// The tips tab: the advice an API cannot give you, grouped so the traveller
/// can jump straight to the section they need.
class PackTipsTab extends StatelessWidget {
  final PackDetailState state;

  const PackTipsTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final tips = state.data?.tips;
    final currency = tips?.currency ?? const <String>[];
    final tipping = tips?.tipping ?? const <String>[];
    final scams = tips?.scams ?? const <String>[];
    final transport = tips?.transport ?? const <String>[];
    final etiquette = tips?.etiquette ?? const <String>[];
    final emergency = tips?.emergency;
    final police = emergency?.police ?? '';
    final ambulance = emergency?.ambulance ?? '';
    final notes = emergency?.notes ?? '';
    final hasEmergency =
        police.isNotEmpty || ambulance.isNotEmpty || notes.isNotEmpty;

    final hasAny =
        currency.isNotEmpty ||
        tipping.isNotEmpty ||
        scams.isNotEmpty ||
        transport.isNotEmpty ||
        etiquette.isNotEmpty ||
        hasEmergency;

    if (!hasAny) {
      return ListView(
        padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 28.h),
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 48.h),
            child: Center(
              child: Text(
                'No local tips in this pack yet',
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 28.h),
      children: <Widget>[
        if (currency.isNotEmpty)
          _TipsSection(
            title: 'Money',
            icon: Icons.payments_outlined,
            items: currency,
          ),
        if (tipping.isNotEmpty)
          _TipsSection(
            title: 'Tipping',
            icon: Icons.volunteer_activism_outlined,
            items: tipping,
          ),
        if (scams.isNotEmpty)
          _TipsSection(
            title: 'Scams to avoid',
            icon: Icons.report_gmailerrorred_rounded,
            items: scams,
            dotColor: AppColors.warning,
          ),
        if (transport.isNotEmpty)
          _TipsSection(
            title: 'Getting around',
            icon: Icons.directions_transit_rounded,
            items: transport,
          ),
        if (etiquette.isNotEmpty)
          _TipsSection(
            title: 'Etiquette',
            icon: Icons.handshake_outlined,
            items: etiquette,
          ),
        if (hasEmergency)
          SectionCard(
            title: 'Emergency',
            icon: Icons.emergency_rounded,
            children: <Widget>[
              if (police.isNotEmpty)
                StatTile(
                  icon: Icons.local_police_outlined,
                  label: 'Police',
                  value: police,
                  valueColor: AppColors.warning,
                ),
              if (ambulance.isNotEmpty)
                StatTile(
                  icon: Icons.local_hospital_outlined,
                  label: 'Ambulance',
                  value: ambulance,
                  valueColor: AppColors.warning,
                ),
              if (notes.isNotEmpty) ...<Widget>[
                SizedBox(height: 4.h),
                Text(
                  notes,
                  style: context.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

/// One non-empty tips list, rendered as a bulleted card.
class _TipsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> items;
  final Color? dotColor;

  const _TipsSection({
    required this.title,
    required this.icon,
    required this.items,
    this.dotColor,
  });

  @override
  Widget build(BuildContext context) => SectionCard(
    title: title,
    icon: icon,
    children: items
        .map<Widget>((String text) => BulletLine(text: text, dotColor: dotColor))
        .toList(),
  );
}
