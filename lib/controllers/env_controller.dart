import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:io';
import '/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

class EnvData {
  int val;
  String key = '';
  List<int> vals = [];
  List<String> keys = [];
  String name = '';

  EnvData({required int this.val, required List<int> this.vals, required List<String> this.keys, required String this.name}) {
    round(val);
  }

  void round(int? v) {
    if (v == null || vals.length == 0 || keys.length == 0) return;
    val = vals[vals.length - 1];
    key = keys[keys.length - 1];
    for (var i = 0; i < vals.length; i++) {
      if (v <= vals[i]) {
        val = vals[i];
        key = keys[i];
        break;
      }
    }
  }
}

/// Environment
class Environment {
  Environment() {}

  EnvData language_code = EnvData(
    val: 0,
    vals: [0, 1],
    keys: ['ja', 'en'],
    name: 'language_code',
  );

  /// font_size
  EnvData font_size = EnvData(
    val: 16,
    vals: [10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32],
    keys: ['10', '12', '14', '16', '18', '20', '22', '24', '26', '28', '30', '32'],
    name: 'font_size',
  );

  EnvData line_height = EnvData(
    val: 150,
    vals: [140, 150, 160],
    keys: ['140', '150', '160'],
    name: 'line_height',
  );

  /// 0=sans-serif 1=serif
  EnvData font_family = EnvData(
    val: 0,
    vals: [0, 1],
    keys: ['sans_serif', 'serif'],
    name: 'font_family',
  );

  String getFontFamily() {
    return font_family.val == 0 ? 'sans-serif' : 'serif';
  }

  /// dark_mode
  EnvData dark_mode = EnvData(
    val: 0,
    vals: [0, 1],
    keys: ['light', 'dark'],
    name: 'dark_mode',
  );

  ///
  EnvData writing_mode = EnvData(
    val: 0,
    vals: [0, 1],
    keys: ['horizontal-tb', 'vertical-rl'],
    name: 'writing_mode',
  );

  EnvData back_color = EnvData(
    val: 0,
    vals: [0, 1, 2],
    keys: ['white', 'gray', 'black'],
    name: 'back_color',
  );

  String getFrontCssColor() {
    String col = '#000';
    if (back_color.val == 1) {
      col = '#FFF';
    } else if (back_color.val == 2) {
      col = '#FFF';
    }
    return col;
  }

  String getBackCssColor() {
    String col = '#FFF';
    if (back_color.val == 1) {
      col = '#333';
    } else if (back_color.val == 2) {
      col = '#000';
    }
    return col;
  }

  int getBack32Color() {
    int col = 0xffFFFFFF;
    if (back_color.val == 1) {
      col = 0xff333333;
    } else if (back_color.val == 2) {
      col = 0xFF000000;
    }
    return col;
  }

  EnvData ui_font_size = EnvData(
    val: 16,
    vals: [14, 16, 18],
    keys: ['14', '16', '18'],
    name: 'ui_font_size',
  );

  Map<String, dynamic> toJson() => {
        language_code.name: language_code.val,
        font_size.name: font_size.val,
        font_family.name: font_family.val,
        line_height.name: line_height.val,
        ui_font_size.name: ui_font_size.val,
        dark_mode.name: dark_mode.val,
        back_color.name: back_color.val,
        writing_mode.name: writing_mode.val,
      };

  Environment.fromJson(Map<String, dynamic> j) {
    fromJsonSub(j, language_code);
    fromJsonSub(j, font_size);
    fromJsonSub(j, font_family);
    fromJsonSub(j, line_height);
    fromJsonSub(j, ui_font_size);
    fromJsonSub(j, dark_mode);
    fromJsonSub(j, back_color);
    fromJsonSub(j, writing_mode);
  }

  fromJsonSub(Map<String, dynamic> j, EnvData data) {
    if (j.containsKey(data.name)) {
      data.val = j[data.name] ?? '';
      data.round(data.val);
    }
  }
}

final envProvider = ChangeNotifierProvider((ref) => EnvNotifier(ref));

class EnvNotifier extends ChangeNotifier {
  Environment env = Environment();

  List<EnvData> listData() {
    List<EnvData> list = [];
    list.add(env.language_code);
    list.add(env.font_size);
    list.add(env.font_family);
    list.add(env.line_height);
    list.add(env.ui_font_size);
    list.add(env.dark_mode);
    list.add(env.back_color);
    list.add(env.writing_mode);
    return list;
  }

  EnvNotifier(ref) {
    load().then((_) {
      this.notifyListeners();
    });
  }

  Future load() async {
    log('env load()');
    try {
      String appdir = (await getApplicationDocumentsDirectory()).path;
      if (!Platform.isIOS && !Platform.isAndroid) {
        appdir = appdir + '/test';
      }
      String settingsdir = appdir + '/settings';
      await Directory('${settingsdir}').create(recursive: true);
      if (File('${settingsdir}/settings.json').existsSync()) {
        String? txt = await File('${settingsdir}/settings.json').readAsString();
        Map<String, dynamic> j = json.decode(txt);
        env = Environment.fromJson(j);
      }
    } on Exception catch (e) {
      log('err load() err=' + e.toString());
    }
  }

  Future<bool> saveVal(EnvData data, int newVal) async {
    if (data.val == newVal) return false;
    data.round(newVal);
    for (EnvData d in listData()) {
      if (d.name == data.name) {
        d.val = data.val;
      }
    }

    var val = json.encode(env.toJson());

    String appdir = (await getApplicationDocumentsDirectory()).path;
    if (!Platform.isIOS && !Platform.isAndroid) {
      appdir = appdir + '/test';
    }
    String settingsdir = appdir + '/settings';
    await Directory('${settingsdir}').create(recursive: true);
    File file = File('${settingsdir}/settings.json');
    await file.writeAsString(val, mode: FileMode.write, flush: true);
    return true;
  }

  Future save() async {
    var val = json.encode(env.toJson());

    String appdir = (await getApplicationDocumentsDirectory()).path;
    if (!Platform.isIOS && !Platform.isAndroid) {
      appdir = appdir + '/test';
    }
    String settingsdir = appdir + '/settings';

    await Directory('${settingsdir}').create(recursive: true);
    File file = File('${settingsdir}/settings.json');
    await file.writeAsString(val, mode: FileMode.write, flush: true);
  }
}
