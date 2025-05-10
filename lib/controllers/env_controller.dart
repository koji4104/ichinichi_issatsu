import 'dart:developer';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '/constants.dart';
import '/controllers/applog_controller.dart';

class EnvData {
  int val;
  String key = '';
  List<int> vals = [];
  List<String> keys = [];
  String name = '';

  EnvData(
      {required int this.val,
      required List<int> this.vals,
      required List<String> this.keys,
      required String this.name}) {
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
    vals: [10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30],
    keys: ['10', '12', '14', '16', '18', '20', '22', '24', '26', '28', '30'],
    name: 'font_size',
  );

  EnvData line_height = EnvData(
    val: 180,
    vals: [140, 150, 160, 170, 180, 200],
    keys: ['140', '150', '160', '170', '180', '200'],
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

  /// 0 横書き　1 縦書き
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

  String getFrontCss() {
    String col = '#000';
    if (back_color.val == 1) {
      col = '#FFF';
    } else if (back_color.val == 2) {
      col = '#FFF';
    }
    return col;
  }

  String getBackCss() {
    String col = '#FFF';
    if (back_color.val == 1) {
      col = '#444';
    } else if (back_color.val == 2) {
      col = '#000';
    }
    return col;
  }

  /// #4169E1 or #87CEFA
  String getH3Css() {
    String col = '#4169E1'; // royal blue
    if (back_color.val == 1) {
      col = '#87CEFA'; // light sky blue
    } else if (back_color.val == 2) {
      col = '#87CEFA';
    }
    return col;
  }

  /// from text back color
  Color getFrontColor({int? val}) {
    if (val == null) val = back_color.val;
    Color col = Color(0xFF000000);
    if (val == 1) {
      col = Color(0xffFFFFFF);
    } else if (val == 2) {
      col = Color(0xffFFFFFF);
    }
    return col;
  }

  Color getBackColor({int? val}) {
    if (val == null) val = back_color.val;
    Color col = Color(0xffFFFFFF);
    if (val == 1) {
      col = Color(0xff303030);
    } else if (val == 2) {
      col = Color(0xFF000000);
    }
    return col;
  }

  EnvData ui_text_scale = EnvData(
    val: 100,
    vals: [100, 110, 120, 130, 140, 150],
    keys: ['100 %', '110 %', '120 %', '130 %', '140 %', '150 %'],
    name: 'ui_text_scale',
  );

  // Voice
  EnvData speak_voice = EnvData(
    val: 1,
    vals: [1, 2, 3],
    keys: ['O-Ren', 'Kyoko', 'Hattori'],
    name: 'speak_voice',
  );

  // Speak-Speed
  EnvData speak_speed = EnvData(
    val: 100,
    vals: [80, 90, 100, 110, 120, 130, 140],
    keys: ['80', '90', '100', '110', '120', '130', '140'],
    name: 'speak_speed',
  );

  Map<String, dynamic> toJson() => {
        language_code.name: language_code.val,
        font_size.name: font_size.val,
        font_family.name: font_family.val,
        //line_height.name: line_height.val,
        dark_mode.name: dark_mode.val,
        back_color.name: back_color.val,
        writing_mode.name: writing_mode.val,
        ui_text_scale.name: ui_text_scale.val,
        speak_voice.name: speak_voice.val,
        speak_speed.name: speak_speed.val,
      };

  Environment.fromJson(Map<String, dynamic> j) {
    fromJsonSub(j, language_code);
    fromJsonSub(j, font_size);
    fromJsonSub(j, font_family);
    //fromJsonSub(j, line_height);
    fromJsonSub(j, dark_mode);
    fromJsonSub(j, back_color);
    fromJsonSub(j, writing_mode);
    fromJsonSub(j, ui_text_scale);
    fromJsonSub(j, speak_voice);
    fromJsonSub(j, speak_speed);
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
    //list.add(env.line_height);
    list.add(env.dark_mode);
    list.add(env.back_color);
    list.add(env.writing_mode);
    list.add(env.ui_text_scale);
    list.add(env.speak_voice);
    list.add(env.speak_speed);
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
      if (APP_DIR == '') {
        APP_DIR = (await getApplicationDocumentsDirectory()).path;
        if (!Platform.isIOS && !Platform.isAndroid) {
          APP_DIR = APP_DIR + '/test';
        }
      }
      String settingsdir = APP_DIR + '/data';
      await Directory('${settingsdir}').create(recursive: true);
      if (File('${settingsdir}/settings.json').existsSync()) {
        String? txt = await File('${settingsdir}/settings.json').readAsString();
        Map<String, dynamic> j = json.decode(txt);
        env = Environment.fromJson(j);
      }
    } on Exception catch (e) {
      log('err load() err=' + e.toString());
      MyLog.err('EnvNotifier.load() ${e.toString()}');
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
    String settingsdir = APP_DIR + '/data';
    await Directory('${settingsdir}').create(recursive: true);
    File file = File('${settingsdir}/settings.json');
    await file.writeAsString(val, mode: FileMode.write, flush: true);
    return true;
  }

  Future save() async {
    var val = json.encode(env.toJson());
    String settingsdir = APP_DIR + '/data';
    await Directory('${settingsdir}').create(recursive: true);
    File file = File('${settingsdir}/settings.json');
    await file.writeAsString(val, mode: FileMode.write, flush: true);
  }
}
