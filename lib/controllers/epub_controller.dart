import 'dart:convert' as convert;
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ichinichi_issatsu/commons/widgets.dart';
import 'package:intl/intl.dart';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:charset_converter/charset_converter.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path_provider/path_provider.dart';

import '/models/book_data.dart';
import '/models/epub_data.dart';

class PermitInvalidCertification extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (cert, host, port) => true;
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

int NUM_OF_FIRST_COWNLOAD = 10;
int NUM_OF_ADD_COWNLOAD = 30;

final epubProvider = ChangeNotifierProvider((ref) => EpubNotifier(ref));

class EpubNotifier extends ChangeNotifier {
  EpubNotifier(ref) {}

  EpubData epub = new EpubData();
  MyEpubStatus status = MyEpubStatus.none;
  int downloaded = 0;
  int downloadedIndex = 0;

  int numOfDownloadRequired = NUM_OF_FIRST_COWNLOAD;

  InAppWebViewController? webViewController;
  InAppWebViewController? webViewController1;
  String? webBody;
  DownloadController downloadCtrl = DownloadController();

  Future writeBook() async {
    if (epub.siteId == null) return;
    if (epub.fileList.length == 0) return;

    epub.addTitle();
    //epub.addNav();
    //epub.addStyle();
    //epub.addOpf();
    //epub.addToc();

    String appdir = (await getApplicationDocumentsDirectory()).path;
    if (!Platform.isIOS && !Platform.isAndroid) {
      appdir += '/test';
    }
    String datadir = appdir + '/book';
    await Directory('${datadir}/${epub.bookId}').create(recursive: true);
    await Directory('${datadir}/${epub.bookId}/text').create(recursive: true);
    await Directory('${datadir}/${epub.bookId}/data').create(recursive: true);
    for (EpubFileData f in epub.fileList) {
      List<int> content = convert.utf8.encode(f.text!);
      final file = File('${datadir}/${epub.bookId}/${f.fileName}');
      await file.writeAsBytes(content);
    }

    BookData book = BookData();
    book.title = epub.bookTitle ?? epub.bookId!;
    book.bookId = epub.bookId!;
    book.siteId = epub.siteId!;
    book.author = epub.bookAuthor ?? '';
    book.chars = 0;
    book.dluri = epub.dluri ?? '';
    book.ctime = DateTime.now();

    IndexData index = IndexData();
    for (EpubFileData f in epub.fileList) {
      if (f.chapNo >= 0) {
        IndexInfo ch = IndexInfo();
        ch.title = f.title ?? '';
        ch.index = f.chapNo;
        ch.chars = f.chars;
        book.chars += f.chars;
        index.list.add(ch);
      }
    }

    String jsonText = json.encode(book.toJson());
    final boolFile = File('${datadir}/${epub.bookId}/data/book.json');
    await boolFile.writeAsString(jsonText, mode: FileMode.write, flush: true);

    String j = json.encode(index.toJson());
    final indexFile = File('${datadir}/${epub.bookId}/data/index.json');
    await indexFile.writeAsString(j, mode: FileMode.write, flush: true);

    PropData prop = PropData();
    var val = json.encode(prop.toJson());
    final propFile = File('${datadir}/${epub.bookId}/data/prop.json');
    await propFile.writeAsString(val, mode: FileMode.write, flush: true);
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
      body = await downloadCtrl.download8(uri);
    }
    checkHtml(uri, body);
  }

  Future checkHtml(String uri, String? body) async {
    epub.reset();
    downloadedIndex = 0;

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
      downloadedIndex = await getMaxIndex(epub.bookId!);
      if (downloadedIndex > epub.uriList.length) downloadedIndex = epub.uriList.length;
      if (downloadedIndex == epub.uriList.length)
        status = MyEpubStatus.same;
      else
        status = MyEpubStatus.downloadable;
      this.notifyListeners();
    } else if (status != MyEpubStatus.none) {
      status = MyEpubStatus.none;
      this.notifyListeners();
    }
  }

  Future<void> download() async {
    if (epub.uriList.length == 0 || epub.dluri == null) {
      log('urlList.length == 0');
      status = MyEpubStatus.failed;
      this.notifyListeners();
      return;
    }

    numOfDownloadRequired = NUM_OF_FIRST_COWNLOAD;
    if (downloadedIndex > 0) {
      numOfDownloadRequired = downloadedIndex + NUM_OF_ADD_COWNLOAD;
    }

    if (epub.dluri.toString().contains('www.aozora.gr.jp/cards/')) {
      await downloadAozora();
    } else if (epub.dluri.toString().contains('kakuyomu.jp/works/')) {
      await downloadKakuyomu();
    } else if (epub.dluri.toString().contains('ncode.syosetu.com/n')) {
      await downloadNarou();
    } else if (epub.dluri.toString().contains('novel18.syosetu.com/n')) {
      await downloadNarou8();
    } else {
      status = MyEpubStatus.failed;
      this.notifyListeners();
    }
  }

  /// tag = '<a '  '<div'
  String deleteTag(String text, String tag) {
    int s1 = 0;
    for (int i = 0; i < 1000; i++) {
      s1 = text.indexOf(tag);
      int e1 = (s1 >= 0) ? text.indexOf(r'>', s1 + tag.length) + 1 : 0;
      if (s1 >= 0 && e1 > 0) {
        text = text.substring(0, s1) + text.substring(e1);
      } else {
        break;
      }
    }
    return text;
  }

  /// tag = '<h3'
  String deleteClassAttr(String text, String tag) {
    int s1 = 0;
    for (int i = 0; i < 1000; i++) {
      s1 = text.indexOf(tag, s1);
      int e1 = (s1 >= 0) ? text.indexOf(r'>', s1 + tag.length) + 1 : 0;
      if (s1 >= 0 && e1 > 0) {
        text = text.substring(0, s1) + tag + r'>' + text.substring(e1);
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
    if (status != MyEpubStatus.none) {
      status = MyEpubStatus.none;
      this.notifyListeners();
    }
  }

  int calcChars(String text) {
    text = text.replaceAll('\n', '');
    text = text.replaceAll('<h3>', '');
    text = text.replaceAll('</h3>', '');
    // delete ruby
    // <ruby><rb>獅子</rb><rp>（</rp><rt>しし</rt><rp>）</rp></ruby>
    text = text.replaceAll('<ruby>', '');
    text = text.replaceAll('</ruby>', '');
    text = text.replaceAll('<rb>', '');
    text = text.replaceAll('</rb>', '');
    text = text.replaceAll('<rp>', '');
    text = text.replaceAll('</rp>', '');
    text = text.replaceAll('<rt>', '');
    text = text.replaceAll('</rt>', '');
    return text.length;
  }

  Future<int> getMaxIndex(String bookId) async {
    int maxIndex = 0;

    String appdir = (await getApplicationDocumentsDirectory()).path;
    if (!Platform.isIOS && !Platform.isAndroid) {
      appdir = appdir + '/test';
    }
    String datadir = appdir + '/book';
    try {
      final file = File('${datadir}/${bookId}/data/index.json');
      if (file.existsSync()) {
        String? txt1 = await file.readAsString();
        Map<String, dynamic> j = json.decode(txt1);
        IndexData bi = IndexData.fromJson(j);
        maxIndex = bi.getMaxIndex();
      }
    } catch (_) {}

    return maxIndex;
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

    status = MyEpubStatus.downloading;
    this.notifyListeners();
    downloaded = 0;

    String? body = await downloadCtrl.downloadSjis(epub.uriList[0]);
    if (body != null) {
      try {
        createAozoraText(body);

        if (epub.fileList.length >= 2) {
          writeBook();
          status = MyEpubStatus.succeeded;
        }
      } catch (_) {}
    }

    if (status != MyEpubStatus.succeeded) status = MyEpubStatus.failed;
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
    text = text.replaceAll('<br>', '<br />');

    // delete div
    text = deleteTag(text, '<div');
    text = text.replaceAll('</div>', '');

    // delete '<a '
    text = deleteTag(text, '<a ');
    text = text.replaceAll('</a>', '');

    // delete class '<h3'
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
      listText.add(listText1[0]);
    } else if (listText1.length > 1) {
      for (int i = 0; i < listText1.length; i++) {
        String t1 = listText1[i];
        if (i > 0) {
          t1 = '<h3' + t1;
          if (i < listText1.length - 1) {
            if (t1.length < 100) {
              String t2 = listText1[i + 1];
              t2 = '<h3' + t2;
              t2 = t2.replaceAll('<h3', '<h4');
              t2 = t2.replaceAll('</h3', '</h4');
              t1 += t2;
              i++;
            }
          }
        }
        listText.add(t1);
      }
    }

    String text0 = '';
    text0 += '<h2>' + (epub.bookTitle ?? epub.bookId!) + '</h2>\n';
    text0 += epub.bookAuthor != null ? '<h2>' + epub.bookAuthor! + '</h2>\n' : '';
    EpubFileData f0 = EpubFileData();
    f0.chapNo = 0;
    f0.fileName = 'text/ch${f0.chapNo000}.txt';
    f0.title = epub.bookTitle;
    f0.text = text0;
    f0.chars = text0.length;
    epub.fileList.add(f0);

    if (listText.length == 1) {
      EpubFileData f = EpubFileData();
      f.chapNo = 1;
      f.fileName = 'text/ch${f.chapNo000}.txt';
      f.text = text;
      f.title = epub.bookTitle;
      f.chars = text.length;
      epub.fileList.add(f);
    } else if (listText.length > 1) {
      for (int i = 1; i < listText.length; i++) {
        String text = listText[i];

        String title = '${i + 1}';
        BeautifulSoup bs1 = BeautifulSoup(text);
        Bs4Element? el1 = bs1.find(hd);
        if (el1 != null) {
          title = el1.innerHtml;
        }

        EpubFileData f = EpubFileData();
        f.chapNo = i;
        f.fileName = 'text/ch${f.chapNo000}.txt';
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
            for (var MapEntry(:key, :value) in map.entries) {
              if (value['__typename'] != null && value['id'] != null) {
                if (value['__typename'] == 'Episode') {
                  epub.uriList
                      .add('https://kakuyomu.jp/works/${epub.siteId}/episodes/${value['id']}');
                } else if (value['__typename'] == 'Work') {
                  if (value['id'] == epub.siteId) {
                    epub.bookTitle = value['title'];
                    var aut = value['author'];
                    var ref = aut['__ref'] ?? '';
                    userId = ref.toString().substring(ref.toString().indexOf('UserAccount:') + 12);
                  }
                } else if (value['__typename'] == 'UserAccount') {
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

    if (epub.bookTitle == null) {
      Bs4Element? el = bs.find('meta', attrs: {'property': 'og:title'});
      if (el != null) epub.bookTitle = el['content'];
    }
  }

  Future<void> downloadKakuyomu() async {
    status = MyEpubStatus.downloading;
    downloaded = 0;
    this.notifyListeners();

    String text0 = '';
    text0 += '<h2>' + (epub.bookTitle ?? epub.bookId!) + '</h2>\n';
    text0 += epub.bookAuthor != null ? '<h2>' + epub.bookAuthor! + '</h2>\n' : '';
    EpubFileData f0 = EpubFileData();
    f0.chapNo = 0;
    f0.fileName = 'text/ch${f0.chapNo000}.txt';
    f0.title = epub.bookTitle;
    f0.text = text0;
    f0.chars = text0.length;
    epub.fileList.add(f0);

    for (int i = downloadedIndex; i < epub.uriList.length; i++) {
      sleep(Duration(milliseconds: 200));

      String? body = await downloadCtrl.download(epub.uriList[i]);
      if (body != null) {
        await createKakuyomuText(body, i + 1);
      } else {
        break;
      }

      downloaded = i;
      if (downloaded % 5 == 0) {
        this.notifyListeners();
      }
      if (i >= numOfDownloadRequired) break;
    }

    if (epub.fileList.length >= 2) {
      writeBook();
      status = MyEpubStatus.succeeded;
    } else {
      status = MyEpubStatus.failed;
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

    Bs4Element? ec = bs.find('div', class_: 'widget-episodeBody js-episode-body');
    if (ec != null) {
      String text = ec.innerHtml;
      text = text.replaceAll('<br>', '<br />');
      text = text.replaceAll('&nbsp;', '');
      String title = '<h3>${f.title}</h3>\n';

      // delete <p>
      text = deleteTag(text, '<p ');
      text = text.replaceAll('</p>', '<br />');

      f.text = title + text;
      f.chars = calcChars(text);
      f.chapNo = chap;
      f.fileName = 'text/ch${f.chapNo000}.txt';
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

    List<Bs4Element> els = bs.findAll('a', class_: 'p-eplist__subtitle');
    for (Bs4Element e in els) {
      String? s = e.getAttrValue('href');
      if (s != null) {
        String u = 'https://ncode.syosetu.com' + s;
        epub.uriList.add(u);
      }
    }
  }

  Future<void> downloadNarou() async {
    status = MyEpubStatus.downloading;
    this.notifyListeners();
    downloaded = 0;

    if (epub.uriList.length > 0) {
      for (int i = downloadedIndex; i < epub.uriList.length; i++) {
        sleep(Duration(milliseconds: 200));

        String? body = await downloadCtrl.download(epub.uriList[i]);
        if (body != null) {
          await createNarouText(body, i + 1);
        } else {
          break;
        }

        downloaded = i;
        if (downloaded % 5 == 0) {
          this.notifyListeners();
        }
        if (i >= numOfDownloadRequired) break;
      }
    }
    writeBook();
    status = MyEpubStatus.succeeded;
    this.notifyListeners();
  }

  Future<void> downloadNarou8() async {
    if (webViewController == null) {
      status = MyEpubStatus.failed;
      return;
    }

    status = MyEpubStatus.downloading;
    this.notifyListeners();
    downloaded = 0;

    if (epub.uriList.length > 0) {
      for (int i = downloadedIndex; i < epub.uriList.length; i++) {
        await Future.delayed(Duration(milliseconds: 100));

        // https://ncode.syosetu.com/n6964jl/1/
        String? body = await downloadCtrl.download8(epub.uriList[i]);
        if (body != null) {
          await createNarouText(body, i + 1);
        } else {
          break;
        }

        downloaded = i;
        if (downloaded % 5 == 0) {
          this.notifyListeners();
        }
        if (i >= numOfDownloadRequired) break;
      }
    }
    writeBook();
    status = MyEpubStatus.succeeded;
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
      Bs4Element? el = bs.find('h1', class_: 'p-novel__title p-novel__title--rensai');
      if (el != null) f.title = el.innerHtml;
    }
    if (f.title == null) {
      Bs4Element? el = bs.find('meta', attrs: {'property': 'og:title'});
      if (el != null) f.title = el['content'];
    }

    String text = '';
    //<div class="js-novel-text p-novel__text">
    List<Bs4Element> els = bs.findAll('div', class_: 'js-novel-text p-novel__text');
    for (Bs4Element el in els) {
      String t1 = el.innerHtml;
      t1 = t1.replaceAll('<br>', '<br />');
      t1 = t1.replaceAll('&nbsp;', '');

      // delete <p>
      text = deleteTag(text, '<p ');
      text = text.replaceAll('</p>', '<br />');

      if (text != '') text += '<br />';
      text += t1;
    }

    if (text != '') {
      String title = '<h3>${f.title}</h3>\n';
      f.text = title + text;
      f.chars = calcChars(text);
      f.fileName = 'text/ch${f.chapNo000}.txt';
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

  Future<String?> download(String uri) async {
    Map<String, String> headers = {
      'user-agent':
          'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148'
    };
    String? body = null;
    try {
      http.Response res = await http.get(Uri.parse(uri), headers: headers);
      if (res.statusCode == 200) {
        body = res.body;
      }
    } catch (_) {}
    return body;
  }

  Future<String?> downloadSjis(String uri) async {
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
    } catch (_) {}
    return body;
  }

  Future<String?> download8(String uri) async {
    if (webViewController8 == null) return null;
    webBody = null;
    try {
      await webViewController8!.loadUrl(
        urlRequest: URLRequest(url: WebUri(uri)),
      );

      for (int wait = 0; wait < 100; wait++) {
        await Future.delayed(Duration(milliseconds: 100));
        if (this.webBody != null) {
          log('download finish wait=${wait}');
          break;
        }
      }
    } catch (_) {}
    return webBody;
  }

  Widget browser8() {
    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
    return InAppWebView(
      key: GlobalKey(),
      onWebViewCreated: (controller) async {
        webViewController8 = controller;
      },
      onLoadStart: (controller, url) {},
      onLoadStop: (controller, url) async {
        if (url != null) {
          webBody = await webViewController8!.getHtml();
        }
      },
    );
  }
}
