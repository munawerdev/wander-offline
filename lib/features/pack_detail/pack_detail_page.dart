import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '/config/theme/app_colors.dart';
import '/core/constants/status_switcher.dart';
import '/core/utils/color_utils.dart';
import '/core/utils/extensions.dart';
import '/core/widgets/app_bar.dart';
import '/core/widgets/status_pill.dart';
import '/data/models/pack/country_pack_model.dart';
import 'pack_detail_cubit.dart';
import 'pack_detail_state.dart';
import 'widgets/currency_tab.dart';
import 'widgets/overview_tab.dart';
import 'widgets/places_tab.dart';
import 'widgets/tips_tab.dart';
import 'widgets/weather_tab.dart';

/// A single installed pack, opened entirely from local storage.
class PackDetailPage extends StatefulWidget {
  final PackDetailCubit cubit;

  const PackDetailPage({super.key, required this.cubit});

  @override
  State<PackDetailPage> createState() => _PackDetailState();
}

class _PackDetailState extends State<PackDetailPage> {
  PackDetailCubit get cubit => widget.cubit;

  @override
  void initState() {
    super.initState();
    cubit.load();
  }

  @override
  void didUpdateWidget(covariant PackDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // See PackBrowserPage: a route builder can supply a fresh, unloaded cubit.
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
    return BlocBuilder<PackDetailCubit, PackDetailState>(
      bloc: cubit,
      builder: (context, state) => Scaffold(
        appBar: CustomAppBar(
          title: state.data?.name ?? 'Pack',
          leading: IconButton(
            onPressed: cubit.openBack,
            icon: const Icon(Icons.arrow_back),
          ),
          quickActions: <AppBarAction>[
            AppBarAction(
              icon: const Icon(Icons.sync_rounded),
              tooltip: 'Refresh weather and rates',
              onPressed: cubit.refresh,
            ),
          ],
        ),
        body: StatusSwitcher<CountryPackModel>(
          response: state.pack,
          onRetry: cubit.load,
          customErrorTitle: 'This pack is not on this device',
          customNoDataTitle: 'Pack unavailable',
          onCompleted: (context, pack) => _content(context, state, pack),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    PackDetailState state,
    CountryPackModel pack,
  ) => DefaultTabController(
    length: 5,
    initialIndex: state.tabIndex,
    child: Column(
      children: <Widget>[
        _PackHeader(pack: pack, isRefreshing: state.isRefreshing),
        TabBar(
          isScrollable: true,
          onTap: cubit.setTab,
          tabs: const <Widget>[
            Tab(text: 'Overview'),
            Tab(text: 'Weather'),
            Tab(text: 'Currency'),
            Tab(text: 'Places'),
            Tab(text: 'Tips'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: <Widget>[
              PackOverviewTab(pack: pack),
              PackWeatherTab(state: state, onRefresh: cubit.refresh),
              PackCurrencyTab(
                state: state,
                onAmountChanged: cubit.setAmount,
                onFromChanged: cubit.setFromCurrency,
                onToChanged: cubit.setToCurrency,
                onSwap: cubit.swapCurrencies,
              ),
              PackPlacesTab(
                state: state,
                onSelectLandmark: cubit.selectLandmark,
                onToggleMapMode: cubit.toggleMapMode,
              ),
              PackTipsTab(state: state),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Header band carrying the pack's identity and a quick read on what is inside.
class _PackHeader extends StatelessWidget {
  final CountryPackModel pack;
  final bool isRefreshing;

  const _PackHeader({required this.pack, required this.isRefreshing});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final accent = colorFromHex(pack.accentColorHex);
    final isDark = context.isDarkMode;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accent.withValues(alpha: isDark ? 0.3 : 0.15),
            scheme.surface,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                PackSummaryModel.fromPack(pack).flagEmoji,
                style: TextStyle(fontSize: 29.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      pack.name,
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${pack.region} · ${pack.primaryCity}',
                      style: context.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isRefreshing)
                SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: const CircularProgressIndicator.adaptive(
                    strokeWidth: 2,
                  ),
                ),
            ],
          ),
          SizedBox(height: 7.h),
          Text(
            pack.tagline,
            style: context.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 9.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: <Widget>[
              StatusPill(
                label: pack.currencyCode,
                icon: Icons.payments_rounded,
                color: accent,
              ),
              StatusPill(
                label: '${pack.landmarks.length} PLACES',
                icon: Icons.place_outlined,
                color: scheme.onSurfaceVariant,
              ),
              StatusPill(
                label: '${pack.cities.length} CITIES',
                icon: Icons.location_city_rounded,
                color: scheme.onSurfaceVariant,
              ),
              if (!pack.weather.hasContent)
                const StatusPill(
                  label: 'NO WEATHER YET',
                  icon: Icons.cloud_off_rounded,
                  color: AppColors.warning,
                ),
              if (!pack.rates.hasRates)
                const StatusPill(
                  label: 'NO RATES YET',
                  icon: Icons.currency_exchange_rounded,
                  color: AppColors.warning,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
