import 'package:wander_offline/features/home/home_navigator.dart';

import '/config/navigation/app_navigator.dart';
import '/config/navigation/app_routes.dart';
import '/features/auth/login/login_navigator.dart';
import 'splash_initial_params.dart';

class SplashNavigator with LoginRoute, HomeRoute {
  SplashNavigator(this.navigator);

  @override
  final AppNavigator navigator;
}

mixin SplashRoute {
  void openSplash(SplashInitialParams initialParams) =>
      navigator.go(AppRoutes.splash, extra: initialParams);

  AppNavigator get navigator;
}
