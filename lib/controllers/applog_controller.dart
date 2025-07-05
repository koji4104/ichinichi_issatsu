import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';

import '/constants.dart';
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
    if (IS_DEBUG_LOG == true) await MyLog.write('error', 'app', msg);
  }

  static debug(String msg) async {
    if (IS_DEBUG_LOG == true) await MyLog.write('debug', 'app', msg);
  }

  static write(String level, String event, String msg) async {
    try {
      log('${level} ${msg}');

      Uint8List enc = await utf8.encode(msg);
      String dec = await utf8.decode(enc);
      if (msg != dec) {
        msg = 'encode error';
      }

      String t = new DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
      String u = '1';
      String l = level;
      String e = event;

      if (APP_DIR == '') {
        APP_DIR = (await getApplicationDocumentsDirectory()).path;
        if (!Platform.isIOS && !Platform.isAndroid) {
          APP_DIR = APP_DIR + '/test';
        }
      }
      String logdir = APP_DIR + '/data';
      await Directory('${logdir}').create(recursive: true);
      final String path = '${logdir}/$_fname';

      // length byte 100kb
      if (await File(path).exists() && File(path).lengthSync() > 100 * 1024) {
        if (await File(path + '.2').exists()) {
          File(path + '.2').deleteSync();
        }
        if (await File(path + '.1').exists()) {
          File(path + '.1').renameSync(path + '.2');
        }
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
      if (APP_DIR == '') {
        APP_DIR = (await getApplicationDocumentsDirectory()).path;
        if (!Platform.isIOS && !Platform.isAndroid) {
          APP_DIR = APP_DIR + '/test';
        }
      }
      String logdir = APP_DIR + '/data';
      await Directory('${logdir}').create(recursive: true);
      final String path = '${logdir}/$_fname';

      if (await File(path + '.2').exists()) {
        txt += await File(path + '.2').readAsString();
      }
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
