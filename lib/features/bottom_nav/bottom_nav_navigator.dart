import 'package:wander_offline/config/navigation/app_routes.dart';

import '/config/navigation/app_navigator.dart';
import 'bottom_nav_initial_params.dart';

class BottomNavNavigator {
  BottomNavNavigator(this.navigator);

  @override
  final AppNavigator navigator;
}

mixin BottomNavRoute {
  void openBottomNav(BottomNavInitialParams initialParams) =>
      navigator.push(AppRoutes.bottomNav, extra: initialParams);

  AppNavigator get navigator;
}
