import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';

class BookData {
  BookData() {}
  String title = '';
  String author = '';
  List<IndexData> indexList = [];
  String bookId = '1';
  int charCount = 0;
  String downloadUri = '';

  BookInfoData info = BookInfoData();

  Map<String, dynamic> toJson() => {
        'title': title,
        'author': author,
        'bookId': bookId,
        'charCount': charCount,
        'downloadUri': downloadUri,
        'indexList': getIndexListJson(),
      };

  List<Map<String, dynamic>> getIndexListJson() {
    List<Map<String, dynamic>> dlist = [];
    for (IndexData d in indexList) {
      dlist.add(d.toJson());
    }
    return dlist;
  }

  BookData.fromJson(Map<String, dynamic> j) {
    if (j.containsKey('title')) title = j['title'] ?? '';
    if (j.containsKey('author')) author = j['author'] ?? '';
    if (j.containsKey('bookId')) bookId = j['bookId'] ?? '';
    if (j.containsKey('charCount')) charCount = j['charCount'] ?? '';
    if (j.containsKey('downloadUri')) downloadUri = j['downloadUri'] ?? '';

    if (!Platform.isIOS && !Platform.isMacOS) {
      title = bookId;
    }

    var list = j['indexList'];
    for (var d in list) {
      IndexData c = IndexData();
      if (d.containsKey('index')) c.index = d['index'] ?? -1;
      if (d.containsKey('title')) c.title = d['title'] ?? '';
      if (d.containsKey('chars')) c.chars = d['chars'] ?? 1;
      indexList.add(c);
    }
  }
}

class IndexData {
  int index = 0;
  String title = '';
  int chars = 0;

  Map<String, dynamic> toJson() => {
        'index': index,
        'title': title,
        'chars': chars,
      };
}

class BookInfoData {
  BookInfoData();

  int flag = 0;
  int nowIndex = 0;
  int nowRatio = 0;
  int maxIndex = 0;
  int maxRatio = 0;
  List<int> listMark = [];
  DateTime lastAccess = DateTime(2000, 1, 1);

  Map<String, dynamic> toJson() => {
        'nowIndex': nowIndex,
        'nowRatio': nowRatio,
        'maxIndex': maxIndex,
        'maxRatio': maxRatio,
        'flag': flag,
        'lastAccess': DateFormat('yyyy-MM-dd HH:mm:ss').format(lastAccess),
      };

  BookInfoData.fromJson(Map<String, dynamic> j) {
    if (j.containsKey('nowIndex')) nowIndex = j['nowIndex'] ?? 0;
    if (j.containsKey('nowRatio')) nowRatio = j['nowRatio'] ?? 0;
    if (j.containsKey('maxIndex')) maxIndex = j['maxIndex'] ?? 0;
    if (j.containsKey('maxRatio')) maxRatio = j['maxRatio'] ?? 0;
    if (j.containsKey('flag')) flag = j['flag'] ?? 0;
    if (j.containsKey('lastAccess')) {
      String dt = j['lastAccess'];
      try {
        lastAccess = DateTime.parse(dt);
      } catch (_) {}
    }
  }
}

class BookClipData {
  BookClipData();
  List<ClipData> list = [];

  sort() {
    list.sort((a, b) {
      bool d = (a.index * 1000000) + a.ratio > (b.index * 1000000) + b.ratio;
      return d ? 1 : -1;
    });
  }

  String toJsonString() {
    Map<String, dynamic> j = {'list': getClipListJson()};
    return json.encode(j);
  }

  List<Map<String, dynamic>> getClipListJson() {
    List<Map<String, dynamic>> dlist = [];
    for (ClipData d in list) {
      dlist.add(d.toJson());
    }
    return dlist;
  }

  BookClipData.fromJson(dynamic jsonList) {
    if (jsonList.containsKey('list')) {
      var list1 = jsonList['list'];
      for (Map<String, dynamic> j in list1) {
        ClipData c = ClipData();
        if (j.containsKey('index')) c.index = j['index'] ?? -1;
        if (j.containsKey('ratio')) c.ratio = j['ratio'] ?? '';
        if (j.containsKey('text')) c.text = j['text'] ?? 1;
        list.add(c);
      }
    }
  }
}

class ClipData {
  ClipData() {}
  int index = 0;
  int ratio = 0;
  String text = '';

  Map<String, dynamic> toJson() => {
        'index': index,
        'ratio': ratio,
        'text': text,
      };
}

class SettingsData {
  int appId = 0;
  List<int> listMark = [];
  DateTime lastDate = DateTime(2000, 1, 1);
}
