import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:developer';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '/models/book_data.dart';
import '/models/log_data.dart';
import '/controllers/applog_controller.dart';

List<String> initUriList = [
  'https://www.aozora.gr.jp/index.html',
  'https://www.aozora.gr.jp/access_ranking/2022_xhtml.html',
  'https://kakuyomu.jp',
  'https://yomou.syosetu.com',
  'https://syosetu.com/site/group/'
  //'https://noc.syosetu.com/top/top/',
];
List<String> initTitleList = [
  'aozora_top',
  'aozora_ranking',
  'https://kakuyomu.jp',
  'https://yomou.syosetu.com',
  'https://syosetu.com/site/group/'
  //'https://noc.syosetu.com/top/top/',
];

List<String> initUriList1 = [
  'https://aws.amazon.com/jp/',
];
List<String> initTitleList1 = [
  'Amazon',
];

final browserProvider = ChangeNotifierProvider((ref) => BrowserNotifier(ref));

class BrowserNotifier extends ChangeNotifier {
  BrowserNotifier(ref) {
    readUriList();
  }

  InAppWebViewController? webViewController;
  InAppWebViewController? webViewController18;
  String? webBody;
  late String datadir;

  FavoData initFavorite = FavoData();
  FavoData favorite = FavoData();

  Future readUriList() async {
    await readInitFavo();
    await readFavoJson();
    this.notifyListeners();
  }

  Future readInitFavo() async {
    initFavorite.list.clear();
    if (Platform.isAndroid || Platform.isIOS || true) {
      for (int i = 0; i < initUriList.length; i++) {
        FavoInfo fi = FavoInfo();
        fi.uri = initUriList[i];
        fi.title = initTitleList[i];
        fi.type = 0;
        initFavorite.list.add(fi);
      }
    } else {
      for (int i = 0; i < initUriList1.length; i++) {
        FavoInfo fi = FavoInfo();
        fi.uri = initUriList1[i];
        fi.title = initTitleList1[i];
        fi.type = 0;
        initFavorite.list.add(fi);
      }
    }
  }

  Future readFavoJson() async {
    favorite.list.clear();

    String appdir = (await getApplicationDocumentsDirectory()).path;
    if (!Platform.isIOS && !Platform.isAndroid) {
      appdir = appdir + '/test';
    }
    datadir = appdir + '/data';
    await Directory('${datadir}').create(recursive: true);

    try {
      final file = File('${datadir}/favo.json');
      if (file.existsSync()) {
        String? txt = file.readAsStringSync();
        Map<String, dynamic> j = json.decode(txt);
        favorite = FavoData.fromJson(j);
        for (FavoInfo i in favorite.list) {
          i.type = 1;
        }
      }
    } catch (_) {}
  }

  //'https://www.aozora.gr.jp/access_ranking/2022_xhtml.html',
  //'https://kakuyomu.jp',
  //'https://yomou.syosetu.com',
  //'https://noc.syosetu.com/top/top/',
  saveFavorite() async {
    if (webViewController != null) {
      WebUri? wUri = await webViewController!.getUrl();
      String? wTitle;
      wTitle = await webViewController!.getTitle();
      if (wTitle == null) {
        List<MetaTag> metaTagList = await webViewController!.getMetaTags();
        for (MetaTag tag in metaTagList) {
          if (tag.attrs!.length > 0) {
            if (tag.attrs![0].name == 'property' && tag.attrs![0].value == 'og:title') {
              log('onLoadStop og:title = ${tag.content}');
              wTitle = tag.content;
              break;
            } else if (tag.attrs![0].name == 'property' && tag.attrs![0].value == 'twitter:title') {
              log('onLoadStop twitter:title = ${tag.content}');
              wTitle = tag.content;
              break;
            }
          }
          if (tag.name == 'description') {
            wTitle = tag.content;
            break;
          }
        }
      }

      if (wUri != null) {
        String path = wUri.rawValue;
        if (path.length > 1) {
          for (FavoInfo i in favorite.list) {
            if (i.uri == path) return;
          }

          FavoInfo info = FavoInfo();
          info.uri = path;
          info.title = wTitle ?? path;
          favorite.list.add(info);
          String jsonText = json.encode(favorite.toJson());

          final file = File('${datadir}/favo.json');
          if (file.existsSync()) {
            file.writeAsString(jsonText, mode: FileMode.write, flush: true);
            this.notifyListeners(); //redraw();
          }
        }
      }
    }
  }

  deleteFavorite(String uri) async {
    FavoData src = favorite;
    FavoData dst = FavoData();
    for (FavoInfo i in src.list) {
      if (uri != i.uri) {
        dst.list.add(i);
      }
    }

    final file = File('${datadir}/favo.json');
    if (file.existsSync()) {
      String jsonText = json.encode(dst.toJson());
      file.writeAsString(jsonText, mode: FileMode.write, flush: true);
      favorite = dst;
      this.notifyListeners();
    }
  }
}
