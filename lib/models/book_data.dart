import 'dart:convert';
import 'dart:io';

class BookData {
  BookData() {}
  String title = '';
  String author = '';
  List<IndexData> indexList = [];
  String bookId = '1';
  int charCount = 0;

  BookInfoData info = BookInfoData();

  Map<String, dynamic> toJson() => {
        'title': title,
        'author': author,
        'bookId': bookId,
        'indexList': getIndexListJson(),
      };

  String getIndexListJson() {
    List<Map<String, dynamic>> dlist = [];
    for (IndexData d in indexList) {
      dlist.add(d.toJson());
    }
    return json.encode(dlist);
  }

  BookData.fromJson(Map<String, dynamic> j) {
    title = j['title'] ?? '';
    author = j['author'] ?? '';
    bookId = j['bookId'] ?? '';

    if (!Platform.isIOS && !Platform.isMacOS) {
      title = bookId;
    }

    String? txt = j['indexList'];
    if (txt != null) {
      var list = json.decode(txt);
      for (var d in list) {
        IndexData c = IndexData();
        c.index = d['index'] ?? -1;
        c.title = d['title'] ?? '';
        c.charCount = d['charCount'] ?? 1;
        indexList.add(c);
      }
    }
  }
}

class IndexData {
  int index = 0;
  String title = '';
  int charCount = 0;

  Map<String, dynamic> toJson() => {
        'index': index,
        'title': title,
        'charCount': charCount,
      };
}

class BookInfoData {
  BookInfoData();

  int lastIndex = 0;
  int lastRate = 0;
  List<int> listMark = [];
  DateTime lastDate = DateTime(2000, 1, 1);

  Map<String, dynamic> toJson() => {
        'lastIndex': lastIndex,
        'lastRate': lastRate,
      };

  BookInfoData.fromJson(Map<String, dynamic> j) {
    lastIndex = j['lastIndex'] ?? 0;
    lastRate = j['lastRate'] ?? 0;
  }
}

class SettingsData {
  int appId = 0;
  List<int> listMark = [];
  DateTime lastDate = DateTime(2000, 1, 1);
}
