import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:io';
import '/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

import '/models/log_data.dart';

class BooklogController {
  Future readBooklog() async {
    String logfile = 'book.log';
    String appdir = (await getApplicationDocumentsDirectory()).path;
    if (!Platform.isIOS && !Platform.isAndroid) {
      appdir = appdir + '/test';
    }
    String logdir = appdir + '/logs';

    await Directory('${logdir}').create(recursive: true);
    final String path = '${logdir}/${logfile}';

    String txt = '';
    if (await File(path).exists()) {
      txt += await File(path).readAsString();
    }

    List<BooklogData> list = [];
    for (String line in txt.split('\n')) {
      List r = line.split('\t');
      if (r.length >= 4) {
        BooklogData d = BooklogData(r[0], r[1], r[2], r[3]);
        list.add(d);
      }
    }
    list.sort((a, b) {
      return b.date.compareTo(a.date);
    });
  }
}
