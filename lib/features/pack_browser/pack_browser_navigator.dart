import '/config/navigation/app_navigator.dart';
import '/features/pack_detail/pack_detail_navigator.dart';

/// The browser is a bottom-navigation tab rather than a pushed route, so it has
/// no `<PackBrowser>Route` mixin - but it does open pack details.
class PackBrowserNavigator with PackDetailRoute {
  PackBrowserNavigator(this.navigator);

  @override
  final AppNavigator navigator;
}
