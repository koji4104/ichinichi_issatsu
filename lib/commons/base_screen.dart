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
    //myTheme = Env.dark_mode.val == 0 ? myLightTheme : myDarkTheme;
    //log('Env.dark_mode.val ${Env.dark_mode.val}');

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
          //surfaceTintColor: Colors.black,
          //foregroundColor: fgcol,
          backgroundColor: bgcol,
          //shape: RoundedRectangleBorder(borderRadius: DEF_BORDER_RADIUS),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(DEF_RADIUS))),
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
            if (ret) onDropdownChanged();
          });
        }
      },
      dropdownColor: myTheme.secondaryHeaderColor,
      style: myTheme.textTheme.bodyMedium!,
    );
  }

  Widget MyDropdownTest() {
    List<String> sList = ['AAA', 'BBB'];
    List<DropdownMenuItem> list = [];
    for (int i = 0; i < sList.length; i++) {
      DropdownMenuItem<int> w = DropdownMenuItem<int>(
        value: i,
        child: MyText(sList[i]),
      );
      list.add(w);
    }
    return DropdownButton(
      items: list,
      value: 0,
      onChanged: (value) {},
      dropdownColor: myTheme.cardColor,
      style: myTheme.textTheme.bodyMedium!,
    );
  }

  onDropdownChanged() {
    ref.read(envProvider).notifyListeners();
  }

  TextStyle getTextStyle() {
    return TextStyle(color: myTheme.textTheme.bodyMedium!.color);
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

  Widget downloadBar() {
    double barHeight = 240;
    double ffBottom = 0;
    if (ref.watch(epubProvider).status == MyEpubStatus.none) {
      ffBottom = -1.0 * barHeight;
    } else {
      ffBottom = 0;
    }

    bool isClose = false;
    String label1 = '';
    String label2 = '';
    int already = ref.watch(epubProvider).downloadedIndex;
    int done = ref.watch(epubProvider).downloaded;
    int all = ref.watch(epubProvider).epub.uriList.length;

    label1 = '${ref.watch(epubProvider).epub.bookTitle ?? ref.watch(epubProvider).epub.bookId}';

    if (ref.watch(epubProvider).status == MyEpubStatus.downloadable) {
      if (all > 1) {
        label2 += ' ${all}';
      }
      if (already > 1) {
        label2 += ' Already ${already}';
      }
    } else if (ref.watch(epubProvider).status == MyEpubStatus.succeeded) {
      label2 = 'Download complete ${done} / ${all}';
      isClose = true;
    } else if (ref.watch(epubProvider).status == MyEpubStatus.same) {
      label2 = 'Already downloaded ${already} / ${all}';
      isClose = true;
    } else if (ref.watch(epubProvider).status == MyEpubStatus.failed) {
      label2 = 'Download failed';
      isClose = true;
    } else if (ref.watch(epubProvider).status == MyEpubStatus.downloading) {
      label2 = 'Downloading';
      isClose = true;
      if (done > 0 && all > 1) {
        label2 += ' ${done} / ${all}';
      }
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
          SizedBox(height: 6),
          Row(children: [
            SizedBox(width: 20),
            Expanded(child: MyText(label2, noScale: true, center: true)),
            SizedBox(width: 20),
          ]),
          SizedBox(height: 8),
          Row(children: [
            Expanded(flex: 1, child: SizedBox(width: 1)),
            if (isClose)
              MyTextButton(
                noScale: true,
                width: 140,
                title: l10n('close'),
                onPressed: () {
                  ref.read(epubProvider).setStatusNone();
                },
              ),
            if (isClose == false)
              MyTextButton(
                noScale: true,
                width: 140,
                title: l10n('cancel'),
                onPressed: () {
                  ref.read(epubProvider).setStatusNone();
                },
              ),
            if (isClose == false) SizedBox(width: 16),
            if (isClose == false)
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
}
