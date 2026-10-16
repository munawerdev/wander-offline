import 'package:flutter_bloc/flutter_bloc.dart';

import '/domain/usecases/theme/get_theme_use_case.dart';
import '/features/bottom_nav/bottom_nav_initial_params.dart';
import 'splash_initial_params.dart';
import 'splash_navigator.dart';
import 'splash_state.dart';

/// Restores the saved theme, then hands over to the pack browser.
///
/// Local storage itself is prepared during dependency-injection start-up, before
/// the first frame, so by the time this runs the pack boxes are already open and
/// the browser can render saved content immediately - even with no connection.
class SplashCubit extends Cubit<SplashState> {
  final SplashInitialParams initialParams;
  final SplashNavigator navigator;
  final GetThemeUseCase getThemeUseCase;

  SplashCubit(this.initialParams, this.navigator, this.getThemeUseCase)
    : super(SplashState.initial(initialParams: initialParams));

  Future<void> start() async {
    emit(state.copyWith(isloading: true));

    await getThemeUseCase.execute();

    if (isClosed) return;
    emit(state.copyWith(isloading: false));

    navigator.openBottomNav(const BottomNavInitialParams());
  }
}
