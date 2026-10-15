import 'package:wander_offline/features/home/home_navigator.dart';

import '/config/navigation/app_navigator.dart';
import '/config/navigation/app_routes.dart';
import 'login_initial_params.dart';

class LoginNavigator with HomeRoute {
  LoginNavigator(this.navigator);

  @override
  final AppNavigator navigator;
}

mixin LoginRoute {
  void openLogin(LoginInitialParams initialParams) =>
      navigator.go(AppRoutes.login, extra: initialParams);

  void openBack() => navigator.pop();

  AppNavigator get navigator;
}
