import 'package:go_router/go_router.dart';

import '/core/constants/global.dart';
import '/core/show/checker_navigator_observer.dart';
import '/features/bottom_nav/bottom_nav_initial_params.dart';
import '/features/bottom_nav/bottom_nav_page.dart';
import '/features/pack_browser/pack_browser_initial_params.dart';
import '/features/pack_detail/pack_detail_initial_params.dart';
import '/features/pack_detail/pack_detail_page.dart';
import '/features/settings/settings_initial_params.dart';
import '/features/splash/splash_initial_params.dart';
import '/features/splash/splash_page.dart';
import '/injection_container.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: GlobalConstants.navigatorKey,
    initialLocation: AppRoutes.splash,
    observers: [CheckerNavigatorObserver()],
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => SplashPage(
          cubit: getIt(
            param1:
                state.extra as SplashInitialParams? ??
                const SplashInitialParams(),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) {
          final params =
              state.extra as BottomNavInitialParams? ??
              const BottomNavInitialParams();
          // The shell owns both tabs, so their cubits are resolved here rather
          // than created inside the pages.
          return BottomNavPage(
            cubit: getIt(param1: params),
            packBrowserCubit: getIt(param1: const PackBrowserInitialParams()),
            settingsCubit: getIt(param1: const SettingsInitialParams()),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.packDetail,
        builder: (context, state) => PackDetailPage(
          cubit: getIt(param1: state.extra as PackDetailInitialParams),
        ),
      ),
    ],
  );
}
