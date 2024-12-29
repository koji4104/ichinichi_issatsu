import 'package:flutter/material.dart';
import 'dart:developer';

String myLanguageCode = '';
String defaultLanguageCode = 'en';

class SampleLocalizationsDelegate extends LocalizationsDelegate<Localized> {
  const SampleLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ja'].contains(locale.languageCode);

  @override
  Future<Localized> load(Locale locale) async {
    defaultLanguageCode = locale.languageCode;
    return Localized();
  }

  @override
  bool shouldReload(SampleLocalizationsDelegate old) => false;
}

class Localized {
  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'One book',
      'language_code': 'Language',
      'settings_title': 'Settings',
      'font_size': 'Font size',
      'font_family': 'Font family',
      'sans_serif': 'Sans serif',
      'serif': 'Serif',
      'ui_font_size': 'UI font size',
      'back_color': 'Back color',
      'writing_mode': 'Writing mode',
      'light': 'Light',
      'dark': 'Dark',
      'dark_mode': 'Dark mode',
      'vertical-rl': 'Vertical',
      'horizontal-tb': 'Horizontal',
      'save': 'Save',
      'delete': 'Delete',
      'cancel': 'Cancel',
    },
    'ja': {
      'app_name': '一日一冊',
      'language_code': '言語',
      'settings_title': '設定',
      'font_size': '文字サイズ',
      'font_family': 'フォント',
      'sans_serif': 'ゴシック',
      'serif': '明朝',
      'ui_font_size': 'UI 文字サイズ',
      'back_color': '背景色',
      'writing_mode': '方向',
      'light': 'ライト',
      'dark': 'ダーク',
      'dark_mode': '外観',
      'vertical-rl': '縦書き',
      'horizontal-tb': '横書き',
      'save': '保存',
      'delete': '削除',
      'cancel': 'キャンセル',
    },
  };

  static String text(String text) {
    String? s;
    try {
      if (myLanguageCode == 'ja')
        s = _localizedValues["ja"]?[text];
      else if (myLanguageCode == 'en')
        s = _localizedValues["en"]?[text];
      else if (myLanguageCode == '' && defaultLanguageCode == "ja")
        s = _localizedValues["ja"]?[text];
      else
        s = _localizedValues["en"]?[text];
    } on Exception catch (e) {
      log('Localized.text() ${e.toString()}');
    }
    if (s == null && text.contains('_desc') == false)
      s = text;
    else if (s == null && text.contains('_desc') == true) s = '';
    return s != null ? s : text;
  }
}
