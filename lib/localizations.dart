import 'package:flutter/material.dart';
import 'dart:developer';

String myLanguageCode = '';
String defaultLanguageCode = 'ja';

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
      'redownload': 'Redownload',
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
      'swipe_to_delete': 'Swipe to delete',
      'copy_to_clipboard': 'Copy to clipboard',
      'home': 'Home',
      'brows': 'Find',
      'option': 'Option',
      'up_to': 'up to',
      'can_add_favorite': 'You can add it to your favorites.',
      'no_data': 'No Data',
      'speak_speed': 'Speed',
      'speak_voice': 'Voice',
      'speak_volume': 'Volume',
      'speaking_is_only_horizontal_text': 'Speaking is only horizontal text',
      // ICON
      'toc': 'TOC',
      'jump': 'Jump',
      'copy': 'Copy',
      'clip': 'Clip',
      'label': 'Label',
      'tag': 'Tag',
      'favorite': 'Favorite',
      'white': 'White',
      'gray': 'Gray',
      'black': 'Black',
      'ja': 'Japanese',
      'en': 'English',
      'bookmark': 'Bookmark',
    },
    'ja': {
      'app_name': '一日一冊',
      'language_code': 'アプリ 言語',
      'font_size': '文字サイズ',
      'font_family': 'フォント',
      'sans_serif': 'ゴシック',
      'serif': '明朝',
      'back_color': '背景色',
      'writing_mode': '方向',
      'line_height': '行間',
      'light': 'ライト',
      'dark': 'ダーク',
      'ui_text_scale': 'アプリ 文字サイズ',
      'dark_mode': 'アプリ カラー',
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
      'flag_changes': 'タグの変更',
      'ok': 'OK',
      'download': 'ダウンロード',
      'redownload': '再ダウンロード',
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
      'swipe_to_delete': 'スワイプで削除できます',
      'copy_to_clipboard': 'クリップボードにコピー',
      'home': 'ホーム',
      'brows': '探す',
      'option': '設定',
      'up_to': 'まで',
      'can_add_favorite': 'お気に入りに追加することができます',
      'no_data': '選択保存データ',
      'speak_speed': '速さ',
      'speak_voice': '声',
      'speak_volume': '音量',
      'speaking_is_only_horizontal_text': '読み上げ機能は横書きのみです',
      // ICON
      'toc': '目次',
      'jump': '最後',
      'copy': '選択',
      'clip': 'リスト',
      'label': 'ラベル',
      'tag': 'タグ',
      'favorite': 'お気に入り',
      'white': '白',
      'gray': 'グレー',
      'black': '黒',
      'ja': '日本語',
      'en': '英語',
      'bookmark': 'ブックマーク',
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
    return s != null ? s : text;
  }
}
