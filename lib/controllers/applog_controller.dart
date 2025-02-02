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

class MyLog {
  static String _fname = "app.log";

  static info(String msg) async {
    await MyLog.write('info', 'app', msg);
  }

  static warn(String msg) async {
    await MyLog.write('warn', 'app', msg);
  }

  static err(String msg) async {
    await MyLog.write('error', 'app', msg);
  }

  static debug(String msg) async {
    await MyLog.write('debug', 'app', msg);
  }

  static write(String level, String event, String msg) async {
    try {
      log('${level} ${msg}');

      String t = new DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
      String u = '1';
      String l = level;
      String e = event;

      String appdir = (await getApplicationDocumentsDirectory()).path;
      if (!Platform.isIOS && !Platform.isAndroid) {
        appdir = appdir + '/test';
      }
      String logdir = appdir + '/data';
      await Directory('${logdir}').create(recursive: true);
      final String path = '${logdir}/$_fname';

      // length byte 200kb
      if (await File(path).exists() && File(path).lengthSync() > 200 * 1024) {
        if (await File(path + '.1').exists()) File(path + '.1').deleteSync();
        File(path).renameSync(path + '.1');
      }
      String tsv = '$t\t$u\t$l\t$e\t$msg\n';
      await File(path).writeAsString(tsv, mode: FileMode.append, flush: true);
    } on Exception catch (e) {
      log('MyLog write() Exception ' + e.toString());
    }
  }

  /// read
  static Future<List<MyLogData>> read() async {
    List<MyLogData> list = [];
    try {
      String txt = '';
      String appdir = (await getApplicationDocumentsDirectory()).path;
      if (!Platform.isIOS && !Platform.isAndroid) {
        appdir = appdir + '/test';
      }
      String logdir = appdir + '/data';
      await Directory('${logdir}').create(recursive: true);
      final String path = '${logdir}/$_fname';

      if (await File(path + '.1').exists()) {
        txt += await File(path + '.1').readAsString();
      }
      if (await File(path).exists()) {
        txt += await File(path).readAsString();
      }

      for (String line in txt.split('\n')) {
        List r = line.split('\t');
        if (r.length >= 5) {
          MyLogData d = MyLogData(date: r[0], user: r[1], level: r[2], event: r[3], msg: r[4]);
          list.add(d);
        }
      }
      list.sort((a, b) {
        return b.date.compareTo(a.date);
      });
    } on Exception catch (e) {
      log('MyLog read() Exception ' + e.toString());
    }
    return list;
  }
}
