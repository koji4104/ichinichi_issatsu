import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '/constants.dart';
import 'dart:developer';

import 'package:intl/intl.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/gestures.dart';

import '/commons/base_screen.dart';
import '/controllers/viewlog_controller.dart';
import '/controllers/booklist_controller.dart';
import '/models/log_data.dart';
import '/models/book_data.dart';
import '/commons/widgets.dart';

class ViewlogScreen extends BaseScreen {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    super.build(context, ref);

    return Scaffold(
      appBar: AppBar(
        title: Text('View Logs'),
        leadingWidth: 150,
        leading: Row(children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          SizedBox(width: 10),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              await ref.watch(viewlogProvider).read();
              ref.read(viewlogProvider).notifyListeners();
            },
          ),
        ]),
        actions: <Widget>[
          MyIconLabelButton(
            icon: Icon(Icons.delete_outline),
            onPressed: () async {
              alertDialog('delete').then((ret) {
                if (ret == true) {
                  ref.read(viewlogProvider).deleteAll();
                  ref.read(viewlogProvider).notifyListeners();
                }
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
            child: Column(children: [
              speed(),
              desc(),
              SizedBox(height: 8),
              header(),
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
    String text = '${ref.watch(viewlogProvider).per_hour}';
    return MyText('${sph} ${text} ${spage}');
  }

  Widget desc() {
    return Row(
      children: [
        Expanded(child: SizedBox(width: 1)),
        Text('${l10n('swipe_to_delete')}', textScaler: TextScaler.linear(myTextScale * 0.7)),
      ],
    );
  }

  Widget header() {
    TextScaler sc = TextScaler.linear(myTextScale * 0.7);
    TextAlign al = TextAlign.right;
    return Row(
      children: [
        SizedBox(width: 20),
        Expanded(flex: 1, child: Text('Date', textScaler: sc)),
        Expanded(flex: 1, child: Text('pages', textScaler: sc, textAlign: al)),
        Expanded(flex: 1, child: Text('min', textScaler: sc, textAlign: al)),
        Expanded(flex: 1, child: Text('pages/h', textScaler: sc, textAlign: al)),
        SizedBox(width: 20),
      ],
    );
  }

  Widget getList() {
    List<Widget> list = [];
    // ログにタイトルも記載のため不要
    if (ref.watch(viewlogProvider).list.length == 0) return Container();

    for (int i = 0; i < ref.watch(viewlogProvider).list.length; i++) {
      String title = ref.watch(viewlogProvider).list[i].bookId;
      list.add(
        MyReadlogListTile(
          data: ref.watch(viewlogProvider).list[i],
          title: title,
          onPressed: () async {
            deleteDialog().then((ret) async {
              if (ret) {
                await ref.watch(viewlogProvider).deleteOne(i);
                ref.watch(viewlogProvider).notifyListeners();
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
              MySlidableAction(
                onPressed: (_) {
                  deleteDialog().then((ret) {
                    if (ret) {
                      log('delete');
                      ref.watch(viewlogProvider).deleteOne(index).then((ret) {
                        ref.watch(viewlogProvider).notifyListeners();
                      });
                    }
                  });
                },
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent,
                icon: Icons.delete,
                label: l10n('delete'),
                //spacing: 0,
                //padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget MyReadlogListTile({
    required ViewlogData data,
    required String title,
    Function()? onPressed,
  }) {
    Widget wDate = Text(
      DateFormat("MM-dd HH:mm").format(data.date),
      textScaler: TextScaler.linear(myTextScale * 0.9),
      textAlign: TextAlign.left,
    );

    int imin = (data.sec / 60).toInt();
    if (imin == 1) imin = 1;
    Widget wMin = Text(
      '${imin}',
      textScaler: TextScaler.linear(myTextScale * 0.9),
      textAlign: TextAlign.right,
    );

    double npage = data.chars / CHARS_PAGE;
    Widget wPage = Text(
      '${npage.toInt()}',
      textScaler: TextScaler.linear(myTextScale * 0.9),
      textAlign: TextAlign.right,
    );

    int per_hour = 0;
    if (data.sec > 0) {
      per_hour = (data.chars * 3600 / data.sec / CHARS_PAGE).toInt();
      if (per_hour > 999) per_hour = 999;
    }
    Widget wSpeed = Text(
      '${per_hour}',
      textScaler: TextScaler.linear(myTextScale * 0.9),
      textAlign: TextAlign.right,
    );

    Widget wTitle = Text(
      data.bookTitle,
      maxLines: 1,
      textScaler: TextScaler.linear(myTextScale * 0.8),
    );

    Widget child = Column(children: [
      Expanded(flex: 1, child: SizedBox(height: 1)),
      Row(children: [
        Expanded(flex: 2, child: wDate),
        Expanded(flex: 1, child: wPage),
        Expanded(flex: 1, child: wMin),
        Expanded(flex: 1, child: wSpeed),
      ]),
      Row(children: [Expanded(child: wTitle)]),
      Expanded(flex: 1, child: SizedBox(height: 1)),
    ]);

    return Container(
      height: 40 + (30 * myTextScale),
      decoration: BoxDecoration(
        color: myTheme.cardColor,
        border: Border(
          top: BorderSide(color: myTheme.dividerColor, width: 0.3),
          bottom: BorderSide(color: myTheme.dividerColor, width: 0.3),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: child,
    );
  }
}
