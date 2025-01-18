import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ichinichi_issatsu/constants.dart';
import 'dart:developer';

import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/gestures.dart';

import '/commons/base_screen.dart';
import '/controllers/log_controller.dart';
import '/controllers/booklist_controller.dart';
import '/screens/log_screen.dart';
import '/models/log_data.dart';
import '/models/book_data.dart';
import '/commons/widgets.dart';

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

class ReadlogScreen extends BaseScreen {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    super.build(context, ref);

    return Scaffold(
      appBar: AppBar(
        title: Text('Logs'),
        leadingWidth: 150,
        leading: Row(children: [
          IconButton(
            iconSize: 24,
            icon: Icon(Icons.arrow_back_ios_new),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          SizedBox(width: 10),
          IconButton(
            iconSize: 24,
            icon: Icon(Icons.refresh),
            onPressed: () async {
              await readLog.read();
              redraw();
            },
          ),
        ]),
        actions: <Widget>[],
      ),
      body: SafeArea(
        child: Stack(children: [
          Container(
            padding: DEF_MENU_PADDING,
            child: Column(children: [
              speed(),
              SizedBox(height: 12),
              Expanded(child: getList()),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget speed() {
    String sph = l10n('per_hour');
    String spage = l10n('page');
    String text = '${readLog.per_hour}';
    return MyText('${sph} ${text} ${spage}');
  }

  Widget getList() {
    List<Widget> list = [];
    List<BookData> bookList1 = ref.watch(booklistProvider).bookList;
    if (readLog.list.length == 0) return Container();

    for (int i = 0; i < readLog.list.length; i++) {
      String title = readLog.list[i].bookId;

      for (BookData d in bookList1) {
        if (d.bookId == readLog.list[i].bookId) {
          title = d.title;
          break;
        }
      }
      list.add(
        MyReadlogListTile(
          data: readLog.list[i],
          title: title,
          onPressed: () async {
            deleteDialog().then((ret) async {
              if (ret) {
                await readLog.delete(i);
                redraw();
              }
            });
          },
        ),
      );
    }
    if (list.length == 0) return Container();

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (BuildContext context, int index) {
        return Slidable(
          dragStartBehavior: DragStartBehavior.start,
          key: UniqueKey(),
          child: list[index],
          endActionPane: ActionPane(
            extentRatio: 0.25,
            motion: const StretchMotion(),
            children: [
              SlidableAction(
                onPressed: (_) {
                  deleteDialog().then((ret) {
                    if (ret) {
                      log('delette');
                      readLog.delete(index).then((ret) {
                        redraw();
                      });
                    }
                  });
                },
                backgroundColor: Colors.redAccent,
                icon: Icons.delete,
                label: null,
                spacing: 0,
                padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
              ),
            ],
          ),
        );
      },
    );
  }

/*
  Widget getList1() {
    List<Widget> list = [];
    List<BookData> bookList1 = ref.watch(booklistProvider).bookList;

    for (int i = 0; i < readLog.list.length; i++) {
      String title = readLog.list[i].bookId;

      for (BookData d in bookList1) {
        if (d.bookId == readLog.list[i].bookId) {
          title = d.title;
          break;
        }
      }
      list.add(
        MyReadlogListTile(
          data: readLog.list[i],
          title: title,
          onPressed: () async {
            deleteDialog().then((ret) async {
              if (ret) {
                await readLog.delete(i);
                redraw();
              }
            });
          },
        ),
      );
    }
    if (list.length == 0) return Container();

    return Container(
      width: MediaQuery.of(context).size.width - 20,
      height: MediaQuery.of(context).size.height - 120,
      decoration: BoxDecoration(
        color: myTheme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: Column(children: list),
      ),
    );
  }
*/
  Widget MyReadlogListTile({
    required ReadlogData data,
    required String title,
    Function()? onPressed,
  }) {
    Widget btn = IconButton(
      icon: Icon(Icons.delete, size: 18, color: myTheme.disabledColor),
      onPressed: onPressed,
    );

    int per_hour = 0;
    if (data.sec > 0) {
      per_hour = (data.chars * 3600 / data.sec / CHARS_PAGE).toInt();
    }

    Widget wDate = Text(
      DateFormat("MM-dd HH:mm").format(data.date),
      textScaler: TextScaler.linear(myTextScale),
      textAlign: TextAlign.left,
    );
    Widget wMin = Text(
      '${(data.sec / 60).toInt()}',
      textScaler: TextScaler.linear(myTextScale),
      textAlign: TextAlign.right,
    );
    Widget wMin1 = Text(
      ' m',
      textScaler: TextScaler.linear(myTextScale - 0.2),
      textAlign: TextAlign.left,
      //style: TextStyle(color: myTheme.disabledColor),
    );
    Widget wPage = Text(
      '${(data.chars / CHARS_PAGE).toInt()}',
      textScaler: TextScaler.linear(myTextScale),
      textAlign: TextAlign.right,
    );
    Widget wPage1 = Text(
      ' p',
      textScaler: TextScaler.linear(myTextScale - 0.2),
      textAlign: TextAlign.left,
      //style: TextStyle(color: myTheme.disabledColor),
    );
    Widget wSpeed = Text(
      '${per_hour}',
      textScaler: TextScaler.linear(myTextScale),
      textAlign: TextAlign.right,
    );
    Widget wSpeed1 = Text(
      ' p/h',
      textScaler: TextScaler.linear(myTextScale - 0.2),
      textAlign: TextAlign.left,
    );
    double titleScale = myTextScale - 0.2;
    //if(title.length>40) title = title.substring(0,40);
    Widget wTitle = Text(
      title,
      maxLines: 1,
      textScaler: TextScaler.linear(myTextScale - 0.2),
    );

    Widget child = Column(children: [
      Expanded(flex: 1, child: SizedBox(height: 1)),
      Row(children: [
        wDate,
        Expanded(flex: 2, child: SizedBox(width: 1)),
        wMin,
        wMin1,
        Expanded(flex: 1, child: SizedBox(width: 1)),
        wPage,
        wPage1,
        Expanded(flex: 1, child: SizedBox(width: 1)),
        wSpeed,
        wSpeed1,
        SizedBox(width: 8),
        //btn,
      ]),
      Row(children: [
        Expanded(child: wTitle),
      ]),
      Expanded(flex: 1, child: SizedBox(height: 1)),
    ]);

    return Container(
      height: 30 + (30 * myTextScale),
      decoration: BoxDecoration(
        color: myTheme.cardColor,
        border: Border(
          top: BorderSide(color: myTheme.dividerColor, width: 0.3),
          bottom: BorderSide(color: myTheme.dividerColor, width: 0.3),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, 0, 8, 0),
      child: child,
    );
  }
}
