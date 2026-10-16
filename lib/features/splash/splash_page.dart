import 'package:material_ui/material_ui.dart';

import 'splash_cubit.dart';

class SplashPage extends StatefulWidget {
  final SplashCubit cubit;

  const SplashPage({super.key, required this.cubit});

  @override
  State<SplashPage> createState() => _SplashState();
}

class _SplashState extends State<SplashPage> {
  SplashCubit get cubit => widget.cubit;

  @override
  void initState() {
    super.initState();
    cubit.start();
  }

  @override
  void didUpdateWidget(covariant SplashPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Without this, a replaced cubit would leave the app stranded on the splash
    // screen, because start() - which performs the navigation - would never run
    // again.
    if (!identical(oldWidget.cubit, widget.cubit)) {
      oldWidget.cubit.close();
      widget.cubit.start();
    }
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}
