import '/config/navigation/app_navigator.dart';
import '/config/navigation/app_routes.dart';
import '/features/bottom_nav/bottom_nav_navigator.dart';
import 'splash_initial_params.dart';

class SplashNavigator with BottomNavRoute {
  SplashNavigator(this.navigator);

  @override
  final AppNavigator navigator;
}

mixin SplashRoute {
  void openSplash(SplashInitialParams initialParams) =>
      navigator.go(AppRoutes.splash, extra: initialParams);

  AppNavigator get navigator;
}
