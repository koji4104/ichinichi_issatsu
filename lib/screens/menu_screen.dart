import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '/commons/base_screen.dart';
import '/commons/widgets.dart';
import '/screens/booklist_screen.dart';
import '/screens/browser_screen.dart';
import '/screens/settings_screen.dart';
import '/constants.dart';

final menuProvider = ChangeNotifierProvider((ref) => MenuNotifier(ref));

class MenuNotifier extends ChangeNotifier {
  MenuNotifier(ref) {}
  int selectedIndex = 0;
}

class MenuScreen extends BaseScreen {
  @override
  Future init() async {}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    super.build(context, ref);
    int index = ref.watch(menuProvider).selectedIndex;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              child: getScreen(index),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: myTheme.scaffoldBackgroundColor,
        selectedItemColor: myTheme.textTheme.bodyMedium!.color,
        unselectedItemColor: myTheme.disabledColor,
        currentIndex: index,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home, size: ICON_BUTTON_SIZE), label: l10n('home')),
          BottomNavigationBarItem(icon: Icon(Icons.search, size: ICON_BUTTON_SIZE), label: l10n('brows')),
          BottomNavigationBarItem(icon: Icon(Icons.settings, size: ICON_BUTTON_SIZE), label: l10n('option')),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  void _onItemTapped(int index) {
    ref.read(menuProvider).selectedIndex = index;
    redraw();
  }

  Widget getScreen(int index) {
    switch (index) {
      case 0:
        return BookListScreen();
      case 1:
        return BrowserScreen();
      case 2:
        return SettingsScreen();
      default:
        return BookListScreen();
    }
  }
}
