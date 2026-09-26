import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

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
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: .center,
            children: [
              const CircularProgressIndicator(),
              ElevatedButton(
                onPressed: () {
                  showCupertinoDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return CupertinoAlertDialog(
                        // ✅ iOS-style dialog
                        title: const Text('Alert Dialog'),
                        content: const Text('This is a basic alert dialog.'),
                        actions: [
                          CupertinoDialogAction(
                            // ✅ iOS-style button
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          CupertinoDialogAction(
                            onPressed: () {
                              // Do something
                              Navigator.pop(context);
                            },
                            isDefaultAction:
                                true, // Makes button bold (like OK)
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Text('Show Basic Dialog'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
