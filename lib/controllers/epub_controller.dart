import 'dart:convert' as convert;
import 'dart:convert';
import 'dart:typed_data'; // Uint8List
import 'dart:developer';
import 'dart:io';
import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:charset_converter/charset_converter.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

import '/models/book_data.dart';
import '/models/epub_data.dart';
import '/controllers/applog_controller.dart';
import '/constants.dart';

class PermitInvalidCertification extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

enum MyEpubStatus {
  none,
  same,
  first,
  add,
  downloadable,
  downloading,
  succeeded,
  failed,
}

final epubProvider = ChangeNotifierProvider((ref) => EpubNotifier(ref));

class EpubNotifier extends ChangeNotifier {
  EpubNotifier(ref) {
    if (!Platform.isIOS && !Platform.isAndroid) {
      //status = MyEpubStatus.downloading;
      //doneIndex = 2;
    }
  }

  EpubData epub = new EpubData();
  MyEpubStatus status = MyEpubStatus.none;
  int doneIndex = 0;
  int existingIndex = 0;
  int requiredIndex = 1;
  bool needtoStopDownloading = false;

  InAppWebViewController? webViewController;
  String? webBody;
  DownloadController downloadCtrl = DownloadController();

  Future writeBook() async {
    if (epub.siteId == null) return;
    if (epub.fileList.length == 0) return;

    String bookdir = APP_DIR + '/book';

    String text0 = '';
    text0 += '<h2>' + (epub.bookTitle ?? epub.bookId!) + '</h2>';
    text0 += epub.bookAuthor != null ? '<h2>' + epub.bookAuthor! + '</h2>' : '';
    text0 += '<br /><br />';
    EpubFileData f0 = EpubFileData();
    f0.chapNo = 0;
    f0.fileName = 'text/ch${f0.chapNo0000}.txt';
    f0.title = epub.bookTitle;
    f0.text = text0;
    f0.chars = text0.length;
    epub.fileList.insert(0, f0);

    await Directory('${bookdir}/${epub.bookId}').create(recursive: true);
    await Directory('${bookdir}/${epub.bookId}/text').create(recursive: true);
    await Directory('${bookdir}/${epub.bookId}/data').create(recursive: true);

    for (EpubFileData f in epub.fileList) {
      List<int> content = convert.utf8.encode(f.text!);
      final file = File('${bookdir}/${epub.bookId}/${f.fileName}');
      await file.writeAsBytes(content);
    }

    // タイトルページ
    BookData book = BookData();
    book.title = epub.bookTitle ?? epub.bookId!;
    book.bookId = epub.bookId!;
    book.siteId = epub.siteId!;
    book.author = epub.bookAuthor ?? '';
    book.chars = 0;
    book.dluri = epub.dluri ?? '';
    book.ctime = DateTime.now();

    book.title = EpubData.deleteInvalidStrInJson(book.title);
    book.author = EpubData.deleteInvalidStrInJson(book.author);

    // 目次
    IndexData index = await getBookIndexJson();
    for (EpubFileData f in epub.fileList) {
      if (f.chapNo >= 0) {
        IndexInfo ch = IndexInfo();
        ch.title = f.title ?? '';
        ch.title = EpubData.deleteInvalidStrInJson(ch.title);
        ch.index = f.chapNo;
        ch.chars = f.chars;

        if (index.list.length > f.chapNo) {
          index.list[f.chapNo] = ch;
        } else {
          index.list.add(ch);
        }
      }
    }

    book.chars = 0;
    for (IndexInfo i in index.list) {
      book.chars += i.chars;
    }

    book.dlver = APP_VERSION;

    String jsonText = json.encode(book.toJson());
    final boolFile = File('${bookdir}/${epub.bookId}/data/book.json');
    await boolFile.writeAsString(jsonText, mode: FileMode.write, flush: true);

    String j = json.encode(index.toJson());
    final indexFile = File('${bookdir}/${epub.bookId}/data/index.json');
    await indexFile.writeAsString(j, mode: FileMode.write, flush: true);

    final propFile = File('${bookdir}/${epub.bookId}/data/prop.json');
    if (propFile.existsSync() == false) {
      PropData prop = PropData();
      var val = json.encode(prop.toJson());
      await propFile.writeAsString(val, mode: FileMode.write, flush: true);
    }
  }

  Future checkUri(String uri) async {
    String? body = null;

    if (uri.contains('www.aozora.gr.jp/cards/')) {
      body = await downloadCtrl.download(uri);
    } else if (uri.contains('kakuyomu.jp/works/')) {
      body = await downloadCtrl.download(uri);
    } else if (uri.contains('ncode.syosetu.com/n')) {
      body = await downloadCtrl.download(uri);
    } else if (uri.contains('novel18.syosetu.com/n')) {
      body = await downloadCtrl.download8(uri, this);
    }
    await checkHtml(uri, body);

    if (status == MyEpubStatus.none) {
      status = MyEpubStatus.failed;
      this.notifyListeners();
    }
  }

  Future checkHtml(String uri, String? body) async {
    epub.reset();
    existingIndex = 0;

    if (body != null) {
      if (uri.contains('www.aozora.gr.jp/cards/')) {
        await checkAozora(uri, body);
      } else if (uri.contains('kakuyomu.jp/works/')) {
        await checkKakuyomu(uri, body);
      } else if (uri.contains('ncode.syosetu.com/n')) {
        await checkNarou(uri, body);
      } else if (uri.contains('novel18.syosetu.com/n')) {
        await checkNarou(uri, body);
      }
    }

    if (epub.bookId != null && epub.uriList.isNotEmpty) {
      if (uri.contains('www.aozora.gr.jp/cards/')) {
        status = MyEpubStatus.downloadable;
      } else {
        existingIndex = await getExistingIndex(epub.bookId!);
        if (existingIndex > epub.uriList.length)
          existingIndex = epub.uriList.length;
        if (existingIndex == epub.uriList.length)
          status = MyEpubStatus.same;
        else
          status = MyEpubStatus.downloadable;
      }
      this.notifyListeners();
    } else if (status != MyEpubStatus.none) {
      status = MyEpubStatus.none;
      this.notifyListeners();
    }
  }

  Future<bool> download(int required) async {
    bool ret = false;
    if (epub.uriList.length == 0 || epub.dluri == null) {
      log('urlList.length == 0');
      status = MyEpubStatus.failed;
      this.notifyListeners();
      return ret;
    }
    needtoStopDownloading = false;
    requiredIndex = required;

    if (epub.dluri.toString().contains('www.aozora.gr.jp/cards/')) {
      await downloadAozora();
      ret = true;
    } else if (epub.dluri.toString().contains('kakuyomu.jp/works/')) {
      await downloadKakuyomu();
      ret = true;
    } else if (epub.dluri.toString().contains('ncode.syosetu.com/n')) {
      await downloadNarou();
      ret = true;
    } else if (epub.dluri.toString().contains('novel18.syosetu.com/n')) {
      await downloadNarou8();
      ret = true;
    } else {
      status = MyEpubStatus.failed;
      this.notifyListeners();
    }
    await Future.delayed(Duration(milliseconds: 500));
    return ret;
  }

  /// tag = '<a '  '<div'
  /// <img src=.....>
  /// text = deleteTag(text, '<a ');
  /// text = text.replaceAll('</a>', '');
  String deleteTag(String text, String tag) {
    int s1 = 0;
    for (int i = 0; i < 10000; i++) {
      s1 = text.indexOf(tag, s1);
      int e1 = (s1 >= 0) ? text.indexOf(r'>', s1 + tag.length) + 1 : 0;
      if (s1 >= 0 && e1 > s1) {
        text = text.substring(0, s1) + text.substring(e1);
      } else {
        break;
      }
    }
    return text;
  }

  /// tag = '<h3'
  /// <h3 class="o-midashi">第三の手記</h3>
  /// <h3>第三の手記</h3>
  String deleteClassAttr(String text, String tag) {
    int s1 = 0;
    for (int i = 0; i < 10000; i++) {
      s1 = text.indexOf(tag + ' ', s1); // '<h3 '
      int e1 = (s1 >= 0) ? text.indexOf(r'>', s1 + tag.length) : 0;
      if (s1 >= 0 && e1 > 0) {
        text = text.substring(0, s1) + tag + text.substring(e1);
        s1++;
      } else {
        break;
      }
    }
    return text;
  }

  Map<String, String> headers = {
    'user-agent':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148'
  };

  setStatusNone() {
    epub.reset();
    needtoStopDownloading = true;
    if (status != MyEpubStatus.none) {
      status = MyEpubStatus.none;
      this.notifyListeners();
    }
  }

  int calcChars(String text) {
    String str = text;
    str = str.replaceAll('\n', '');
    str = str.replaceAll('<h3>', '');
    str = str.replaceAll('</h3>', '');

    // delete ruby
    str = EpubData.deleteRuby(str);

    return str.length;
  }

  int calcCharsSimple(String text) {
    String str = text;
    str = str.replaceAll('<rp>（', '');
    str = str.replaceAll('）<rp>', '');
    str = str.replaceAll('）</rp>', '');

    str = str.replaceAll('\n', '');
    str = str.replaceAll('<ruby>', '');
    str = str.replaceAll('</ruby>', '');
    str = str.replaceAll('<rb>', '');
    str = str.replaceAll('</rb>', '');
    str = str.replaceAll('<rp>', '');
    str = str.replaceAll('</rp>', '');
    str = str.replaceAll('<rt>', '');
    str = str.replaceAll('</rt>', '');

    return str.length;
  }

  Future<int> getExistingIndex(String bookId) async {
    int existingIndex = 0;
    String datadir = APP_DIR + '/book';

    try {
      Directory dir = Directory('${datadir}/${bookId}/text');

      if (dir.existsSync()) {
        var plist = dir.listSync();
        List<String> flist = [];
        for (var p in plist) {
          if (p.path.contains('ch')) flist.add(p.path);
        }
        flist.sort((a, b) {
          return b.compareTo(a);
        });
        String path = basename(flist[0]);
        String schap = path.replaceAll('ch', '');
        schap = schap.replaceAll('.txt', '');
        int ichap = int.parse(schap);
        existingIndex = ichap;
      }
    } catch (_) {}

    return existingIndex;
  }

  Future<IndexData> getBookIndexJson() async {
    IndexData data = IndexData();
    if (epub.bookId == null) return data;

    try {
      String datadir = APP_DIR + '/book';
      final file = File('${datadir}/${epub.bookId!}/data/index.json');
      if (file.existsSync()) {
        String? txt1 = await file.readAsString();
        Map<String, dynamic> j = json.decode(txt1);
        data = IndexData.fromJson(j);
      }
    } catch (_) {}
    return data;
  }

  //-------------------------------------------------------
  // Aozora
  //-------------------------------------------------------

  Future checkAozora(String url, String body) async {
    epub.dluri = url;

    //https://www.aozora.gr.jp/cards/000148/card773.html
    //https://www.aozora.gr.jp/cards/000148/files/773_14560.html
    BeautifulSoup bs = BeautifulSoup(body);

    List<Bs4Element> els = bs.findAll('a');
    for (Bs4Element el in els) {
      String href = el.attributes['href'] ?? '';
      if (href.contains('/files/') && href.contains('.html')) {
        String u1 = url.substring(0, url.lastIndexOf('/card'));
        String u2 = href.substring(href.indexOf('/files/'));
        String dl = u1 + u2;
        epub.uriList.add(dl);

        try {
          String fname = dl.substring(dl.lastIndexOf('/files/') + 7);
          epub.siteId = fname.substring(0, fname.indexOf('_'));
          epub.bookId = 'A' + epub.siteId!;
        } catch (_) {}
        break;
      }
    }

    // こころ (夏目 漱石)
    Bs4Element? elTitle = bs.find('meta', attrs: {'property': 'og:title'});
    if (elTitle != null) {
      epub.bookTitle = elTitle['content'] ?? epub.bookId;
    }
  }

  Future downloadAozora() async {
    if (epub.uriList.length == 0) return;
    if (epub.bookId == null) return;

    MyLog.info('Download ${epub.bookTitle}');
    status = MyEpubStatus.downloading;
    doneIndex = 0;
    this.notifyListeners();

    String? body = await downloadCtrl.downloadSjis(epub.uriList[0]);
    if (body != null) {
      try {
        await createAozoraText(body);
        if (epub.fileList.length >= 1) {
          await writeBook();
          doneIndex = 1;
          status = MyEpubStatus.succeeded;
        }
      } catch (_) {}
    } else {
      MyLog.warn('download() failed ${epub.uriList[0]}');
    }

    if (status == MyEpubStatus.succeeded) {
      MyLog.info('Download succeeded');
    } else {
      status = MyEpubStatus.failed;
      MyLog.warn('Download failed');
    }
    this.notifyListeners();
  }

  Future createAozoraText(String body) async {
    if (epub.bookId == null) return;

    BeautifulSoup bs = BeautifulSoup(body);

    String? oldTitle = epub.bookTitle;
    epub.bookTitle = null;
    if (epub.bookTitle == null) {
      Bs4Element? el = bs.find('meta', attrs: {'name': 'DC.Title'});
      if (el != null) {
        epub.bookTitle = el['content'];
      }
    }
    if (epub.bookTitle == null) {
      Bs4Element? el = bs.find('h1', class_: 'title');
      if (el != null) {
        epub.bookTitle = el.innerHtml;
      }
    }
    if (epub.bookTitle == null && oldTitle != null) {
      epub.bookTitle = oldTitle!;
    }
    if (epub.bookTitle == null) {
      epub.bookTitle = epub.bookId!;
    }

    if (epub.bookAuthor == null) {
      Bs4Element? el = bs.find('meta', attrs: {'name': 'DC.Creator'});
      if (el != null) {
        epub.bookAuthor = el['content'] ?? '';
      }
    }
    if (epub.bookAuthor == null) {
      Bs4Element? el = bs.find('h2', class_: 'author');
      if (el != null) {
        epub.bookAuthor = el.innerHtml;
      }
    }

    Bs4Element? el = bs.find('div', class_: 'main_text');
    String text = el!.innerHtml;

    text = text.replaceAll('\n', '<br />\n');
    text = text.replaceAll('<br>', '<br />');
    text = text.replaceAll('<br /><br />\n', '<br />\n');

    for (int i = 0; i < 3; i++) {
      if (text.indexOf('<br />') == 0) {
        text = text.replaceFirst('<br />', '');
      }
      if (text.indexOf('\n') == 0) {
        text = text.replaceFirst('\n', '');
      }
    }

    // delete div
    text = deleteTag(text, '<div');
    text = text.replaceAll('</div>', '');

    // delete <a
    text = deleteTag(text, '<a ');
    text = text.replaceAll('</a>', '');

    // delete <img
    text = deleteTag(text, '<img');

    // delete <span
    text = deleteTag(text, '<span');
    text = text.replaceAll('</span>', '');

    // delete <em
    text = deleteTag(text, '<em');
    text = text.replaceAll('</em>', '');

    // </div> を消してから
    text = text.replaceAll('</h3><br />', '</h3>');
    text = text.replaceAll(
        '</h3>\n<br />\n<br />\n<br />', '</h3>\n<br />\n<br />');

    // delete class <h3
    text = deleteClassAttr(text, '<h3');
    text = deleteClassAttr(text, '<h4');

    // <div class="jisage_3" style="margin-left: 3em"><h3 class="o-midashi"><a class="midashi_anchor" id="midashi400">第三の手記</a></h3></div>
    // <br /><br />
    // <div class="jisage_5" style="margin-left: 5em"><h4 class="naka-midashi"><a class="midashi_anchor" id="midashi410">一</a></h4></div>
    // <br />

    // <h3>第三の手記</h3>
    // <br /><br />
    // <h4>一</h4>
    // <br />

    String hd = 'h3';
    text = text.replaceAll('<h4', '<h3');
    text = text.replaceAll('</h4', '</h3');

    List<String> listText1 = text.split('<h3');
    List<String> listText = [];
    if (listText1.length == 1) {
      List<String> listTemp = [];
      listTemp.add('dummy');
      String temp = listText1[0];
      temp = '>1</h3>' + temp;
      listTemp.add(temp);
      listText1 = listTemp;
    }
    if (listText1.length > 1) {
      for (int i = 0; i < listText1.length; i++) {
        String t1 = listText1[i];
        if (i > 0) {
          t1 = '<h3' + t1;
          t1 = t1.replaceAll('</h3><br />', '</h3>');
          if (i < listText1.length - 1) {
            if (t1.length < 180) {
              String t2 = listText1[i + 1];
              t2 = '<h3' + t2;
              t2 = t2.replaceAll('<h3', '<h4');
              t2 = t2.replaceAll('</h3', '</h4');
              t1 += t2;
              i++;
            }
          }
        }

        // <ruby><rb>A</rb><rp>（</rp><rt>b</rt><rp>）</rp></ruby> 53 chars
        // ver 1.1
        // int count1 = 15000 len>100 20000
        // int count2 = 10000 len>100 15000

        for (int i = 0; i < 100; i++) {
          int count1 = 15000;
          int count2 = 10000;
          if (t1.split('<ruby>').length > 100) {
            count1 = 20000;
            count2 = 15000;
          }
          if (t1.length < count1) {
            if (i >= 1) {
              t1 = '<h3>${listText.length}</h3>' + t1;
            }
            listText.add(t1);
            break;
          }
          int s1 = t1.indexOf('<br />', count2);
          if (s1 > 0 && t1.length - s1 > 1000) {
            String t2 = t1.substring(0, s1 + 6);
            if (i >= 1) {
              t2 = '<h3>${listText.length}</h3>' + t2;
            }
            listText.add(t2);
            t1 = t1.substring(s1 + 6);
          } else {
            if (i >= 1) {
              t1 = '<h3>${listText.length}</h3>' + t1;
            }
            listText.add(t1);
            break;
          }
        }
      }
    }

    if (listText.length == 1) {
      EpubFileData f = EpubFileData();
      f.chapNo = 1;
      f.fileName = 'text/ch${f.chapNo0000}.txt';
      f.text = text;
      f.title = epub.bookTitle;
      f.chars = text.length;
      epub.fileList.add(f);
    } else if (listText.length > 1) {
      for (int i = 1; i < listText.length; i++) {
        String text = listText[i];

        String title = '${i}';
        BeautifulSoup bs1 = BeautifulSoup(text);
        Bs4Element? el1 = bs1.find(hd);
        if (el1 != null) {
          title = el1.innerHtml;
        }

        EpubFileData f = EpubFileData();
        f.chapNo = i;
        f.fileName = 'text/ch${f.chapNo0000}.txt';
        f.text = text;
        f.title = title;
        f.chars = calcChars(text);
        epub.fileList.add(f);
      }
    }
  }

  //-------------------------------------------------------
  // Kakuyomu
  //-------------------------------------------------------

  Future<void> checkKakuyomu(String url, String body) async {
    epub.dluri = url;
    epub.siteId = url.substring(url.indexOf('works/') + 6);
    epub.bookId = 'K' + epub.siteId!;
    String userId = '';

    BeautifulSoup bs = BeautifulSoup(body);
    List<Bs4Element> els = bs.findAll('script', id: '__NEXT_DATA__');
    for (Bs4Element e in els) {
      String js = e.innerHtml;
      var json1 = json.decode(js);
      if (json1['props'] != null) {
        if (json1['props']['pageProps'] != null) {
          if (json1['props']['pageProps']['__APOLLO_STATE__'] != null) {
            var map = json1['props']['pageProps']['__APOLLO_STATE__'];

            // title uriList
            for (var MapEntry(:key, :value) in map.entries) {
              if (value['__typename'] != null && value['id'] != null) {
                if (value['__typename'] == 'Episode') {
                  epub.uriList.add(
                      'https://kakuyomu.jp/works/${epub.siteId}/episodes/${value['id']}');
                } else if (value['__typename'] == 'Work') {
                  if (value['id'] == epub.siteId) {
                    epub.bookTitle = value['title'];
                    var aut = value['author'];
                    var ref = aut['__ref'] ?? '';
                    userId = ref
                        .toString()
                        .substring(ref.toString().indexOf('UserAccount:') + 12);
                  }
                }
              }
            }

            // author
            if (userId != '') {
              for (var MapEntry(:key, :value) in map.entries) {
                if (value['__typename'] != null && value['id'] != null) {
                  if (value['__typename'] == 'UserAccount') {
                    if (value['id'] == userId) {
                      epub.bookAuthor = value['activityName'];
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    if (epub.bookTitle == null) {
      Bs4Element? el = bs.find('meta', attrs: {'property': 'og:title'});
      if (el != null) epub.bookTitle = el['content'];
    }
  }

  Future<void> downloadKakuyomu() async {
    MyLog.info('Download ${epub.bookTitle}');

    status = MyEpubStatus.downloading;
    doneIndex = 0;
    needtoStopDownloading = false;
    this.notifyListeners();

    for (int i = existingIndex; i < epub.uriList.length; i++) {
      sleep(Duration(milliseconds: 200));

      String? body = await downloadCtrl.download(epub.uriList[i]);
      if (body != null) {
        await createKakuyomuText(body, i + 1);
      } else {
        break;
      }

      doneIndex = i + 1;
      if (doneIndex % 2 == 0) {
        this.notifyListeners();
      }
      if ((i + 1) >= requiredIndex) break;
      if (needtoStopDownloading == true) break;
    }

    if (epub.fileList.length >= 1 && needtoStopDownloading == false) {
      await writeBook();
      status = MyEpubStatus.succeeded;
      MyLog.info('Download succeeded');
    } else {
      status = MyEpubStatus.failed;
      MyLog.warn('Download failed');
    }
    this.notifyListeners();
  }

  Future createKakuyomuText(String body, int chap) async {
    EpubFileData f = new EpubFileData();

    f.chapNo = chap;
    BeautifulSoup bs = BeautifulSoup(body);
    Bs4Element? et = bs.find('p', class_: 'widget-episodeTitle');
    if (et != null) f.title = et.innerHtml;

    if (epub.bookAuthor == null) {
      Bs4Element? eAuthor = bs.find('p', id: 'contentMain-header-author');
      if (eAuthor != null) epub.bookAuthor = eAuthor.innerHtml;
    }

    Bs4Element? ec =
        bs.find('div', class_: 'widget-episodeBody js-episode-body');
    if (ec != null) {
      String text = ec.innerHtml;
      text = text.replaceAll('<br>', '<br />');
      text = text.replaceAll('&nbsp;', '');
      String title = '<h3>${f.title}</h3>\n';

      // delete div
      text = deleteTag(text, '<div');
      text = text.replaceAll('</div>', '');

      // delete <a
      text = deleteTag(text, '<a ');
      text = text.replaceAll('</a>', '');

      // delete <img
      text = deleteTag(text, '<img');

      // delete <p>
      text = deleteTag(text, '<p ');
      text = text.replaceAll('</p>', '<br />');

      // delete <span
      text = deleteTag(text, '<span');
      text = text.replaceAll('</span>', '');

      // delete <em
      text = deleteTag(text, '<em');
      text = text.replaceAll('</em>', '');

      f.text = title + text;
      f.chars = calcChars(text);
      f.chapNo = chap;
      f.fileName = 'text/ch${f.chapNo0000}.txt';
      epub.fileList.add(f);
    }
    return;
  }

  //-------------------------------------------------------
  // Narou
  //-------------------------------------------------------

  Future<void> checkNarou(String url, String body) async {
    epub.dluri = url;
    epub.siteId = url.substring(url.indexOf('syosetu.com/') + 12);
    epub.bookId = 'N' + epub.siteId!;
    BeautifulSoup bs = BeautifulSoup(body);

    Bs4Element? elTitle = bs.find('meta', attrs: {'property': 'og:title'});
    if (elTitle != null) {
      epub.bookTitle = elTitle['content'] ?? epub.bookId;
    }

    // <meta name="twitter:creator" content="黒昆布">
    Bs4Element? elAuthor = bs.find('meta', attrs: {'name': 'twitter:creator'});
    if (elAuthor != null) {
      epub.bookAuthor = elAuthor['content'] ?? '';
    }

    String? nextBody;
    for (int i = 0; i < 100; i++) {
      if (nextBody != null) {
        bs = BeautifulSoup(nextBody);
      }

      List<Bs4Element> els = bs.findAll('a', class_: 'p-eplist__subtitle');
      for (Bs4Element e in els) {
        String? s = e.getAttrValue('href');
        if (s != null) {
          String u = 'https://ncode.syosetu.com' + s;
          epub.uriList.add(u);
        }
      }

      nextBody = null;
      Bs4Element? elNext = bs.find('a', class_: 'c-pager__item--next');
      if (elNext != null) {
        String? s = elNext.getAttrValue('href'); // /n8611bv/?p=2
        if (s != null) {
          await Future.delayed(Duration(milliseconds: 500));
          String u = 'https://ncode.syosetu.com' + s;
          if (url.contains('ncode.syosetu.com/n')) {
            nextBody = await downloadCtrl.download(u);
          } else if (url.contains('novel18.syosetu.com/n')) {
            nextBody = await downloadCtrl.download8(u, this);
          }
        }
      }
      if (nextBody == null) break;
    }
  }

  Future<void> downloadNarou() async {
    MyLog.info('Download ${epub.bookTitle}');

    status = MyEpubStatus.downloading;
    doneIndex = 0;
    needtoStopDownloading = false;
    this.notifyListeners();

    if (epub.uriList.length > 0) {
      for (int i = existingIndex; i < epub.uriList.length; i++) {
        sleep(Duration(milliseconds: 200));

        String? body = await downloadCtrl.download(epub.uriList[i]);
        if (body != null) {
          await createNarouText(body, i + 1);
        } else {
          break;
        }

        doneIndex = i + 1;
        if (doneIndex % 2 == 0) {
          this.notifyListeners();
        }
        if ((i + 1) >= requiredIndex) break;
        if (needtoStopDownloading == true) break;
      }
    }

    if (epub.fileList.length >= 1 && needtoStopDownloading == false) {
      await writeBook();
      status = MyEpubStatus.succeeded;
      MyLog.info('Download succeeded');
    } else {
      MyLog.warn('Download failed');
    }

    this.notifyListeners();
  }

  Future<void> downloadNarou8() async {
    MyLog.info('Download ${epub.bookTitle}');

    status = MyEpubStatus.downloading;
    doneIndex = 0;
    needtoStopDownloading = false;
    this.notifyListeners();

    if (epub.uriList.length > 0) {
      for (int i = existingIndex; i < epub.uriList.length; i++) {
        await Future.delayed(Duration(milliseconds: 200));

        // https://ncode.syosetu.com/n6964jl/1/
        String? body =
            await downloadCtrl.download8(epub.uriList[i], this); // waiting
        if (body != null) {
          await createNarouText(body, i + 1);
        } else {
          break;
        }

        doneIndex = i + 1;
        if (doneIndex % 2 == 0) {
          this.notifyListeners();
        }
        if ((i + 1) >= requiredIndex) break;
        if (needtoStopDownloading == true) break;
      }
    }
    if (epub.fileList.length >= 1 && needtoStopDownloading == false) {
      await writeBook();
      status = MyEpubStatus.succeeded;
      MyLog.info('Download succeeded');
    } else {
      MyLog.warn('Download failed');
    }

    this.notifyListeners();
  }

  Future createNarouText(String body, int chap) async {
    EpubFileData f = new EpubFileData();
    f.chapNo = chap;
    BeautifulSoup bs = BeautifulSoup(body);

    if (f.title == null) {
      Bs4Element? el = bs.find('div', class_: 'p-novel__subtitle-episode');
      if (el != null) f.title = el.innerHtml;
    }
    if (f.title == null) {
      Bs4Element? el =
          bs.find('h1', class_: 'p-novel__title p-novel__title--rensai');
      if (el != null) f.title = el.innerHtml;
    }
    if (f.title == null) {
      Bs4Element? el = bs.find('meta', attrs: {'property': 'og:title'});
      if (el != null) f.title = el['content'];
    }

    String text = '';
    //<div class="js-novel-text p-novel__text">
    List<Bs4Element> els =
        bs.findAll('div', class_: 'js-novel-text p-novel__text');
    for (Bs4Element el in els) {
      String t1 = el.innerHtml;
      t1 = t1.replaceAll('<br>', '<br />');
      t1 = t1.replaceAll('&nbsp;', '');

      // delete div
      text = deleteTag(text, '<div');
      text = text.replaceAll('</div>', '');

      // delete <a
      text = deleteTag(text, '<a ');
      text = text.replaceAll('</a>', '');

      // delete <img
      text = deleteTag(text, '<img');

      // delete <p>
      text = deleteTag(text, '<p ');
      text = text.replaceAll('</p>', '<br />');

      // delete <span
      text = deleteTag(text, '<span');
      text = text.replaceAll('</span>', '');

      if (t1 != '') t1 += '<br />';
      text += t1;
    }

    if (text != '') {
      String title = '<h3>${f.title}</h3>\n';
      f.text = title + text;
      f.chars = calcChars(text);
      f.fileName = 'text/ch${f.chapNo0000}.txt';
      epub.fileList.add(f);
    }

    return f;
  }

  //-------------------------------------------------------
  // Hamel
  //-------------------------------------------------------

  Future<void> checkHamel(String url, String body) async {
    epub.bookId = url.substring(url.indexOf('syosetu.com/') + 12);

    //<a href=./1.html style="text-decoration:none;">キッドナッシング</a>
    BeautifulSoup bs = BeautifulSoup(body);
    List<Bs4Element> els = bs.findAll('a', class_: 'p-eplist__subtitle');
    for (Bs4Element e in els) {
      String? s = e.getAttrValue('href');
      if (s != null) {
        String u = 'http://ncode.syosetu.com' + s;
        epub.uriList.add(u);
      }
    }
  }
}

class DownloadController {
  DownloadController() {}

  InAppWebViewController? webViewController8;
  String? webBody;
  String? selectedUri;

  Future<String?> download(String uri) async {
    HttpOverrides.global = PermitInvalidCertification();
    Map<String, String> headers = {
      'user-agent':
          'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148'
    };
    String? body = null;
    try {
      http.Response res = await http.get(Uri.parse(uri), headers: headers);
      if (res.statusCode == 200) {
        body = utf8.decode(res.bodyBytes);
      }
    } catch (e) {
      MyLog.err('DownloadController.download() ${e.toString()}');
    }
    return body;
  }

  Future<String?> downloadSjis(String uri) async {
    HttpOverrides.global = PermitInvalidCertification();
    Map<String, String> headers = {
      'user-agent':
          'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148'
    };
    String? body = null;
    try {
      http.Response res = await http.get(Uri.parse(uri), headers: headers);
      if (res.statusCode == 200) {
        body = await CharsetConverter.decode("Shift_JIS", res.bodyBytes);
      }
    } catch (e) {
      MyLog.err('DownloadController.downloadSjis() ${e.toString()}');
    }
    return body;
  }

  Future<String?> download8(String uri, EpubNotifier noti) async {
    webBody = null;
    selectedUri = uri;
    noti.notifyListeners();
    try {
      for (int wait = 0; wait < 100; wait++) {
        await Future.delayed(Duration(milliseconds: 200));
        if (this.webBody != null) {
          log('download finish wait=${wait}');
          break;
        }
      }
    } catch (e) {
      MyLog.err('DownloadController.download8() ${e.toString()}');
    }
    return webBody;
  }

  Widget browser8() {
    if (selectedUri == null) return Container();
    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
    return InAppWebView(
      key: GlobalKey(),
      initialUrlRequest: URLRequest(url: WebUri(selectedUri!)),
      onWebViewCreated: (controller) async {
        webViewController8 = controller;
      },
      onLoadStart: (controller, url) {
        MyLog.debug('browser8 onLoadStart url=${url}');
      },
      onLoadStop: (controller, url) async {
        MyLog.debug('browser8 onLoad Stop url=${url}');
        if (url != null) {
          webBody = await webViewController8!.getHtml();
        }
      },
    );
  }
}
