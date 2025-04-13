import 'dart:convert' as convert;

class EpubFileData {
  EpubFileData({this.fileName, this.text}) {}
  String? title;
  String? text;
  String? fileName;
  int chapNo = -1;
  int chars = 0;

  String get chapNo0000 {
    return chapNo.toString().padLeft(4, '0');
  }
}

class EpubData {
  EpubData() {}
  String? bookId;
  String? bookTitle;
  String? bookAuthor;
  String? siteId;

  List<EpubFileData> fileList = [];
  List<String> uriList = [];
  String? dluri;

  reset() {
    bookId = null;
    bookTitle = null;
    bookAuthor = null;
    siteId = null;
    dluri = null;
    fileList.clear();
    uriList.clear();
  }

  String head1 = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="ja-JP">
<head>
  <meta charset="utf-8" />
  <style>
  </style>
  <link rel="stylesheet" type="text/css" href="../styles/stylesheet1.css" />
</head>
<body>
""";

  String head2 = '</body></html>';

  static String deleteInvalidStrInJson(String str) {
    str = str.replaceAll('"', '');
    str = str.replaceAll('\\', '');
    str = str.replaceAll('/', '');
    str = str.replaceAll('\b', '');
    str = str.replaceAll('\f', '');
    str = str.replaceAll('\n', '');
    str = str.replaceAll('\r', '');
    str = str.replaceAll('\t', '');
    str = deleteRuby(str);
    return str;
  }

  static String deleteRuby(String str) {
    // <ruby><rb>獅子</rb><rp>（</rp><rt>しし</rt><rp>）</rp></ruby>
    // <ruby><rb>卍<rb><rp>（<rp><rt>まんじ<rt><rp>）<rp><ruby>
    // <ruby><rb>嵐の雷竜</rb><rp>（</rp><rt>ストーム・サンダードラゴン</rt><rp>）</rp></ruby>
    // <ruby><rb>第</rb><rp>（</rp><rt>だい</rt><rp>）</rp></ruby>
    str = deleteTagAndInner(str, '<rp>（', '）</rp>');
    str = deleteTagAndInner(str, '<rp>（', '）<rp>');

    str = str.replaceAll('<ruby>', '');
    str = str.replaceAll('</ruby>', '');
    str = str.replaceAll('<rb>', '');
    str = str.replaceAll('</rb>', '');
    str = str.replaceAll('<rp>', '');
    str = str.replaceAll('</rp>', '');
    str = str.replaceAll('<rt>', '');
    str = str.replaceAll('</rt>', '');
    return str;
  }

  // tag1 <rp>（
  // tag2 ）</rp>
  // <ruby><rb>獅子</rb><rp>（</rp><rt>しし</rt><rp>）</rp></ruby>
  // <ruby><rb>獅子</rb></ruby>
  static String deleteTagAndInner(String text, String tag1, String tag2) {
    int s1 = 0;
    for (int i = 0; i < 20000; i++) {
      s1 = text.indexOf(tag1);
      int e1 = (s1 >= 0) ? text.indexOf(tag2, s1 + tag1.length) + 1 : 0;
      if (s1 >= 0 && e1 > 0 && e1 - s1 < 100) {
        text = text.substring(0, s1) + text.substring(e1 + tag2.length - 1);
      } else {
        break;
      }
    }
    return text;
  }

  static String extractRuby(String str) {
    // <ruby><rb>獅子</rb><rp>（</rp><rt>しし</rt><rp>）</rp></ruby>
    // <ruby><rb>卍<rb><rp>（<rp><rt>まんじ<rt><rp>）<rp><ruby>
    // <ruby><rb>嵐の雷竜</rb><rp>（</rp><rt>ストーム・サンダードラゴン</rt><rp>）</rp></ruby>
    // <ruby><rb>第</rb><rp>（</rp><rt>だい</rt><rp>）</rp></ruby>
    // <ruby><rb>獅子</rb><rp>（</rp><rt>しし</rt><rp>）</rp></ruby>
    // ↓
    // しし
    str = deleteTagAndInner(str, '<ruby>', '<rt>');
    str = deleteTagAndInner(str, '</rt>', '</ruby>');
    return str;
  }
}
