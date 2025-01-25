import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/gestures.dart';

import '/models/book_data.dart';
import '/commons/base_screen.dart';
import '/commons/widgets.dart';
import '/controllers/epub_controller.dart';
import '/controllers/browser_controller.dart';
import '/screens/booklist_screen.dart';

final browserScreenProvider = ChangeNotifierProvider((ref) => ChangeNotifier());

class BrowserScreen extends BaseScreen {
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
  Future init() async {
    //log('BrowserScreen() init()');
    //readUri();
  }

  bool isActionButton() {
    if (webViewController == null) return false;
    if (selectedUri == null) return false;
    return true;
  }

  String getSiteTitle() {
    if (selectedUri == null) {
      siteTitle == 'Brows';
    } else if (siteTitle == null) {
      siteTitle == 'Brows';
    }
    return siteTitle!;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    super.build(context, ref);
    ref.watch(browserScreenProvider);
    ref.watch(browserProvider);
    ref.watch(epubProvider);

    //uriList = ref.watch(browserProvider).uriList;
    //titleList = ref.watch(browserProvider).titleList;

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
          title: Text(siteTitle ?? 'Brows'),
          //leadingWidth: 150,
          leading: (isActionButton() == false)
              ? null
              : IconButton(
                  iconSize: 22,
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
              IconButton(
                icon: Icon(Icons.star_border),
                onPressed: () async {
                  if (webViewController != null) {
                    String? title = await webViewController!.getTitle();
                    alertDialog('save', msg: title).then((ret) {
                      ref.watch(browserProvider).webViewController = webViewController;
                      ref.watch(browserProvider).saveFavorite();
                    });
                  }
                },
              ),
            SizedBox(width: 16)
          ],
        ),
        body: SafeArea(
          child: Stack(children: [
            ref.watch(epubProvider).downloadCtrl.browser8(),
            //widget1(),

            Container(
              color: myTheme.scaffoldBackgroundColor,
              padding: DEF_MENU_PADDING,
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.watch(browserProvider).readUriList();
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
    return getUriList();
  }

  Widget browser() {
    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
    return InAppWebView(
      key: webViewKey,
      initialUrlRequest: URLRequest(url: WebUri(selectedUri!)),
      onWebViewCreated: (controller) async {
        webViewController = controller;
      },
      onLoadStart: (controller, url) {},
      onLoadStop: (controller, url) async {
        List<MetaTag> metaTagList = await webViewController!.getMetaTags();
        for (MetaTag tag in metaTagList) {
          if (tag.attrs!.length > 0) {
            if (tag.attrs![0].name == 'property' && tag.attrs![0].value == 'og:title') {
              log('onLoadStop og:title = ${tag.content}');
              siteTitle = tag.content;
              break;
            } else if (tag.attrs![0].name == 'property' && tag.attrs![0].value == 'twitter:title') {
              log('onLoadStop twitter:title = ${tag.content}');
              siteTitle = tag.content;
              break;
            }
          }
        }

        if (url != null) {
          checkHtml(url: url.rawValue);
          redraw();
        }
      },
    );
  }

  checkHtml({String? url}) async {
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

  /*
  Widget downloadBar1() {
    double barHeight = 230;
    double ffBottom = 0;
    if (ref.watch(epubProvider).status == MyEpubStatus.none) {
      ffBottom = -1.0 * barHeight;
    } else {
      ffBottom = 0;
    }

    String label1 = '';
    String label2 = '';
    int already = ref.watch(epubProvider).downloadedIndex;
    int done = ref.watch(epubProvider).downloaded;
    int all = ref.watch(epubProvider).epub.uriList.length;

    label1 = '${ref.watch(epubProvider).epub.bookTitle ?? ref.watch(epubProvider).epub.bookId}';

    if (ref.watch(epubProvider).status == MyEpubStatus.downloadable) {
      if (all > 1) {
        label2 += ' (${all})';
      }
      if (already > 1) {
        label2 += ' Already (${already})';
      }
    } else if (ref.watch(epubProvider).status == MyEpubStatus.succeeded) {
      label2 = 'Download complete (${all})';
    } else if (ref.watch(epubProvider).status == MyEpubStatus.failed) {
      label2 = 'Failed';
    } else if (ref.watch(epubProvider).status == MyEpubStatus.downloading) {
      label2 = 'Downloading';
      if (done > 0 && all > 1) {
        label2 += ' ${done} / ${all}';
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
            Expanded(child: MyText(label1, noScale: true, center: true)),
            SizedBox(width: 20),
          ]),
          SizedBox(height: 8),
          Row(children: [
            SizedBox(width: 20),
            Expanded(child: MyText(label2, noScale: true, center: true)),
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
      left: 0,
      top: null,
      right: 0,
      bottom: ffBottom,
      height: barHeight,
      child: bar,
    );
  }
  */

  Widget getUriList() {
    if (initFavorite.list.length <= 0) return Container();

    List<FavoInfo> favoList = [];
    List<Widget> list = [];
    for (FavoInfo info in initFavorite.list) {
      favoList.add(info);
      list.add(MyUriListTile(
        title: info.title,
        onPressed: () {
          selectedUri = info.uri;
          redraw();
        },
      ));
    }
    for (FavoInfo info in favorite.list) {
      favoList.add(info);
      list.add(MyUriListTile(
        title: info.title,
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
                SlidableAction(
                  onPressed: (_) {
                    deleteDialog().then((ret) {
                      if (ret) {
                        log('delette');
                        ref.watch(browserProvider).deleteFavorite(favoList[index].uri);
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
    );
  }

  Widget MyUriListTile({
    required String title,
    Function()? onPressed,
  }) {
    Widget e = Expanded(child: SizedBox(width: 8));
    Widget w = SizedBox(width: 6);
    Icon icon = Icon(Icons.arrow_forward_ios, size: 14.0);

    double scale = myTextScale;

    Widget wText = Text(
      title,
      overflow: TextOverflow.ellipsis,
      maxLines: 3,
      textScaler: TextScaler.linear(scale),
    );

    double height = 44 + (14 * myTextScale);
    Widget child = Row(children: [
      Expanded(child: wText),
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
}
