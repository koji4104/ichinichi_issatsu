import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '/commons/base_screen.dart';
import '/controllers/applog_controller.dart';
import '/models/log_data.dart';
import '/commons/widgets.dart';

final logListProvider = StateProvider<List<MyLogData>>((ref) {
  return [];
});

final logScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());

class ApplogScreen extends BaseScreen {
  @override
  Future init() async {
    readLog(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    super.build(context, ref);
    List<MyLogData> list = ref.watch(logListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Logs'),
        actions: [
          MyIconLabelButton(
            icon: Icon(Icons.delete_outline),
            onPressed: () async {
              alertDialog('delete').then((ret) {
                MyLog.deleteAll();
              });
            },
          ),
          SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Stack(children: [
          Container(
            padding: DEF_MENU_PADDING,
            child: getTable(context, ref, list),
          ),
        ]),
      ),
    );
  }

  void readLog(WidgetRef ref) async {
    List<MyLogData> list = await MyLog.read();
    ref.read(logListProvider.state).state = list;
  }

  Widget getTable(BuildContext context, WidgetRef ref, List<MyLogData> list) {
    List<TextSpan> spans = [];
    TextStyle tsErr = TextStyle(color: Colors.redAccent);
    TextStyle tsWarn = TextStyle(color: Colors.orangeAccent);
    TextStyle tsInfo = TextStyle(color: myTheme.textTheme.bodyMedium!.color);
    TextStyle tsDebug = TextStyle(color: Colors.grey);
    TextStyle tsTime = TextStyle(color: Colors.grey);

    String format = "yyyy-MM-dd HH:mm";
    for (MyLogData d in list) {
      try {
        String stime = DateFormat(format).format(DateTime.parse(d.date));
        Wrap w = Wrap(children: [getText(stime), getText(d.msg)]);
        spans.add(TextSpan(text: stime + '\n', style: tsTime));

        if (d.level.toLowerCase().contains('err'))
          spans.add(TextSpan(text: 'error ', style: tsErr));
        else if (d.level.toLowerCase().contains('warn'))
          spans.add(TextSpan(text: 'warn ', style: tsWarn));
        else if (d.level.toLowerCase().contains('debug'))
          spans.add(TextSpan(text: 'debug ', style: tsDebug));

        spans.add(TextSpan(text: d.msg + '\n', style: tsInfo));
      } on Exception catch (e) {}
    }

    return Container(
      width: MediaQuery.of(context).size.width - 20,
      height: MediaQuery.of(context).size.height - 120,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: SelectableText.rich(
          textScaler: TextScaler.linear(myTextScale - 0.1),
          TextSpan(style: TextStyle(fontFamily: 'monospace'), children: spans),
        ),
      ),
    );
  }

  Widget getText(String s) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
      child: Text(s),
    );
  }
}
