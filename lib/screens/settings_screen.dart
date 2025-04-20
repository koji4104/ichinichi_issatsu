import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '/screens/applog_screen.dart';
import '/screens/viewlog_screen.dart';
import '/commons/base_screen.dart';
import '/commons/widgets.dart';
import '/controllers/viewlog_controller.dart';

/// Settings
class SettingsScreen extends BaseScreen {
  @override
  Future init() async {}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    super.build(context, ref);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n("option")),
        actions: <Widget>[],
      ),
      body: SingleChildScrollView(
        padding: DEF_MENU_PADDING,
        child: Container(
          color: myTheme.scaffoldBackgroundColor,
          child: getList(),
        ),
      ),
    );
  }

  @override
  Widget getList() {
    List<Widget> list = [];
    list.add(MySettingsTile(data: env.font_size));
    list.add(MySettingsTile(data: env.back_color));
    list.add(MySettingsTile(data: env.writing_mode));
    list.add(MySettingsTile(data: env.font_family));

    list.add(SizedBox(height: 16));
    list.add(MySettingsTile(data: env.dark_mode));
    list.add(MySettingsTile(data: env.language_code));
    list.add(MySettingsTile(data: env.ui_text_scale));

    list.add(SizedBox(height: 16));
    list.add(MySettingsTile(data: env.speak_voice));
    list.add(MySettingsTile(data: env.speak_speed));
    list.add(MySettingsTile(data: env.speak_volume));

    String sph = l10n('per_hour');
    String spage = l10n('page');

    int speed = ref.watch(viewlogProvider).per_hour;

    list.add(SizedBox(height: 16));
    list.add(
      MyListTile(
        title1: MyText('${sph} ${speed} ${spage}'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ViewlogScreen(),
            ),
          );
        },
      ),
    );

    list.add(SizedBox(height: 6));
    list.add(
      MyListTile(
        title1: MyText('Logs'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ApplogScreen(),
            ),
          );
        },
      ),
    );

    list.add(SizedBox(height: 6));
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
                  child: Image(
                      image: AssetImage('lib/assets/appicon.png'),
                      width: 64,
                      height: 64),
                ),
              );
            }),
          );
        },
      ),
    );

    list.add(SizedBox(height: 10));
    return Column(children: list);
  }
}
