import 'dart:convert';
import 'dart:io';
import 'dart:developer';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

import '/commons/base_screen.dart';
import '/commons/widgets.dart';
import '/controllers/epub_controller.dart';
import '/controllers/booklist_controller.dart';
import '/models/book_data.dart';
import '/screens/browser_screen.dart';
import '/screens/viewer_screen.dart';
import '/screens/settings_screen.dart';

/// BookScreen
class BookListScreen extends BaseScreen {
  bool isCheckBox = true;
  String datadir = '';

  @override
  Future init() async {
    String appdir = (await getApplicationDocumentsDirectory()).path;
    if (!Platform.isIOS && !Platform.isAndroid) {
      appdir = appdir + '/test';
    }
    datadir = appdir + '/data';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    super.build(context, ref);

    return Scaffold(
      appBar: AppBar(
        title: MyText('Home', noScale: true),
        leading: IconButton(
          onPressed: () async {
            ref.watch(booklistProvider).readBookList();
          },
          iconSize: 24.0,
          icon: Icon(Icons.refresh),
        ),
        actions: [dropdownFlag(), SizedBox(width: 20)],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              padding: DEF_MENU_PADDING,
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.watch(booklistProvider).readBookList();
                },
                child: getList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getList() {
    List<BookData> bookList1 = ref.watch(booklistProvider).bookList;
    if (bookList1.length <= 0) return Container();
    if (ref.watch(booklistProvider).isReading) return Container();

    List<BookData> bookList = [];
    for (BookData d in bookList1) {
      if (selectedFlag == 0) {
        bookList.add(d);
      } else {
        if (selectedFlag == d.info.flag) {
          bookList.add(d);
        }
      }
    }
    bookList.sort((a, b) {
      return b.info.accessDate.compareTo(a.info.accessDate) > 0 ? 1 : -1;
    });

    return ListView.builder(
      itemCount: bookList.length,
      itemBuilder: (BuildContext context, int index) {
        return Slidable(
          dragStartBehavior: DragStartBehavior.start,
          key: UniqueKey(),
          child: MyBookListTile(
            title: bookList[index].title,
            flag: bookList[index].info.flag,
            onPressed: () {
              ref.watch(booklistProvider).saveLastAccess(index);
              var screen = ViewerScreen(book: bookList[index]);
              NavigatorPush(screen);
            },
          ),
          startActionPane: ActionPane(
            extentRatio: 0.20,
            motion: const StretchMotion(),
            children: [
              SlidableAction(
                onPressed: (_) {
                  flagDialog().then((ret) {
                    if (ret >= 0) {
                      ref.watch(booklistProvider).saveFlag(index, ret);
                      bookList[index].info.flag = ret;
                      redraw();
                    }
                  });
                },
                foregroundColor: myTheme.textTheme.bodyMedium!.color!,
                backgroundColor: myTheme.scaffoldBackgroundColor,
                icon: Icons.circle_outlined,
                label: null,
                spacing: 0,
                padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
              ),
            ],
          ),
          endActionPane: ActionPane(
            extentRatio: 0.50,
            motion: const StretchMotion(),
            children: [
              SlidableAction(
                onPressed: (_) {
                  okDialog(msg: 're download').then((ret) {
                    if (ret) {
                      String dir = datadir + '/${bookList[index].bookId}';
                      //if (Directory(dir).existsSync()) {
                      //  Directory(dir).deleteSync(recursive: true);
                      //  ref.watch(booklistProvider).readBookList();
                      //}
                    }
                  });
                },
                backgroundColor: Colors.grey,
                icon: Icons.download,
                label: null,
                spacing: 0,
                padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
              ),
              SlidableAction(
                onPressed: (_) {
                  okDialog(msg: 'add download').then((ret) {
                    if (ret) {
                      String dir = datadir + '/${bookList[index].bookId}';
                      //if (Directory(dir).existsSync()) {
                      //  Directory(dir).deleteSync(recursive: true);
                      //  ref.watch(booklistProvider).readBookList();
                      //}
                    }
                  });
                },
                backgroundColor: Colors.blueAccent,
                icon: Icons.add,
                label: null,
                spacing: 0,
                padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
              ),
              SlidableAction(
                onPressed: (_) {
                  deleteDialog().then((ret) {
                    if (ret) {
                      log('delette');
                      String dir = datadir + '/${bookList[index].bookId}';
                      if (Directory(dir).existsSync()) {
                        Directory(dir).deleteSync(recursive: true);
                        ref.watch(booklistProvider).readBookList();
                      }
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

  Future<int> flagDialog() async {
    int ret = -1;

    await showDialog(
      context: this.context,
      builder: (BuildContext context) {
        List<SimpleDialogOption> list = [];
        for (int i = 0; i < flagIconList.length; i++) {
          list.add(
            SimpleDialogOption(
              child: flagIconList[i],
              onPressed: () {
                ret = i;
                Navigator.of(context).pop();
              },
            ),
          );
        }

        return SimpleDialog(
          title: Text(l10n('flag_changes'), style: myTheme.textTheme.bodyMedium!),
          children: list,
          /*
            SimpleDialogOption(
              child: flagIconList[0],
              onPressed: () {
                ret = 0;
                Navigator.of(context).pop();
              },
            ),
            SimpleDialogOption(
              child: flagIconList[1],
              onPressed: () {
                ret = 1;
                Navigator.of(context).pop();
              },
            ),
            SimpleDialogOption(
              child: flagIconList[2],
              onPressed: () {
                ret = 2;
                Navigator.of(context).pop();
              },
            ),
            SimpleDialogOption(
              child: flagIconList[3],
              onPressed: () {
                ret = 3;
                Navigator.of(context).pop();
              },
            ),
          ],*/
        );
      },
    );
    return ret;
  }

  int selectedFlag = 0;
  List<Icon> flagIconList = [
    Icon(Icons.circle_outlined, size: 18),
    Icon(Icons.circle, color: COL_FLAG1, size: 18),
    Icon(Icons.circle, color: COL_FLAG2, size: 18),
    Icon(Icons.circle, color: COL_FLAG3, size: 18),
    Icon(Icons.circle, color: COL_FLAG4, size: 18),
    Icon(Icons.circle, color: COL_FLAG5, size: 18),
    Icon(Icons.circle, color: COL_FLAG6, size: 18),
  ];

  Widget dropdownFlag() {
    List<DropdownMenuItem> list = [];
    for (int i = 0; i < flagIconList.length; i++) {
      list.add(
        DropdownMenuItem<int>(value: i, child: flagIconList[i]),
      );
    }

    return DropdownButton(
      items: list,
      value: 0,
      onChanged: (value) {
        if (selectedFlag != value) {
          selectedFlag = value;
          redraw();
        }
      },
      dropdownColor: myTheme.cardColor,
      style: myTheme.textTheme.bodyMedium!,
    );
  }
}
