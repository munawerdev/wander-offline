import 'package:material_ui/material_ui.dart';
import 'home_cubit.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_state.dart';
import '/core/constants/status_switcher.dart';

class HomePage extends StatefulWidget {
final HomeCubit cubit;

const HomePage({
super.key,
required this.cubit
});

@override
State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {

HomeCubit get cubit => widget.cubit;

  @override
  void initState() {
    super.initState();
    cubit.navigator.context = context;
  }
  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
return Scaffold(
  
      body: RefreshIndicator.adaptive(
        onRefresh: cubit.home,
        child: BlocBuilder(
          bloc: cubit,
          builder: (context, state) {
            state as HomeState;
            return state.response.toWidget(
                onCompleted: (context, data) => const SizedBox()
                
                ,onRetry: () => cubit.home(showLoading: true)
                
                );
          }
        )
      )
    
    
    );
  }
}