import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:io';
import 'dart:async';
import 'dart:developer';
import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:core';
import 'package:flutter/widgets.dart';
import 'package:flutter/src/widgets/framework.dart';

import '/models/book_data.dart';
import '/models/epub_data.dart';
import '/commons/widgets.dart';
import '/controllers/applog_controller.dart';
import '/constants.dart';
import '/controllers/env_controller.dart';

enum ViewerBarType {
  none,
  tocBar,
  actionBar,
  settingsBar,
  clipTextBar,
  clipListBar,
  maxpageBar,
  speakSettingsBar,
}

final viewerProvider = ChangeNotifierProvider((ref) => ViewerNotifier(ref));

class ViewerNotifier extends ChangeNotifier {
  ViewerNotifier(ref) {
    Future.delayed(const Duration(seconds: 1), () {});
  }

  @override
  void dispose() {}

  Environment env = Environment();
  BookData? book;

  ScrollController? scrollCtrl;
  bool isLoading = false;
  bool isJumping = false;
  bool bScrollingListener = true;

  DateTime lastTime = DateTime.now();
  double lastPixel = 0;
  int nowIndex = 0;
  int nowRatio = 0;
  int nowChars = 0;
  int maxChars = 0;

  Map<String, String> m = {};
  double jumpMarginPx = 0;
  ViewerBarType barType = ViewerBarType.none;

  bool isActionBar() {
    return barType != ViewerBarType.none;
  }

  List<String> listText = [];
  List<List<String>> listSpeak = [[]];
  List<double> listWidth = [];
  List<InAppWebViewController?> listWebViewCtrl = [];
  List<GlobalKey> listKey = [];
  List<ContextMenu?> listContextMenu = [];

  double scrollWidth = DEF_VIEW_SCROLL_WIDTH;
  double width = 1000.0;
  double _widthPad = DEF_VIEW_LINE_WIDTH;
  double height = 1000.0;
  double _heightPad = DEF_VIEW_LINE_HEIGHT;

  Future load(Environment env, double w, double h) async {
    log('load() start');

    this.env = env;

    width = w;
    height = h;

    isLoading = true;
    listText.clear();
    listSpeak.clear();
    listWidth.clear();
    listKey.clear();
    listContextMenu.clear();
    m.clear();

    try {
      if (scrollCtrl != null) scrollCtrl!.dispose();
      for (InAppWebViewController? ctrl in listWebViewCtrl) {
        if (ctrl != null) ctrl.dispose();
      }
    } on Exception catch (e) {
      MyLog.err('ViewerController.ctrl.dispose() ${e.toString()}');
    } catch (_) {
      MyLog.err('ViewerController.ctrl.dispose()(_)');
    }

    try {
      scrollCtrl = new ScrollController();
      scrollCtrl!.addListener(scrollingListener);
      listWebViewCtrl.clear();

      this.notifyListeners();
      await Future.delayed(Duration(milliseconds: 50));

      String bookdir = APP_DIR + '/book';
      EpubData e = new EpubData();

      for (int i = 0; i < 10000; i++) {
        String path1 = '${bookdir}/${book!.bookId}/text/ch${(i).toString().padLeft(4, '0')}.txt';
        if (File(path1).existsSync()) {
          String orgText = await File(path1).readAsStringSync();
          String body = orgText;

          // chars
          int fsize = env.font_size.val;
          double w = (env.writing_mode.val == 0) ? (width - _widthPad) : (height - _heightPad);
          int chars = ((w / fsize) - 0.0).toInt();
          body = body.replaceAll('\n', '');
          body = body.replaceAll('<h3>', '');
          body = body.replaceAll('</h3>', '<br />');
          body = body.replaceAll('<h2>', '');
          body = body.replaceAll('</h2>', '<br />');
          int rubyCount = body.split('<ruby>').length;

          // delete ruby
          body = EpubData.deleteRuby(body);
          List<String> list1 = body.split('<br />');
          int lineCount = 0;
          for (String s in list1) {
            int d = (s.length / chars).toInt() + 1;
            lineCount += d;
          }
          lineCount += 1;
          lineCount += (rubyCount / (40 + fsize * 2)).toInt();

          double dh = (env.line_height.val - 3) / 100.0;
          double calcWidth = lineCount.toDouble() * fsize * dh;
          calcWidth += scrollWidth;
          if (calcWidth < 400) calcWidth = 400;
          if (!Platform.isIOS && !Platform.isAndroid) {
            //if (calcWidth > 3000) calcWidth = 3000;
          }
          // chars

          // speech
          String text2 = orgText;

          // 縦書き
          if (env.writing_mode.val == 1) {
            VerticalRotated.map.forEach((String key, String value) {
              text2 = text2.replaceAll(key, value);
            });
          }

          text2 = text2.replaceAll('\n', '');
          List<String> lines2 = text2.split('<br />');
          String text1 = "";
          int ii = 0;
          List<String> linesTemp = [];
          for (String s in lines2) {
            if (s == "") {
              text1 += "<br />";
              linesTemp.add("");
              ii++;
            } else {
              text1 += "<p id='p${ii}'>${s}</p>";
              ii++;
              s = EpubData.getRuby(s, m);
              linesTemp.add(s);
            }
          }
          listSpeak.add(linesTemp);

          text1 = e.head1 + text1 + e.head2;
          text1 = changeTextStyle(text1);
          text1 += '<br />';
          // speech

          listWidth.add(calcWidth);
          listWebViewCtrl.add(null);
          listKey.add(GlobalKey());
          listText.add(text1);

          if (Platform.isIOS) {
            ContextMenu contextMenu = ContextMenu(
                settings: ContextMenuSettings(hideDefaultSystemContextMenuItems: true),
                menuItems: [],
                onCreateContextMenu: (hitTestResult) async {
                  print("onCreateContextMenu");
                  print('hitTestResult.extra ${hitTestResult.extra}');
                },
                onHideContextMenu: () {
                  print("onHideContextMenu");
                },
                onContextMenuActionItemClicked: (contextMenuItemClicked) async {});
            listContextMenu.add(contextMenu);
          } else {
            listContextMenu.add(null);
          }
        } else {
          if (i >= 1) break;
        }
      } // for (int i = 0; i < 10000; i++) {
    } on Exception catch (e) {
      MyLog.err('ViewerController.losd() ${e.toString()}');
    } catch (_) {
      MyLog.err('ViewerController.catch(_)');
    }
    isLoading = false;
    try {
      nowChars = book!.prop.nowChars;
      maxChars = book!.prop.maxChars;
      int chars1 = nowChars;
      for (int i = 0; i < book!.index.list.length; i++) {
        int c = book!.index.list[i].chars;
        if (chars1 > c) {
          chars1 -= c;
        } else {
          nowIndex = i;
          nowRatio = (chars1 * 10000 / c).toInt();
          break;
        }
      }
      log('load jump [${nowIndex}] ${(nowRatio / 100).toInt()}% (${nowChars})');
      jumpToIndex(nowIndex, nowRatio);
    } on Exception catch (e) {
      MyLog.err('ViewerController.losd().jump ${e.toString()}');
    }
    log('load() end');
  } // load

  /// Styleを書き換えて高さは同じ
  Future refresh() async {
    log('refresh()');
    try {
      for (int i = 0; i < listText.length; i++) {
        listText[i] = changeTextStyle(listText[i]);
      }
      await Future.delayed(Duration(milliseconds: 100));

      //if (Platform.isIOS) {
      int ni = nowIndex;
      if (listWebViewCtrl.length > ni && listWebViewCtrl[ni] != null && listText.length > ni) {
        try {
          await listWebViewCtrl[ni]!.loadData(data: listText[ni]);
        } on Exception catch (e) {
          log('warn Viewer.refresh() +0');
        }
      }
      if (ni > 0 &&
          listWebViewCtrl.length > ni - 1 &&
          listWebViewCtrl[ni - 1] != null &&
          listText.length > ni - 1) {
        try {
          await listWebViewCtrl[ni - 1]!.loadData(data: listText[ni - 1]);
        } on Exception catch (e) {
          log('warn Viewer.refresh() -1');
        }
      }
      if (listWebViewCtrl.length > ni + 1 &&
          listWebViewCtrl[ni + 1] != null &&
          listText.length > ni + 1) {
        try {
          await listWebViewCtrl[ni + 1]!.loadData(data: listText[ni + 1]);
        } on Exception catch (e) {
          log('warn Viewer.refresh() +1');
        }
      }
      this.notifyListeners();
    } on Exception catch (e) {
      MyLog.err('Viewer.refresh() ${e.toString()}');
    }
  }

  Future<String?> getSelectedText() async {
    String? text = null;
    try {
      if (listWebViewCtrl.length < nowIndex) return null;
      if (listWebViewCtrl[nowIndex] == null) return null;
      if (Platform.isIOS || Platform.isAndroid) {
        int i = nowIndex;
        text = await getSelectedTextSub(i);
        if (text == null) {
          text = await getSelectedTextSub(i - 1);
        }
        if (text == null) {
          text = await getSelectedTextSub(i + 1);
        }
        log('getSelectedText() [${i}] text=${text}');
      } else {
        text = 'あいうえお';
      }
    } on Exception catch (e) {
      MyLog.err('ViewerNotifier.getSelectedText() ${e.toString()}');
    }
    return text;
  }

  Future<String?> getSelectedTextSub(int i) async {
    if (i <= 0) return null;
    if (i >= listWebViewCtrl.length) return null;
    if (listWebViewCtrl[i] == null) return null;
    try {
      String? text = await listWebViewCtrl[i]!.getSelectedText();
      if (text != null && text == "") text = null;
      return text;
    } on Exception catch (e) {
      MyLog.err('getSelectedTextSub() ${e.toString()}');
    }
    return null;
  }

  Future clearFocus() async {
    try {
      if (listWebViewCtrl.length < nowIndex) return null;
      if (listWebViewCtrl[nowIndex] == null) return null;
      if (Platform.isIOS || Platform.isAndroid) {
        int i = nowIndex;
        await listWebViewCtrl[i]!.clearFocus();
        if (i - 1 >= 0) await listWebViewCtrl[i - 1]!.clearFocus();
        if (i + 1 < listWebViewCtrl.length) await listWebViewCtrl[i + 1]!.clearFocus();
      }
    } catch (_) {
      log('err clearFocus() [${nowIndex}]');
    }
  }

  Future jumpToIndex(int index, int ratio) async {
    if (scrollCtrl == null) return;
    isJumping = true;
    bScrollingListener = false;

    try {
      for (int k = 0; k < 5; k++) {
        if (scrollCtrl!.hasClients == false) {
          log('scrollController.hasClients==false nowIndex=${index} k=${k}');
          await Future.delayed(Duration(milliseconds: 100));
          this.notifyListeners();
          await Future.delayed(Duration(milliseconds: 100));
        }
      }
      if (scrollCtrl!.hasClients == false) {
        log('return jumpTo index [${index}] ${(ratio / 100).toInt()}%');
        return;
      }
      if (listWidth.length == 0) return;
      if (index > listWidth.length - 1) index = listWidth.length - 1;
      if ((nowIndex - index).abs() >= 2) isLoading = true;
      nowIndex = index;
      nowRatio = ratio;
      double curdx = scrollCtrl!.position.pixels;
      double maxdx = scrollCtrl!.position.maxScrollExtent;

      double dx = 0;
      for (int i = 0; i < index + 1; i++) {
        if (i < index) dx += listWidth[i];
      }
      dx += listWidth[index] * ratio / 10000;
      if (dx > jumpMarginPx) dx -= jumpMarginPx;
      if ((dx - curdx).abs() < 2000) isJumping = false;

      for (int k = 0; k < 5; k++) {
        if (dx > maxdx && maxdx > 2000) {
          //log('jumpTo [x${k}][${index}] dx>max cur=${curdx.toInt()} dx=${dx.toInt()} max=${maxdx.toInt()}');

          double dx1 = curdx + (dx - curdx) / 2;
          if (dx1 - curdx > (100000)) dx1 = curdx + (100000);

          if (scrollCtrl!.hasClients == true) {
            log('jumpTo [x${k}][${index}] dx>max cur=${curdx.toInt()} dx=${dx.toInt()} max=${maxdx.toInt()} dx1=${dx1.toInt()}');
            await scrollCtrl!
                .animateTo(dx1, duration: Duration(milliseconds: 500), curve: Curves.linear);
            this.notifyListeners();
          } else {
            log('jumpTo [x${k}][${index}] dx>max cur=${curdx.toInt()} dx=${dx.toInt()} max=${maxdx.toInt()} scrollController!.hasClients');
            this.notifyListeners();
          }

          await Future.delayed(Duration(milliseconds: 100));
          if (scrollCtrl!.hasClients == true) {
            curdx = scrollCtrl!.position.pixels;
            maxdx = scrollCtrl!.position.maxScrollExtent;
          }
        } else {
          break;
        }
      }

      if (index > 0 && curdx == 0) {
        log('jumpTo [${index}][${(ratio / 100).toInt()}%] curdx==0');
        this.notifyListeners();
        for (int k = 0; k < 1; k++) {
          await Future.delayed(Duration(milliseconds: 100));
          if (scrollCtrl != null && scrollCtrl!.hasClients == true) {
            curdx = scrollCtrl!.position.pixels;
            maxdx = scrollCtrl!.position.maxScrollExtent;
            break;
          }
        }
      }

      if (dx < maxdx) {
        log('jumpTo start [${index}][${(ratio / 100).toInt()}%] cur=${curdx.toInt()} dx=${dx.toInt()} max=${maxdx.toInt()}');
        await scrollCtrl!
            .animateTo(dx, duration: Duration(milliseconds: 500), curve: Curves.linear);
        log('jumpTo end');
      } else {
        log('jumpTo else [${index}][${(ratio / 100).toInt()}%] cur=${curdx.toInt()} dx=${dx.toInt()} max=${maxdx.toInt()}');
      }

      // 進捗を保存
      isLoading = false;
      nowChars = getNowChars();
      if (maxChars < nowChars) {
        maxChars = nowChars;
      }
      saveIndex();
    } on Exception catch (e) {
      MyLog.err('jumpToIndex() ${e.toString()}');
    }
    isJumping = false;
    isLoading = false;
    bScrollingListener = true;
    this.notifyListeners();
  } // jumpToIndex

  String getProgress() {
    if (book == null) return '';
    int allChars = book!.chars;
    if (allChars < 100) allChars = 100;
    int per = (nowChars * 100 / allChars).toInt();
    return '${per} %';
  }

  Future moveMaxpage() async {
    int maxIndex = 0;
    int maxRatio = 0;
    int chars1 = maxChars;
    for (int i = 0; i < book!.index.list.length; i++) {
      int c = book!.index.list[i].chars;
      if (chars1 > c) {
        chars1 -= c;
      } else {
        maxIndex = i;
        maxRatio = (chars1 * 10000 / c).toInt();
        break;
      }
    }
    jumpToIndex(maxIndex, maxRatio);
  }

  Future resetMaxpage() async {
    maxChars = nowChars;
    saveIndex();
    notifyListeners();
  }

  /// nowIndex と nowRatio から nowChars を計算
  int getNowChars() {
    if (book == null) return -1;
    int chars = 0;
    for (int i = 0; i < book!.index.list.length; i++) {
      if (i < nowIndex) {
        chars += book!.index.list[i].chars;
      } else if (i == nowIndex) {
        chars += (book!.index.list[i].chars * nowRatio / 10000).toInt();
      } else {
        break;
      }
    }
    return chars;
  }

  String getNowPage() {
    return '${(nowChars / 450).toInt()}';
  }

  String getMaxPage() {
    return '${(maxChars / 450).toInt()}';
  }

  void scrollingListener() async {
    if (scrollCtrl == null) return;
    if (scrollCtrl!.hasClients == false) return;
    if (isLoading == true) return;
    if (isJumping == true) return;
    if (bScrollingListener == false) return;

    try {
      double px = scrollCtrl!.position.pixels;
      if (px > jumpMarginPx) px -= jumpMarginPx;
      if ((lastPixel - px).abs() < 100) return;

      final past = lastTime.add(Duration(milliseconds: 500));
      if (DateTime.now().compareTo(past) < 1) return;

      lastPixel = px;
      lastTime = DateTime.now();

      int oldNowIndex = nowIndex;
      for (int i = 0; i < listWidth.length; i++) {
        if (px < listWidth[i]) {
          nowIndex = i;
          nowRatio = (px * 10000.0 / listWidth[i]).toInt();
          break;
        }
        px -= listWidth[i];
      }
      if (oldNowIndex - 1 == nowIndex) this.notifyListeners();

      nowChars = getNowChars();
      if (maxChars < nowChars) {
        maxChars = nowChars;
      }
      saveIndex();
    } on Exception catch (e) {
      MyLog.err('scrollingListener() ${e.toString()}');
    }
  }

  /// nowChars と maxChars を保存
  saveIndex() {
    if (scrollCtrl == null) return;
    if (scrollCtrl!.hasClients == false) return;
    if (scrollCtrl == null) return;
    if (book == null) return;
    if (isLoading == true) return;

    try {
      book!.prop.nowChars = nowChars;
      book!.prop.maxChars = maxChars;
      book!.prop.atime = DateTime.now();

      String bookdir = APP_DIR + '/book';
      String jsonText = json.encode(book!.prop.toJson());
      final file = File('${bookdir}/${book!.bookId}/data/prop.json');
      file.writeAsString(jsonText, mode: FileMode.write, flush: true);
    } on Exception catch (e) {
      MyLog.err('saveIndex() ${e.toString()}');
    }
  }

  /// <style>を変える
  String changeTextStyle(String t1) {
    String tag1 = '<style>';
    String tag2 = '</style>';
    int s1 = t1.indexOf(tag1);
    int e1 = (s1 >= 0) ? t1.indexOf(tag2, s1 + tag1.length) : 0;
    if (s1 >= 0 && e1 > 0 && e1 - s1 < 1000) {
      t1 = t1.substring(0, s1) + '<style>${getStyle(env)}' + t1.substring(e1);
    }
    return t1;
  }

  String getStyle(Environment env) {
    int fontSize = env.font_size.val;
    String fontFamily = env.getFontFamily();

    String bodyWidth = 'width: ${(width - _widthPad).toInt()}px;';
    if (env.writing_mode.val == 1) {
      bodyWidth = 'height: ${(height - _heightPad).toInt()}px;';
    }

    String bodyPadding = 'padding-left: 0em;';
    if (env.writing_mode.val == 1) {
      bodyPadding = """padding-top: 0em;
padding-bottom: 1em;
margin: 10;
""";
    }

    String hPadding = 'padding-left: 0em;';
    if (env.writing_mode.val == 1) {
      hPadding = 'padding-top: 0em;';
    }

    String c = '';
    if (env.writing_mode.val == 1) {
      c += """body {
-webkit-writing-mode: vertical-rl;
-epub-writing-mode: tb-rl;
writing-mode: vertical-rl;
text-orientation: upright;
-webkit-text-orientation: upright;
}
""";
    }

    c += """body {
color: ${env.getFrontCss()};
background: ${env.getBackCss()};
font-size: ${fontSize}px;
font-family: ${fontFamily};
${bodyWidth}
word-break: break-all;
line-height: ${env.line_height.val}%;
${bodyPadding}
}
""";

    c += """p {
margin: 0;
}
h1, h2, h3 {
font-size: 1.2em;
font-weight: normal;
color: ${env.getH3Css()};
${hPadding}
line-height: ${env.line_height.val}%;
}
h4, h5 {
font-size: 1.0em;
font-weight: normal;
line-height: ${env.line_height.val}%;
}
""";
    return c;
  }

  Widget viewer(Environment env) {
    if (listText.length == 0) return Container();
    if (isLoading) return Container();
    this.env = env;

    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
    ScrollPhysics physics =
        barType == ViewerBarType.clipTextBar ? NeverScrollableScrollPhysics() : ScrollPhysics();

    try {
      return ListView.builder(
        scrollDirection: env.writing_mode.val == 0 ? Axis.vertical : Axis.horizontal,
        reverse: env.writing_mode.val == 0 ? false : true,
        shrinkWrap: true,
        controller: scrollCtrl,
        itemCount: listText.length,
        // 999,999,999,999,999
        cacheExtent: 100 * 1000,
        physics: physics,
        hitTestBehavior: HitTestBehavior.opaque,
        itemBuilder: (context, int index) {
          if (listWidth.length <= index) return Container();
          if (env.writing_mode.val == 0) {
            return SizedBox(
              height: listWidth[index],
              child: inviewer(index, listText[index]),
            );
          } else {
            return SizedBox(
              width: listWidth[index],
              child: inviewer(index, listText[index]),
            );
          }
        },
      );
    } on Exception catch (e) {
      MyLog.err('ViewerNotifier.viewer() ${e.toString()}');
      return Container();
    }
  }

  Widget inviewer(int index, String text) {
    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
    if ((nowIndex - index).abs() > 1) {
      return Container();
    }
    // now=20 ratio=10% 19は不要
    // now=20 ratio=10% 21は不要
    String logtxt = '[${index}] [${nowIndex}][${(nowRatio / 100).toInt()}%]';
    if (nowIndex - 1 == index) {
      //log('inviewer1 Container ${logtxt}');
      return Container();
    } else if (nowIndex + 1 == index) {
      double rest = (listWidth[nowIndex] * (10000 - nowRatio) / 10000);
      if (rest > 2000) {
        //log('inviewer1 Container ${logtxt}');
        return Container();
      }
    }

    try {
      Widget view = InAppWebView(
        key: listKey[index],
        initialData: InAppWebViewInitialData(data: text),
        initialSettings: initialSettings,
        findInteractionController: null,
        contextMenu: listContextMenu[index],
        onWebViewCreated: (controller) async {
          if (listWebViewCtrl.length > index) listWebViewCtrl[index] = controller;
        },
        onLoadStart: (controller, url) async {},
        onLoadStop: (controller, url) async {
          getActualWidth(controller, index);
        },
      );
      return view;
    } catch (_) {
      log('inviewer catch');
      return Container();
    }
  }

  Future getActualWidth(InAppWebViewController controller, int index) async {
    if (!Platform.isIOS && !Platform.isAndroid) {
      //this.notifyListeners();
      //return;
    }
    try {
      dynamic vw = null;
      if (env.writing_mode.val == 0) {
        vw = await controller
            .evaluateJavascript(source: '''(() => { return document.body.scrollHeight; })()''');
      } else {
        vw = await controller
            .evaluateJavascript(source: '''(() => { return document.body.scrollWidth; })()''');
      }
      if (vw != null && vw != '') {
        double dw = double.parse('${vw}');
        if (dw > 400 && (dw - listWidth[index]).abs() > 10) {
          if ((dw - listWidth[index]) > 300) {
            // 隙間が多い不具合
            dw = listWidth[index] + 300;
          }
          int d = dw.toInt();
          int l = listWidth[index].toInt();
          if ((d - l).abs() >= 200) {
            MyLog.debug('webWidth [${index}] ${l} ${d - l}');
          }
          listWidth[index] = dw;
        }
      }
      this.notifyListeners();
    } catch (_) {
      log('onLoadStop catch');
    }
  }

  InAppWebViewSettings initialSettings = InAppWebViewSettings(
    useOnLoadResource: false,
    javaScriptEnabled: true,
    enableViewportScale: false,
    mediaPlaybackRequiresUserGesture: false,
    transparentBackground: false,
    supportZoom: false,
    allowsInlineMediaPlayback: false,
    isElementFullscreenEnabled: true,
    iframeAllowFullscreen: true,
    disableLongPressContextMenuOnLinks: false,
    automaticallyAdjustsScrollIndicatorInsets: true,
    accessibilityIgnoresInvertColors: true,
    allowsLinkPreview: false,
    alwaysBounceVertical: false,
    alwaysBounceHorizontal: false,
    // Cache InAppWebViewController. clearAllCache
    //clearCache: true,
    // Scroll
    verticalScrollBarEnabled: false,
    horizontalScrollBarEnabled: false,
    // Scroll
    disableVerticalScroll: false,
    disableHorizontalScroll: false,
    useWideViewPort: true,
    // copy translate ...
    disableContextMenu: false,
    disableInputAccessoryView: false,
    shouldPrintBackgrounds: true,
    selectionGranularity: SelectionGranularity.CHARACTER,
    defaultFixedFontSize: 11,
    defaultFontSize: 11,
    // log
    isInspectable: false,
    // find
    isFindInteractionEnabled: false,
    isTextInteractionEnabled: true,
    // edit
    useOnNavigationResponse: true,
  );

  String getTitle() {
    if (book == null) return '';
    return book!.title;
  }

  /// Clip
  Future saveClip(String text) async {
    String bookdir = APP_DIR + '/book';
    ClipData d = ClipData();
    final file = File('${bookdir}/${book!.bookId}/data/clip.json');
    if (file.existsSync()) {
      String? txt = await file.readAsString();
      Map<String, dynamic> j = json.decode(txt);
      d = ClipData.fromJson(j);
    }

    ClipInfo c = ClipInfo();
    c.index = nowIndex;
    c.ratio = nowRatio;
    c.text = EpubData.deleteInvalidStrInJson(text);

    d.list.add(c);
    d.sort();
    String jsonText = json.encode(d.toJson());
    file.writeAsString(jsonText, mode: FileMode.write, flush: true);
  }

  ClipData readClip() {
    ClipData d = ClipData();
    if (book == null) return d;
    String bookdir = APP_DIR + '/book';
    final file = File('${bookdir}/${book!.bookId}/data/clip.json');
    if (file.existsSync()) {
      String? txt = file.readAsStringSync();
      Map<String, dynamic> j = json.decode(txt);
      d = ClipData.fromJson(j);
    }
    return d;
  }

  Future deleteClip({required int index}) async {
    String bookdir = APP_DIR + '/book';
    try {
      final file = File('${bookdir}/${book!.bookId}/data/clip.json');
      if (file.existsSync()) {
        String? txt = file.readAsStringSync();
        Map<String, dynamic> j = json.decode(txt);
        ClipData d = ClipData.fromJson(j);
        d.list.removeAt(index);
        String jsonText = json.encode(d.toJson());
        await file.writeAsString(jsonText, mode: FileMode.write, flush: true);
        this.notifyListeners();
      }
    } catch (_) {}
    return;
  }

  // TextToSpeech
  //--------------
  FlutterTts flutterTts = FlutterTts();
  bool initialized = false;
  bool isSpeaking = false;
  int speakIndex = 0;
  int speakLine = 0;
  int speakWait = 1000; // ms
  double pitch = 1.0;
  double pitch1 = 1.0;
  double pitch2 = 1.3;

  int speak2Index = 0;
  List<String> listSpeak2 = [];

  Future startSpeaking() async {
    if (isSpeaking) return;
    if (initialized == false) {
      initialized = true;

      // 言語を設定
      await flutterTts.setLanguage("ja-JP");

      // コールバック設定
      flutterTts.setCompletionHandler(() async {
        speak2Index++;
        speak2();
      });
    }

    // 速さ
    double sp = 0.5;
    switch (env.speak_speed.val) {
      case 80:
        sp = 0.40;
        speakWait = 1000;
      case 90:
        sp = 0.45;
        speakWait = 1000;
      case 100:
        sp = 0.50;
        speakWait = 800;
      case 110:
        sp = 0.55;
        speakWait = 600;
      case 120:
        sp = 0.60;
        speakWait = 400;
      case 130:
        sp = 0.65;
        speakWait = 300;
      case 140:
        sp = 0.70;
        speakWait = 200;
    }
    await flutterTts.setSpeechRate(sp);

    // 音量（無効）
    double vl = 1.0;
    if (!Platform.isIOS && !Platform.isAndroid) {
      vl = 0.0;
    }
    await flutterTts.setVolume(vl);

    // ピッチ
    pitch = pitch1;
    await flutterTts.setPitch(pitch);

    // ボイス
    //[log] voices O-ren
    //[log] voices Kyoko
    //[log] voices Hattori
    String v = 'O-ren';
    switch (env.speak_voice.val) {
      case 1:
        v = 'O-ren';
      case 2:
        v = 'Kyoko';
      case 3:
        v = 'Hattori';
    }
    await flutterTts.setVoice({"name": v, "locale": "ja-JP"});

    speakIndex = nowIndex;
    if (speakIndex > listSpeak.length - 1) speakIndex = listSpeak.length - 1;
    int ratio = nowRatio;
    if (speakIndex > listSpeak.length - 1 && ratio < 9500) {
      ratio += 500;
    } else if (speakIndex > listSpeak.length - 2 && ratio >= 9500) {
      speakIndex++;
      ratio = ratio + 500 - 10000;
    }

    int fsize = env.font_size.val;
    double w = (env.writing_mode.val == 0) ? (width - _widthPad) : (height - _heightPad);
    int chars = (w / fsize).toInt();
    double dh = env.line_height.val / 100.0;

    int all = 0;
    // allを計算
    for (int i = 0; i < listSpeak[speakIndex].length; i++) {
      String s = listSpeak[speakIndex][i].replaceAll('<br />', ' ');
      int lineCount = (s.length / chars).toInt() + 1;
      int len = (lineCount * (fsize * dh)).toInt();

      all += len;
    }

    // sumを計算
    speakLine = 0;
    int sum = 0;
    for (int i = 0; i < listSpeak[speakIndex].length; i++) {
      String s = listSpeak[speakIndex][i].replaceAll('<br />', ' ');
      int lineCount = (s.length / chars).toInt() + 1;
      int len = (lineCount * (fsize * dh)).toInt();

      sum += len;
      if ((sum * 10000 / all) > ratio) {
        break;
      }
      speakLine = i;
    }

    isSpeaking = true;
    speak1();
    this.notifyListeners();
  }

  int oldIndex = 0;
  String oldTag = '';

  Future<String> getSpeakText1() async {
    String text = '';
    if (speakIndex < listSpeak.length && speakLine >= listSpeak[speakIndex].length) {
      speakIndex++;
      speakLine = 0;
    }
    if (speakIndex < listSpeak.length) {
      text = listSpeak[speakIndex][speakLine];
      if (text == '') {
        speakLine++;
        text = await getSpeakText1();
      }
    }
    return text;
  }

  Future speak1() async {
    if (isSpeaking) {
      String text = await getSpeakText1();
      if (text != '') {
        //text = EpubData.getRuby(text, m);
        m.forEach((String key, String value) {
          text = text.replaceAll(key, value);
        });

        if (oldTag != '') {
          String ss1 = 'mark0("${oldTag}");';
          await listWebViewCtrl[oldIndex]!.evaluateJavascript(source: ss1);
          oldTag = '';
        }
        String ss2 = 'mark1("p${speakLine}", "${env.getH3Css()}");';
        await listWebViewCtrl[speakIndex]!.evaluateJavascript(source: ss2);
        oldTag = 'p${speakLine}';
        oldIndex = speakIndex;
        this.notifyListeners();

        text = text.replaceAll('<h3>', '');
        text = text.replaceAll('</h3>', '<br />');
        text = text.replaceAll('<h2>', '');
        text = text.replaceAll('</h2>', '<br />');

        text = text.replaceAll('。」', '」');
        text = text.replaceAll('。', '。<br />');
        text = text.replaceAll('「', '<br />「<br />');
        text = text.replaceAll('」', '<br />」<br />');

        listSpeak2.clear();
        List<String> list = text.split('<br />');
        for (String s in list) {
          if (s.length >= 1) listSpeak2.add(s);
        }

        speak2Index = 0;
        log('[${nowIndex}]=[${speakIndex}] [${nowRatio}] mark1("p${speakLine}"); ${text}');
        speak2();

        // ジャンプ長さ
        int all = 0;
        int sum = 0;
        for (int i = 0; i < listSpeak[speakIndex].length; i++) {
          int fsize = env.font_size.val;
          double w = (env.writing_mode.val == 0) ? (width - _widthPad) : (height - _heightPad);
          int chars = (w / fsize).toInt();
          double dh = env.line_height.val / 100.0;

          String s = listSpeak[speakIndex][i].replaceAll('<br />', '');
          int lineCount = (s.length / chars).toInt() + 1;
          int len = (lineCount * (fsize * dh)).toInt();

          if (i < speakLine) sum += len;
          all += len;
        }

        int ratio = (sum * 10000.0 / all).toInt();

        bool isJump = true;
        if (speakIndex == listWidth.length - 1) {
          double rest = listWidth[speakIndex] * (10000 - ratio) / 10000;
          if (rest < height) isJump = false;
        }
        if (isJump) jumpToIndex(speakIndex, ratio);
      } else {
        log('speak1() stop');
        stopSpeaking();
      }
    }
  }

  String getSpeakText2() {
    String text = '';
    if (speak2Index < listSpeak2.length) {
      text = listSpeak2[speak2Index];
    }
    return text;
  }

  Future speak2() async {
    if (isSpeaking) {
      String text = getSpeakText2();
      if (text == '「') {
        speak2Index++;
        text = getSpeakText2();
        if (pitch != pitch2) {
          pitch = pitch2;
          await flutterTts.setPitch(pitch);
        }
      } else if (text == '」') {
        speak2Index++;
        text = getSpeakText2();
        if (text == '「') {
          speak2Index++;
          text = getSpeakText2();
          if (pitch != pitch2) {
            pitch = pitch2;
            await flutterTts.setPitch(pitch);
          }
        } else {
          if (pitch != pitch1) {
            pitch = pitch1;
            await flutterTts.setPitch(pitch);
          }
        }
      }
      if (text != '') {
        await Future.delayed(Duration(milliseconds: speakWait));
        await flutterTts.speak(text);
      } else {
        speakLine++;
        speak1();
      }
    } else {
      stopSpeaking();
    }
  }

  Future stopSpeaking() async {
    isSpeaking = false;
    flutterTts.stop();
    if (oldTag != '') {
      String ss1 = 'mark1("${oldTag}", "${env.getFrontCss()}");';
      await listWebViewCtrl[oldIndex]!.evaluateJavascript(source: ss1);
      oldTag = '';
    }
    this.notifyListeners();
  }

  Future test() async {
    await listWebViewCtrl[nowIndex]!.evaluateJavascript(source: 'location.href="#p2"');
    this.notifyListeners();
  }
}

class VerticalRotated {
  static const map = {
    //' ': '　',
    '↑': '→',
    '↓': '←',
    '←': '↑',
    '→': '↓',
    '。': '︒',
    '、': '︑',
    'ー': '丨',
    '─': '丨',
    '-': '丨',
    'ｰ': '丨',
    '_': '丨 ',
    '−': '丨',
    '－': '丨',
    '—': '丨',
    '〜': '丨',
    '～': '丨',
    '／': '＼',
    '…': '︙',
    '⋯': '︙',
    '‥': '︰',
    //'︙': '…',
    '：': '︓',
    ':': '︓',
    '；': '︔',
    ';': '︔',
    '＝': '॥',
    '=': '॥',
    '（': '︵',
    '(': '︵',
    '）': '︶',
    ')': '︶',
    '［': '﹇',
    "[": '﹇',
    '］': '﹈',
    ']': '﹈',
    '｛': '︷',
    '{': '︷',
    '＜': '︿',
    //'<': '︿',
    '＞': '﹀',
    //'>': '﹀',
    '｝': '︸',
    '}': '︸',
    '「': '﹁',
    '」': '﹂',
    '『': '﹃',
    '』': '﹄',
    '【': '︻',
    '】': '︼',
    '〖': '︗',
    '〗': '︘',
    '｢': '﹁',
    '｣': '﹂',
    ',': '︐',
    '､': '︑',
  };
}
