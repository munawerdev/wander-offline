import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wander_offline/core/widgets/app_button.dart';
import 'package:wander_offline/features/home/home_initial_params.dart';

import 'login_cubit.dart';

class LoginPage extends StatefulWidget {
  final LoginCubit cubit;

  const LoginPage({super.key, required this.cubit});

  @override
  State<LoginPage> createState() => _LoginState();
}

class _LoginState extends State<LoginPage> {
  LoginCubit get cubit => widget.cubit;

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AppButton(
          onPressed: () =>
              // cubit.navigator.openHome(const HomeInitialParams(name: 'name')),
              context.go('/home', extra: const HomeInitialParams(name: 'name')),
          text: 'Login',
        ),
      ),
    );
  }
}
