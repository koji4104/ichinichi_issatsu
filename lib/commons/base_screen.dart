import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '/localizations.dart';
import '/commons/widgets.dart';
import '/controllers/env_controller.dart';
import 'dart:io';
import 'dart:developer';

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
    final snackBar = SnackBar(content: Text(msg));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<bool> okDialog() async {
    bool ret = false;
    Text msg = Text(l10n(''));
    double w = Platform.isIOS ? 130 : 70;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: DEF_BORDER_RADIUS),
          titlePadding: EdgeInsets.all(0.0),
          actionsPadding: EdgeInsets.all(28.0),
          buttonPadding: EdgeInsets.all(0.0),
          contentPadding: EdgeInsets.all(0.0),
          iconPadding: EdgeInsets.all(0.0),
          backgroundColor: myTheme.cardColor,
          content: msg,
          actions: <Widget>[
            MyTextButton(
              title: l10n('cancel'),
              width: w,
              cancelStyle: true,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            SizedBox(width: 20),
            MyTextButton(
              title: l10n('OK'),
              width: w,
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

  Future<bool> saveDialog() async {
    bool ret = false;
    Text msg = Text(l10n(''));
    double width = 110;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: DEF_BORDER_RADIUS),
          titlePadding: EdgeInsets.all(0.0),
          actionsPadding: EdgeInsets.all(18.0),
          buttonPadding: EdgeInsets.all(0.0),
          contentPadding: EdgeInsets.all(0.0),
          iconPadding: EdgeInsets.all(0.0),
          backgroundColor: myTheme.cardColor,
          content: msg,
          actions: <Widget>[
            MyTextButton(
              title: l10n('cancel'),
              width: width,
              cancelStyle: true,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            SizedBox(width: 16),
            MyTextButton(
              title: l10n('save'),
              width: width,
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

  Future<bool> deleteDialog() async {
    bool ret = false;
    Text msg = Text(l10n(''));
    double width = 110;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: DEF_BORDER_RADIUS),
          titlePadding: EdgeInsets.all(0.0),
          actionsPadding: EdgeInsets.all(18.0),
          buttonPadding: EdgeInsets.all(0.0),
          contentPadding: EdgeInsets.all(0.0),
          iconPadding: EdgeInsets.all(0.0),
          backgroundColor: myTheme.cardColor,
          content: msg,
          actions: <Widget>[
            MyTextButton(
              title: l10n('cancel'),
              width: width,
              cancelStyle: true,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            SizedBox(width: 16),
            MyTextButton(
              title: l10n('delete'),
              width: width,
              deleteStyle: true,
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

  redraw() {
    if (ref.read(baseProvider) != null) ref.read(baseProvider)!.notifyListeners();
  }
}

/// BaseSettings
class BaseSettingsScreen extends BaseScreen {
  BaseSettingsScreen? rightScreen;

  @override
  Future init() async {}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    super.build(context, ref);
    return Container();
  }

  @override
  Widget getList() {
    return Container();
  }

  Widget MyValue({required EnvData data}) {
    return MyListTile(
      title1: Text(l10n(data.name)),
      title2: Text(l10n(data.key)),
      onPressed: () async {
        //var result = await NavigatorPush(RadioListScreen(data: data));
        NavigatorPush(RadioListScreen(data: data)).then((onValue) {
          redraw();
          log('NavigatorPush end ${onValue}');
        });
        log('NavigatorPush start');
      },
    );
  }
}

/// RadioListScreen
class RadioListScreen extends BaseSettingsScreen {
  int selVal = 0;
  late EnvData data;

  RadioListScreen({required EnvData data}) {
    this.data = data;
    selVal = data.val;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    super.build(context, ref);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n(data.name)),
        leading: Row(
          children: [
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
      body: Container(
        padding: EdgeInsets.fromLTRB(2, 14, 2, 0),
        child: SingleChildScrollView(
          child: getList(),
        ),
      ),
    );
  }

  @override
  Widget getList() {
    List<Widget> list = [];
    for (int i = 0; i < data.vals.length; i++) {
      list.add(
        MyRadioListTile(
          title: l10n(data.keys[i]),
          value: data.vals[i],
          groupValue: selVal,
          onChanged: () => _onRadioSelected(data.vals[i]),
        ),
      );
    }
    list.add(MyLabel(l10n(data.name + '_desc')));
    return Column(children: list);
  }

  Widget MyRadioListTile({
    required String title,
    required int value,
    required int groupValue,
    required void Function()? onChanged,
  }) {
    return Container(
      padding: EdgeInsets.fromLTRB(2, 2, 2, 2),
      child: MyListTile(
        title1: Text(title),
        radio: groupValue == value,
        onPressed: onChanged,
      ),
    );
  }

  void _onRadioSelected(value) async {
    selVal = value;
    ref.read(envProvider).saveVal(data, selVal).then((ret) {
      if (ret) ref.read(envProvider).notifyListeners();
      //if (ret) redraw();
    });
  }
}
