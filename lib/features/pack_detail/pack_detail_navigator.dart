import '/config/navigation/app_navigator.dart';
import '/config/navigation/app_routes.dart';
import 'pack_detail_initial_params.dart';

class PackDetailNavigator {
  PackDetailNavigator(this.navigator);

  final AppNavigator navigator;

  void openBack() => navigator.pop();
}

mixin PackDetailRoute {
  Future<T?> openPackDetail<T>(PackDetailInitialParams initialParams) =>
      navigator.push<T>(AppRoutes.packDetail, extra: initialParams);

  AppNavigator get navigator;
}
