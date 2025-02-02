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
import '/controllers/viewlog_controller.dart';
import '/controllers/booklist_controller.dart';
import '/screens/applog_screen.dart';
import '/models/log_data.dart';
import '/models/book_data.dart';
import '/commons/widgets.dart';

class ViewlogScreen extends BaseScreen {
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
            iconSize: 28,
            icon: Icon(Icons.refresh),
            onPressed: () async {
              await ref.watch(viewlogProvider).read();
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
    String text = '${ref.watch(viewlogProvider).per_hour}';
    return MyText('${sph} ${text} ${spage}');
  }

  Widget getList() {
    List<Widget> list = [];
    List<BookData> bookList1 = ref.watch(booklistProvider).bookList;
    if (ref.watch(viewlogProvider).list.length == 0) return Container();

    for (int i = 0; i < ref.watch(viewlogProvider).list.length; i++) {
      String title = ref.watch(viewlogProvider).list[i].bookId;

      for (BookData d in bookList1) {
        if (d.bookId == ref.watch(viewlogProvider).list[i].bookId) {
          title = d.title;
          break;
        }
      }
      list.add(
        MyReadlogListTile(
          data: ref.watch(viewlogProvider).list[i],
          title: title,
          onPressed: () async {
            deleteDialog().then((ret) async {
              if (ret) {
                await ref.watch(viewlogProvider).delete(i);
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
                      ref.watch(viewlogProvider).delete(index).then((ret) {
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

  Widget MyReadlogListTile({
    required ViewlogData data,
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
      '${(data.sec / 60).toInt().toString().padLeft(4, ' ')}',
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
      '${(data.chars / CHARS_PAGE).toInt().toString().padLeft(4, ' ')}',
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
      '${per_hour.toString().padLeft(4, ' ')}',
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
      data.bookId,
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
