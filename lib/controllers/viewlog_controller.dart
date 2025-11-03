import 'dart:developer';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:math' as math;

import '/constants.dart';
import '/models/log_data.dart';
import '/models/book_data.dart';

final viewlogProvider = ChangeNotifierProvider((ref) => ViewlogNotifier(ref));

class ViewlogNotifier extends ChangeNotifier {
  ViewlogNotifier(ref) {
    read();
  }

  List<ViewlogData> list = [];
  DateTime startDate = DateTime.now();
  int startChars = 0;
  String logfile = 'view.log';
  int per_hour = 0; // page/h
  int sumSec = 0;
  int sumChars = 0;

  Future init(int nowChars) async {
    startDate = DateTime.now();
    startChars = nowChars;
  }

  Future save(int chars, BookData book) async {
    String logdir = APP_DIR + '/data';
    await Directory('${logdir}').create(recursive: true);
    final String path = '${logdir}/${logfile}';

    if (await File(path).exists() && File(path).lengthSync() > 100 * 1024) {
      if (await File(path + '.1').exists()) File(path + '.1').deleteSync();
      File(path).renameSync(path + '.1');
    }

    String date = new DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
    int sec = DateTime.now().difference(startDate).inSeconds;
    int defChars = chars - startChars;

    int temp_per_hour = (defChars * 3600 / sec / CHARS_PAGE).toInt();
    if (temp_per_hour <= 900) {
      if (sec >= 60 && defChars >= CHARS_PAGE) {
        String tsv = '${date}\t${sec}\t${defChars}\t${book.bookId}\t${book.title}\n';
        await File(path).writeAsString(tsv, mode: FileMode.append, flush: true);
        this.notifyListeners();
      }
    }
  }

  Future read() async {
    list.clear();

    // キャプチャー用・テスト用
    if (IS_TEST_SS == true) {
      var random = math.Random();
      for (int i = 0; i < 5; i++) {
        int ran1 = random.nextInt(10);
        int ran2 = random.nextInt(10);
        ViewlogData d = ViewlogData();
        d.date = DateTime(2025, 7, 1 + ran1, 8 + ran2, 0, 0);
        d.bookId = 'A776';
        d.bookTitle = '草枕';
        // chars * 8 / sec = 50;
        d.sec = 120 + (60 * ran1);
        d.chars = d.sec * 6 + (ran2 * 100);
        list.add(d);
      }
    } else {
      String logdir = APP_DIR + '/data';
      await Directory('${logdir}').create(recursive: true);
      final String path = '${logdir}/${logfile}';

      String txt = '';
      if (await File(path).exists()) {
        txt += await File(path).readAsString();
      }
      if (await File(path + '.1').exists()) {
        txt += await File(path + '.1').readAsString();
      }

      for (String line in txt.split('\n')) {
        ViewlogData? d = ViewlogData.fromTsv(line);
        if (d != null) list.add(d);
      }
    }

    list.sort((a, b) {
      return b.date.compareTo(a.date);
    });

    sumSec = 1;
    sumChars = 0;
    for (ViewlogData d in list) {
      sumSec += d.sec;
      sumChars += d.chars;
    }
    per_hour = (sumChars * 3600 / sumSec / CHARS_PAGE).toInt();
    this.notifyListeners();
  }

  Future deleteOne(int index) async {
    String logdir = APP_DIR + '/data';
    await Directory('${logdir}').create(recursive: true);

    DateTime date = list[index].date;
    String sDate = DateFormat("yyyy-MM-dd HH:mm:ss").format(date);

    bool done = false;
    if (done == false) {
      final String path = '${logdir}/${logfile}';
      if (await File(path).exists()) {
        String txt = await File(path).readAsString();

        List<ViewlogData> logList = [];
        for (String line in txt.split('\n')) {
          ViewlogData? d = ViewlogData.fromTsv(line);
          if (d != null) logList.add(d);
        }
        for (ViewlogData d in logList) {
          if (d.date == date) {
            logList.remove(d);
            String tsv = listToTsv(logList);
            await File(path).writeAsString(tsv, mode: FileMode.write, flush: true);
            done = true;
            break;
          }
        }
      }
    }
    if (done == false) {
      final String path = '${logdir}/${logfile}.1';
      if (await File(path).exists()) {
        String txt = await File(path).readAsString();

        List<ViewlogData> logList = [];
        for (String line in txt.split('\n')) {
          ViewlogData? d = ViewlogData.fromTsv(line);
          if (d != null) logList.add(d);
        }
        for (ViewlogData d in logList) {
          if (d.date == date) {
            logList.remove(d);
            String tsv = listToTsv(logList);
            await File(path).writeAsString(tsv, mode: FileMode.write, flush: true);
            done = true;
            break;
          }
        }
      }
    }
    if (done) read();
  }

  /// deleteAll
  Future deleteAll() async {
    try {
      String logdir = APP_DIR + '/data';
      await Directory('${logdir}').create(recursive: true);
      final String path = '${logdir}/${logfile}';

      String txt = '';
      if (await File(path).exists()) {
        File(path).deleteSync();
      }
      if (await File(path + '.1').exists()) {
        File(path + '.1').deleteSync();
      }
      if (await File(path + '.2').exists()) {
        File(path + '.2').deleteSync();
      }
      list.clear();
    } on Exception catch (e) {
      log('viewlog.deleteAll() ' + e.toString());
    }
  }

  String listToTsv(List<ViewlogData> tempList) {
    String txt = '';
    for (ViewlogData d in tempList) {
      String sdate = DateFormat("yyyy-MM-dd HH:mm:ss").format(d.date);
      txt += '${sdate}\t${d.sec}\t${d.chars}\t${d.bookId}\t${d.bookTitle}\n';
    }
    return txt;
  }
}
