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

enum BottomBarType {
  none,
  tocBar,
  bottomBar,
  settingsBar,
  clipTextBar,
  clipListBar,
}

class ViewerScreen extends BaseScreen {
  ViewerScreen({required BookData this.book}) {}

  BookData book;

  bool isLoading = false;

  final GlobalKey settingsFlushbarKey = GlobalKey();
  bool isSettingsBar = false;

  final GlobalKey tocFlushbarKey = GlobalKey();
  bool isTocFlushbar = false;
  bool isTocFlushbarInit = false;
  bool isTopBottomBar = false;
  BottomBarType bottomBarType = BottomBarType.none;

  bool isAppBar = true;

  double _width = 1000.0;
  double _widthPad = Platform.isIOS ? 100.0 : 50;
  double _height = 1000.0;
  double _heightPad = Platform.isIOS ? 200.0 : 50;

  @override
  Future init() async {
    reload();
  }

  bool isActionBar() {
    return bottomBarType == BottomBarType.bottomBar ||
        bottomBarType == BottomBarType.settingsBar ||
        bottomBarType == BottomBarType.clipTextBar;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double oldWidth = _width;
    _width = MediaQuery.of(context).size.width;
    if (_width != oldWidth) {
      log('width ${_width.toInt()}');
      ref.read(viewerProvider).width = _width;
    }

    double oldHeight = _height;
    _height = MediaQuery.of(context).size.height;
    myTheme.appBarTheme.toolbarHeight;
    if (_height != oldHeight) {
      log('height ${_height.toInt()}');
      ref.read(viewerProvider).height = _height;
    }

    super.build(context, ref);
    ref.watch(viewerProvider);
    ref.watch(stateProvider);

    if (ref.watch(viewerProvider).changeedClipText) {
      ref.watch(viewerProvider).changeedClipText = false;
      bottomBarType = BottomBarType.clipTextBar;
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
            if (isActionBar()) SizedBox(width: 10),
            if (isActionBar())
              IconButton(
                icon: Icon(Icons.list),
                onPressed: () {
                  bottomBarType = BottomBarType.tocBar;
                  redraw();
                },
              ),
          ],
        ),
        title: (isActionBar() == false) ? MyText('${book.title}') : null,
        actions: [
          if (isActionBar())
            IconButton(
              icon: Icon(Icons.article),
              onPressed: () {
                bottomBarType = BottomBarType.clipListBar;
                redraw();
              },
            ),
          if (isActionBar()) SizedBox(width: 10),
          if (isActionBar())
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () => ref.read(viewerProvider).find(0, '写真'),
            ),
          if (isActionBar()) SizedBox(width: 10),
          if (isActionBar())
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                bottomBarType = BottomBarType.settingsBar;
                redraw();
              },
            ),
          if (isActionBar()) SizedBox(width: 10)
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
                          //scrollRight();
                        } else if (dx > _width - 120) {
                          //scrollLeft();
                        } else {
                          if (bottomBarType != BottomBarType.bottomBar) {
                            bottomBarType = BottomBarType.bottomBar;
                            redraw();
                          } else {
                            bottomBarType = BottomBarType.none;
                            redraw();
                          }
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
          tocBar(),
          bottomBar(),
          clipTextBar(),
          settingsBar(),
          clipListBar(),
        ]),
      ),
    );
  }

  Widget Widget1() {
    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
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
    double barHeight = 80;
    double ffBottom = -1.0 * barHeight;
    if (bottomBarType == BottomBarType.bottomBar) {
      ffBottom = 0;
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 100),
      curve: Curves.linear,
      left: 0,
      top: null,
      right: 0,
      bottom: ffBottom,
      height: barHeight,
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

  Widget clipTextBar() {
    double barHeight = 200;
    double ffBottom = -1.0 * barHeight;
    if (bottomBarType == BottomBarType.clipTextBar) {
      ffBottom = 0;
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.linear,
      left: 0,
      top: null,
      right: 0,
      bottom: ffBottom,
      height: barHeight,
      child: clipTextBar1(),
    );
  }

  Widget clipTextBar1() {
    String text = ref.watch(viewerProvider).clipText;
    return Container(
      color: myTheme.scaffoldBackgroundColor,
      child: Column(
        children: [
          SizedBox(height: 1, child: Container(color: myTheme.dividerColor)),
          closeButtonRow(),
          MyTextButton(
            title: l10n('save'),
            width: 120,
            onPressed: () async {
              saveDialog().then((ret) {
                if (ret) {
                  ref.read(viewerProvider).saveClip(text);
                }
              });
            },
          ),
          Expanded(child: Text(text, overflow: TextOverflow.clip)),
        ],
      ),
    );
  }

  IconButton closeButton() {
    return IconButton(
      icon: Icon(Icons.close),
      iconSize: 18,
      onPressed: () async {
        bottomBarType = BottomBarType.none;
        redraw();
      },
    );
  }

  Widget closeButtonRow() {
    return Row(children: [
      closeButton(),
      Expanded(flex: 1, child: SizedBox(width: 1)),
      closeButton(),
    ]);
  }

  Widget settingsBar() {
    double barHeight = 280;
    double ffBottom = -1.0 * barHeight;
    if (bottomBarType == BottomBarType.settingsBar) {
      ffBottom = 0;
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
      left: 0,
      top: null,
      right: 0,
      bottom: ffBottom,
      height: barHeight,
      child: settingsBar1(),
    );
  }

  Widget settingsBar1() {
    return Container(
      decoration: BoxDecoration(
        color: myTheme.cardColor,
        borderRadius: DEF_BORDER_RADIUS,
        border: Border.all(color: myTheme.dividerColor),
      ),
      child: Column(
        children: [
          closeButtonRow(),
          Row(children: [
            Expanded(flex: 1, child: SizedBox(width: 1)),
            IconButton(
              icon: Icon(Icons.remove),
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
            IconButton(
              icon: Icon(Icons.add),
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

  Widget tocBar() {
    double barHeight = _height / 2;
    double ffBottom = -1.0 * barHeight;
    if (bottomBarType == BottomBarType.tocBar) {
      ffBottom = 0;
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.linear,
      left: 0,
      top: null,
      right: 0,
      bottom: ffBottom,
      height: barHeight,
      child: tocBar1(),
    );
  }

  Widget tocBar1() {
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

    return Container(
      decoration: BoxDecoration(
        color: myTheme.cardColor,
        borderRadius: DEF_BORDER_RADIUS,
        border: Border.all(color: myTheme.dividerColor),
      ),
      child: Column(
        children: [
          closeButtonRow(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: list),
            ),
          ),
        ],
      ),
    );
  }

  Widget clipListBar() {
    double barHeight = _height / 2;
    double ffBottom = -1.0 * barHeight;
    if (bottomBarType == BottomBarType.clipListBar) {
      ffBottom = 0;
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.linear,
      left: 0,
      top: null,
      right: 0,
      bottom: ffBottom,
      height: barHeight,
      child: clipListBar1(),
    );
  }

  Widget clipListBar1() {
    BookClipData d = ref.watch(viewerProvider).readClip();

    List<Widget> list = [];
    for (int i = 0; i < d.list.length; i++) {
      list.add(
        Text(d.list[i].text, overflow: TextOverflow.clip),
      );
    }
    if (list.length == 0) return Container();
    return Container(
      decoration: BoxDecoration(
        color: myTheme.cardColor,
        borderRadius: DEF_BORDER_RADIUS,
        border: Border.all(color: myTheme.dividerColor),
      ),
      child: Column(
        children: [
          closeButtonRow(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: list),
            ),
          ),
        ],
      ),
    );
  }
}
