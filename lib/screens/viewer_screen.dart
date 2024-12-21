import 'dart:developer';
import 'dart:io';
import 'dart:convert';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '/commons/base_screen.dart';
import '/commons/widgets.dart';
import '/models/book_data.dart';
import '/models/epub_data.dart';
import '/controllers/viewer_controller.dart';
import '/controllers/env_controller.dart';

final stateProvider = ChangeNotifierProvider((ref) => stateNotifier(ref));

class stateNotifier extends ChangeNotifier {
  stateNotifier(ref) {}
  List<double> listWidth = [];
}

class ViewerScreen extends BaseScreen {
  ViewerScreen({required BookData this.book});

  BookData book;

  bool isLoading = false;

  final GlobalKey settingsFlushbarKey = GlobalKey();
  bool isSettingsBar = false;

  final GlobalKey tocFlushbarKey = GlobalKey();
  bool isTocFlushbar = false;
  bool isTocFlushbarInit = false;
  bool isTopBottomBar = false;

  bool isAppBar = true;

  double _width = 1000.0;
  double _widthPad = Platform.isIOS ? 100.0 : 50;
  double _height = 1000.0;
  double _heightPad = Platform.isIOS ? 200.0 : 50;

  @override
  Future init() async {
    await reload();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    super.build(context, ref);
    ref.watch(viewerProvider);
    ref.watch(stateProvider);

    double oldWidth = _width;
    _width = MediaQuery.of(context).size.width;
    if (_width != oldWidth) {
      log('width ${_width}');
      ref.read(viewerProvider).width = _width;
    }

    double oldHeight = _height;
    _height = MediaQuery.of(context).size.height;
    myTheme.appBarTheme.toolbarHeight;
    if (_height != oldHeight) {
      log('height ${_height}');
      ref.read(viewerProvider).height = _height;
    }

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 120,
        leading: Row(
          children: [
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.of(context).pop(),
            ),
            if (isTopBottomBar) SizedBox(width: 10),
            if (isTopBottomBar)
              IconButton(
                icon: Icon(Icons.list),
                onPressed: () => tocBar(),
              ),
          ],
        ),
        title: (isTopBottomBar == false) ? MyText('${book.title}') : null,
        actions: [
          if (isTopBottomBar)
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () => settingsBar(),
            ),
          if (isTopBottomBar) SizedBox(width: 10)
        ],
      ),
      body: SafeArea(
        child: Stack(children: [
          Container(
            padding: env.writing_mode.val == 0 ? DEF_VIEW_PADDING_TB : DEF_VIEW_PADDING_RL,
            color: Color(env.getBack32Color()),
            child: Widget1(),
          ),
          if (ref.watch(viewerProvider).isLoading) loadingWidget(),
          topBar(),
          bottomBar(),
          Container(
            padding: EdgeInsets.fromLTRB(1, 1, 1, 1),
            child: RawGestureDetector(
              behavior: HitTestBehavior.translucent,
              gestures: {
                TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                  () => TapGestureRecognizer(),
                  (TapGestureRecognizer instance) {
                    instance
                      ..onTapUp = (TapUpDetails details) {
                        double dx = details.globalPosition.dx;
                        if (dx < 120) {
                          scrollRight();
                        } else if (dx > _width - 120) {
                          scrollLeft();
                        } else {
                          isTopBottomBar = !isTopBottomBar;
                          redraw();
                        }
                      }
                      ..onTapDown = (TapDownDetails details) {}
                      ..onTap = () {}
                      ..onTapCancel = () {};
                  },
                ),
              },
              child: Container(),
            ),
          ),
          settingsWidget(),
        ]),
      ),
    );
  }

  Widget Widget1() {
    return ref.read(viewerProvider).viewer(env);
  }

  Widget loadingWidget() {
    return Stack(children: [
      Container(color: myTheme.scaffoldBackgroundColor),
      Positioned(
        top: 140,
        left: 0,
        right: 0,
        child: Icon(
          Icons.refresh,
          size: 48,
        ),
      ),
    ]);
  }

  scrollRight() {
    ref.read(viewerProvider).scrollRight();
  }

  scrollLeft() {
    ref.read(viewerProvider).scrollLeft();
  }

  Future reload() async {
    ref.read(viewerProvider).load(env, book, _width, _height);
  }

  Widget topBar() {
    return Container();
    double settingsHeight = 60;
    double ffBottom = 0;
    if (isTopBottomBar == false) {
      ffBottom = -1.0 * settingsHeight;
    } else {
      ffBottom = 0;
    }
    if (isTocFlushbar == true) ffBottom = 0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 100),
      curve: Curves.linear,
      left: 0,
      top: ffBottom,
      right: 0,
      bottom: null,
      height: settingsHeight,
      child: topBar1(),
    );
  }

  Widget topBar1() {
    String title = ref.watch(viewerProvider).getTitle();
    String subTitle = ref.watch(viewerProvider).getSubTitle();
    return Container(
      color: myTheme.scaffoldBackgroundColor,
      child: Column(
        children: [
          SizedBox(height: 1),
          MyText(title),
          SizedBox(height: 4),
          MyText(subTitle),
          Expanded(child: SizedBox(height: 1)),
          SizedBox(height: 1, child: Container(color: myTheme.dividerColor)),
        ],
      ),
    );
  }

  Widget bottomBar() {
    double bottomBarHeight = 80;
    double ffBottom = 0;
    if (isTopBottomBar == false) {
      ffBottom = -1.0 * bottomBarHeight;
    } else {
      ffBottom = 0;
    }
    if (isTocFlushbar == true) ffBottom = 0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 100),
      curve: Curves.linear,
      left: 0,
      top: null,
      right: 0,
      bottom: ffBottom,
      height: bottomBarHeight,
      child: bottomBar1(),
    );
  }

  Widget bottomBar1() {
    String title = ref.watch(viewerProvider).getTitle();
    String subTitle = ref.watch(viewerProvider).getSubTitle();
    String progress = ref.watch(viewerProvider).getProgress();
    return Container(
      color: myTheme.scaffoldBackgroundColor,
      child: Column(
        children: [
          SizedBox(height: 1, child: Container(color: myTheme.dividerColor)),
          SizedBox(height: 8),
          //Row(children: [
          //Expanded(flex: 1, child: SizedBox(width: 1)),
          MyText(title),
          MyText(subTitle),
          MyText(progress),
          //Expanded(flex: 1, child: SizedBox(width: 1)),
          //]),
          Expanded(child: SizedBox(height: 1)),
        ],
      ),
    );
  }

  void settingsBar() {
    isSettingsBar = !isSettingsBar;
    redraw();
  }

  Widget settingsWidget() {
    double settingsHeight = 300;
    double ffBottom = 0;
    if (isSettingsBar == false) {
      ffBottom = -1.0 * settingsHeight;
    } else {
      ffBottom = 0;
    }
    if (isTocFlushbar == true) ffBottom = -1.0 * settingsHeight;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 100),
      curve: Curves.linear,
      left: 1,
      top: null,
      right: 1,
      bottom: ffBottom,
      height: settingsHeight,
      child: settingsWidget1(),
    );
  }

  Widget settingsWidget1() {
    return Container(
      decoration: BoxDecoration(
        color: myTheme.cardColor,
        borderRadius: DEF_BORDER_RADIUS,
        border: Border.all(color: myTheme.dividerColor),
      ),
      child: Column(
        children: [
          Row(children: [
            IconButton(
              icon: Icon(Icons.close),
              iconSize: 20,
              onPressed: () async {
                isSettingsBar = false;
                redraw();
              },
            ),
            Expanded(flex: 1, child: SizedBox(width: 1)),
            IconButton(
              icon: Icon(Icons.close),
              iconSize: 20,
              onPressed: () async {
                isSettingsBar = false;
                redraw();
              },
            ),
          ]),
          Row(children: [
            Expanded(flex: 1, child: SizedBox(width: 1)),
            MyIconButton(
              icon: Icons.remove,
              iconSize: 20,
              onPressed: () async {
                env.font_size.val -= 2;
                if (env.font_size.val < 10) env.font_size.val = 10;
                ref.read(envProvider).save();
                reload();
              },
            ),
            SizedBox(width: 16),
            MyText('${env.font_size.val}'),
            SizedBox(width: 16),
            MyIconButton(
              icon: Icons.add,
              iconSize: 20,
              onPressed: () async {
                env.font_size.val += 2;
                if (env.font_size.val > 32) env.font_size.val = 32;
                ref.read(envProvider).save();
                reload();
              },
            ),
            Expanded(flex: 1, child: SizedBox(width: 1)),
          ]),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(flex: 1, child: SizedBox(width: 1)),
              MyTextButton(
                title: l10n('sans_serif'),
                width: 120,
                onPressed: () async {
                  env.font_family.val = 0;
                  ref.read(envProvider).save();
                  reload();
                },
              ),
              SizedBox(width: 20),
              MyTextButton(
                title: l10n('serif'),
                width: 120,
                onPressed: () async {
                  env.font_family.val = 1;
                  ref.read(envProvider).save();
                  reload();
                },
              ),
              Expanded(flex: 1, child: SizedBox(width: 1)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(flex: 1, child: SizedBox(width: 1)),
              MyTextButton(
                title: l10n('horizontal-tb'),
                width: 120,
                onPressed: () async {
                  env.writing_mode.val = 0;
                  ref.read(envProvider).save();
                  reload();
                },
              ),
              SizedBox(width: 20),
              MyTextButton(
                title: l10n('vertical-rl'),
                width: 120,
                onPressed: () async {
                  env.writing_mode.val = 1;
                  ref.read(envProvider).save();
                  reload();
                },
              ),
              Expanded(flex: 1, child: SizedBox(width: 1)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(flex: 1, child: SizedBox(width: 1)),
              IconButton(
                icon: Icon(Icons.rectangle, color: COL_LIGHT_CARD),
                onPressed: () async {
                  env.back_color.val = 0;
                  ref.read(envProvider).save();
                  reload();
                },
              ),
              SizedBox(width: 10),
              IconButton(
                icon: Icon(Icons.rectangle, color: COL_DARK_CARD),
                onPressed: () async {
                  env.back_color.val = 1;
                  ref.read(envProvider).save();
                  reload();
                },
              ),
              SizedBox(width: 10),
              IconButton(
                icon: Icon(Icons.rectangle, color: COL_DARK_BACK),
                onPressed: () async {
                  env.back_color.val = 2;
                  ref.read(envProvider).save();
                  reload();
                },
              ),
              Expanded(flex: 1, child: SizedBox(width: 1)),
            ],
          ),
        ],
      ),
    );
  }

  tocBar() {
    if (isTocFlushbar == true) return;
    isSettingsBar = false;
    List<Widget> list = [];

    for (int i = 0; i < book.indexList.length; i++) {
      int sum = 0;
      for (int j = 0; j <= i; j++) {
        sum += book.indexList[j].chars;
      }
      String txt = '${book.indexList[i].title}  ${sum} chars';

      list.add(
        MyListTile(
          title1: MyText(txt),
          onPressed: () {
            ref.read(viewerProvider).jumpToIndex(i, 0);
          },
        ),
      );
    }

    Widget sw = Container(
      width: 300,
      height: _height / 2,
      child: SingleChildScrollView(
        child: Column(children: list),
      ),
    );

    return Flushbar(
      borderColor: myTheme.textTheme.bodyMedium!.color!,
      backgroundColor: myTheme.scaffoldBackgroundColor,
      key: tocFlushbarKey,
      titleText: MyText('-'),
      messageText: sw,
      onStatusChanged: (FlushbarStatus? status) {
        if (status == null) return;
        switch (status) {
          case FlushbarStatus.SHOWING:
          case FlushbarStatus.IS_APPEARING:
            isTocFlushbar = true;
            break;
          case FlushbarStatus.IS_HIDING:
          case FlushbarStatus.DISMISSED:
            isTocFlushbar = false;
            break;
        }
      },
    ).show(context);
  }
}
