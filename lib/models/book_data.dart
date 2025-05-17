import 'package:intl/intl.dart';

class CacheData {
  String bookId = '1';
  String title = '';
  String author = '';
}

class BookData {
  BookData() {}
  String bookId = '1';
  String title = '';
  String author = '';
  int chars = 0;
  String siteId = '';
  String dluri = '';
  String dlver = '1.0.0';
  DateTime ctime = DateTime(2000, 1, 1);

  IndexData index = IndexData();
  PropData prop = PropData();

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'title': title,
        'author': author,
        'chars': chars,
        'siteId': siteId,
        'dluri': dluri,
        'dlver': dlver,
        'ctime': DateFormat('yyyy-MM-dd HH:mm:ss').format(ctime),
      };

  BookData.fromJson(Map<String, dynamic> j) {
    if (j.containsKey('title')) title = j['title'] ?? '';
    if (j.containsKey('author')) author = j['author'] ?? '';
    if (j.containsKey('bookId')) bookId = j['bookId'] ?? '';
    if (j.containsKey('chars')) chars = j['chars'] ?? '';
    if (j.containsKey('siteId')) siteId = j['siteId'] ?? '';
    if (j.containsKey('dluri')) dluri = j['dluri'] ?? '';
    if (j.containsKey('dlver')) dlver = j['dlver'] ?? '';

    if (j.containsKey('ctime')) {
      String date = j['ctime'];
      try {
        ctime = DateTime.parse(date);
      } catch (_) {}
    }
  }
}

class IndexInfo {
  IndexInfo() {}

  int index = 0;
  String title = '';
  int chars = 0;

  Map<String, dynamic> toJson() => {
        'index': index,
        'title': title,
        'chars': chars,
      };

  IndexInfo.fromJson(Map<String, dynamic> j) {
    if (j.containsKey('index')) index = j['index'] ?? 0;
    if (j.containsKey('title')) title = j['title'] ?? '';
    if (j.containsKey('chars')) chars = j['chars'] ?? 0;
  }
}

class IndexData {
  IndexData() {}

  List<IndexInfo> list = [];

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> jsonlist = [];
    for (IndexInfo d in list) {
      jsonlist.add(d.toJson());
    }
    return {'list': jsonlist};
  }

  IndexData.fromJson(dynamic jsonList) {
    if (jsonList.containsKey('list')) {
      var list1 = jsonList['list'];
      for (Map<String, dynamic> j in list1) {
        IndexInfo l = IndexInfo.fromJson(j);
        list.add(l);
      }
    }
  }

  int getExistingIndex() {
    int existingIndex = 0;
    for (IndexInfo i in list) {
      if (existingIndex < i.index) existingIndex = i.index;
    }
    return existingIndex;
  }
}

class ClipInfo {
  ClipInfo() {}

  int index = 0;
  int ratio = 0;
  String text = '';

  Map<String, dynamic> toJson() => {
        'index': index,
        'ratio': ratio,
        'text': text,
      };

  ClipInfo.fromJson(Map<String, dynamic> j) {
    if (j.containsKey('index')) index = j['index'] ?? 0;
    if (j.containsKey('ratio')) ratio = j['ratio'] ?? 0;
    if (j.containsKey('text')) text = j['text'] ?? '';
  }
}

class ClipData {
  ClipData();

  List<ClipInfo> list = [];

  sort() {
    list.sort((a, b) {
      bool d = (a.index * 1000000) + a.ratio > (b.index * 1000000) + b.ratio;
      return d ? 1 : -1;
    });
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> dlist = [];
    for (ClipInfo d in list) {
      dlist.add(d.toJson());
    }
    return {'list': dlist};
  }

  ClipData.fromJson(dynamic jsonList) {
    if (jsonList.containsKey('list')) {
      var list1 = jsonList['list'];
      for (Map<String, dynamic> j in list1) {
        ClipInfo c = ClipInfo.fromJson(j);
        list.add(c);
      }
    }
  }
}

class PropData {
  PropData();

  int flag = 0;
  int nowChars = 0;
  int maxChars = 1;
  DateTime atime = DateTime.now();

  Map<String, dynamic> toJson() => {
        'flag': flag,
        'nowChars': nowChars,
        'maxChars': maxChars,
        'atime': DateFormat('yyyy-MM-dd HH:mm:ss').format(atime),
      };

  PropData.fromJson(Map<String, dynamic> j) {
    if (j.containsKey('flag')) flag = j['flag'] ?? 0;
    if (j.containsKey('nowChars')) nowChars = j['nowChars'] ?? 0;
    if (j.containsKey('maxChars')) maxChars = j['maxChars'] ?? 0;
    if (j.containsKey('atime')) {
      String date = j['atime'];
      try {
        atime = DateTime.parse(date);
      } catch (_) {}
    }
  }
}

class SettingsData {
  int appId = 0;
  List<int> listMark = [];
  DateTime lastDate = DateTime(2000, 1, 1);
}

class FavoInfo {
  FavoInfo() {}
  String uri = '';
  String title = '';
  int type = 0;

  Map<String, dynamic> toJson() => {
        'uri': uri,
        'title': title,
      };

  FavoInfo.fromJson(Map<String, dynamic> j) {
    if (j.containsKey('uri')) uri = j['uri'] ?? '';
    if (j.containsKey('title')) title = j['title'] ?? '';
  }
}

class FavoData {
  FavoData() {}
  List<FavoInfo> list = [];

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> dlist = [];
    for (FavoInfo d in list) {
      dlist.add(d.toJson());
    }
    return {'list': dlist};
  }

  FavoData.fromJson(dynamic jsonList) {
    if (jsonList.containsKey('list')) {
      var list1 = jsonList['list'];
      for (Map<String, dynamic> j in list1) {
        FavoInfo c = FavoInfo.fromJson(j);
        list.add(c);
      }
    }
  }
}
