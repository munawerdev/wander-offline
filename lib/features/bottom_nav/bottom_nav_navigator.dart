import '/config/navigation/app_navigator.dart';
import '/config/navigation/app_routes.dart';
import 'bottom_nav_initial_params.dart';

/// The shell is reached by `go` rather than `push`, so it becomes the root of the
/// stack and the splash screen cannot be returned to.
class BottomNavNavigator {
  BottomNavNavigator(this.navigator);

  final AppNavigator navigator;
}

mixin BottomNavRoute {
  void openBottomNav(BottomNavInitialParams initialParams) =>
      navigator.go(AppRoutes.home, extra: initialParams);

  AppNavigator get navigator;
}
