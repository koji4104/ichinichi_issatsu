import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '/screens/menu_screen.dart';
import 'commons/widgets.dart';
import '/controllers/env_controller.dart';
import 'dart:developer';

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(envProvider);
    myTheme = ref.watch(envProvider).env.dark_mode.val == 0 ? myLightTheme : myDarkTheme;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'onebook',
      theme: myTheme,
      home: MenuScreen(),
    );
  }
}
