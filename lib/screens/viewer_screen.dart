import 'dart:developer';
import 'dart:io';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/services.dart';

import '/commons/base_screen.dart';
import '/commons/widgets.dart';
import '/models/book_data.dart';
import '/constants.dart';
import '/controllers/viewer_controller.dart';
import '/controllers/env_controller.dart';
import '/controllers/viewlog_controller.dart';
import '/controllers/applog_controller.dart';

class ViewerScreen extends BaseScreen with WidgetsBindingObserver {
  ViewerScreen({required BookData this.book}) {}

  BookData book;
  double _width = 1000.0;
  double _height = 1000.0;
  ViewerBarType barType = ViewerBarType.none;

  ViewerController viewerCtrl = ViewerController();

  bool isActionBar() {
    return barType != ViewerBarType.none;
  }

  @override
  Future init() async {
    if (Platform.isAndroid || Platform.isIOS) {
      WidgetsBinding.instance.addObserver(this);
    }
    ref.read(viewerProvider).barType = ViewerBarType.none;
    viewerCtrl.ref = ref;
    viewerCtrl.book = this.book;

    viewerCtrl.load(env, _width, _height).then((ret) {
      startReadlog();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    viewerCtrl.stopSpeaking();
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
      viewerCtrl.width = _width;
    }

    double oldHeight = _height;
    _height = MediaQuery.of(context).size.height;
    myTheme.appBarTheme.toolbarHeight;
    if (_height != oldHeight) {
      log('height ${_height.toInt()}');
      viewerCtrl.height = _height;
    }

    super.build(context, ref);
    barType = ref.watch(viewerProvider).barType;

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
              padding: env.writing_mode.val == 0
                  ? DEF_VIEW_PADDING_TB
                  : DEF_VIEW_PADDING_RL,
              color: env.getBackColor(),
              child: Widget1(),
            ),
            //if (ref.watch(viewerProvider).isLoading) loadingWidget(),
            if (this.barType != ViewerBarType.clipTextBar)
              Container(
                padding: EdgeInsets.fromLTRB(1, 1, 1, 1),
                child: RawGestureDetector(
                  behavior: HitTestBehavior.translucent,
                  gestures: {
                    TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                        TapGestureRecognizer>(
                      () => TapGestureRecognizer(),
                      (TapGestureRecognizer instance) {
                        instance
                          ..onTapUp = (TapUpDetails details) {
                            if (barType != ViewerBarType.actionBar) {
                              ref.read(viewerProvider).barType =
                                  ViewerBarType.actionBar;
                              redraw();
                            } else {
                              ref.read(viewerProvider).barType =
                                  ViewerBarType.none;
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
    return viewerCtrl.viewer(env, barType);
  }

  Widget loadingWidget() {
    return Stack(children: [
      Container(
        color: env.getBackColor(),
        padding: EdgeInsets.fromLTRB(2, 2, 2, 2),
      ),
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

  Future startReadlog() async {
    int nowChars = viewerCtrl.nowChars;
    ref.read(viewlogProvider).init(nowChars);
  }

  Future endReadlog() async {
    int nowChars = viewerCtrl.nowChars;
    ref.read(viewlogProvider).save(nowChars, book);
    viewerCtrl.stopSpeaking();
  }

  Widget actionRow() {
    double pad = 1.0;
    if (Platform.isIOS == false && Platform.isAndroid == false) {
      pad = 16.0;
    }
    return Row(children: [
      SizedBox(width: 4),
      IconButton(
          icon: Icon(Icons.arrow_back_ios_new),
          color: env.getFrontColor(),
          onPressed: () {
            endReadlog();
            viewerCtrl.stopSpeaking();
            Navigator.of(context).pop();
          }),
      if (isActionBar()) SizedBox(width: pad),
      if (isActionBar())
        MyIconLabelButton(
          label: l10n('toc'),
          icon: Icon(Icons.list),
          color: env.getFrontColor(),
          onPressed: () {
            ref.read(viewerProvider).barType = ViewerBarType.tocBar;
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
            if (barType == ViewerBarType.maxpageBar) {
              ref.read(viewerProvider).barType = ViewerBarType.none;
            } else {
              ref.read(viewerProvider).barType = ViewerBarType.maxpageBar;
            }
            redraw();
          },
        ),
      if (isActionBar() && IS_CLIP == true) SizedBox(width: pad),
      if (isActionBar() && IS_CLIP == true)
        MyIconLabelButton(
          label: l10n('copy'),
          icon: Icon(Icons.pan_tool_alt_outlined),
          color: env.getFrontColor(),
          onPressed: () {
            if (barType == ViewerBarType.clipTextBar) {
              ref.read(viewerProvider).barType = ViewerBarType.none;
            } else {
              ref.read(viewerProvider).barType = ViewerBarType.clipTextBar;
            }
            redraw();
          },
        ),
      if (isActionBar() && IS_CLIP == true) SizedBox(width: pad),
      if (isActionBar() && IS_CLIP == true)
        MyIconLabelButton(
          label: l10n('clip'),
          icon: Icon(Icons.article_outlined),
          color: env.getFrontColor(),
          onPressed: () {
            ref.read(viewerProvider).barType = ViewerBarType.clipListBar;
            redraw();
          },
        ),
      if (isActionBar()) SizedBox(width: pad),
      if (isActionBar())
        MyIconLabelButton(
          label: l10n('option'),
          icon: Icon(Icons.settings_outlined),
          color: env.getFrontColor(),
          onPressed: () {
            ref.read(viewerProvider).barType = ViewerBarType.settingsBar;
            redraw();
          },
        ),
      if (isActionBar()) SizedBox(width: pad)
    ]);
  }

  // トップバー
  Widget topBar() {
    double barHeight = 70;
    double ffTop = -30;
    if (isActionBar()) {
      ffTop = 0;
    }

    Widget wText = Text(
      viewerCtrl.getTitle(),
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

  // ボトムバー
  Widget bottomBar() {
    double barHeight = 200;
    double ffBottom = 40 - barHeight; // -160
    bool isSpeaking = viewerCtrl.isSpeaking;
    if (barType == ViewerBarType.speakSettingsBar &&
        env.writing_mode.val == 0) {
      // 読み上げは横書きのみ
      ffBottom = 0;
    }

    String progress = viewerCtrl.getProgress();
    Widget wText = Container(
      child: Text(
        progress,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        textScaler: TextScaler.linear(0.9),
        style: TextStyle(color: env.getFrontColor()),
      ),
    );

    double iconSize = ICON_BUTTON_SIZE;
    Widget btnStart = IconButton(
      iconSize: iconSize,
      icon: Icon(Icons.volume_up_outlined),
      color: env.getFrontColor(),
      onPressed: () {
        viewerCtrl.startSpeaking();
      },
    );

    Widget btnStop = IconButton(
      iconSize: iconSize,
      icon: Icon(Icons.stop_circle_outlined),
      color: Colors.redAccent,
      onPressed: () {
        viewerCtrl.stopSpeaking();
      },
    );

    Widget btnSettings = IconButton(
      iconSize: iconSize,
      icon: Icon(Icons.settings_outlined),
      color: env.getFrontColor(),
      onPressed: () {
        if (barType == ViewerBarType.speakSettingsBar) {
          ref.read(viewerProvider).barType = ViewerBarType.none;
        } else {
          ref.read(viewerProvider).barType = ViewerBarType.speakSettingsBar;
        }
        redraw();
      },
    );

    Widget space = SizedBox(width: iconSize + 24, height: iconSize + 24);
    Widget e = Expanded(child: SizedBox(width: 1));

    Widget leftBtn = space;
    if (env.writing_mode.val == 1)
      leftBtn = space;
    else if (isSpeaking)
      leftBtn = btnStop;
    else if (isActionBar() && !isSpeaking) leftBtn = btnStart;

    Widget rightBtn = space;
    if (env.writing_mode.val == 1)
      rightBtn = space;
    else if (isActionBar()) rightBtn = btnSettings;

    Widget bar = Container(
      color: env.getBackColor(),
      child: Column(children: [
        SizedBox(height: 4),
        Row(
          children: [
            SizedBox(width: 20, height: iconSize),
            leftBtn,
            e,
            wText,
            e,
            rightBtn,
            SizedBox(width: 20),
          ],
        ),
        SizedBox(height: 16),
        MySettingsTile(data: env.speak_voice),
        MySettingsTile(data: env.speak_speed),
        Expanded(child: SizedBox(height: 1)),
      ]),
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

  // 最後のページバー
  Widget maxpageBar() {
    double barHeight = 300;
    double ffBottom = -1.0 * barHeight;
    if (barType == ViewerBarType.maxpageBar) {
      ffBottom = 0;
    }

    double pad = (_width - 290) / 2;
    String nowPage = viewerCtrl.getNowPage();
    String maxPage = viewerCtrl.getMaxPage();
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
                  viewerCtrl.moveMaxpage();
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
                    viewerCtrl.resetMaxpage();
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
    if (barType == ViewerBarType.clipTextBar) {
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
                ref.read(viewerProvider).barType = ViewerBarType.none;
                await viewerCtrl.clearFocus();
                redraw();
              },
            ),
            SizedBox(width: 16),
            MyTextButton(
              commit: true,
              title: l10n('save_selection'),
              width: 140,
              onPressed: () async {
                String? text = await viewerCtrl.getSelectedText();
                if (text != null && text.length > 2) {
                  alertDialog('save', msg: text).then((ret) {
                    if (ret) {
                      viewerCtrl.saveClip(text);
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
    ref.read(viewerProvider).barType = ViewerBarType.none;
    viewerCtrl.clearFocus();
    redraw();
  }

  /// settingsBar
  Widget settingsBar() {
    double barHeight = 300;
    barHeight += env.ui_text_scale.val;

    double ffBottom = -1.0 * barHeight;
    if (barType == ViewerBarType.settingsBar) {
      ffBottom = 0;
    }

    List<Widget> list = [];
    list.add(closeButtonRow());
    list.add(MySettingsTile(data: env.font_size));
    list.add(MySettingsTile(data: env.back_color));
    list.add(MySettingsTile(data: env.writing_mode));
    list.add(MySettingsTile(data: env.font_family));
    //list.add(MySettingsTile(data: env.dark_mode));
    list.add(SizedBox(height: 10));
    list.add(MySettingsTile(data: env.speak_voice));
    list.add(MySettingsTile(data: env.speak_speed));
    list.add(MyText(l10n('speaking_is_only_horizontal_text'), small: true));

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
    } else if (data.name == 'back_color') {
      super.onSettingsDropdownChanged(data);
      refresh();
    } else {
      refresh();
    }
  }

  @override
  Future redraw() async {
    ref.read(viewerProvider).notifyListeners();
  }

  Future reload() async {
    viewerCtrl.load(env, _width, _height);
  }

  Future refresh() async {
    viewerCtrl.refresh();
  }

  // 目次バー
  Widget tocBar() {
    double barHeight =
        book.index.list.length > 20 ? _height * 3 / 5 : _height / 2;
    double ffBottom = -1.0 * barHeight;
    if (barType == ViewerBarType.tocBar) {
      ffBottom = 0;
    }
    List<Widget> list = [];

    int nowIndex = viewerCtrl.nowIndex;
    int nowRatio = viewerCtrl.nowRatio;
    if (nowIndex < book.index.list.length - 1 && nowRatio > 9500) nowIndex++;

    for (int i = 0; i < book.index.list.length; i++) {
      int sum = 0;
      for (int j = 0; j <= i; j++) {
        sum += book.index.list[j].chars;
      }
      String txt = '${book.index.list[i].title}';
      String pages = '${(sum / CHARS_PAGE).toInt()}';

      list.add(
        MyTocTile(
          check: (i == nowIndex),
          title1: MyText(txt, maxLength: 24),
          title2: MyText(pages),
          onPressed: () {
            // v2.0 h3を<br>で下げている
            viewerCtrl.jumpToIndex(i, 0);
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
    if (barType == ViewerBarType.clipListBar) {
      ffBottom = 0;
    }
    ClipData d = viewerCtrl.readClip();

    // 表示用
    List<Widget> list = [];
    for (int i = 0; i < d.list.length; i++) {
      list.add(
        MyClipListTile(
          text: d.list[i].text,
          onPressed: () {
            deleteDialog().then((ret) {
              if (ret) {
                viewerCtrl.deleteClip(index: i);
              }
            });
          },
        ),
      );
    }

    // コピー用
    String clipText = '';
    for (int i = 0; i < d.list.length; i++) {
      clipText += d.list[i].text + '\n';
    }

    Widget w1 = Row(
      children: [
        Expanded(child: SizedBox(width: 1)),
        MyTextButton(
          title: l10n('copy_to_clipboard'),
          width: 230,
          scaleRatio: 0.9,
          onPressed: () async {
            final data = ClipboardData(text: clipText);
            await Clipboard.setData(data);
          },
        ),
        Expanded(child: SizedBox(width: 1)),
      ],
    );
    Widget w2 = Row(
      children: [
        Expanded(child: SizedBox(width: 1)),
        Text('${l10n('swipe_to_delete')}',
            textScaler: TextScaler.linear(myTextScale * 0.7)),
        SizedBox(width: 20),
      ],
    );
    Widget bar = Container(
      color: myTheme.cardColor,
      child: Column(children: [
        closeButtonRow(),
        Row(children: [
          Expanded(child: SizedBox(width: 1)),
          Text(l10n('no_data')),
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
            w1,
            w2,
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
                        MySlidableAction(
                          onPressed: (_) {
                            deleteDialog().then((ret) {
                              if (ret) {
                                log('delette');
                                viewerCtrl.deleteClip(index: index).then((ret) {
                                  redraw();
                                });
                              }
                            });
                          },
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.redAccent,
                          icon: Icons.delete,
                          label: null,
                          //spacing: 0,
                          //padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
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
