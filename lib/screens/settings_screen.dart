import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'log_screen.dart';
import '/commons/base_screen.dart';
import '/commons/widgets.dart';
import '/controllers/env_controller.dart';

/// Settings
class SettingsScreen extends BaseScreen {
  @override
  Future init() async {}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    super.build(context, ref);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n("settings_title")),
        actions: <Widget>[],
      ),
      body: SingleChildScrollView(
        padding: DEF_MENU_PADDING,
        child: Container(
          child: getList(),
        ),
      ),
    );
  }

  @override
  Widget getList() {
    List<Widget> list = [];
    for (EnvData d in ref.watch(envProvider).listData()) {
      list.add(MyValue(data: d));
    }
    list.add(MyLabel(''));
    list.add(
      MyListTile(
        title1: MyText('Logs'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LogScreen(),
            ),
          );
        },
      ),
    );
    list.add(
      MyListTile(
        title1: MyText('Licenses'),
        onPressed: () async {
          final info = await PackageInfo.fromPlatform();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) {
              return LicensePage(
                applicationName: l10n('app_name'),
                applicationVersion: info.version,
                applicationIcon: Container(
                  padding: EdgeInsets.all(8),
                  child: Image(image: AssetImage('lib/assets/appicon.png'), width: 32, height: 32),
                ),
              );
            }),
          );
        },
      ),
    );
    return Column(children: list);
  }

  Widget MyValue({required EnvData data}) {
    return MyListTile(
      title1: Text(l10n(data.name)),
      title2: Text(l10n(data.key)),
      onPressed: () async {
        var result = await NavigatorPush(RadioListScreen(data: data));
        //NavigatorPush(RadioListScreen(data: data)).then((onValue) {
        //redraw();
        //  log('NavigatorPush end ${onValue}');
        //});
        //log('NavigatorPush start');
      },
    );
  }
}
