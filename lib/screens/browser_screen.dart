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
            selectedUri == null ? getUriList() : browser(),
            downloadBar(),
          ]),
        ),
      ),
    );
  }

  Widget browser() {
    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
    //log('${selectedUrl}');

    return InAppWebView(
      key: webViewKey,
      initialUrlRequest: URLRequest(url: WebUri(selectedUri!)),
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
    if (ref.watch(epubProvider).status == MyEpubStatus.downloading) {
      String? body = await webViewController!.getHtml();
      ref.watch(epubProvider).webBody = body;
      return;
    }
    if (url == null) return;
    String? body = await webViewController!.getHtml();
    if (body == null) return;

    ref.watch(epubProvider).webViewController = webViewController;
    await ref.read(epubProvider).checkHtml(url, body);
  }

  @override
  Future onPressedCloseButton() async {
    ref.read(epubProvider).setStatusNone();
  }

  Widget downloadBar() {
    double barHeight = 220;
    double ffBottom = 0;
    if (ref.watch(epubProvider).status == MyEpubStatus.none) {
      ffBottom = -1.0 * barHeight;
    } else {
      ffBottom = 0;
    }

    String label = '';

    if (ref.watch(epubProvider).status == MyEpubStatus.downloadable) {
      label = '${ref.watch(epubProvider).epub.bookTitle ?? ref.watch(epubProvider).epub.bookId}';
      if (ref.watch(epubProvider).epub.uriList.length > 1) {
        label += ' (${ref.watch(epubProvider).epub.uriList.length})';
      }
    } else if (ref.watch(epubProvider).status == MyEpubStatus.succeeded) {
      label = 'done';
    } else if (ref.watch(epubProvider).status == MyEpubStatus.failed) {
      label = 'failed';
    } else if (ref.watch(epubProvider).status == MyEpubStatus.downloading) {
      label = 'downloading';
      int done = ref.watch(epubProvider).downloaded;
      int all = ref.watch(epubProvider).epub.uriList.length;
      if (done > 0 && all > 1) {
        label += ' ${done}/${all}';
      }
    }

    Widget bar = Container(
      color: myTheme.cardColor,
      child: Column(
        children: [
          closeButtonRow(),
          SizedBox(height: 0),
          Row(children: [
            SizedBox(width: 20),
            Expanded(child: MyText(label, noScale: true, center: true)),
            SizedBox(width: 20),
          ]),
          SizedBox(height: 8),
          Row(children: [
            Expanded(flex: 1, child: SizedBox(width: 1)),
            MyTextButton(
              noScale: true,
              width: 140,
              title: l10n('cancel'),
              onPressed: () {
                ref.read(epubProvider).setStatusNone();
              },
            ),
            SizedBox(width: 16),
            MyTextButton(
              noScale: true,
              commit: true,
              width: 140,
              title: l10n('download'),
              onPressed: () {
                ref.read(epubProvider).download();
              },
            ),
            Expanded(flex: 1, child: SizedBox(width: 1)),
          ]),
          Expanded(child: SizedBox(height: 1)),
        ],
      ),
    );

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.linear,
      left: 1,
      top: null,
      right: 1,
      bottom: ffBottom,
      height: barHeight,
      child: bar,
    );
  }

  String? selectedUri;
  List<String> uriList = [
    'https://www.aozora.gr.jp/access_ranking/2022_xhtml.html',
    'https://kakuyomu.jp',
    'https://yomou.syosetu.com',
    'https://noc.syosetu.com/top/top/',
  ];
  List<String> titleList = [
    'https://www.aozora.gr.jp/access_ranking/2022_xhtml.html',
    'https://kakuyomu.jp',
    'https://yomou.syosetu.com',
    'https://noc.syosetu.com/top/top/',
  ];

  Widget getUriList() {
    if (uriList.length <= 0) return Container();

    return Container(
      padding: DEF_MENU_PADDING,
      child: ListView.builder(
        itemCount: uriList.length,
        itemBuilder: (BuildContext context, int index) {
          return MyBookListTile(
            title: titleList[index],
            onPressed: () {
              selectedUri = uriList[index];
              redraw();
            },
          );
        },
      ),
    );
  }
}
