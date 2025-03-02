// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:ichinichiissatsu/controllers/epub_controller.dart';

// flutter test test/widget_test.dart

ProviderContainer createContainer({
  ProviderContainer? parent,
  List<Override> overrides = const [],
  List<ProviderObserver>? observers,
}) {
  final container = ProviderContainer(
    parent: parent,
    overrides: overrides,
    observers: observers,
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  testWidgets('test', (WidgetTester tester) async {
    // mock provider
    final ref = createContainer(
      overrides: [ChangeNotifierProvider((ref) => EpubNotifier(ref))],
    );

    String test = ref.read(epubProvider).deleteClassAttr('<h3 class="BBB">AAA</h3>', '<h3');
    print('${test}');
    expect(
      ref.read(epubProvider).doneIndex,
      equals(0),
    );
  });
}
