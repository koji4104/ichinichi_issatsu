import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:io';
import 'dart:developer';

import '/localizations.dart';
import '/commons/widgets.dart';
import '/controllers/env_controller.dart';
import '/controllers/epub_controller.dart';

/// BaseScreen
class BaseScreen extends ConsumerWidget {
  late BuildContext context;
  late WidgetRef ref;

  Environment get env {
    return myEnv;
  }

  @override
  bool bInit = false;

  Future init() async {
    if (bInit == false) {
      bInit = true;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    this.context = context;
    this.ref = ref;
    myLanguageCode = env.language_code.val == 0 ? 'ja' : 'en';

    if (bInit == false) {
      bInit = true;
      Future.delayed(Duration.zero, () => init());
    }
    return Container();
  }

  Future<int?> NavigatorPush(var screen) async {
    int? ret = await Navigator.of(context).push(MaterialPageRoute<int>(
      builder: (context) => screen,
    ));
    return ret;
  }

  String l10n(String text) {
    return Localized.text(text);
  }

  void showSnackBar(String msg) {
    final snackBar = SnackBar(content: MyText(msg));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<bool> okDialog({String? msg}) async {
    return alertDialog('ok', msg: msg);
  }

  Future<bool> deleteDialog() async {
    return alertDialog('delete');
  }

  Future<bool> alertDialog(String title, {String? msg}) async {
    bool ret = false;
    Widget? wMsg = null;
    if (msg != null) {
      wMsg = MyText(l10n(msg), maxLength: 80, maxLines: 5);
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          shape: RoundedRectangleBorder(borderRadius: DEF_BORDER_RADIUS),
          titlePadding: EdgeInsets.all(0.0),
          contentPadding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          actionsPadding: EdgeInsets.fromLTRB(8, 16, 8, 16),
          buttonPadding: EdgeInsets.all(0.0),
          iconPadding: EdgeInsets.all(0.0),
          backgroundColor: myTheme.cardColor,
          content: wMsg,
          actions: <Widget>[
            alertButton(
              title: 'cancel',
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            SizedBox(width: 10),
            alertButton(
              title: title,
              onPressed: () {
                ret = true;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    return ret;
  }

  /// Used with alertDialog()
  Widget alertButton({
    required String title,
    required void Function()? onPressed,
    double? width,
  }) {
    Color? fgcol = Color(0xFFFFFFFF);
    Color? bgcol = Colors.blueAccent;
    Color? bdcol = null;
    double scale = myTextScale;

    if (title == 'cancel') {
      fgcol = myTheme.textTheme.bodyMedium!.color!;
      bgcol = null;
      bdcol = myTheme.dividerColor;
      if (scale > 1.2) scale = 1.2;
    } else if (title == 'delete') {
      fgcol = Color(0xFFFFFFFF);
      bgcol = Colors.redAccent;
      bdcol = null;
    }

    return Container(
      width: width != null ? width : 120,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: bgcol,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(DEF_RADIUS))),
          side: bdcol != null ? BorderSide(color: bdcol) : null,
        ),
        child: Text(
          l10n(title),
          style: TextStyle(color: fgcol),
          textAlign: TextAlign.center,
          textScaler: TextScaler.linear(scale),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget MySettingsTile({required EnvData data}) {
    Widget e = Expanded(child: SizedBox(width: 1));
    Widget child = Row(children: [
      MyText(l10n(data.name)),
      e,
      MySettingsDropdown(data: data),
    ]);

    return Container(
      decoration: BoxDecoration(
        color: myTheme.cardColor,
        border: Border(
          top: BorderSide(color: myTheme.dividerColor, width: 0.3),
          bottom: BorderSide(color: myTheme.dividerColor, width: 0.3),
        ),
      ),
      height: 22 + (16 * myTextScale),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: child,
    );
  }

  Widget MySettingsDropdown({required EnvData data}) {
    List<DropdownMenuItem> list = [];
    for (int i = 0; i < data.vals.length; i++) {
      DropdownMenuItem<int> w = DropdownMenuItem<int>(
        value: data.vals[i],
        child: MyText(l10n(data.keys[i])),
      );
      list.add(w);
    }
    return DropdownButton(
      items: list,
      value: data.val,
      onChanged: (value) {
        if (data.val != value) {
          ref.read(envProvider).saveVal(data, value).then((ret) {
            if (ret) onSettingsDropdownChanged(data);
          });
        }
      },
      dropdownColor: myTheme.secondaryHeaderColor,
      style: myTheme.textTheme.bodyMedium!,
    );
  }

  @override
  onSettingsDropdownChanged(EnvData data) {
    ref.read(envProvider).notifyListeners();
  }

  @override
  Future onPressedCloseButton() async {
    redraw();
  }

  @override
  redraw() {}

  IconButton closeButton() {
    return IconButton(
      icon: Icon(Icons.close),
      iconSize: 20,
      constraints: BoxConstraints(minWidth: 0.0, minHeight: 0.0),
      padding: EdgeInsets.all(2),
      onPressed: () async {
        onPressedCloseButton();
      },
    );
  }

  Widget closeButtonRow() {
    return Container(
      child: Column(children: [
        SizedBox(height: 2),
        Row(children: [
          SizedBox(width: 2),
          closeButton(),
          Expanded(flex: 1, child: SizedBox(width: 1)),
          closeButton(),
          SizedBox(width: 2),
        ]),
      ]),
    );
  }

  bool isDownloadFinished = false;

  @override
  Future onDownloadFinished() async {}

  /// ダウンロードバー
  Widget downloadBar() {
    double barHeight = Platform.isIOS ? 260 : 200;
    double ffBottom = 0;
    if (ref.watch(epubProvider).status == MyEpubStatus.none) {
      ffBottom = -1.0 * barHeight;
    } else if (ref.watch(epubProvider).status == MyEpubStatus.downloading) {
      ffBottom = -1.0 * 80;
    } else {
      ffBottom = 0;
    }

    int DL_COUNT1 = 10;
    int DL_COUNT2 = 100;
    int DL_SPARE = 10;

    bool isClose = false;
    String label1 = '';
    String label2 = '';
    int already = ref.watch(epubProvider).existingIndex;
    int done = ref.watch(epubProvider).doneIndex;
    int all = ref.watch(epubProvider).epub.uriList.length;
    int req1 = 0;
    int req2 = 0;
    label1 =
        '${ref.watch(epubProvider).epub.bookTitle ?? ref.watch(epubProvider).epub.bookId}';

    if (ref.watch(epubProvider).status == MyEpubStatus.downloadable) {
      if (all == 1) {
        // 全1話
        req1 = all;
        req2 = 0;
      } else if (all > 0 && already == 0) {
        // 初回ダウンロード
        if (all < DL_COUNT1 + DL_SPARE) {
          req1 = all;
          req2 = 0;
        } else if (all < DL_COUNT2 + DL_SPARE) {
          req1 = DL_COUNT1;
          req2 = all;
        } else {
          req1 = DL_COUNT1;
          req2 = DL_COUNT2;
        }
      } else if (all > 0 && already > 0) {
        // 追加ダウンロード
        if (all < already + DL_COUNT1 + DL_SPARE) {
          req1 = all;
          req2 = 0;
        } else if (all < already + DL_COUNT2 + DL_SPARE) {
          req1 = already + DL_COUNT1;
          req2 = all;
        } else {
          req1 = already + DL_COUNT1;
          req2 = already + DL_COUNT2;
        }
      }
      if (all > 1 && already > 1) {
        label2 += '${already} / ${all} ${l10n('episode')}';
      } else if (all > 1) {
        label2 += '${all} ${l10n('episode')}';
      }
    } else if (ref.watch(epubProvider).status == MyEpubStatus.succeeded) {
      // 成功
      label2 = '${l10n('download_complete')} ${done} / ${all}';
      isClose = true;
    } else if (ref.watch(epubProvider).status == MyEpubStatus.same) {
      // 最新
      label2 = '${l10n('already_downloaded')} ${already} / ${all}';
      isClose = true;
    } else if (ref.watch(epubProvider).status == MyEpubStatus.failed) {
      // 失敗
      label2 = '${l10n('download_failed')}';
      isClose = true;
    } else if (ref.watch(epubProvider).status == MyEpubStatus.downloading) {
      // ダウンロード中
      label1 = 'Downloading';
      if (done > 0) {
        label1 += ' ${done} / ${all}';
      }
    }

    Widget h = SizedBox(height: 4);
    Widget btn = Column(children: []);
    double btnWidth = 240;

    if (isClose) {
      btn = Column(children: [
        MyTextButton(
          noScale: true,
          width: btnWidth,
          title: l10n('close'),
          onPressed: () {
            ref.read(epubProvider).setStatusNone();
          },
        ),
      ]);
    } else if (req1 > 0) {
      // 10 話 まで ダウンロード
      String btnTitle1 =
          '${req1} ${l10n('episode')} ${l10n('up_to')} ${l10n('download')}';
      if (req1 == 1) btnTitle1 = '${l10n('download')}';
      String btnTitle2 =
          '${req2} ${l10n('episode')} ${l10n('up_to')} ${l10n('download')}';

      btn = Column(children: [
        MyTextButton(
          noScale: true,
          width: btnWidth,
          commit: true,
          title: btnTitle1,
          onPressed: () {
            ref.read(epubProvider).download(req1).then((ret) {
              if (ret) {
                onDownloadFinished();
              }
            });
          },
        ),
        if (req2 > 0) h,
        if (req2 > 0)
          MyTextButton(
            noScale: true,
            width: btnWidth,
            commit: true,
            title: btnTitle2,
            onPressed: () {
              ref.read(epubProvider).download(req2).then((ret) {
                if (ret) {
                  onDownloadFinished();
                }
              });
            },
          ),
        h,
        MyTextButton(
          noScale: true,
          width: btnWidth,
          title: l10n('cancel'),
          onPressed: () {
            ref.read(epubProvider).setStatusNone();
          },
        ),
      ]);
    }

    Widget bar = Container(
      color: myTheme.cardColor,
      child: Column(
        children: [
          closeButtonRow(),
          Row(children: [
            SizedBox(width: 20),
            Expanded(child: MyText(label1, noScale: true, center: true)),
            SizedBox(width: 20),
          ]),
          if (label2 != '') SizedBox(height: 4),
          if (label2 != '')
            Row(children: [
              SizedBox(width: 20),
              Expanded(child: MyText(label2, noScale: true, center: true)),
              SizedBox(width: 20),
            ]),
          SizedBox(height: 6),
          btn,
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
}
