import 'dart:developer';
import 'dart:io';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/services.dart';

import '/commons/base_screen.dart';
import '/commons/widgets.dart';
import '/models/book_data.dart';
import '/constants.dart';
import '/controllers/viewer_controller.dart';
import '/controllers/env_controller.dart';
import '/controllers/viewlog_controller.dart';

final stateProvider = ChangeNotifierProvider((ref) => stateNotifier(ref));

class stateNotifier extends ChangeNotifier {
  stateNotifier(ref) {}
  List<double> listWidth = [];
}

class ViewerScreen extends BaseScreen with WidgetsBindingObserver {
  ViewerScreen({required BookData this.book}) {}

  BookData book;
  double _width = 1000.0;
  double _height = 1000.0;

  bool isActionBar() {
    return ref.watch(viewerProvider).isActionBar();
  }

  @override
  Future init() async {
    if (Platform.isAndroid || Platform.isIOS) {
      WidgetsBinding.instance.addObserver(this);
    }
    ref.read(viewerProvider).bottomBarType = ViewerBottomBarType.none;
    ref.read(viewerProvider).book = this.book;
    await reload();
    await startReadlog();
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
        startReadlog();
      } else if (state == AppLifecycleState.paused) {
        log('paused');
        endReadlog();
      } else if (state == AppLifecycleState.detached) {
        log('detached');
        endReadlog();
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

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        log('pop');
        endReadlog();
      },
      child: Scaffold(
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
                    TapGestureRecognizer:
                        GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
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
            maxpageBar(),
            tocBar(),
            clipTextBar(),
            settingsBar(),
            clipListBar(),
          ]),
        ),
      ),
    );
  }

  Widget Widget1() {
    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
    return ref.read(viewerProvider).viewer(env);
  }

  Widget loadingWidget() {
    //String txt = ref.read(viewerProvider).jumpStatusText;
    return Stack(children: [
      Container(color: env.getBackColor()),
      Positioned(
        top: _height / 5,
        left: 0,
        right: 0,
        child: Icon(
          Icons.refresh,
          size: 32,
          color: env.getFrontColor(),
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

  Future startReadlog() async {
    int nowChars = ref.watch(viewerProvider).nowChars;
    ref.watch(viewlogProvider).init(nowChars);
  }

  Future endReadlog() async {
    int nowChars = ref.watch(viewerProvider).nowChars;
    ref.watch(viewlogProvider).save(nowChars, book);
  }

  Widget actionRow() {
    double pad = 12.0;
    return Row(children: [
      SizedBox(width: 4),
      IconButton(
          icon: Icon(Icons.arrow_back_ios_new),
          color: env.getFrontColor(),
          onPressed: () {
            endReadlog();
            Navigator.of(context).pop();
          }),
      if (isActionBar()) SizedBox(width: pad),
      if (isActionBar())
        MyIconLabelButton(
          label: l10n('toc'),
          icon: Icon(Icons.list),
          color: env.getFrontColor(),
          onPressed: () {
            ref.watch(viewerProvider).bottomBarType = ViewerBottomBarType.tocBar;
            redraw();
          },
        ),
      Expanded(child: SizedBox(width: 1)),
      if (isActionBar())
        MyIconLabelButton(
          label: l10n('jump'),
          icon: Icon(Icons.bookmark_border_outlined),
          color: env.getFrontColor(),
          onPressed: () {
            if (ref.watch(viewerProvider).bottomBarType == ViewerBottomBarType.maxpageBar) {
              ref.watch(viewerProvider).bottomBarType = ViewerBottomBarType.none;
            } else {
              ref.watch(viewerProvider).bottomBarType = ViewerBottomBarType.maxpageBar;
            }
            redraw();
          },
        ),
      if (isActionBar() && IS_TEST == true) SizedBox(width: pad),
      if (isActionBar() && IS_TEST == true)
        MyIconLabelButton(
          label: l10n('copy'),
          icon: Icon(Icons.edit_outlined),
          color: env.getFrontColor(),
          onPressed: () {
            if (ref.watch(viewerProvider).bottomBarType == ViewerBottomBarType.clipTextBar) {
              ref.watch(viewerProvider).bottomBarType = ViewerBottomBarType.none;
            } else {
              ref.watch(viewerProvider).bottomBarType = ViewerBottomBarType.clipTextBar;
            }
            redraw();
          },
        ),
      if (isActionBar() && IS_TEST == true) SizedBox(width: pad),
      if (isActionBar() && IS_TEST == true)
        MyIconLabelButton(
          label: l10n('clip'),
          icon: Icon(Icons.article_outlined),
          color: env.getFrontColor(),
          onPressed: () {
            ref.watch(viewerProvider).bottomBarType = ViewerBottomBarType.clipListBar;
            redraw();
          },
        ),
      if (isActionBar()) SizedBox(width: pad),
      if (isActionBar())
        MyIconLabelButton(
          label: l10n('option'),
          icon: Icon(Icons.settings),
          color: env.getFrontColor(),
          onPressed: () {
            ref.watch(viewerProvider).bottomBarType = ViewerBottomBarType.settingsBar;
            redraw();
          },
        ),
      if (isActionBar()) SizedBox(width: pad)
    ]);
  }

  Widget topBar() {
    double barHeight = 70;
    double ffTop = -30;
    if (isActionBar()) {
      ffTop = 0;
    }

    Widget wText = Text(
      ref.watch(viewerProvider).getTitle(),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      textAlign: TextAlign.center,
      textScaler: TextScaler.linear(0.9),
      style: TextStyle(color: env.getFrontColor()),
    );

    Widget topBar1 = Container();
    if (isActionBar()) {
      // アクションバーのとき
      topBar1 = Container(
        color: env.getBackColor(),
        child: Column(
          children: [
            Expanded(flex: 1, child: SizedBox(height: 1)),
            actionRow(),
            Expanded(flex: 1, child: SizedBox(height: 1)),
          ],
        ),
      );
    } else {
      // タイトルのみのとき
      topBar1 = Container(
        color: env.getBackColor(),
        child: Column(
          children: [
            Expanded(child: SizedBox(height: 1)),
            Row(children: [
              SizedBox(width: 4),
              Expanded(child: wText),
              SizedBox(width: 4),
            ]),
            SizedBox(height: 6),
          ],
        ),
      );
    }
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

  // 下 進捗バー
  Widget bottomBar() {
    double barHeight = 25;
    double ffBottom = 0;

    String progress = ref.watch(viewerProvider).getProgress();
    Widget wText = Text(
      progress,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      textScaler: TextScaler.linear(0.9),
      style: TextStyle(color: env.getFrontColor()),
    );

    Widget bar = Container(
      color: env.getBackColor(),
      child: Column(
        children: [
          SizedBox(height: 6),
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

  // 最後のページバー
  Widget maxpageBar() {
    double barHeight = 300;
    double ffBottom = -1.0 * barHeight;
    if (ref.watch(viewerProvider).bottomBarType == ViewerBottomBarType.maxpageBar) {
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
          SizedBox(height: 6),
          MyTextButton(
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

  /// コピーして保存バー
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
                await ref.watch(viewerProvider).clearFocus();
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
                  alertDialog('save', msg: text).then((ret) {
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
    list.add(MySettingsTile(data: env.dark_mode));

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
  onSettingsDropdownChanged(EnvData data) {
    if (data.name == 'font_size' || data.name == 'writing_mode') {
      reload();
    } else if (data.name == 'dark_mode') {
      super.onSettingsDropdownChanged(data);
    } else {
      refresh();
    }
  }

  Future reload() async {
    ref.read(viewerProvider).load(env, _width, _height);
  }

  Future refresh() async {
    ref.read(viewerProvider).refresh();
  }

  // 目次バー
  Widget tocBar() {
    double barHeight = book.index.list.length > 20 ? _height * 2 / 3 : _height / 2;
    double ffBottom = -1.0 * barHeight;
    if (ref.watch(viewerProvider).bottomBarType == ViewerBottomBarType.tocBar) {
      ffBottom = 0;
    }
    List<Widget> list = [];

    for (int i = 0; i < book.index.list.length; i++) {
      int sum = 0;
      for (int j = 0; j <= i; j++) {
        sum += book.index.list[j].chars;
      }
      String txt = '${book.index.list[i].title}';
      String pages = '${(sum / CHARS_PAGE).toInt()}';
      int nowIndex = ref.watch(viewerProvider).nowIndex;

      list.add(
        MyTocTile(
          check: (i == nowIndex),
          title1: MyText(txt, maxLength: 24),
          title2: MyText(pages),
          onPressed: () {
            ref.read(viewerProvider).jumpToIndex(i, 0);
            startReadlog();
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

  // クリップバー（保存した文章）
  Widget clipListBar() {
    double barHeight = _height * 2 / 3;
    double ffBottom = -1.0 * barHeight;
    if (ref.watch(viewerProvider).bottomBarType == ViewerBottomBarType.clipListBar) {
      ffBottom = 0;
    }
    ClipData d = ref.watch(viewerProvider).readClip();

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

    String clipText = '';
    for (int i = 0; i < d.list.length; i++) {
      clipText += d.list[i].text + '\n';
    }

    Widget w = Row(
      children: [
        SizedBox(width: 30),
        MyTextButton(
          title: l10n('copy_to_clipboard'),
          width: 170,
          scaleRatio: 0.9,
          onPressed: () async {
            final data = ClipboardData(text: clipText);
            await Clipboard.setData(data);
          },
        ),
        Expanded(child: SizedBox(width: 1)),
        Text('${l10n('swipe_to_delete')}', textScaler: TextScaler.linear(myTextScale * 0.7)),
        SizedBox(width: 20),
      ],
    );

    Widget bar = Container(
      color: myTheme.cardColor,
      child: Column(children: [
        closeButtonRow(),
        Row(children: [
          Expanded(child: SizedBox(width: 1)),
          Text('No data'),
          Expanded(child: SizedBox(width: 1)),
        ]),
      ]),
    );

    if (list.length > 0) {
      bar = Container(
        color: myTheme.cardColor,
        child: Column(
          children: [
            closeButtonRow(),
            w,
            Expanded(
              child: ListView.builder(
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
                                ref.watch(viewerProvider).deleteClip(index: index).then((ret) {
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
              ),
            )
          ],
        ),
      );
    }

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
