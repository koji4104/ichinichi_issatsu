import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ichinichi_issatsu/controllers/env_controller.dart';
import 'package:ichinichi_issatsu/controllers/epub_controller.dart';
import 'package:xml/xpath.dart';
import 'dart:io';
import 'dart:async';
import 'dart:developer';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '/models/book_data.dart';
import '/models/epub_data.dart';
import '/commons/widgets.dart';

final viewerProvider = ChangeNotifierProvider((ref) => ViewerNotifier(ref));

class ViewerNotifier extends ChangeNotifier {
  ViewerNotifier(ref) {
    Future.delayed(const Duration(seconds: 1), () {
      //onTimer();
    });
  }

  @override
  void dispose() {}

  Environment env1 = Environment();
  BookData? book;
  ScrollController? scrollController;
  bool isLoading = false;

  //Timer? _timer;

  List<String> listText = [];
  List<double> listWidth = [];
  List<int> listState = [];
  double widthRate = 1.0;

  List<int> listRead = [];
  List<InAppWebViewController?> listWebViewController = [];
  List<GlobalKey> listKey = [];
  List<FindInteractionController?> listFindController = [];
  List<ContextMenu?> listContextMenu = [];

  String? datadir;

  double scrollWidth = DEF_VIEW_SCROLL_WIDTH;
  double width = 1000.0;
  double _widthPad =
      Platform.isIOS ? DEF_VIEW_LINE_WIDTH : DEF_VIEW_LINE_WIDTH + DEF_VIEW_SCROLL_WIDTH;
  double height = 1000.0;
  double _heightPad =
      Platform.isIOS ? DEF_VIEW_LINE_HEIGHT : DEF_VIEW_LINE_HEIGHT + DEF_VIEW_SCROLL_WIDTH;

  Future load(Environment env, BookData book1, double w, double h) async {
    log('load()');
    env1 = env;
    this.book = book1;
    String appdir = (await getApplicationDocumentsDirectory()).path;
    if (!Platform.isIOS && !Platform.isAndroid) {
      appdir = appdir + '/test';
    }
    datadir = appdir + '/data';

    width = w;
    height = h;
    try {
      listText.clear();
      listWidth.clear();
      listWebViewController.clear();
      listKey.clear();
      listState.clear();
      listFindController.clear();
      listContextMenu.clear();

      scrollController = new ScrollController();
      scrollController!.addListener(scrollingListener);

      try {
        String appdir = (await getApplicationDocumentsDirectory()).path;
        if (!Platform.isIOS && !Platform.isAndroid) {
          appdir = appdir + '/test';
        }
        datadir = appdir + '/data';

        for (int i = 0; i < 1000; i++) {
          String path1 = '${datadir}/${book!.bookId}/text/ch${(i).toString().padLeft(3, '0')}.txt';
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
            listText.add(text1);

            // chars
            int fsize = env.font_size.val;
            double w = (env.writing_mode.val == 0) ? (width - _widthPad) : (height - _heightPad);
            int chars = (w / fsize).toInt();
            body = body.replaceAll('\n', '');
            body = body.replaceAll('</h3>', '<br /><br />');

            // delete ruby
            // <ruby><rb>獅子</rb><rp>（</rp><rt>しし</rt><rp>）</rp></ruby>
            body = body.replaceAll('<ruby>', '');
            body = body.replaceAll('</ruby>', '');
            body = body.replaceAll('<rb>', '');
            body = body.replaceAll('</rb>', '');
            body = body.replaceAll('<rp>', '');
            body = body.replaceAll('</rp>', '');
            body = body.replaceAll('<rt>', '');
            body = body.replaceAll('</rt>', '');

            List<String> list1 = body.split('<br />');

            int lines = 0;
            for (String s in list1) {
              int d = (s.length / chars).toInt() + 1;
              lines += d;
            }

            double dh = env.line_height.val / 100.0;
            double calcWidth = lines.toDouble() * (fsize * dh);
            calcWidth += scrollWidth;
            if (!Platform.isIOS && calcWidth > 10000) calcWidth = 10000;
            if (calcWidth < 800) calcWidth = 800;
            // chars

            listWidth.add(calcWidth);
            listState.add(0);
            listWebViewController.add(null);
            listKey.add(GlobalKey());

            if (Platform.isIOS || Platform.isAndroid) {
              FindInteractionController findCtrl = FindInteractionController(
                onFindResultReceived:
                    (controller, activeMatchOrdinal, numberOfMatches, isDoneCounting) async {
                  if (isDoneCounting) {
                    //setState(() {
                    String textFound =
                        numberOfMatches > 0 ? '${activeMatchOrdinal + 1} of $numberOfMatches' : '';
                    log('textFound = ${textFound}');
                    //});
                    if (numberOfMatches == 0) {
                      //ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      //  content: Text('No matches found for "${await findInteractionController.getSearchText()}"'),
                      //));
                    }
                  }
                },
              );
              listFindController.add(findCtrl);
            } else {
              listFindController.add(null);
            }

            ContextMenu contextMenu = ContextMenu(
                settings: ContextMenuSettings(hideDefaultSystemContextMenuItems: true),
                menuItems: [
                  ContextMenuItem(
                    androidId: 1,
                    iosId: "1",
                    title: "Special",
                    action: () async {
                      print("Menu item Special clicked!");

                      //var selectedText = await _webViewController.getSelectedText();
                      //await _webViewController.clearFocus();
                      //await _webViewController.evaluateJavascript(source: "window.alert('You have selected: $selectedText')");
                    },
                  )
                ],

                //options: ContextMenuOptions(hideDefaultSystemContextMenuItems: false),
                onCreateContextMenu: (hitTestResult) async {
                  print("onCreateContextMenu");
                  print('hitTestResult.extra ${hitTestResult.extra}');
                  //print(await _webViewController.getSelectedText());
                },
                onHideContextMenu: () {
                  print("onHideContextMenu");
                },
                onContextMenuActionItemClicked: (contextMenuItemClicked) async {
                  //var id = (Platform.isAndroid) ? contextMenuItemClicked.androidId : contextMenuItemClicked.iosId;
                  //print("onContextMenuActionItemClicked: " + id.toString() + " " + contextMenuItemClicked.title);
                });
            listContextMenu.add(contextMenu);
          } else {
            if (i > 0) break;
          }
        }
        isLoading = true;
        await Future.delayed(Duration(milliseconds: 1000));
        this.notifyListeners();
        await Future.delayed(Duration(milliseconds: 1000));
        jumpToIndex(book!.info.lastIndex, book!.info.lastRate);
      } on Exception catch (e) {
        print('-- PreviewScreen.init ${e.toString()}');
      }
    } on Exception catch (e) {
      print('-- PreviewScreen.init ${e.toString()}');
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

  Future find(int index, String text) async {
    index = nowIndex;
    if (listFindController.length < index) return;
    if (listFindController[index] == null) return;
    if (listState[index] == 0) return;
    await listFindController[index]!.findAll(find: text);

    var selectedText = await listWebViewController[index]!.getSelectedText();
    log('selectedText ${selectedText}');
  }

  Future findNext(int index) async {
    if (listFindController.length < index) return;
    if (listFindController[index] == null) return;
    if (listState[index] == 0) return;
    listFindController[index]!.findNext();
  }

  Future next(int index) async {
    if (listWebViewController.length < index) return;
    if (listWebViewController[index] == null) return;
    if (Platform.isIOS || Platform.isAndroid) {
      String? st = await listWebViewController[index]!.getSelectedText();
      if (st != null) log('next ${st}');
    }
  }

  Future jumpToIndex(int index, int rate) async {
    if (scrollController == null) return;
    for (int k = 0; k < 5; k++) {
      if (scrollController!.hasClients == false) {
        log('scrollController.hasClients == false k = ${k}');
        this.notifyListeners();
        await Future.delayed(Duration(milliseconds: 100));
      }
    }
    if (scrollController!.hasClients == false) {
      log('return jumpTo index [${index}] ${(rate / 100).toInt()}%');
      return;
    }
    if (listWidth.length == 0) return;
    //if (isLoading) return;
    if (index > listWidth.length - 1) index = listWidth.length - 1;
    isLoading = true;

    double curdx = scrollController!.position.pixels;
    double maxdx = scrollController!.position.maxScrollExtent;

    isLoading = true;

    double dx = 0;
    for (int i = 0; i < index + 1; i++) {
      if (listState[i] == 2) {
        double sdx = dx;
        curdx = scrollController!.position.pixels;
        maxdx = scrollController!.position.maxScrollExtent;
        if (sdx > maxdx) sdx = maxdx;
        if (sdx > curdx) scrollController!.jumpTo(sdx);
        await Future.delayed(Duration(milliseconds: 50));
        this.notifyListeners();
        for (int k = 0; k < 10; k++) {
          if (listState[i] == 0) {
            if (k > 2 && i > 0) scrollController!.jumpTo(sdx += 100);
            log('jumpTo ${sdx.toInt()}px max ${maxdx.toInt()} k ${k}');
            await Future.delayed(Duration(milliseconds: 50));
          }
        }
      }
      if (i < index) dx += listWidth[i];
    }
    dx += listWidth[index] * rate / 10000;

    curdx = scrollController!.position.pixels;
    maxdx = scrollController!.position.maxScrollExtent;

    log('jumpTo index [${index}] ${(rate / 100).toInt()}% ${dx.toInt()}px ${curdx.toInt()}/${maxdx.toInt()}');
    if (dx > maxdx) {
      log('jumpTo index dx>max ${dx.toInt()} > ${maxdx.toInt()}');
      dx = maxdx;
    }
    if (dx > curdx) {
      //scrollController!.jumpTo(dx);
      for (int i = 0; i < 1000; i++) {
        if (dx > curdx + 2000) {
          log('jumpTo curdx +1000 ${curdx.toInt()}');
          curdx = scrollController!.position.pixels;
          await scrollController!
              .animateTo(curdx + 2000, duration: Duration(milliseconds: 100), curve: Curves.linear);
          continue;
        }
      }
      scrollController!.jumpTo(dx);
    } else {
      for (int i = 0; i < 1000; i++) {
        if (dx < curdx - 2000) {
          log('jumpTo curdx -1000 ${curdx.toInt()}');
          curdx = scrollController!.position.pixels;
          await scrollController!
              .animateTo(curdx - 2000, duration: Duration(milliseconds: 100), curve: Curves.linear);
          continue;
        }
      }
      scrollController!.jumpTo(dx);
    }

    await Future.delayed(Duration(milliseconds: 100));
    this.notifyListeners();
    isLoading = false;
    scrollingListener();
  }

  DateTime lastTime = DateTime.now();
  double lastPixel = 0;
  int nowIndex = 0;
  int nowRate = 0;
  int nowPixel = 0;
  int allPixel = 100;

  String getProgress() {
    int per = (nowPixel * 100 / allPixel).toInt();
    return '${per}%  ${nowPixel}/${allPixel}';
  }

  void scrollingListener() async {
    if (scrollController == null) return;
    if (scrollController!.hasClients == false) return;

    double px = scrollController!.position.pixels;
    final past = lastTime.add(Duration(seconds: 1));
    if (DateTime.now().compareTo(past) > 0 && (lastPixel - px).abs() > 100) {
      return;
    }
    lastTime = DateTime.now();
    lastPixel = px;

    for (int i = 0; i < listWidth.length; i++) {
      if (px < listWidth[i]) {
        nowIndex = i;
        nowRate = (px * 10000.0 / listWidth[i]).toInt();
        break;
      }
      px -= listWidth[i];
    }
    nowPixel = scrollController!.position.pixels.toInt();
    allPixel = 1;
    for (int i = 0; i < listWidth.length; i++) {
      allPixel += listWidth[i].toInt();
    }
    saveIndex();
  }

  saveIndex() {
    if (scrollController == null) return;
    if (scrollController!.hasClients == false) return;
    if (scrollController == null) return;
    if (book == null) return;
    if (nowIndex == 0 && nowRate < 100) return;
    if (isLoading == true) return;
    log('saveIndex [${nowIndex}]');
    book!.info.lastIndex = nowIndex;
    book!.info.lastRate = nowRate;
    String jsonText = json.encode(book!.info.toJson());
    final file = File('${datadir}/${book!.bookId}/book_info.json');
    file.writeAsString(jsonText, mode: FileMode.write, flush: true);
  }

  updateStylesheet(int index, Environment env) async {
    if (!Platform.isIOS && !Platform.isAndroid) return;
    if (listWebViewController.length <= index) return;
    if (listWebViewController[index] == null) return;
    String c = getStyle(env);
    await listWebViewController[index]!.injectCSSCode(source: c);
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
    c += '  color: ${env.getFrontCssColor()};\n';
    c += '  background: ${env.getBackCssColor()};\n';
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
    c += '  font-size: 1.0em;\n';
    c += '  font-weight: bold;\n';
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
    //if (_inited == false) return Container();
    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
    try {
      return ListView.builder(
        scrollDirection: env.writing_mode.val == 0 ? Axis.vertical : Axis.horizontal,
        reverse: env.writing_mode.val == 0 ? false : true,
        shrinkWrap: true,
        controller: scrollController,
        itemCount: listText.length,
        cacheExtent: 2000,
        physics: AlwaysScrollableScrollPhysics(),
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
        findInteractionController: listFindController[index],
        contextMenu: listContextMenu[index],
        onWebViewCreated: (controller) async {
          listWebViewController[index] = controller;
        },
        onLoadStart: (controller, url) async {
          //await updateStylesheet(index, env);
        },
        onLoadStop: (controller, url) async {
          try {
            double webWidth = 0;
            dynamic vw = await controller
                .evaluateJavascript(source: '''(() => { return document.body.scrollWidth; })()''');
            if (vw != null && vw != '') {
              webWidth = double.parse('${vw}');
            }
            double webHeight = 0;
            dynamic vh = await controller
                .evaluateJavascript(source: '''(() => { return document.body.scrollHeight; })()''');
            if (vh != null && vh != '') {
              webHeight = double.parse('${vh}');
            }

            if (env.writing_mode.val == 0 && webHeight > 100) {
              webHeight += scrollWidth;
              if (listWidth[index] != webHeight) {
                log('onLoadStop height [${index}] ${env.font_size.val}px ${env.line_height.val}% ${listWidth[index].toInt()} -> ${webHeight.toInt()}');
                listWidth[index] = webHeight;
              }
            } else if (webWidth > 100) {
              webWidth += scrollWidth;
              if (!Platform.isIOS && webWidth > 10000) webWidth = 10000;
              if (listWidth[index] != webWidth) {
                log('onLoadStop width [${index}] ${env.font_size.val}px ${env.line_height.val}% ${listWidth[index].toInt()} -> ${webWidth.toInt()}');
                listWidth[index] = webWidth;
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

  String getSubTitle() {
    if (book == null) return '';
    if (book!.indexList.length <= nowIndex) return '';
    return book!.indexList[nowIndex].title;
  }

  String clipText = 'needToInit';
  bool changeedClipText = false;

  /// Timer
  void onTimer() async {
    if (clipText == 'needToInit') {
      clipText = await getClipText();
    } else {
      String text = await getClipText();
      if (clipText != text) {
        clipText = text;
        changeedClipText = true;
        log('onTimer ${clipText}');
        this.notifyListeners();
      }
    }
    Future.delayed(const Duration(seconds: 1), () {
      onTimer();
    });
  }

  Future<String> getClipText() async {
    String s = '';
    ClipboardData? clip = await Clipboard.getData(Clipboard.kTextPlain);
    if (clip != null && clip.text != null && clip.text != '') {
      s = clip.text!;
      if (s.length > 100) {
        s = s.substring(0, 100);
      }
      if (env1.writing_mode.val == 1) {
        VerticalRotated.map.forEach((String key, String value) {
          s = s.replaceAll(value, key);
        });
      }
    }
    return s;
  }

  saveClip(String text) async {
    BookClipData d = BookClipData();

    final file = File('${datadir}/${book!.bookId}/book_clip.json');
    if (file.existsSync()) {
      String? txt = await file.readAsString();
      Map<String, dynamic> j = json.decode(txt);

      d = BookClipData.fromJson(j);
    }
    ClipData c = ClipData();
    c.index = nowIndex;
    c.rate = nowRate;
    c.text = text;
    d.list.add(c);
    String jsonText = await d.toJsonString();
    file.writeAsString(jsonText, mode: FileMode.write, flush: true);
  }

  BookClipData readClip() {
    BookClipData d = BookClipData();
    if (datadir == null) return d;
    final file = File('${datadir}/${book!.bookId}/book_clip.json');
    if (file.existsSync()) {
      String? txt = file.readAsStringSync();
      Map<String, dynamic> j = json.decode(txt);
      d = BookClipData.fromJson(j);
    }
    return d;
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
    '‥': '︰',
    '︙': '…',
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
