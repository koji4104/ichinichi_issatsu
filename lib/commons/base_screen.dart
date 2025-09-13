import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:developer';

import '/localizations.dart';
import '/commons/widgets.dart';
import '/controllers/env_controller.dart';

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

  /// Tile of Settings
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
      height: 24 + (16 * myTextScale),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: child,
    );
  }

  /// Dropdown of Settings
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
  redraw() {}

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
}
