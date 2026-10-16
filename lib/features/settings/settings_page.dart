import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '/config/support/support_config.dart';
import '/config/theme/app_colors.dart';
import '/core/utils/extensions.dart';
import '/core/utils/format_utils.dart';
import '/core/widgets/app_bar.dart';
import '/core/widgets/app_button.dart';
import '/core/widgets/section_card.dart';
import '/core/widgets/stat_tile.dart';
import 'settings_cubit.dart';
import 'settings_state.dart';

class SettingsPage extends StatefulWidget {
  final SettingsCubit cubit;

  const SettingsPage({super.key, required this.cubit});

  @override
  State<SettingsPage> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsPage> {
  SettingsCubit get cubit => widget.cubit;

  @override
  void initState() {
    super.initState();
    cubit.load();
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // See PackBrowserPage: the route builder can hand over a fresh, unloaded
    // cubit while this State survives, so reload instead of showing stale or
    // empty state.
    if (!identical(oldWidget.cubit, widget.cubit)) {
      oldWidget.cubit.close();
      widget.cubit.load();
    }
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Settings',
        showLeading: false,
        quickActions: <AppBarAction>[
          AppBarAction(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload',
            onPressed: cubit.load,
          ),
        ],
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        bloc: cubit,
        builder: (context, state) => ListView(
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 28.h),
          children: <Widget>[
            _SupportCard(cubit: cubit),
            _StorageCard(state: state, cubit: cubit),
            _AppearanceCard(state: state, cubit: cubit),
            const _DataSourcesCard(),
          ],
        ),
      ),
    );
  }
}

/// The tip jar. Everything in the app is free, so this asks for nothing and
/// gates nothing.
class _SupportCard extends StatelessWidget {
  final SettingsCubit cubit;

  const _SupportCard({required this.cubit});

  @override
  Widget build(BuildContext context) {
    // App Review Guideline 3.1.1 makes an outbound payment link a real risk on
    // iOS, so the card can be hidden there without touching anything else.
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    if (isIos && !SupportConfig.showDonationLinkOnIos) {
      return const SizedBox.shrink();
    }

    return SectionCard(
      title: SupportConfig.donationHeadline,
      icon: Icons.favorite_outline_rounded,
      children: <Widget>[
        Text(
          SupportConfig.donationBlurb,
          style: context.textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        SizedBox(height: 12.h),
        if (SupportConfig.hasPlaceholderUrl)
          const _PlaceholderNotice()
        else
          AppButton(
            text: SupportConfig.donationLabel,
            onPressed: cubit.openSupportPage,
            icon: const Icon(Icons.local_cafe_outlined),
          ),
      ],
    );
  }
}

/// Shown while the support URL is still the template value, so a placeholder can
/// never ship as a button that opens a dead page.
class _PlaceholderNotice extends StatelessWidget {
  const _PlaceholderNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(10.w),
    decoration: BoxDecoration(
      color: AppColors.warning.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(10.r),
      border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.edit_outlined, size: 15.sp, color: AppColors.warning),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            'Developer: set SupportConfig.donationUrl to your own Ko-fi, Buy Me '
            'a Coffee or GitHub Sponsors page and this becomes a real button.',
            style: context.textTheme.bodySmall?.copyWith(height: 1.4),
          ),
        ),
      ],
    ),
  );
}

class _StorageCard extends StatelessWidget {
  final SettingsState state;
  final SettingsCubit cubit;

  const _StorageCard({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Offline storage',
    icon: Icons.sd_storage_outlined,
    children: <Widget>[
      StatTile(
        icon: Icons.download_done_rounded,
        label: 'Packs on this device',
        value: '${state.installedCount}',
      ),
      StatTile(
        icon: Icons.data_usage_rounded,
        label: 'Space used',
        value: formatBytes(state.installedBytes),
      ),
      SizedBox(height: 8.h),
      AppButton.outlined(
        text: 'Remove all downloads',
        onPressed: cubit.clearInstalledPacks,
        loading: state.isBusyWith(SettingsCubit.clearPacksLabel),
        disabled: state.isBusy || state.installedCount == 0,
        icon: const Icon(Icons.delete_outline_rounded),
      ),
      SizedBox(height: 6.h),
      Text(
        'Packs are free, so removing one only costs you the download - install '
        'it again whenever you like, online or off.',
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
          height: 1.35,
        ),
      ),
    ],
  );
}

class _AppearanceCard extends StatelessWidget {
  final SettingsState state;
  final SettingsCubit cubit;

  const _AppearanceCard({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Appearance',
    icon: Icons.palette_outlined,
    padding: EdgeInsets.fromLTRB(6.w, 12.h, 10.w, 6.h),
    children: <Widget>[
      SwitchListTile(
        value: state.isDarkMode,
        onChanged: (bool value) => cubit.setDarkMode(value: value),
        title: const Text('Dark theme'),
        subtitle: const Text('Easier on the eyes on overnight buses'),
        secondary: Icon(
          state.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
        ),
        contentPadding: EdgeInsets.zero,
      ),
    ],
  );
}

class _DataSourcesCard extends StatelessWidget {
  const _DataSourcesCard();

  @override
  Widget build(BuildContext context) => SectionCard(
    title: 'Where the data comes from',
    icon: Icons.source_outlined,
    children: <Widget>[
      const StatTile(
        icon: Icons.thermostat_rounded,
        label: 'Weather',
        value: 'Open-Meteo',
      ),
      const StatTile(
        icon: Icons.currency_exchange_rounded,
        label: 'Exchange rates',
        value: 'Frankfurter (ECB)',
      ),
      const StatTile(
        icon: Icons.map_outlined,
        label: 'Map tiles',
        value: 'OpenStreetMap',
      ),
      const StatTile(
        icon: Icons.edit_note_rounded,
        label: 'Facts, places, tips',
        value: 'Written for this app',
      ),
      SizedBox(height: 6.h),
      Text(
        'Weather and exchange rates are fetched while you are online and then '
        'saved with the pack. Everything else is bundled, so a downloaded pack '
        'works with no connection at all.',
        style: context.textTheme.bodySmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
          height: 1.35,
        ),
      ),
    ],
  );
}
