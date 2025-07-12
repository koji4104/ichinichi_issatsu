import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '/screens/menu_screen.dart';
import '/commons/widgets.dart';
import '/controllers/env_controller.dart';

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    myEnv = ref.watch(envProvider).env;
    myTheme = myEnv.isDarkMode() ? myDarkTheme : myLightTheme;
    myTextScale = (myEnv.ui_text_scale.val / 100).toDouble();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'onebook',
      theme: myTheme,
      home: MenuScreen(),
    );
  }
}
