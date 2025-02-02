import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class MyLogData {
  String date = '';
  String user = '';
  String level = '';
  String event = '';
  String msg = '';

  MyLogData({String? date, String? user, String? level, String? event, String? msg}) {
    this.date = date ?? '';
    this.user = user ?? '';
    this.level = level ?? '';
    this.event = event ?? '';
    this.msg = msg ?? '';
  }
}

String sample = '''
2022-04-01 00:00:00\tuser\terror\tapp\tmessage1
2022-04-02 00:00:00\tuser\twarn\tapp\tmessage2
2022-04-03 00:00:00\tuser\tinfo\tapp\tmessage3
''';

class ViewlogData {
  ViewlogData() {}

  DateTime date = DateTime(2000, 1, 1);
  int sec = 0;
  int chars = 0;
  String bookId = '';

  ReadlogData1(
    String? adate,
    String? amin,
    String? achars,
    String? abookId,
  ) {
    if (adate == null || amin == null || achars == null) return;
    try {
      date = DateTime.parse(adate);
    } catch (_) {}
    this.sec = int.parse(amin);
    this.chars = int.parse(achars);
    if (abookId != null) this.bookId = abookId;
  }

  static ViewlogData? fromTsv(String line) {
    List r = line.split('\t');
    if (r.length >= 4) {
      ViewlogData data = ViewlogData();
      try {
        data.date = DateTime.parse(r[0]);
        data.sec = int.parse(r[1]);
        data.chars = int.parse(r[2]);
        data.bookId = r[3];
        return data;
      } catch (_) {}
    }
    return null;
  }
}
