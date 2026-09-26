

  


import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_initial_params.dart';
import 'home_navigator.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeNavigator navigator;
  final HomeInitialParams initialParams;
HomeCubit(
  this.initialParams,
      this.navigator)
   : super(HomeState.initial(initialParams:initialParams));

}
