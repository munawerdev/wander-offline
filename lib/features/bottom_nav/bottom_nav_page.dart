import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '/features/pack_browser/pack_browser_cubit.dart';
import '/features/pack_browser/pack_browser_page.dart';
import '/features/settings/settings_cubit.dart';
import '/features/settings/settings_page.dart';
import 'bottom_nav_cubit.dart';
import 'bottom_nav_state.dart';

/// The app shell: the pack browser and settings, held in an `IndexedStack` so
/// both tabs keep their scroll position and neither is rebuilt when switching.
///
/// The tab cubits are injected rather than created here, matching the rest of the
/// app, and each tab page closes its own cubit when it is disposed.
class BottomNavPage extends StatefulWidget {
  final BottomNavCubit cubit;
  final PackBrowserCubit packBrowserCubit;
  final SettingsCubit settingsCubit;

  const BottomNavPage({
    super.key,
    required this.cubit,
    required this.packBrowserCubit,
    required this.settingsCubit,
  });

  @override
  State<BottomNavPage> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNavPage> {
  BottomNavCubit get cubit => widget.cubit;

  @override
  void didUpdateWidget(covariant BottomNavPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only this page's own cubit is closed here; the tab cubits belong to the tab
    // pages, which reload and close their own.
    if (!identical(oldWidget.cubit, widget.cubit)) {
      oldWidget.cubit.close();
    }
  }

  @override
  void dispose() {
    cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottomNavCubit, BottomNavState>(
      bloc: cubit,
      builder: (context, state) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (state.selectedIndex > 0) {
            cubit.setSelectedIndex(0);
            return;
          }

          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => const ExitAppDialog(
              text: 'Are you sure you want to exit the app?',
              label: 'Exit App',
              onPressed: SystemNavigator.pop,
            ),
          );

          if (shouldExit == true) {
            await SystemNavigator.pop();
          }
        },
        child: Scaffold(
          body: IndexedStack(
            index: state.selectedIndex,
            children: <Widget>[
              PackBrowserPage(cubit: widget.packBrowserCubit),
              SettingsPage(cubit: widget.settingsCubit),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: state.selectedIndex,
            onDestinationSelected: cubit.setSelectedIndex,
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore_rounded),
                label: 'Explore',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExitAppDialog extends StatelessWidget {
  final String text;
  final String label;
  final VoidCallback onPressed;

  const ExitAppDialog({
    super.key,
    required this.text,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(text),
    actions: <Widget>[
      TextButton(onPressed: onPressed, child: Text(label)),
    ],
  );
}
