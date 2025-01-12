import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:developer';

import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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

final logListProvider = StateProvider<List<MyLogData>>((ref) {
  return [];
});

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
    log('${level} ${msg}');

    String t = new DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());
    String l = level;
    String e = event;
    String u = '1';

    String appdir = (await getApplicationDocumentsDirectory()).path;
    if (!Platform.isIOS && !Platform.isAndroid) {
      appdir = appdir + '/test';
    }
    String logdir = appdir + '/logs';
    await Directory('${logdir}').create(recursive: true);
    final String path = '${logdir}/$_fname';

    // length byte 200kb
    if (await File(path).exists() && File(path).lengthSync() > 200 * 1024) {
      if (await File(path + '.1').exists()) File(path + '.1').deleteSync();
      File(path).renameSync(path + '.1');
      File(path).deleteSync();
    }
    String tsv = '$t\t$u\t$l\t$e\t$msg\n';
    await File(path).writeAsString(tsv, mode: FileMode.append, flush: true);
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
      String logdir = appdir + '/logs';
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
      print('-- MyLog read() Exception ' + e.toString());
    }
    return list;
  }
}

final logScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());

class LogScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future.delayed(Duration.zero, () => readLog(ref));
    List<MyLogData> list = ref.watch(logListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Logs'),
        backgroundColor: Color(0xFF000000),
        actions: <Widget>[],
      ),
      body: Container(
        child: Stack(children: <Widget>[
          getTable(context, ref, list),
        ]),
      ),
    );
  }

  void readLog(WidgetRef ref) async {
    List<MyLogData> list = await MyLog.read();
    ref.watch(logListProvider.state).state = list;
  }

  Widget getTable(BuildContext context, WidgetRef ref, List<MyLogData> list) {
    List<TextSpan> spans = [];
    TextStyle tsErr = TextStyle(color: Color(0xFFFF8888));
    TextStyle tsWarn = TextStyle(color: Color(0xFFeeee44));
    TextStyle tsInfo = TextStyle(color: Color(0xFFFFFFFF));
    TextStyle tsDebug = TextStyle(color: Color(0xFFaaaaaa));
    TextStyle tsTime = TextStyle(color: Color(0xFFcccccc));

    String format = MediaQuery.of(context).size.width > 500 ? "yyyy-MM-dd HH:mm.ss" : "MM-dd HH:mm";
    for (MyLogData d in list) {
      try {
        String stime = DateFormat(format).format(DateTime.parse(d.date));
        Wrap w = Wrap(children: [getText(stime), getText(d.msg)]);
        spans.add(TextSpan(text: stime, style: tsTime));
        if (d.level.toLowerCase().contains('err'))
          spans.add(TextSpan(text: ' error', style: tsErr));
        else if (d.level.toLowerCase().contains('warn'))
          spans.add(TextSpan(text: ' warn', style: tsWarn));
        if (d.level.toLowerCase().contains('debug'))
          spans.add(TextSpan(text: ' ' + d.msg + '\n', style: tsDebug));
        else
          spans.add(TextSpan(text: ' ' + d.msg + '\n', style: tsInfo));
      } on Exception catch (e) {}
    }

    return Container(
      width: MediaQuery.of(context).size.width - 20,
      height: MediaQuery.of(context).size.height - 120,
      decoration: BoxDecoration(
        color: Color(0xFF404040),
        borderRadius: BorderRadius.circular(3),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: SelectableText.rich(
          TextSpan(style: TextStyle(fontSize: 14, fontFamily: 'monospace'), children: spans),
        ),
      ),
    );
  }

  Widget getText(String s) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
      child: Text(s, style: TextStyle(fontSize: 13, color: Colors.white)),
    );
  }
}
