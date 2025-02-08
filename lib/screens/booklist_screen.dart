import 'dart:convert';
import 'dart:io';
import 'dart:developer';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '/commons/base_screen.dart';
import '/commons/widgets.dart';
import '/controllers/epub_controller.dart';
import '/controllers/booklist_controller.dart';
import '/models/book_data.dart';
import '/models/epub_data.dart';
import '/screens/browser_screen.dart';
import '/screens/viewer_screen.dart';
import '/screens/settings_screen.dart';
import '/constants.dart';
import '/controllers/epub_controller.dart';

/// BookScreen
class BookListScreen extends BaseScreen {
  bool isCheckBox = true;
  String datadir = '';
  double _width = 400.0;
  double _height = 800.0;

  GlobalKey webViewKey1 = GlobalKey();
  InAppWebViewController? webViewController1;

  @override
  Future init() async {
    String appdir = (await getApplicationDocumentsDirectory()).path;
    if (!Platform.isIOS && !Platform.isAndroid) {
      appdir = appdir + '/test';
    }
    datadir = appdir + '/book';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    super.build(context, ref);
    ref.watch(epubProvider);

    _width = MediaQuery.of(context).size.width;
    _height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: MyText(l10n('home'), noScale: true),
        leading: IconButton(
          onPressed: () async {
            ref.watch(booklistProvider).readBookList();
          },
          icon: Icon(Icons.refresh),
        ),
        actions: [dropdownFlag(), SizedBox(width: 20)],
      ),
      body: SafeArea(
        child: Stack(children: [
          Container(
            padding: DEF_MENU_PADDING,
            child: ref.watch(epubProvider).downloadCtrl.browser8(),
          ),
          Container(
            color: myTheme.scaffoldBackgroundColor,
            padding: DEF_MENU_PADDING,
            child: RefreshIndicator(
              onRefresh: () async {
                ref.watch(booklistProvider).readBookList();
              },
              child: getList(),
            ),
          ),
          downloadBar(),
        ]),
      ),
    );
  }

  Widget getList() {
    List<BookData> bookList1 = ref.watch(booklistProvider).bookList;
    if (bookList1.length <= 0) return Container();
    if (ref.watch(booklistProvider).isReading) return Container();

    List<BookData> bookList = [];
    for (BookData b in bookList1) {
      if (selectedFlag == 0) {
        bookList.add(b);
      } else {
        if (selectedFlag == b.prop.flag) {
          bookList.add(b);
        }
      }
    }
    bookList.sort((a, b) {
      return b.prop.atime.compareTo(a.prop.atime) > 0 ? 1 : -1;
    });

    return ListView.builder(
      itemCount: bookList.length,
      itemBuilder: (BuildContext context, int index) {
        bool isAddDownload = false;
        String type = bookList[index].bookId.substring(0, 1);
        if (type == 'K' || type == 'N' || type == 'T') isAddDownload = true;

        return Slidable(
          dragStartBehavior: DragStartBehavior.start,
          key: UniqueKey(),
          child: MyBookListTile(
            data: bookList[index],
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
                      bookList[index].prop.flag = ret;
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
              if (isAddDownload)
                SlidableAction(
                  onPressed: (_) {
                    okDialog(msg: l10n('check_addition')).then((ret) {
                      if (ret) {
                        AddDownload(bookList[index]);
                      }
                    });
                  },
                  backgroundColor: Colors.blueAccent,
                  icon: Icons.download,
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
        List<Widget> list = [];
        for (int i = 0; i < getIconList(28).length; i++) {
          list.add(
            IconButton(
              icon: getIconList(28)[i],
              padding: EdgeInsets.all(4),
              onPressed: () {
                ret = i;
                Navigator.of(context).pop();
              },
            ),
          );
        }
        Widget e = Expanded(child: SizedBox(width: 1));
        Widget w = SizedBox(width: 4);
        Widget w1 = Row(children: [e, list[0], e]);
        Widget w2 = Row(children: [e, list[1], w, list[2], w, list[3], e]);
        Widget w3 = Row(children: [e, list[4], w, list[5], w, list[6], e]);
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          shape: RoundedRectangleBorder(borderRadius: DEF_BORDER_RADIUS),
          titlePadding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          contentPadding: EdgeInsets.all(0.0),
          actionsPadding: EdgeInsets.fromLTRB(8, 16, 8, 16),
          buttonPadding: EdgeInsets.all(0.0),
          iconPadding: EdgeInsets.all(0.0),
          backgroundColor: myTheme.cardColor,
          title: Text(l10n('flag_changes'), style: myTheme.textTheme.bodyMedium!),
          actions: [w1, w2, w3],
        );
      },
    );
    return ret;
  }

  int selectedFlag = 0;

  List<Icon> getIconList(double size) {
    List<Icon> list = [];
    list.add(Icon(Icons.circle_outlined, size: size));
    list.add(Icon(Icons.circle, color: COL_FLAG1, size: size));
    list.add(Icon(Icons.circle, color: COL_FLAG2, size: size));
    list.add(Icon(Icons.circle, color: COL_FLAG3, size: size));
    list.add(Icon(Icons.circle, color: COL_FLAG4, size: size));
    list.add(Icon(Icons.circle, color: COL_FLAG5, size: size));
    list.add(Icon(Icons.circle, color: COL_FLAG6, size: size));
    return list;
  }

  Widget dropdownFlag() {
    List<DropdownMenuItem> list = [];
    for (int i = 0; i < getIconList(ICON_BUTTON_SIZE).length; i++) {
      list.add(
        DropdownMenuItem<int>(value: i, child: getIconList(ICON_BUTTON_SIZE)[i]),
      );
    }

    return DropdownButton(
      items: list,
      value: selectedFlag,
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

  Widget MyBookListTile({
    required BookData data,
    Function()? onPressed,
  }) {
    Widget e = Expanded(child: SizedBox(width: 1, height: 1));
    Widget w = SizedBox(width: 6);
    Icon icon = Icon(Icons.arrow_forward_ios, size: 14.0);

    int prog = 0;
    if (data.prop.nowChars > 0 && data.prop.maxChars > 100) {
      prog = (data.prop.nowChars * 100 / data.prop.maxChars).toInt();
    }
    Widget flagIcon = Container(width: 16);
    if (1 <= data.prop.flag && data.prop.flag <= 6) {
      flagIcon = Icon(Icons.circle, size: 16.0, color: COL_FLAG_LIST[data.prop.flag]);
    }

    double scale = myTextScale;
    double height = 40 + ((14 + 14) * scale);
    double hr = (data.title.length + 5) * 14 * scale / (_width * 3 / 5);
    if (hr >= 1.0) {
      if (hr > 3) hr = 3.0;
      height += (14 * scale) * hr;
    }

    Widget wTitle = Text(
      data.title,
      overflow: TextOverflow.ellipsis,
      maxLines: 3,
      textScaler: TextScaler.linear(scale),
    );

    Widget wProg = Text(
      '${prog}%',
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      textScaler: TextScaler.linear(myTextScale - 0.2),
    );

    Widget wPages = Text(
      '${(data.chars / CHARS_PAGE).toInt()} ${l10n('page')}',
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      textScaler: TextScaler.linear(myTextScale - 0.2),
    );

    Widget wNumIndex = Text(
      '${(data.index.list.length - 1).toInt()} ${l10n('episode')}',
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      textScaler: TextScaler.linear(myTextScale - 0.2),
    );

    bool isKakuyomu = false;
    String type = data.bookId.substring(0, 1);
    if (type == 'K' || type == 'N' || type == 'T') isKakuyomu = true;

    Widget wAuthor = Text(
      '${data.author}',
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      textScaler: TextScaler.linear(myTextScale - 0.2),
      textAlign: TextAlign.left,
    );

    Widget wAuthorRow = Row(children: [
      wAuthor,
      SizedBox(width: 20),
      isKakuyomu ? wNumIndex : wPages,
    ]);

    Widget child = Row(children: [
      SizedBox(width: 4),
      Column(children: [
        Expanded(flex: 1, child: SizedBox(height: 1)),
        flagIcon,
        Expanded(flex: 2, child: SizedBox(height: 1)),
      ]),
      SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [e, wTitle, wAuthorRow, e],
        ),
      ),
      w,
      Column(children: [e, wProg, e]),
      w,
      icon,
    ]);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: myTheme.cardColor,
        border: Border(
          top: BorderSide(color: myTheme.dividerColor, width: 0.3),
          bottom: BorderSide(color: myTheme.dividerColor, width: 0.3),
        ),
      ),
      child: TextButton(
        child: child,
        onPressed: onPressed,
      ),
    );
  }

  Future AddDownload(BookData data) async {
    await ref.watch(epubProvider).checkUri(data.dluri);
  }

  @override
  Future onDownloadFinished() async {
    ref.watch(booklistProvider).readBookList();
  }
}
