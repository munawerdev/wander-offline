import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '/config/theme/app_colors.dart';
import '/core/constants/status_switcher.dart';
import '/core/utils/extensions.dart';
import '/core/utils/format_utils.dart';
import '/core/widgets/app_bar.dart';
import 'pack_browser_cubit.dart';
import 'pack_browser_state.dart';
import 'widgets/pack_card.dart';

/// The pack browser: every pack the app knows about, merged with what this
/// device actually has installed and unlocked.
class PackBrowserPage extends StatefulWidget {
  final PackBrowserCubit cubit;

  const PackBrowserPage({super.key, required this.cubit});

  @override
  State<PackBrowserPage> createState() => _PackBrowserState();
}

class _PackBrowserState extends State<PackBrowserPage> {
  PackBrowserCubit get cubit => widget.cubit;

  @override
  void initState() {
    super.initState();
    cubit.load();
  }

  @override
  void didUpdateWidget(covariant PackBrowserPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Cubits are resolved from getIt inside the GoRouter route builder, and a
    // builder is a *build* function: when it re-runs, this page is handed a
    // brand new, unloaded cubit while this State - and therefore its initState -
    // survives. Close the old one so its connectivity subscription cannot leak,
    // and load the new one so the screen is never stuck on the initial state.
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
        title: 'Explore packs',
        showLeading: false,
        quickActions: <AppBarAction>[
          AppBarAction(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload the catalogue',
            onPressed: () => cubit.load(showLoading: false),
          ),
        ],
      ),
      body: BlocBuilder<PackBrowserCubit, PackBrowserState>(
        bloc: cubit,
        builder: (context, state) => Column(
          children: <Widget>[
            if (!state.isOnline) const _OfflineBanner(),
            _SummaryStrip(state: state),
            _FilterBar(state: state, onSelected: cubit.setFilter),
            Expanded(
              child: StatusSwitcher<List<PackCardState>>(
                response: state.catalogue,
                onRetry: cubit.load,
                customNoDataTitle: 'No packs here yet',
                onCompleted: (context, catalogue) =>
                    _packList(context, state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _packList(BuildContext context, PackBrowserState state) {
    final cards = state.visibleCards;

    if (cards.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.filter_alt_off_rounded,
                size: 40.sp,
                color: context.colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: 10.h),
              Text(
                'Nothing downloaded yet',
                textAlign: TextAlign.center,
                style: context.textTheme.titleSmall,
              ),
              SizedBox(height: 4.h),
              Text(
                'Download a pack on wifi and it will show up here, ready for '
                'airplane mode.',
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => cubit.load(showLoading: false),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 28.h),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return PackCard(
            card: card,
            isDownloading: state.isDownloadingCode(card.countryCode),
            downloadFraction: state.downloadFraction,
            downloadMessage: state.downloadProgress?.message,
            onOpen: () => cubit.openDetails(card.countryCode),
            onDownload: () => cubit.download(card.countryCode),
            onDelete: () => cubit.deletePack(card.countryCode),
            onRefresh: () => cubit.refreshPack(card.countryCode),
          );
        },
      ),
    );
  }
}

/// Shown when the device reports no connection. Packs that are already
/// installed stay fully usable, which is the point of the app.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: AppColors.warning.withValues(alpha: 0.16),
    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
    child: Row(
      children: <Widget>[
        Icon(Icons.cloud_off_rounded, size: 15.sp, color: AppColors.warning),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            'No connection - your downloaded packs still work',
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SummaryStrip extends StatelessWidget {
  final PackBrowserState state;

  const _SummaryStrip({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 4.h),
      child: Row(
        children: <Widget>[
          _metric(context, '${state.cards.length}', 'in catalogue', scheme.primary),
          _divider(context),
          _metric(
            context,
            '${state.installedCount}',
            'ready offline',
            AppColors.success,
          ),
          _divider(context),
          _metric(
            context,
            formatBytes(state.installedBytes),
            'on device',
            scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) => Container(
    width: 1.w,
    height: 26.h,
    margin: EdgeInsets.symmetric(horizontal: 12.w),
    color: context.colorScheme.outlineVariant.withValues(alpha: 0.6),
  );

  Widget _metric(
    BuildContext context,
    String value,
    String label,
    Color color,
  ) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          value,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
            fontSize: 10.5.sp,
          ),
        ),
      ],
    ),
  );
}

class _FilterBar extends StatelessWidget {
  final PackBrowserState state;
  final ValueChanged<PackFilter> onSelected;

  const _FilterBar({required this.state, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final entries = <(PackFilter, String, int)>[
      (PackFilter.all, 'All', state.cards.length),
      (PackFilter.offline, 'Offline', state.installedCount),
    ];

    return SizedBox(
      height: 42.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        children: <Widget>[
          for (final (filter, label, count) in entries)
            Padding(
              padding: EdgeInsets.only(right: 7.w),
              child: ChoiceChip(
                selected: state.filter == filter,
                onSelected: (bool selected) => onSelected(filter),
                label: Text('$label ($count)'),
                labelStyle: context.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: state.filter == filter
                      ? context.colorScheme.onSecondaryContainer
                      : context.colorScheme.onSurfaceVariant,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}
