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
      'ui_text_scale': 'UI text scale',
      'back_color': 'Back color',
      'writing_mode': 'Writing mode',
      'line_height': 'Line height',
      'light': 'Light',
      'dark': 'Dark',
      'dark_mode': 'Dark mode',
      'vertical-rl': 'Vertical',
      'horizontal-tb': 'Horizontal',
      'save': 'Save',
      'delete': 'Delete',
      'cancel': 'Cancel',
      'save_selection': 'Save selection',
      'select_the_text': 'Please select the text',
      'move_maxpage': 'move maxpage',
      'reset_maxpage': 'reset maxpage',
      'nowpage': 'Now page',
      'maxpage': 'Max page',
      'flag_changes': 'Flag changes',
      'ok': 'OK',
      'download': 'Download',
      'per_hour': 'Per hour',
      'page': 'Pages',
      'aozora_top': 'Aozora top',
      'aozora_ranking': 'Aozora ranking',
      'episode': 'Episode',
      'check_addition': 'Check the addition.',
      'download_complete': 'Complete',
      'already_downloaded': 'Already downloaded',
      'download_failed': 'Download failed',
      'close': 'Close',
    },
    'ja': {
      'app_name': '一日一冊',
      'language_code': '言語',
      'settings_title': '設定',
      'font_size': '文字サイズ',
      'font_family': 'フォント',
      'sans_serif': 'ゴシック',
      'serif': '明朝',
      'back_color': '背景色',
      'writing_mode': '方向',
      'line_height': '行間',
      'light': 'ライト',
      'dark': 'ダーク',
      'ui_text_scale': '文字サイズ',
      'dark_mode': '外観 カラー',
      'vertical-rl': '縦書き',
      'horizontal-tb': '横書き',
      'save': '保存',
      'delete': '削除',
      'cancel': 'キャンセル',
      'save_selection': '選択を保存',
      'select_the_text': '文字を選択状態にしてください',
      'move_maxpage': '最後のページへジャンプ',
      'reset_maxpage': '最後のページをリセット',
      'nowpage': '現在のページ',
      'maxpage': '最後のページ',
      'flag_changes': 'フラグの変更',
      'ok': 'OK',
      'download': 'ダウンロード',
      'per_hour': '時速',
      'page': 'ページ',
      'aozora_top': '青空文庫トップ',
      'aozora_ranking': '青空文庫ランキング',
      'episode': '話',
      'check_addition': '更新をチェックします',
      'download_complete': '完了',
      'already_downloaded': '最新の状態',
      'download_failed': 'ダウンロード失敗',
      'close': '閉じる',
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
