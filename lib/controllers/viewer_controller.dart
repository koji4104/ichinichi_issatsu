import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ichinichi_issatsu/controllers/env_controller.dart';
import 'package:xml/xpath.dart';
import 'dart:io';
import 'dart:async';
import 'dart:developer';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '/models/book_data.dart';

final viewerProvider = ChangeNotifierProvider((ref) => ViewerNotifier(ref));

class ViewerNotifier extends ChangeNotifier {
  ViewerNotifier(ref) {
    scrollController = ScrollController();
    scrollController.addListener(scrollingListener);
  }

  BookData? book;
  late ScrollController scrollController;
  bool _inited = false;
  bool isLoading = false;

  List<String> listText = [];
  List<double> listWidth = [];
  List<int> listState = [];
  double widthRate = 1.0;

  List<int> listRead = [];
  List<InAppWebViewController?> listWebViewController = [];
  List<GlobalKey> listKey = [];

  late String datadir;

  double width = 1000.0;
  double _widthPad = 60 + 20;
  double height = 1000.0;
  double _heightPad = 120 + 60;

  int type = 1;

  Future load(Environment env, BookData book1, double w, double h) async {
    this.book = book1;

    _inited = true;
    String appdir = (await getApplicationDocumentsDirectory()).path;
    if (!Platform.isIOS && !Platform.isAndroid) {
      appdir = appdir + '/test';
    }
    datadir = appdir + '/data';

    width = w;
    height = h;
    try {
      _inited = false;
      listText.clear();
      listWidth.clear();
      listWebViewController.clear();
      listKey.clear();
      listState.clear();

      try {
        String appdir = (await getApplicationDocumentsDirectory()).path;
        if (!Platform.isIOS && !Platform.isAndroid) {
          appdir = appdir + '/test';
        }
        datadir = appdir + '/data';

        for (int i = 0; i < 1000; i++) {
          String path1 =
              '${datadir}/${book!.bookId}/text/ch${(i + 1).toString().padLeft(3, '0')}.xhtml';
          if (File(path1).existsSync()) {
            String text = await File(path1).readAsStringSync();
            text = text.replaceAll('</body>', '<br /><br /></body>');
            listText.add(text);

            int fsize = env.font_size.val;
            double line = (env.writing_mode.val == 0) ? (width - _widthPad) : (height - _heightPad);
            double numChar = line / fsize;
            double numLine = (text.length * 1.2) / numChar;
            double calcWidth = numLine * fsize;
            listWidth.add(calcWidth);

            listState.add(0);
            listWebViewController.add(null);
            listKey.add(GlobalKey());
          } else {
            break;
          }
        }
        jumpToIndex(book!.info.lastIndex, book!.info.lastRate);
        this.notifyListeners();
      } on Exception catch (e) {
        print('-- PreviewScreen.init ${e.toString()}');
      }
      _inited = true;
    } on Exception catch (e) {
      print('-- PreviewScreen.init ${e.toString()}');
    }
  }

  scrollRight() {
    if (scrollController.hasClients == false) return;
    var px = scrollController.position.pixels + 400.0;
    if (px < 0) px = 0;
    scrollController.animateTo(px, duration: Duration(milliseconds: 600), curve: Curves.linear);
  }

  scrollLeft() {
    if (scrollController.hasClients == false) return;
    var px = scrollController.position.pixels - 400.0;
    final maxpx = scrollController.position.maxScrollExtent;
    if (px > maxpx) px = maxpx;
    scrollController.animateTo(px, duration: Duration(milliseconds: 600), curve: Curves.linear);
  }

  Future jumpToIndex(int index, int rate) async {
    if (scrollController.hasClients == false) return;
    if (listWidth.length == 0) return;
    if (isLoading) return;
    if (index > listWidth.length - 1) index = listWidth.length - 1;
    isLoading = true;

    double dx1 = 0;
    for (int i = 0; i < index + 1; i++) {
      if (listState.length > i && listState[i] == 0) {
        scrollController.jumpTo(dx1);
        for (int j = 0; j < 20; j++) {
          await Future.delayed(Duration(milliseconds: 32));
          if (listState[i] == 1) {
            log('listState[${i}]==1  j=${j}');
            break;
          }
        }
      }
      dx1 += listWidth[i];
    }

    double dx = 0;
    for (int i = 0; i < index; i++) {
      dx += listWidth[i];
      if (listState[i] == 0) {
        log('listState[${i}]=${listState[i]}');
      }
    }
    dx += listWidth[index] * rate / 10000;

    log('jumpTo index ${index} ${(rate / 100).toInt()}% ${dx.toInt()}px');
    if (dx > scrollController.position.maxScrollExtent)
      dx = scrollController.position.maxScrollExtent;
    scrollController.jumpTo(dx);
    isLoading = false;
    lastTime = DateTime.now().add(Duration(seconds: -5));
    scrollingListener();
    this.notifyListeners();
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
    if (scrollController.hasClients == false) return;
    if (_inited == false) return;

    double px = scrollController.position.pixels;
    final past = DateTime.now().add(Duration(seconds: -1));
    if (lastTime.compareTo(past) > 0 && (lastPixel - px).abs() > 100) {
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
    nowPixel = scrollController.position.pixels.toInt();
    allPixel = 1;
    for (int i = 0; i < listWidth.length; i++) {
      allPixel += listWidth[i].toInt();
    }
    saveIndex();
  }

  saveIndex() {
    if (scrollController.hasClients == false) return;
    if (scrollController == null) return;
    if (book == null) return;
    if (nowIndex == 0 && nowRate < 100) return;

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
    c += '}\n';
    c += 'p {\n';
    c += '  margin: 0;\n';
    c += '}\n';
    c += 'h1, h2, h3 {\n';
    c += '  font-size: 1.2em;\n';
    c += '}\n';
    return c;
  }

  Widget viewer(Environment env) {
    if (listText.length == 0) return Container();
    if (_inited == false) return Container();

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
  }

  Widget inviewer(int index, String text, Environment env) {
    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
    return InAppWebView(
      key: listKey[index],
      initialData: InAppWebViewInitialData(data: text),
      initialSettings: initialSettings,
      onWebViewCreated: (controller) async {
        listWebViewController[index] = controller;
      },
      onLoadStart: (controller, url) async {
        await updateStylesheet(index, env);
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

          if (env.writing_mode.val == 0 && webWidth > 100) {
            if (listWidth[index] != webHeight) {
              log('onLoadStop height ${index} ${listWidth[index].toInt()} -> ${webHeight.toInt()}');
              listWidth[index] = webHeight;
              listState[index] = 1;
            }
          } else if (webHeight > 100) {
            if (listWidth[index] != webWidth) {
              log('onLoadStop width ${index} ${listWidth[index].toInt()} -> ${webWidth.toInt()}');
              listWidth[index] = webWidth;
              listState[index] = 1;
            }
          }
          this.notifyListeners();
        } catch (_) {}
      },
    );
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
    verticalScrollBarEnabled: true,
    horizontalScrollBarEnabled: true,
    disableVerticalScroll: false,
    disableHorizontalScroll: false,
    useWideViewPort: true,
    disableContextMenu: true,
    disableInputAccessoryView: true,
    shouldPrintBackgrounds: true,
    selectionGranularity: SelectionGranularity.DYNAMIC,
    defaultFixedFontSize: 11,
    defaultFontSize: 11,
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
}
