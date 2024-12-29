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
  List<BookData> bookList = [];
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
    this.bookList = ref.watch(booklistProvider).bookList;

    return Scaffold(
      appBar: AppBar(
        title: MyText('Home'),
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
    if (bookList.length <= 0) return Container();

    return ListView.builder(
      itemCount: bookList.length,
      itemBuilder: (BuildContext context, int index) {
        final message = bookList[index];
        return Slidable(
          dragStartBehavior: DragStartBehavior.start,
          key: UniqueKey(),
          child: MyBookTile(
            title1: MyText(bookList[index].title),
            onPressed: () {
              var screen = ViewerScreen(book: bookList[index]);
              NavigatorPush(screen);
            },
          ),
          startActionPane: ActionPane(
            extentRatio: 0.2,
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                onPressed: (_) {},
                backgroundColor: Colors.blue,
                //foregroundColor: AppColor.backgroundColor,
                //icon: AppIcon.draftsOutlined,
                label: '',
              )
            ],
          ),
          endActionPane: ActionPane(
            extentRatio: 0.2,
            motion: const StretchMotion(),
            children: [
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
                backgroundColor: Colors.red,
                //foregroundColor: AppColor.backgroundColor,
                icon: Icons.delete,
                label: null,
              ),
            ],
          ),
        );
      },
    );
  }
}
