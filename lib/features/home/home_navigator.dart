import 'package:wander_offline/features/auth/login/login_navigator.dart';

import '/config/navigation/app_navigator.dart';
import '/config/navigation/app_routes.dart';
import 'home_initial_params.dart';

class HomeNavigator with LoginRoute {
  HomeNavigator(this.navigator);
  @override
  AppNavigator navigator;
}

mixin HomeRoute {
  void openHome(HomeInitialParams initialParams) =>
      navigator.go(AppRoutes.home, extra: initialParams);

  AppNavigator get navigator;
}
