import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '/localizations.dart';
import '/commons/widgets.dart';
import 'dart:io';
import 'dart:developer';

import '/controllers/env_controller.dart';
import '/controllers/epub_controller.dart';

/// BaseScreen
class BaseScreen extends ConsumerWidget {
  late BuildContext context;
  late WidgetRef ref;
  ChangeNotifierProvider baseProvider = ChangeNotifierProvider((ref) => ChangeNotifier());

  late Environment env;
  bool bInit = false;

  @override
  Future init() async {
    if (bInit == false) {
      bInit = true;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(baseProvider);
    this.context = context;
    this.ref = ref;
    this.env = ref.watch(envProvider).env;

    ref.watch(envProvider);
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
          contentPadding: EdgeInsets.fromLTRB(8, 8, 8, 0),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(DEF_RADIUS))),
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

  redraw() {
    if (ref.read(baseProvider) != null) ref.read(baseProvider)!.notifyListeners();
  }

  Widget MySettingsTile({required EnvData data}) {
    Widget e = Expanded(child: SizedBox(width: 1));
    Widget child = Row(children: [MyText(l10n(data.name)), e, MyDropdown(data: data)]);

    return Container(
      decoration: BoxDecoration(
        color: myTheme.cardColor,
        border: Border(
          top: BorderSide(color: myTheme.dividerColor, width: 0.3),
          bottom: BorderSide(color: myTheme.dividerColor, width: 0.3),
        ),
      ),
      height: 30 + (16 * myTextScale),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: child,
    );
  }

  Widget MyDropdown({required EnvData data}) {
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
            if (ret) onDropdownChanged(data);
          });
        }
      },
      dropdownColor: myTheme.secondaryHeaderColor,
      style: myTheme.textTheme.bodyMedium!,
    );
  }

  onDropdownChanged(EnvData data) {
    ref.read(envProvider).notifyListeners();
  }

  @override
  Future onPressedCloseButton() async {
    redraw();
  }

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
        Container(
          color: myTheme.scaffoldBackgroundColor,
          height: 4,
        ),
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

  @override
  Future onDownloadFinished() async {}

  Widget downloadBar() {
    double barHeight = Platform.isIOS ? 300 : 200;
    double ffBottom = 0;
    if (ref.watch(epubProvider).status == MyEpubStatus.none) {
      ffBottom = -1.0 * barHeight;
    } else {
      ffBottom = 0;
    }

    int DL_COUNT1 = 20;
    int DL_COUNT2 = 50;
    int DL_SPARE = 10;

    bool isClose = false;
    bool isCancel = false;
    String label1 = '';
    String label2 = '';
    int already = ref.watch(epubProvider).existingIndex;
    int done = ref.watch(epubProvider).doneIndex;
    int all = ref.watch(epubProvider).epub.uriList.length;
    int req1 = 1;
    int req2 = 0;
    label1 = '${ref.watch(epubProvider).epub.bookTitle ?? ref.watch(epubProvider).epub.bookId}';

    if (ref.watch(epubProvider).status == MyEpubStatus.downloadable) {
      if (all > 0 && already == 0) {
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
      label2 = '${l10n('download_complete')} ${done} / ${all}';
      isClose = true;
      onDownloadFinished();
    } else if (ref.watch(epubProvider).status == MyEpubStatus.same) {
      label2 = '${l10n('already_downloaded')} ${already} / ${all}';
      isClose = true;
    } else if (ref.watch(epubProvider).status == MyEpubStatus.failed) {
      label2 = '${l10n('download_failed')}';
      isClose = true;
    } else if (ref.watch(epubProvider).status == MyEpubStatus.downloading) {
      label2 = 'Downloading';
      isCancel = true;
      if (done > 0 && all > 1) {
        label2 += ' ${done} / ${all}';
      }
    }

    Widget e = Expanded(flex: 1, child: SizedBox(width: 1));
    Widget h = SizedBox(height: 4);
    Widget btn = Column(children: []);
    if (isClose) {
      btn = Column(children: [
        MyTextButton(
          noScale: true,
          width: 140,
          title: l10n('close'),
          onPressed: () {
            ref.read(epubProvider).setStatusNone();
          },
        ),
      ]);
    } else if (isCancel) {
      btn = Column(children: [
        MyTextButton(
          noScale: true,
          width: 140,
          title: l10n('Cancel'),
          onPressed: () {
            ref.read(epubProvider).needtoStopDownloading = true;
          },
        ),
      ]);
    } else {
      btn = Column(children: [
        MyTextButton(
          noScale: true,
          width: 180,
          commit: true,
          title: '${req1} ${l10n('episode')} ${l10n('up_to')} ${l10n('download')}',
          onPressed: () {
            ref.read(epubProvider).download(req1);
          },
        ),
        if (req2 > 0) h,
        if (req2 > 0)
          MyTextButton(
            noScale: true,
            width: 180,
            commit: true,
            title: '${req2} ${l10n('episode')} ${l10n('up_to')} ${l10n('download')}',
            onPressed: () {
              ref.read(epubProvider).download(req2);
            },
          ),
        h,
        MyTextButton(
          noScale: true,
          width: 180,
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
          SizedBox(height: 4),
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
