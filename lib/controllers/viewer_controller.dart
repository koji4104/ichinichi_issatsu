import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ichinichi_issatsu/controllers/env_controller.dart';
import 'package:ichinichi_issatsu/controllers/epub_controller.dart';
import 'package:xml/xpath.dart';
import 'dart:io';
import 'dart:async';
import 'dart:developer';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '/models/book_data.dart';
import '/models/epub_data.dart';
import '/commons/widgets.dart';
import '/controllers/applog_controller.dart';

enum ViewerBottomBarType {
  none,
  tocBar,
  actionBar,
  settingsBar,
  clipTextBar,
  clipListBar,
  bookmarkBar,
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

  ViewerBottomBarType bottomBarType = ViewerBottomBarType.none;

  bool isActionBar() {
    return bottomBarType != ViewerBottomBarType.none;
  }

  List<String> listText = [];
  List<double> listWidth = [];
  List<int> listState = [];

  List<int> listRead = [];
  List<InAppWebViewController?> listWebViewCtrl = [];
  List<GlobalKey> listKey = [];
  List<ContextMenu?> listContextMenu = [];

  String? datadir;

  double scrollWidth = DEF_VIEW_SCROLL_WIDTH;
  double width = 1000.0;
  double _widthPad = Platform.isIOS ? DEF_VIEW_LINE_WIDTH : DEF_VIEW_LINE_WIDTH + 0;
  double height = 1000.0;
  double _heightPad = Platform.isIOS ? DEF_VIEW_LINE_HEIGHT : DEF_VIEW_LINE_HEIGHT + 0;

  Future load(Environment env, BookData book1, double w, double h) async {
    log('load()');
    this.env = env;
    this.book = book1;

    width = w;
    height = h;

    isLoading = true;
    listText.clear();
    listWidth.clear();
    listWebViewCtrl.clear();
    listKey.clear();
    listState.clear();
    listContextMenu.clear();

    try {
      scrollController = new ScrollController();
      scrollController!.addListener(scrollingListener);

      isLoading = true;
      this.notifyListeners();

      try {
        String appdir = (await getApplicationDocumentsDirectory()).path;
        if (!Platform.isIOS && !Platform.isAndroid) {
          appdir = appdir + '/test';
        }
        datadir = appdir + '/book';

        for (int i = 0; i < 10000; i++) {
          String path1 = '${datadir}/${book!.bookId}/text/ch${(i).toString().padLeft(4, '0')}.txt';
          if (File(path1).existsSync()) {
            String text = await File(path1).readAsStringSync();
            String body = text;

            if (env.writing_mode.val == 1) {
              VerticalRotated.map.forEach((String key, String value) {
                text = text.replaceAll(key, value);
              });
            }

            EpubData e = new EpubData();
            String text1 = e.head1 + text + e.head2;
            text1 = text1.replaceAll('<style>', '<style>${getStyle(env)}');
            //listText.add(text1);

            // chars
            int fsize = env.font_size.val;
            double w = (env.writing_mode.val == 0) ? (width - _widthPad) : (height - _heightPad);
            int chars = (w / fsize).toInt();
            body = body.replaceAll('\n', '');
            body = body.replaceAll('<h3>', '');
            body = body.replaceAll('</h3>', '<br />');

            // delete ruby
            body = EpubData.deleteRuby(body);
            List<String> list1 = body.split('<br />');
            int lines = 0;
            for (String s in list1) {
              int d = (s.length / chars).toInt() + 1;
              lines += d;
            }
            double dh = env.line_height.val / 100.0;
            double calcWidth = lines.toDouble() * (fsize * dh);
            calcWidth += scrollWidth;
            //if (!Platform.isIOS && calcWidth > 5000) calcWidth = 5000;
            if (calcWidth < 400) calcWidth = 400;
            // chars

            listWidth.add(calcWidth);
            listState.add(0);
            listWebViewCtrl.add(null);
            listKey.add(GlobalKey());
            listText.add(text1);

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
            if (i >= 1) break;
          }
        }
        isLoading = true;
        await Future.delayed(Duration(milliseconds: 500));
        this.notifyListeners();

        nowIndex = book!.prop.nowIndex;
        nowRatio = book!.prop.nowRatio;
        maxRatio = book!.prop.maxRatio;
        maxRatio = book!.prop.maxRatio;
        nowChars = getNowChars();
        jumpToIndex(nowIndex, nowRatio);
      } on Exception catch (e) {
        log('PreviewScreen.init ${e.toString()}');
      }
    } on Exception catch (e) {
      log('PreviewScreen.init ${e.toString()}');
    }
  }

  Future refresh() async {
    log('refresh()');
    try {
      listText.clear();

      try {
        String appdir = (await getApplicationDocumentsDirectory()).path;
        if (!Platform.isIOS && !Platform.isAndroid) {
          appdir = appdir + '/test';
        }
        datadir = appdir + '/book';

        for (int i = 0; i < 10000; i++) {
          String path1 = '${datadir}/${book!.bookId}/text/ch${(i).toString().padLeft(3, '0')}.txt';
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

        int ni = nowIndex;
        if (listWebViewCtrl.length > ni && listWebViewCtrl[ni] != null) {
          await listWebViewCtrl[ni]!.loadData(data: listText[ni]);
        }
        if (ni > 0 && listWebViewCtrl.length > ni - 1 && listWebViewCtrl[ni - 1] != null) {
          await listWebViewCtrl[ni - 1]!.loadData(data: listText[ni - 1]);
        }
        if (listWebViewCtrl.length > ni + 1 && listWebViewCtrl[ni + 1] != null) {
          await listWebViewCtrl[ni + 1]!.loadData(data: listText[ni + 1]);
        }
        this.notifyListeners();
      } on Exception catch (e) {
        log('PreviewScreen.init ${e.toString()}');
      }
    } on Exception catch (e) {
      log('PreviewScreen.init ${e.toString()}');
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
        text = await getSelectedText1(i);
        if (text == null) {
          text = await getSelectedText1(i - 1);
        }
        if (text == null) {
          text = await getSelectedText1(i + 1);
        }
        log('getSelectedText() [${i}] text=${text}');
      } else {
        text = 'あいうえお';
      }
    } catch (_) {
      log('err getSelectedText() [${nowIndex}]');
    }
    return text;
  }

  Future<String?> getSelectedText1(int i) async {
    if (i <= 0) return null;
    if (i >= listWebViewCtrl.length) return null;
    if (listWebViewCtrl[i] == null) return null;
    try {
      String? text = await listWebViewCtrl[i]!.getSelectedText();
      if (text != null && text == "") text = null;
      return text;
    } catch (_) {
      log('error getSelectedText() [${i}]');
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

  String jumpStatusText = '';

  Future jumpToIndex(int index, int ratio) async {
    jumpStatusText = '';
    if (scrollController == null) return;
    for (int k = 0; k < 5; k++) {
      if (scrollController!.hasClients == false) {
        log('scrollController.hasClients == false k = ${k}');
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
    this.notifyListeners();

    double curdx = scrollController!.position.pixels;
    double maxdx = scrollController!.position.maxScrollExtent;
    double dx = 0;

    for (int i = 0; i < index + 1; i++) {
      if (i < index) dx += listWidth[i];
    }
    dx += listWidth[index] * ratio / 10000;

    log('jumpTo [${index}][${(ratio / 100).toInt()}%] dx=${dx.toInt()} cur=${curdx.toInt()} max=${maxdx.toInt()}');
    if (dx > maxdx) {
      log('jumpTo index dx>max ${dx.toInt()} > ${maxdx.toInt()}');
      dx = maxdx;
    }

    int len = 3000;
    if (dx > curdx) {
      for (int i = 0; i < 1000; i++) {
        if (dx > curdx + len) {
          curdx = scrollController!.position.pixels;
          jumpStatusText = '${(curdx / 100).toInt()} / ${(dx / 100).toInt()}';
          //log('jumpTo ${jumpStatusText}');

          await scrollController!.animateTo(curdx + len, duration: Duration(milliseconds: 50), curve: Curves.linear);
          if (i % 10 == 9) await Future.delayed(Duration(milliseconds: 50));
          if (!Platform.isIOS && !Platform.isAndroid) {
            Future.delayed(Duration(milliseconds: 100));
          }
          continue;
        }
      }
    } else {
      for (int i = 0; i < 1000; i++) {
        if (dx < curdx - len) {
          curdx = scrollController!.position.pixels;
          jumpStatusText = '${(curdx / 100).toInt()} / ${(dx / 100).toInt()}';
          //log('jumpTo ${jumpStatusText}');

          await scrollController!.animateTo(curdx - len, duration: Duration(milliseconds: 50), curve: Curves.linear);
          if (i % 10 == 9) await Future.delayed(Duration(milliseconds: 50));
          continue;
        }
      }
    }

    await Future.delayed(Duration(milliseconds: 100));
    dx = 0;
    for (int i = 0; i < index + 1; i++) {
      if (i < index) dx += listWidth[i];
    }
    dx += listWidth[index] * ratio / 10000;
    await scrollController!.animateTo(dx, duration: Duration(milliseconds: 50), curve: Curves.linear);
    jumpStatusText = '';
    log('jumpTo end');
    isLoading = false;
    this.notifyListeners();
    scrollingListener();
  }

  DateTime lastTime = DateTime.now();
  double lastPixel = 0;
  int nowIndex = 0;
  int nowRatio = 0;
  int maxIndex = 0;
  int maxRatio = 0;
  int nowPixel = 0;
  int allPixel = 100;
  int nowChars = 0;

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
  }

  saveIndex() {
    if (scrollController == null) return;
    if (scrollController!.hasClients == false) return;
    if (scrollController == null) return;
    if (book == null) return;
    if (isLoading == true) return;
    log('saveIndex [${nowIndex}] ${nowRatio}');

    book!.prop.nowIndex = nowIndex;
    book!.prop.nowRatio = nowRatio;
    book!.prop.nowChars = nowChars;

    book!.prop.maxIndex = maxIndex;
    book!.prop.maxRatio = maxRatio;
    book!.prop.maxChars = book!.chars;

    book!.prop.atime = DateTime.now();

    String jsonText = json.encode(book!.prop.toJson());
    final file = File('${datadir}/${book!.bookId}/data/prop.json');
    file.writeAsString(jsonText, mode: FileMode.write, flush: true);
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
    c += '}\n';
    c += 'p {\n';
    c += '  margin: 0;\n';
    c += '}\n';
    c += 'h1, h2, h3 {\n';
    c += '  font-size: 1.2em;\n';
    c += '  font-weight: normal;\n';
    c += '  color: ${env.getH3Css()};\n';
    if (env.writing_mode.val == 0) {
      c += '  padding-left: 1em;\n';
    } else {
      c += '  padding-top: 1em;\n';
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
    ScrollPhysics physics = bottomBarType == ViewerBottomBarType.clipTextBar ? NeverScrollableScrollPhysics() : ScrollPhysics();
    try {
      return ListView.builder(
        scrollDirection: env.writing_mode.val == 0 ? Axis.vertical : Axis.horizontal,
        reverse: env.writing_mode.val == 0 ? false : true,
        shrinkWrap: true,
        controller: scrollController,
        itemCount: listText.length,
        cacheExtent: 5000,
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
    } catch (_) {
      return Container();
    }
  }

  Widget inviewer(int index, String text, Environment env) {
    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;

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
          try {
            double webWidth = 0;
            dynamic vw = await controller.evaluateJavascript(source: '''(() => { return document.body.scrollWidth; })()''');
            if (vw != null && vw != '') {
              webWidth = double.parse('${vw}');
            }
            double webHeight = 0;
            dynamic vh = await controller.evaluateJavascript(source: '''(() => { return document.body.scrollHeight; })()''');
            if (vh != null && vh != '') {
              webHeight = double.parse('${vh}');
            }

            if (env.writing_mode.val == 0) {
              if (webHeight > 100) {
                webHeight += scrollWidth;
                if (!Platform.isIOS && webHeight > 5000) {
                  webHeight = 5000;
                }
                //webHeight [38] 2747 -> 2484
                if (listWidth[index] != webHeight) {
                  log('webHeight [${index}] ${listWidth[index].toInt()} -> ${webHeight.toInt()}');
                  listWidth[index] = webHeight;
                }
              }
            } else {
              if (webWidth > 100) {
                webWidth += scrollWidth;
                if (!Platform.isIOS && webWidth > 5000) {
                  webWidth = 5000;
                }
                if (listWidth[index] != webWidth) {
                  log('webWidth [${index}] ${listWidth[index].toInt()} -> ${webWidth.toInt()}');
                  listWidth[index] = webWidth;
                }
              }
            }
            listState[index] = 1;
            this.notifyListeners();
          } catch (_) {}
        },
      );
    } catch (_) {
      return Container();
    }
  }

  InAppWebViewSettings initialSettings = InAppWebViewSettings(
    useOnLoadResource: true,
    javaScriptEnabled: true,
    enableViewportScale: true,
    mediaPlaybackRequiresUserGesture: false,
    transparentBackground: true,
    supportZoom: false,
    allowsInlineMediaPlayback: true,
    isElementFullscreenEnabled: true,
    iframeAllowFullscreen: true,
    disableLongPressContextMenuOnLinks: false,
    automaticallyAdjustsScrollIndicatorInsets: true,
    accessibilityIgnoresInvertColors: true,
    allowsLinkPreview: false,
    alwaysBounceVertical: false,
    alwaysBounceHorizontal: false,
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
    ClipData d = ClipData();
    final file = File('${datadir}/${book!.bookId}/data/clip.json');
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
    if (datadir == null) return d;
    final file = File('${datadir}/${book!.bookId}/data/clip.json');
    if (file.existsSync()) {
      String? txt = file.readAsStringSync();
      Map<String, dynamic> j = json.decode(txt);
      d = ClipData.fromJson(j);
    }
    return d;
  }

  Future deleteClip({required int index}) async {
    if (datadir == null) return;
    try {
      final file = File('${datadir}/${book!.bookId}/data/clip.json');
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
