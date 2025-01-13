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
import '/screens/settings_screen.dart';

final stateProvider = ChangeNotifierProvider((ref) => stateNotifier(ref));

class stateNotifier extends ChangeNotifier {
  stateNotifier(ref) {}
  List<double> listWidth = [];
}

class ViewerScreen extends BaseScreen with WidgetsBindingObserver {
  ViewerScreen({required BookData this.book}) {}

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
  double _height = 1000.0;

  bool isActionBar() {
    return ref.watch(viewerProvider).isActionBar();
  }

  @override
  Future init() async {
    reload();
    if (Platform.isAndroid || Platform.isIOS) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (Platform.isAndroid || Platform.isIOS) {
      if (state == AppLifecycleState.inactive) {
        log('inactive'); // no
      } else if (state == AppLifecycleState.resumed) {
        log('resumed');
      } else if (state == AppLifecycleState.paused) {
        log('paused');
      } else if (state == AppLifecycleState.detached) {
        log('detached');
      }
    }
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

    return Scaffold(
      backgroundColor: env.getBackColor(),
      body: SafeArea(
        child: Stack(children: [
          Container(
            padding: env.writing_mode.val == 0 ? DEF_VIEW_PADDING_TB : DEF_VIEW_PADDING_RL,
            color: env.getBackColor(),
            child: Widget1(),
          ),
          if (ref.watch(viewerProvider).isLoading) loadingWidget(),
          if (ref.watch(viewerProvider).bottomBarType != ViewerBottomBarType.clipTextBar)
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
                            if (ref.watch(viewerProvider).bottomBarType !=
                                ViewerBottomBarType.actionBar) {
                              ref.watch(viewerProvider).bottomBarType =
                                  ViewerBottomBarType.actionBar;
                              redraw();
                            } else {
                              ref.watch(viewerProvider).bottomBarType = ViewerBottomBarType.none;
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
          topBar(),
          bottomBar(),
          bookmarkBar(),
          tocBar(),
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
        top: _height / 5,
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

  Widget actionRow() {
    double pad = 12.0;
    return Row(children: [
      SizedBox(width: 4),
      IconButton(
        iconSize: 20,
        icon: Icon(Icons.arrow_back_ios_new),
        onPressed: () => Navigator.of(context).pop(),
      ),
      if (isActionBar()) SizedBox(width: pad),
      if (isActionBar())
        IconButton(
          icon: Icon(Icons.list),
          onPressed: () {
            ref.watch(viewerProvider).bottomBarType = ViewerBottomBarType.tocBar;
            redraw();
          },
        ),
      Expanded(child: SizedBox(width: 1)),
      if (isActionBar())
        IconButton(
          icon: Icon(Icons.bookmark),
          onPressed: () {
            if (ref.watch(viewerProvider).bottomBarType == ViewerBottomBarType.bookmarkBar) {
              ref.watch(viewerProvider).bottomBarType = ViewerBottomBarType.none;
            } else {
              ref.watch(viewerProvider).bottomBarType = ViewerBottomBarType.bookmarkBar;
            }
            redraw();
          },
        ),
      if (isActionBar()) SizedBox(width: pad),
      if (isActionBar())
        IconButton(
          icon: Icon(Icons.edit),
          onPressed: () {
            if (ref.watch(viewerProvider).bottomBarType == ViewerBottomBarType.clipTextBar) {
              ref.watch(viewerProvider).bottomBarType = ViewerBottomBarType.none;
            } else {
              ref.watch(viewerProvider).bottomBarType = ViewerBottomBarType.clipTextBar;
            }
            redraw();
          },
        ),
      if (isActionBar()) SizedBox(width: pad),
      if (isActionBar())
        IconButton(
          icon: Icon(Icons.article),
          onPressed: () {
            ref.watch(viewerProvider).bottomBarType = ViewerBottomBarType.clipListBar;
            redraw();
          },
        ),
      if (isActionBar()) SizedBox(width: pad),
      if (isActionBar())
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: () {
            ref.watch(viewerProvider).bottomBarType = ViewerBottomBarType.settingsBar;
            redraw();
          },
        ),
      if (isActionBar()) SizedBox(width: pad)
    ]);
  }

  Widget topBar() {
    double barHeight = 80;
    double ffTop = -40;
    if (isActionBar()) {
      ffTop = 0;
    }

    Widget wText = Text(
      ref.watch(viewerProvider).getTitle(),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      textAlign: TextAlign.center,
      textScaler: TextScaler.linear(0.9),
    );

    Widget topBar1 = Container(
      color: myTheme.scaffoldBackgroundColor,
      child: Column(
        children: [
          Expanded(child: SizedBox(height: 1)),
          if (isActionBar()) actionRow(),
          Row(children: [
            SizedBox(width: 4),
            Expanded(child: wText),
            SizedBox(width: 4),
          ]),
          SizedBox(height: 8),
        ],
      ),
    );

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 100),
      curve: Curves.linear,
      left: 0,
      top: ffTop,
      right: 0,
      bottom: null,
      height: barHeight,
      child: topBar1,
    );
  }

  Widget bottomBar() {
    double barHeight = 30;
    double ffBottom = 0;

    String progress = ref.watch(viewerProvider).getProgress();
    Widget wText = Text(
      progress,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      textScaler: TextScaler.linear(0.9),
    );

    Widget bar = Container(
      color: myTheme.scaffoldBackgroundColor,
      child: Column(
        children: [
          SizedBox(height: 8),
          wText,
          Expanded(child: SizedBox(height: 1)),
        ],
      ),
    );

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 100),
      curve: Curves.linear,
      left: 0,
      top: null,
      right: 0,
      bottom: ffBottom,
      height: barHeight,
      child: bar,
    );
  }

  Widget bookmarkBar() {
    double barHeight = 300;
    double ffBottom = -1.0 * barHeight;
    if (ref.watch(viewerProvider).bottomBarType == ViewerBottomBarType.bookmarkBar) {
      ffBottom = 0;
    }

    double pad = (_width - 290) / 2;
    String nowPage = ref.watch(viewerProvider).getNowPage();
    String maxPage = ref.watch(viewerProvider).getMaxPage();
    Widget wNow = Row(children: [
      SizedBox(width: pad),
      MyText(l10n('nowpage')),
      Expanded(child: SizedBox(width: 1)),
      MyText(nowPage),
      SizedBox(width: pad),
    ]);
    Widget wMax = Row(children: [
      SizedBox(width: pad),
      MyText(l10n('maxpage')),
      Expanded(child: SizedBox(width: 1)),
      MyText(maxPage),
      SizedBox(width: pad),
    ]);

    Widget bar = Container(
      color: myTheme.cardColor,
      child: Column(
        children: [
          closeButtonRow(),
          wNow,
          SizedBox(height: 8),
          wMax,
          SizedBox(height: 12),
          MyTextButton(
            //noScale: true,
            title: l10n('move_maxpage'),
            width: 280,
            onPressed: () async {
              okDialog().then((ret) {
                if (ret) {
                  ref.watch(viewerProvider).moveMaxpage();
                }
              });
            },
          ),
          SizedBox(height: 8),
          MyTextButton(
              //noScale: true,
              title: l10n('reset_maxpage'),
              width: 280,
              onPressed: () async {
                okDialog().then((ret) {
                  if (ret) {
                    ref.read(viewerProvider).resetMaxpage();
                    redraw();
                  }
                });
              }),
          Expanded(child: SizedBox(height: 1)),
        ],
      ),
    );

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 100),
      curve: Curves.linear,
      left: 0,
      top: null,
      right: 0,
      bottom: ffBottom,
      height: barHeight,
      child: bar,
    );
  }

  /// clipTextBar
  Widget clipTextBar() {
    double barHeight = 200;
    double ffBottom = -1.0 * barHeight;
    if (ref.watch(viewerProvider).bottomBarType == ViewerBottomBarType.clipTextBar) {
      ffBottom = 0;
    }

    Widget bar = Container(
      color: myTheme.cardColor,
      child: Column(
        children: [
          SizedBox(height: 1, child: Container(color: myTheme.dividerColor)),
          closeButtonRow(),
          Row(children: [
            Expanded(child: SizedBox(width: 1)),
            MyTextButton(
              noScale: true,
              title: l10n('cancel'),
              width: 140,
              onPressed: () async {
                ref.watch(viewerProvider).bottomBarType = ViewerBottomBarType.none;
                ref.watch(viewerProvider).clearFocus();
                redraw();
              },
            ),
            SizedBox(width: 16),
            MyTextButton(
              commit: true,
              title: l10n('save_selection'),
              width: 140,
              onPressed: () async {
                String? text = await ref.watch(viewerProvider).getSelectedText();
                if (text != null && text.length > 2) {
                  alertDialog('save').then((ret) {
                    if (ret) {
                      ref.read(viewerProvider).saveClip(text);
                    }
                  });
                } else {}
              },
            ),
            Expanded(child: SizedBox(width: 1)),
          ]),
          SizedBox(height: 8),
          Expanded(child: MyText(l10n('select_the_text'))),
        ],
      ),
    );

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.linear,
      left: 0,
      top: null,
      right: 0,
      bottom: ffBottom,
      height: barHeight,
      child: bar,
    );
  }

  @override
  Future onPressedCloseButton() async {
    ref.watch(viewerProvider).bottomBarType = ViewerBottomBarType.none;
    ref.watch(viewerProvider).clearFocus();
    redraw();
  }

  /// settingsBar
  Widget settingsBar() {
    double barHeight = 350;
    double ffBottom = -1.0 * barHeight;
    if (ref.watch(viewerProvider).bottomBarType == ViewerBottomBarType.settingsBar) {
      ffBottom = 0;
    }

    List<Widget> list = [];
    list.add(closeButtonRow());
    list.add(MySettingsTile(data: env.font_size));
    list.add(MySettingsTile(data: env.back_color));
    list.add(MySettingsTile(data: env.writing_mode));
    list.add(MySettingsTile(data: env.font_family));
    //list.add(MySettingsTile(data: env.line_height));
    Widget bar = Container(
      color: myTheme.cardColor,
      child: Column(children: list),
    );

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      curve: Curves.linear,
      left: 0,
      top: null,
      right: 0,
      bottom: ffBottom,
      height: barHeight,
      child: bar,
    );
  }

  @override
  onDropdownChanged() {
    reload();
  }

  Widget tocBar() {
    double barHeight = _height / 2;
    double ffBottom = -1.0 * barHeight;
    if (ref.watch(viewerProvider).bottomBarType == ViewerBottomBarType.tocBar) {
      ffBottom = 0;
    }
    List<Widget> list = [];

    for (int i = 0; i < book.indexList.length; i++) {
      int sum = 0;
      for (int j = 0; j <= i; j++) {
        sum += book.indexList[j].chars;
      }
      String txt = '${book.indexList[i].title}';
      String pages = '${(sum / 450).toInt()}';

      list.add(
        MyTocTile(
          title1: MyText(txt, maxLength: 24),
          title2: MyText(pages),
          onPressed: () {
            ref.read(viewerProvider).jumpToIndex(i, 0);
          },
        ),
      );
    }

    Widget bar = Container(
      color: myTheme.cardColor,
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

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.linear,
      left: 0,
      top: null,
      right: 0,
      bottom: ffBottom,
      height: barHeight,
      child: bar,
    );
  }

  Widget clipListBar() {
    double barHeight = _height * 2 / 3;
    double ffBottom = -1.0 * barHeight;
    if (ref.watch(viewerProvider).bottomBarType == ViewerBottomBarType.clipListBar) {
      ffBottom = 0;
    }

    BookClipData d = ref.watch(viewerProvider).readClip();

    List<Widget> list = [];
    for (int i = 0; i < d.list.length; i++) {
      list.add(
        MyClipListTile(
          text: d.list[i].text,
          onPressed: () {
            deleteDialog().then((ret) {
              if (ret) {
                ref.watch(viewerProvider).deleteClip(index: i);
              }
            });
          },
        ),
      );
    }
    if (list.length == 0) return Container();

    Widget bar = Container(
      color: myTheme.cardColor,
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

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.linear,
      left: 0,
      top: null,
      right: 0,
      bottom: ffBottom,
      height: barHeight,
      child: bar,
    );
  }
}
