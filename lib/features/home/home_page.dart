import 'package:material_ui/material_ui.dart';
import 'package:wander_offline/core/widgets/app_bar.dart';

import 'home_cubit.dart';

class HomePage extends StatefulWidget {
  final HomeCubit cubit;

  const HomePage({super.key, required this.cubit});

  @override
  State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {
  HomeCubit get cubit => widget.cubit;

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'title',
        leading: IconButton(
          onPressed: () => cubit.navigator.openBack(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Text(cubit.initialParams.name),
    );
  }
}
