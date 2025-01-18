import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:io';
import '/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

import '/models/log_data.dart';

ReadlogController readLog = ReadlogController();

class ReadlogController {
  ReadlogController() {
    read();
  }

  List<ReadlogData> list = [];
  DateTime startDate = DateTime.now();
  int startChars = 0;
  String logfile = 'read.txt';
  int per_hour = 0; // page/h
  int sumSec = 0;
  int sumChars = 0;

  Future init(int nowChars) async {
    startDate = DateTime.now();
    startChars = nowChars;
  }

  Future save(int chars, String id) async {
    String appdir = (await getApplicationDocumentsDirectory()).path;
    if (!Platform.isIOS && !Platform.isAndroid) {
      appdir = appdir + '/test';
    }
    String logdir = appdir + '/data';
    await Directory('${logdir}').create(recursive: true);
    final String path = '${logdir}/${logfile}';

    if (await File(path).exists() && File(path).lengthSync() > 64 * 1024) {
      if (await File(path + '.1').exists()) File(path + '.1').deleteSync();
      File(path).renameSync(path + '.1');
    }

    String date = new DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
    int sec = DateTime.now().difference(startDate).inSeconds;
    int defChars = chars - startChars;

    if (sec >= 30 && defChars >= 450) {
      String tsv = '${date}\t${sec}\t${defChars}\t${id}\n';
      await File(path).writeAsString(tsv, mode: FileMode.append, flush: true);
    }
  }

  Future read() async {
    list.clear();

    String appdir = (await getApplicationDocumentsDirectory()).path;
    if (!Platform.isIOS && !Platform.isAndroid) {
      appdir = appdir + '/test';
    }
    String logdir = appdir + '/data';

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
      ReadlogData? d = ReadlogData.fromTsv(line);
      if (d != null) list.add(d);
    }

    list.sort((a, b) {
      return b.date.compareTo(a.date);
    });

    sumSec = 1;
    sumChars = 0;
    for (ReadlogData d in list) {
      sumSec += d.sec;
      sumChars += d.chars;
    }

    per_hour = (sumChars * 3600 / sumSec / CHARS_PAGE).toInt();
  }

  Future delete(int i) async {
    String appdir = (await getApplicationDocumentsDirectory()).path;
    if (!Platform.isIOS && !Platform.isAndroid) {
      appdir = appdir + '/test';
    }
    String logdir = appdir + '/data';
    await Directory('${logdir}').create(recursive: true);
    final String path = '${logdir}/${logfile}';

    DateTime date = list[i].date;
    String sDate = DateFormat("yyyy-MM-dd HH:mm:ss").format(date);

    String txt = '';
    if (await File(path).exists()) {
      txt += await File(path).readAsString();
    }

    List<ReadlogData> tempList = [];
    for (String line in txt.split('\n')) {
      ReadlogData? d = ReadlogData.fromTsv(line);
      if (d != null) tempList.add(d);
    }
    for (ReadlogData d in tempList) {
      if (d.date == date) {
        tempList.remove(d);

        String tsv = listToTsv(tempList);
        await File(path).writeAsString(tsv, mode: FileMode.write, flush: true);
        break;
      }
    }
  }

  String listToTsv(List<ReadlogData> tempList) {
    String txt = '';
    for (ReadlogData d in tempList) {
      String sdate = DateFormat("yyyy-MM-dd HH:mm:ss").format(d.date);
      txt += '${sdate}\t${d.sec}\t${d.chars}\t${d.bookId}\n';
    }
    return txt;
  }
}
