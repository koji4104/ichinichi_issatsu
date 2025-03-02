import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

import 'package:ichinichiissatsu/controllers/epub_controller.dart';
import 'package:ichinichiissatsu/models/epub_data.dart';

// flutter test
// flutter test test/unit_test.dart
// flutter test test/unit_test.dart --plain-apk

/*
flutter test --coverage

coverage
- lcov.info

macOS: brew install lcov

VS code 'flutter coverage'
左側のツリーに表示

*/

void main() {
  test('Unit test', () async {
    EpubData epub = EpubData();
    String s = '<ruby><rb>獅子</rb><rp>（</rp><rt>しし</rt><rp>）</rp></ruby>';
    s = EpubData.deleteRuby(s);
    print(s);

    expect(
      0,
      equals(0),
    );
  });
}
