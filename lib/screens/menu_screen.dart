import 'dart:convert';
import 'dart:io';
import 'dart:developer';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

import '/commons/base_screen.dart';
import '/commons/widgets.dart';
import '/controllers/epub_controller.dart';
import '/models/book_data.dart';
import '/screens/booklist_screen.dart';
import '/screens/browser_screen.dart';
import '/screens/viewer_screen.dart';
import '/screens/settings_screen.dart';

final menuProvider = ChangeNotifierProvider((ref) => MenuNotifier(ref));

class MenuNotifier extends ChangeNotifier {
  MenuNotifier(ref) {}
  int selectedIndex = 0;
}

class MenuScreen extends BaseScreen {
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
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home, size: 28), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.text_snippet, size: 28), label: 'Brows'),
          BottomNavigationBarItem(icon: Icon(Icons.settings, size: 28), label: 'Option'),
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
