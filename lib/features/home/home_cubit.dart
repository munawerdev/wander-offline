
import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_initial_params.dart';
import 'home_navigator.dart';
import 'home_state.dart';
import '/data/models/home_model.dart';
import '/domain/repositories/network/network_base_api_service.dart';
import '/config/response/api_response.dart';
import '/core/utils/app_url.dart';

class HomeCubit extends Cubit<HomeState> {
  final NetworkBaseApiService networkRepository;
  final HomeNavigator navigator;
  final HomeInitialParams initialParams;
HomeCubit(
  this.initialParams,
      this.networkRepository,
      this.navigator)
   : super(HomeState.initial(initialParams:initialParams));

Future<void> home({bool? showLoading = false}) async {
  if (showLoading!) {
    emit(state.copyWith(response: ApiResponse.loading()));
  }
    final home = await networkRepository.get<Map<String, dynamic>>(url: AppUrl.home);
    home.fold(
      (l) => emit(state.copyWith(response: ApiResponse.error(l))),
      ((r) =>emit(state.copyWith(response: ApiResponse.completed(HomeModel.fromJson(r))))));
  }  
}


  

