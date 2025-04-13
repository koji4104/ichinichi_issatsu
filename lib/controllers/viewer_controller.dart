import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:io';
import 'dart:async';
import 'dart:developer';
import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '/models/book_data.dart';
import '/models/epub_data.dart';
import '/commons/widgets.dart';
import '/controllers/applog_controller.dart';
import '/constants.dart';
import '/controllers/env_controller.dart';

enum ViewerBottomBarType {
  none,
  tocBar,
  actionBar,
  settingsBar,
  clipTextBar,
  clipListBar,
  maxpageBar,
  speakBar,
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

  ScrollController? scrollController;
  bool isLoading = false;

  DateTime lastTime = DateTime.now();
  double lastPixel = 0;
  int nowIndex = 0;
  int nowRatio = 0;
  int maxIndex = 0;
  int maxRatio = 0;
  int nowPixel = 0;
  int allPixel = 100;
  int nowChars = 0;

  ViewerBottomBarType bottomBarType = ViewerBottomBarType.none;

  bool isActionBar() {
    return bottomBarType != ViewerBottomBarType.none;
  }

  List<String> listText = [];
  List<List<String>> listLine = [[]];
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
    log('load()');
    this.env = env;

    width = w;
    height = h;

    isLoading = true;
    listText.clear();
    listWidth.clear();
    listWebViewCtrl.clear();
    listKey.clear();
    listContextMenu.clear();
    listLine.clear();

    try {
      scrollController = new ScrollController();
      scrollController!.addListener(scrollingListener);

      this.notifyListeners();
      await Future.delayed(Duration(milliseconds: 100));

      String bookdir = APP_DIR + '/book';

      for (int i = 0; i < 10000; i++) {
        String path1 = '${bookdir}/${book!.bookId}/text/ch${(i).toString().padLeft(4, '0')}.txt';
        if (File(path1).existsSync()) {
          String text1 = await File(path1).readAsStringSync();
          String body = text1;
          String speech = text1;

          if (env.writing_mode.val == 1) {
            VerticalRotated.map.forEach((String key, String value) {
              text1 = text1.replaceAll(key, value);
            });
          }

          EpubData e = new EpubData();
          text1 = e.head1 + text1 + e.head2;
          text1 = text1.replaceAll('<style>', '<style>${getStyle(env)}');
          text1 += '<br />';

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

          //log('rubyCount ${i} ${rubyCount}');

          // delete ruby
          body = EpubData.deleteRuby(body);
          List<String> list1 = body.split('<br />');
          int lineCount = 0;
          for (String s in list1) {
            int d = (s.length / chars).toInt() + 1;
            lineCount += d;
          }
          lineCount += 1;
          lineCount += (rubyCount / (40 + fsize)).toInt();

          double dh = env.line_height.val / 100.0;
          double calcWidth = lineCount.toDouble() * (fsize * dh);
          calcWidth += scrollWidth;
          if (calcWidth < 400) calcWidth = 400;
          if (Platform.isIOS == false && Platform.isAndroid == false) {
            if (calcWidth > 3000) calcWidth = 3000;
            book!.prop.nowIndex = 1;
            book!.prop.nowRatio = 0;
          }
          // chars

          // speech
          List<String> lines = [];
          speech = speech.replaceAll('\n', '');
          speech = speech.replaceAll('<h3>', '');
          speech = speech.replaceAll('</h3>', '<br />');
          speech = speech.replaceAll('<h2>', '');
          speech = speech.replaceAll('</h2>', '<br />');
          speech = EpubData.extractRuby(speech);
          List<String> list2 = speech.split('<br />');
          for (String s in list2) {
            if (s.length > 1) lines.add(s);
          }
          listLine.add(lines);
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
      }

      await Future.delayed(Duration(milliseconds: 100));
      this.notifyListeners();

      nowIndex = book!.prop.nowIndex;
      nowRatio = book!.prop.nowRatio;
      maxRatio = book!.prop.maxRatio;
      maxRatio = book!.prop.maxRatio;
      nowChars = getNowChars();
      jumpToIndex(nowIndex, nowRatio);
    } on Exception catch (e) {
      MyLog.err('ViewerNotifier.losd() ${e.toString()}');
    }
  }

  Future refresh() async {
    log('refresh()');
    try {
      listText.clear();

      String bookdir = APP_DIR + '/book';

      for (int i = 0; i < 10000; i++) {
        String path1 = '${bookdir}/${book!.bookId}/text/ch${(i).toString().padLeft(4, '0')}.txt';
        if (File(path1).existsSync()) {
          String text = await File(path1).readAsStringSync();

          if (env.writing_mode.val == 1) {
            VerticalRotated.map.forEach((String key, String value) {
              text = text.replaceAll(key, value);
            });
          }

          EpubData e = new EpubData();
          String text1 = e.head1 + text + e.head2;
          text1 = text1.replaceAll('<style>', '<style>${getStyle(env)}');
          listText.add(text1);
        } else {
          if (i >= 1) break;
        }
      }

      await Future.delayed(Duration(milliseconds: 100));

      if (Platform.isIOS) {
        int ni = nowIndex;
        if (listWebViewCtrl.length > ni && listWebViewCtrl[ni] != null && listText.length > ni) {
          try {
            await listWebViewCtrl[ni]!.loadData(data: listText[ni]);
          } on Exception catch (e) {
            log('warn ViewerNotifier.refresh()');
          }
        }
        if (ni > 0 &&
            listWebViewCtrl.length > ni - 1 &&
            listWebViewCtrl[ni - 1] != null &&
            listText.length > ni - 1) {
          try {
            await listWebViewCtrl[ni - 1]!.loadData(data: listText[ni - 1]);
          } on Exception catch (e) {
            log('warn ViewerNotifier.refresh()');
          }
        }
        if (listWebViewCtrl.length > ni + 1 &&
            listWebViewCtrl[ni + 1] != null &&
            listText.length > ni + 1) {
          try {
            await listWebViewCtrl[ni + 1]!.loadData(data: listText[ni + 1]);
          } on Exception catch (e) {
            log('warn ViewerNotifier.refresh()');
          }
        }
      } else {
        log('refresh() loadData is ios only');
      }
      this.notifyListeners();
    } on Exception catch (e) {
      MyLog.err('ViewerNotifier.refresh() ${e.toString()}');
    }
  }

  scrollRight() {
    if (scrollController == null) return;
    if (scrollController!.hasClients == false) return;
    var px = scrollController!.position.pixels + 400.0;
    if (px < 0) px = 0;
    scrollController!.animateTo(px, duration: Duration(milliseconds: 600), curve: Curves.linear);
  }

  scrollLeft() {
    if (scrollController == null) return;
    if (scrollController!.hasClients == false) return;
    var px = scrollController!.position.pixels - 400.0;
    final maxpx = scrollController!.position.maxScrollExtent;
    if (px > maxpx) px = maxpx;
    scrollController!.animateTo(px, duration: Duration(milliseconds: 600), curve: Curves.linear);
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
    if (scrollController == null) return;
    try {
      for (int k = 0; k < 5; k++) {
        if (scrollController!.hasClients == false) {
          log('scrollController.hasClients==false k=${k}');
          this.notifyListeners();
          await Future.delayed(Duration(milliseconds: 100));
        }
      }
      if (scrollController!.hasClients == false) {
        log('return jumpTo index [${index}] ${(ratio / 100).toInt()}%');
        return;
      }
      if (listWidth.length == 0) return;

      if (index > listWidth.length - 1) index = listWidth.length - 1;
      isLoading = true;
      nowIndex = index;
      this.notifyListeners();

      double curdx = scrollController!.position.pixels;
      double maxdx = scrollController!.position.maxScrollExtent;

      double dx = 0;
      for (int i = 0; i < index + 1; i++) {
        if (i < index) dx += listWidth[i];
      }
      dx += listWidth[index] * ratio / 10000;

      log('jumpTo [${index}][${(ratio / 100).toInt()}%] cur=${curdx.toInt()} dx=${dx.toInt()} max=${maxdx.toInt()}');
      await scrollController!
          .animateTo(dx, duration: Duration(milliseconds: 500), curve: Curves.linear);

      isLoading = false;
      this.notifyListeners();
      scrollingListener();
    } on Exception catch (e) {
      MyLog.err('jumpToIndex() ${e.toString()}');
    }
  }

  String getProgress() {
    if (book == null) return '';
    int c = book!.chars;
    if (c < 1) c = 1;
    int per = (nowChars * 100 / c).toInt();
    return '${per} %';
  }

  Future moveMaxpage() async {
    jumpToIndex(maxIndex, maxRatio);
  }

  Future resetMaxpage() async {
    maxIndex = nowIndex;
    maxRatio = nowRatio;
    saveIndex();
    notifyListeners();
  }

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
    if (book == null) return '-1';
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
    return '${(chars / 450).toInt()}';
  }

  String getMaxPage() {
    if (book == null) return '-1';
    int chars = 0;
    for (int i = 0; i < book!.index.list.length; i++) {
      if (i < maxIndex) {
        chars += book!.index.list[i].chars;
      } else if (i == maxIndex) {
        chars += (book!.index.list[i].chars * maxRatio / 10000).toInt();
      } else {
        break;
      }
    }
    return '${(chars / 450).toInt()}';
  }

  void scrollingListener() async {
    if (scrollController == null) return;
    if (scrollController!.hasClients == false) return;
    if (isLoading == true) return;
    try {
      double px = scrollController!.position.pixels;
      final past = lastTime.add(Duration(seconds: 1));
      if (DateTime.now().compareTo(past) < 1 || (lastPixel - px).abs() < 200) {
        return;
      }

      if (isActionBar() && bottomBarType != ViewerBottomBarType.tocBar) {
        bottomBarType = ViewerBottomBarType.none;
      }

      lastTime = DateTime.now();
      lastPixel = px;

      for (int i = 0; i < listWidth.length; i++) {
        if (px < listWidth[i]) {
          nowIndex = i;
          nowRatio = (px * 10000.0 / listWidth[i]).toInt();
          break;
        }
        px -= listWidth[i];
      }
      nowChars = getNowChars();
      nowPixel = scrollController!.position.pixels.toInt();
      allPixel = 1;
      for (int i = 0; i < listWidth.length; i++) {
        allPixel += listWidth[i].toInt();
      }

      if (maxIndex * 10000 + maxRatio <= nowIndex * 10000 + nowRatio) {
        maxIndex = nowIndex;
        maxRatio = nowRatio;
      }
      saveIndex();
    } on Exception catch (e) {
      MyLog.err('scrollingListener() ${e.toString()}');
    }
  }

  saveIndex() {
    if (scrollController == null) return;
    if (scrollController!.hasClients == false) return;
    if (scrollController == null) return;
    if (book == null) return;
    if (isLoading == true) return;

    try {
      book!.prop.nowIndex = nowIndex;
      book!.prop.nowRatio = nowRatio;
      book!.prop.nowChars = nowChars;

      book!.prop.maxIndex = maxIndex;
      book!.prop.maxRatio = maxRatio;
      book!.prop.maxChars = book!.chars;

      book!.prop.atime = DateTime.now();

      String bookdir = APP_DIR + '/book';
      String jsonText = json.encode(book!.prop.toJson());
      final file = File('${bookdir}/${book!.bookId}/data/prop.json');
      file.writeAsString(jsonText, mode: FileMode.write, flush: true);
    } on Exception catch (e) {
      MyLog.err('saveIndex() ${e.toString()}');
    }
  }

  String getStyle(Environment env) {
    int fontSize = env.font_size.val;
    String fontFamily = env.getFontFamily();

    String writing_mode = 'width: ${(width - _widthPad).toInt()}px';
    if (env.writing_mode.val == 1) {
      writing_mode = 'height: ${(height - _heightPad).toInt()}px';
    }

    String c = '';
    if (env.writing_mode.val == 1) {
      c += 'html {\n';
      c += '  -webkit-writing-mode: vertical-rl;\n';
      c += '  -epub-writing-mode: tb-rl;\n';
      c += '  writing-mode: vertical-rl;\n';
      c += '  text-orientation: upright;\n';
      c += '  -webkit-text-orientation: upright;\n';
      c += '}\n';
    }
    c += 'body {\n';
    c += '  color: ${env.getFrontCss()};\n';
    c += '  background: ${env.getBackCss()};\n';
    c += '  font-size: ${fontSize}px;\n';
    c += '  font-family: ${fontFamily};\n';
    c += '  ${writing_mode};\n';
    c += '  word-break: break-all;\n';
    c += '  line-height: ${env.line_height.val}%;\n';

    if (env.writing_mode.val == 0) {
      c += '  padding-left: 0em;\n';
    } else {
      c += '  padding-top: 0em;\n';
      c += '  padding-bottom: 1em;\n';
      c += '  margin: 10;\n';
    }

    c += '}\n';
    c += 'p {\n';
    c += '  margin: 0;\n';
    c += '}\n';
    c += 'h1, h2, h3 {\n';
    c += '  font-size: 1.2em;\n';
    c += '  font-weight: normal;\n';
    c += '  color: ${env.getH3Css()};\n';
    if (env.writing_mode.val == 0) {
      c += '  padding-left: 0em;\n';
    } else {
      c += '  padding-top: 0em;\n';
    }
    c += '  line-height: ${env.line_height.val}%;\n';
    c += '}\n';
    c += 'h4, h5 {\n';
    c += '  font-size: 1.0em;\n';
    c += '  font-weight: normal;\n';
    c += '  line-height: ${env.line_height.val}%;\n';
    c += '}\n';
    return c;
  }

  Widget viewer(Environment env) {
    if (listText.length == 0) return Container();

    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
    ScrollPhysics physics = bottomBarType == ViewerBottomBarType.clipTextBar
        ? NeverScrollableScrollPhysics()
        : ScrollPhysics();
    try {
      return ListView.builder(
        scrollDirection: env.writing_mode.val == 0 ? Axis.vertical : Axis.horizontal,
        reverse: env.writing_mode.val == 0 ? false : true,
        shrinkWrap: true,
        controller: scrollController,
        itemCount: listText.length,
        cacheExtent: 10000,
        physics: physics,
        hitTestBehavior: HitTestBehavior.opaque,
        itemBuilder: (context, int index) {
          if (listWidth.length <= index) return Container();
          if (env.writing_mode.val == 0) {
            return SizedBox(
              height: listWidth[index],
              child: inviewer(index, listText[index], env),
            );
          } else {
            return SizedBox(
              width: listWidth[index],
              child: inviewer(index, listText[index], env),
            );
          }
        },
      );
    } on Exception catch (e) {
      MyLog.err('ViewerNotifier.viewer() ${e.toString()}');
      return Container();
    }
  }

  DateTime lastView = DateTime.now();

  Widget inviewer(int index, String text, Environment env) {
    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
    if ((nowIndex - index).abs() > 2) {
      return Container();
    }
    //log('inviewer [${index}]');
    try {
      return InAppWebView(
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
          if (controller == null) log('error onLoadStop controller==null');
          if (IS_UNUSE_VIEW_WIDTH == true) {
            if (nowIndex == index) this.notifyListeners();
            return;
          }
          if (index == 0) {
            this.notifyListeners();
            return;
          }
          //log('onLoadStop [${index}]');
          try {
            dynamic vw = null;
            if (env.writing_mode.val == 0) {
              vw = await controller.evaluateJavascript(
                  source: '''(() => { return document.body.scrollHeight; })()''');
            } else {
              vw = await controller.evaluateJavascript(
                  source: '''(() => { return document.body.scrollWidth; })()''');
            }
            if (vw != null && vw != '') {
              double dw = double.parse('${vw}');
              if (dw > 400 && (dw - listWidth[index]).abs() > 10) {
                if ((dw - listWidth[index]) > 100) {
                  // 隙間が多い不具合
                  dw = listWidth[index] + 100;
                }
                int d = dw.toInt();
                int l = listWidth[index].toInt();
                if ((d - l).abs() >= 100) {
                  MyLog.debug('webWidth [${index}] ${env.font_size.val}px ${l} ${d - l}');
                }
                listWidth[index] = dw;
              }
            }

            DateTime old = lastView.add(Duration(milliseconds: 100));
            //log('[${index}] compareTo = ${DateTime.now().compareTo(old)}');
            if (DateTime.now().compareTo(old) > 0) {
              log('[${index}] compareTo = ${DateTime.now().compareTo(old)}');
              await Future.delayed(Duration(milliseconds: 100));
            }
            lastView = DateTime.now();
            this.notifyListeners();
          } catch (_) {}
        },
      );
    } catch (_) {
      return Container();
    }
  }

  InAppWebViewSettings initialSettings = InAppWebViewSettings(
    useOnLoadResource: false,
    javaScriptEnabled: true,
    enableViewportScale: false,
    mediaPlaybackRequiresUserGesture: false,
    transparentBackground: true,
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
    // Cache
    clearCache: true,
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
  FlutterTts flutterTts = FlutterTts();
  bool initialized = false;
  bool isSpeaking = false;
  int speakIndex = 0;
  int speakLine = 0;

  Future startSpeaking() async {
    if (initialized == false) {
      initialized = true;

      // 言語を設定する
      await flutterTts.setLanguage("ja-JP");

      // 特定の言語が利用可能かどうかを確認する
      //await flutterTts.isLanguageAvailable("en-US");

      // OSのボイス名一覧
      List voices = await flutterTts.getVoices;
      for (var item in voices) {
        var map = item as Map<Object?, Object?>;
        // 日本語のみ
        if (map["locale"].toString().toLowerCase().contains("ja")) {
          log('voices ${map["name"].toString()}');
        }
      }

      // iOS, macOS only
      //await flutterTts.setVoice({"identifier": "com.apple.voice.compact.en-AU.Karen"});

      flutterTts.setCompletionHandler(() async {
        speakLine++;
        speak();
      });
    }

    // 速さ
    await flutterTts.setSpeechRate(0.5);

    // 音量
    await flutterTts.setVolume(1.0);

    // ピッチ
    await flutterTts.setPitch(1.0);

    // ボイス
    //com.apple.eloquence.ja-JP.Eddy
    //com.apple.eloquence.ja-JP.Flo
    //com.apple.voice.compact.ja-JP.Kyoko", "com.apple.voice.enhanced.ja-JP.Kyoko",
    //com.apple.eloquence.ja-JP.Rocko
    //com.apple.eloquence.ja-JP.Shelley
    //await flutterTts.setVoice({"identifier": "com.apple.eloquence.ja-JP.Eddy"});

    //[log] voices O-ren
    //[log] voices Kyoko
    //[log] voices Hattori
    await flutterTts.setVoice({"name": "O-ren", "locale": "ja-JP"});

    speakIndex = nowIndex;
    if (speakIndex > listLine.length - 1) speakIndex = listLine.length - 1;
    speakLine = (listLine[speakIndex].length * nowRatio / 10000).toInt();

    isSpeaking = true;
    speak();
  }

  Future speak() async {
    if (isSpeaking) {
      if (speakLine >= listLine[speakIndex].length) {
        speakIndex++;
        speakLine = 0;
      }
      if (speakIndex >= listLine.length) {
        isSpeaking = false;
      }
      if (isSpeaking) {
        await Future.delayed(Duration(milliseconds: 1000));
        String text = listLine[speakIndex][speakLine];
        await flutterTts.speak(text);
        log('${text}');
      }
    }
  }

  Future stopSpeaking() async {
    isSpeaking = false;
    flutterTts.stop();
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
