import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/gestures.dart';

import '/models/book_data.dart';
import '/commons/base_screen.dart';
import '/commons/widgets.dart';
import '/controllers/epub_controller.dart';
import '/controllers/browser_controller.dart';
import '/controllers/booklist_controller.dart';
import '/controllers/applog_controller.dart';

class BrowserScreen extends DownloadScreen {
  BrowserScreen() {}

  GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;

  String? selectedUri;
  String? siteTitle;

  List<String> uriList = [];
  List<String> titleList = [];

  FavoData initFavorite = FavoData();
  FavoData favorite = FavoData();

  @override
  Future init() async {}

  bool isActionButton() {
    if (webViewController == null) return false;
    if (selectedUri == null) return false;
    return true;
  }

  String getSiteTitle() {
    if (selectedUri == null) {
      siteTitle = l10n('brows');
    } else if (siteTitle == null) {
      siteTitle = l10n('brows');
    }
    return siteTitle!;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    super.build(context, ref);
    ref.watch(browserProvider);
    ref.watch(epubProvider);

    initFavorite = ref.watch(browserProvider).initFavorite;
    favorite = ref.watch(browserProvider).favorite;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (webViewController != null) {
          if (await webViewController!.canGoBack()) {
            await webViewController!.goBack();
            log('goBack');
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(siteTitle ?? l10n('brows')),
          leading: (isActionButton() == false)
              ? null
              : IconButton(
                  icon: Icon(Icons.arrow_back_ios_new),
                  onPressed: () async {
                    if (webViewController != null) {
                      if (await webViewController!.canGoBack()) {
                        await webViewController!.goBack();
                        log('goBack');
                      }
                    }
                  },
                ),
          actions: [
            if (isActionButton())
              MyIconLabelButton(
                //label: l10n('bookmark'),
                icon: Icon(Icons.star_border),
                onPressed: () async {
                  if (webViewController != null) {
                    String? title = await webViewController!.getTitle();
                    alertDialog('save', msg: title).then((ret) {
                      ref.read(browserProvider).webViewController =
                          webViewController;
                      ref.read(browserProvider).saveFavorite();
                    });
                  }
                },
              ),
            SizedBox(width: 16)
          ],
        ),
        body: SafeArea(
          child: Stack(children: [
            Container(
              padding: DEF_MENU_PADDING,
              //child: ref.read(epubProvider).downloadCtrl.browser8(),
              child: epubCtrl.downloadCtrl.browser8(),
            ),
            Container(
              color: myTheme.scaffoldBackgroundColor,
              padding: DEF_MENU_PADDING,
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.read(browserProvider).readUriList();
                },
                child: widget1(),
              ),
            ),
            downloadBar(),
          ]),
        ),
      ),
    );
  }

  Widget widget1() {
    if (selectedUri != null) {
      return browser();
    }
    if (favorite.list.length > 0) {
      return Column(
        children: [
          Row(children: [
            Expanded(child: SizedBox(width: 1)),
            Text('${l10n('swipe_to_delete')}',
                textScaler: TextScaler.linear(myTextScale * 0.7)),
            SizedBox(width: 10),
          ]),
          Expanded(child: getUriList()),
        ],
      );
    } else {
      return getUriList();
    }
  }

  Widget browser() {
    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
    try {
      return InAppWebView(
        key: webViewKey,
        initialUrlRequest: URLRequest(url: WebUri(selectedUri!)),
        onWebViewCreated: (controller) async {
          webViewController = controller;
        },
        onLoadStart: (controller, url) {},
        onLoadStop: (controller, url) async {
          try {
            List<MetaTag> metaTagList = await webViewController!.getMetaTags();
            for (MetaTag tag in metaTagList) {
              if (tag.attrs!.length > 0) {
                if (tag.attrs![0].name == 'property' &&
                    tag.attrs![0].value == 'og:title') {
                  log('onLoadStop og:title = ${tag.content}');
                  siteTitle = tag.content;
                  break;
                } else if (tag.attrs![0].name == 'property' &&
                    tag.attrs![0].value == 'twitter:title') {
                  log('onLoadStop twitter:title = ${tag.content}');
                  siteTitle = tag.content;
                  break;
                }
              }
            }
          } catch (e) {
            MyLog.err('browser() ${e.toString()}');
          }
          if (url != null) {
            checkHtml(url: url.rawValue);
            redraw();
          }
        },
      );
    } catch (e) {
      MyLog.err('browser() ${e.toString()}');
      return Container();
    }
  }

  checkHtml({String? url}) async {
    MyLog.debug('checkHtml() ${url}');
    try {
      if (url == null) return;
      String? body = await webViewController!.getHtml();
      if (body == null) return;
      //ref.read(epubProvider).webViewController = webViewController;
      epubCtrl.webViewController = webViewController;
      //await ref.read(epubProvider).checkHtml(url, body);

      await epubCtrl.checkHtml(url, body);
    } catch (e) {
      MyLog.err('checkHtml() ${e.toString()}');
    }
  }

  @override
  redraw() {
    ref.read(browserProvider).notifyListeners();
  }

  @override
  Future onPressedCloseButton() async {
    //ref.read(epubProvider).setStatusNone();
    epubCtrl.setStatusNone();
  }

  Widget getUriList() {
    if (initFavorite.list.length <= 0) return Container();

    List<FavoInfo> favoList = [];
    List<Widget> list = [];
    for (FavoInfo info in initFavorite.list) {
      favoList.add(info);
      list.add(MyUriListTile(
        favo: info,
        onPressed: () {
          selectedUri = info.uri;
          redraw();
        },
      ));
    }
    for (FavoInfo info in favorite.list) {
      info.type = 1;
      favoList.add(info);
      list.add(MyUriListTile(
        favo: info,
        onPressed: () {
          selectedUri = info.uri;
          redraw();
        },
      ));
    }
    return ListView.builder(
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
              if (favoList[index].type == 1)
                MySlidableAction(
                  onPressed: (_) {
                    deleteDialog().then((ret) {
                      if (ret) {
                        log('delette');
                        ref
                            .read(browserProvider)
                            .deleteFavorite(favoList[index].uri);
                      }
                    });
                  },
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.redAccent,
                  icon: Icons.delete,
                  label: l10n('delete'),
                  spacing: 0,
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget MyUriListTile({
    required FavoInfo favo,
    Function()? onPressed,
  }) {
    Widget e = Expanded(child: SizedBox(width: 1));
    Widget w = SizedBox(width: 10);
    Icon icon = Icon(Icons.arrow_forward_ios, size: 14.0);

    double scale = myTextScale;

    Widget wTitle = Text(
      l10n(favo.title),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
      textScaler: TextScaler.linear(scale),
    );
    Widget wUri = Text(
      Uri.decodeFull(favo.uri),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      textScaler: TextScaler.linear(scale * 0.8),
    );

    double height = 50 + (30 * myTextScale);
    Widget child = Row(children: [
      w,
      Expanded(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          e,
          wTitle,
          Row(children: [Expanded(child: wUri)]),
          e,
        ]),
      ),
      w,
      icon,
    ]);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: myTheme.cardColor,
        border: Border(
          top: BorderSide(color: myTheme.dividerColor, width: 0.3),
          bottom: BorderSide(color: myTheme.dividerColor, width: 0.3),
        ),
      ),
      child: TextButton(
        child: child,
        onPressed: onPressed,
      ),
    );
  }

  @override
  Future onDownloadFinished() async {
    //ref.read(booklistProvider).readBookList();
  }
}
