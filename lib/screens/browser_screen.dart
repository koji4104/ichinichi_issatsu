import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '/commons/base_screen.dart';
import '/commons/widgets.dart';
import '/controllers/epub_controller.dart';
import '/screens/booklist_screen.dart';

final browserScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());

class BrowserScreen extends BaseScreen {
  BrowserScreen() {}

  GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  //MyEpubController ctrl = new MyEpubController();

  bool isDownloadBar = false;

  @override
  Future init() async {}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    super.build(context, ref);
    ref.watch(browserScreenProvider);
    ref.watch(epubProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (await webViewController!.canGoBack()) {
          await webViewController!.goBack();
          log('goBack');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Brows'),
        ),
        body: SafeArea(
          child: Stack(children: [
            selectedUrl == null ? getUrlList() : browser(),
            downloadBar(),
          ]),
        ),
      ),
    );
  }

  Widget browser() {
    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
    log('${selectedUrl}');

    return InAppWebView(
      key: webViewKey,
      initialUrlRequest: URLRequest(url: WebUri(selectedUrl!)),
      onWebViewCreated: (controller) async {
        webViewController = controller;
      },
      onLoadStart: (controller, url) {},
      onLoadStop: (controller, url) async {
        if (url != null) {
          checkHtml(url: url.rawValue);
        }
      },
    );
  }

  checkHtml({String? url}) async {
    if (url == null) return;
    String? body = await webViewController!.getHtml();
    if (body == null) return;

    await ref.read(epubProvider).checkHtml(url, body);
    if (ref.read(epubProvider).epub.urlList.length > 0) {
      isDownloadBar = true;
      sleep(Duration(milliseconds: 100));
      redraw();
    } else {
      isDownloadBar = false;
      redraw();
    }
  }

  Widget downloadBar() {
    double settingsHeight = 240;
    double ffBottom = 0;
    if (isDownloadBar == false) {
      ffBottom = -1.0 * settingsHeight;
    } else {
      ffBottom = 0;
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.linear,
      left: 1,
      top: null,
      right: 1,
      bottom: ffBottom,
      height: settingsHeight,
      child: downloadBar1(),
    );
  }

  Widget downloadBar1() {
    String title = 'Download ${ref.watch(epubProvider).epub.bookId}';
    if (ref.watch(epubProvider).epub.urlList.length > 1) {
      title += '(${ref.watch(epubProvider).epub.urlList.length})';
    }

    String label = '';
    if (ref.watch(epubProvider).status == MyEpubStatus.succeeded) {
      label = 'done';
    } else if (ref.watch(epubProvider).status == MyEpubStatus.failed) {
      label = 'failed';
    } else if (ref.watch(epubProvider).status == MyEpubStatus.downloading) {
      label = 'downloading';
    }

    return Container(
      color: myTheme.scaffoldBackgroundColor,
      child: Column(
        children: [
          Row(children: [
            IconButton(
              icon: Icon(Icons.close),
              iconSize: 20,
              onPressed: () async {
                isDownloadBar = false;
                redraw();
              },
            ),
            Expanded(flex: 1, child: SizedBox(width: 1)),
            IconButton(
              icon: Icon(Icons.close),
              iconSize: 20,
              onPressed: () async {
                isDownloadBar = false;
                redraw();
              },
            ),
          ]),
          //SizedBox(height: 1, child: Container(color: myTheme.dividerColor)),
          SizedBox(height: 4),
          Row(children: [
            Expanded(flex: 1, child: SizedBox(width: 1)),
            label == ''
                ? MyTextButton(
                    title: title,
                    onPressed: () {
                      ref.read(epubProvider).download();
                    },
                  )
                : MyText(label),
            Expanded(flex: 1, child: SizedBox(width: 1)),
          ]),
          Expanded(child: SizedBox(height: 1)),
        ],
      ),
    );
  }

  String? selectedUrl;
  List<String> listUrl = [
    'https://www.aozora.gr.jp/access_ranking/2022_xhtml.html',
    'https://kakuyomu.jp',
    'https://syosetu.com',
  ];

  Widget getUrlList() {
    if (listUrl.length <= 0) return Container();

    return Container(
      padding: DEF_MENU_PADDING,
      child: ListView.builder(
        itemCount: listUrl.length,
        itemBuilder: (BuildContext context, int index) {
          return MyBookTile(
            title1: MyText(listUrl[index]),
            onPressed: () {
              selectedUrl = listUrl[index];
              redraw();
            },
          );
        },
      ),
    );
  }
}
