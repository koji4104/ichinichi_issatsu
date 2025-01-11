import 'dart:convert' as convert;
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:async';
import 'package:flutter/material.dart';

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
  downloadable,
  downloading,
  succeeded,
  failed,
}

final epubProvider = ChangeNotifierProvider((ref) => EpubNotifier(ref));

class EpubNotifier extends ChangeNotifier {
  EpubNotifier(ref) {}

  EpubData epub = new EpubData();
  MyEpubStatus status = MyEpubStatus.none;
  int downloaded = 0;

  Future writeBook() async {
    if (epub.bookId == null) return;
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
    String datadir = appdir + '/data';
    await Directory('${datadir}/${epub.bookId}').create(recursive: true);
    await Directory('${datadir}/${epub.bookId}/text').create(recursive: true);
    for (EpubFileData f in epub.fileList) {
      List<int> content = convert.utf8.encode(f.text!);
      final file = File('${datadir}/${epub.bookId}/${f.fileName}');
      await file.writeAsBytes(content);
    }

    BookData book = BookData();
    book.title = epub.bookTitle ?? epub.bookId!;
    book.bookId = epub.bookId!;
    book.author = epub.bookAuthor ?? '';
    book.charCount = 0;
    book.downloadUri = epub.downloadUri ?? '';
    for (EpubFileData f in epub.fileList) {
      if (f.chapNo >= 0) {
        IndexData ch = IndexData();
        ch.title = f.title ?? '';
        ch.index = f.chapNo;
        ch.chars = f.chars;
        book.charCount += f.chars;
        book.indexList.add(ch);
      }
    }

    String jsonText = json.encode(book.toJson());
    final file = File('${datadir}/${epub.bookId}/book_data.json');
    await file.writeAsString(jsonText, mode: FileMode.write, flush: true);

    BookInfoData bi = BookInfoData();
    var val = json.encode(bi.toJson());
    final fileInfo = File('${datadir}/${epub.bookId}/book_info.json');
    await fileInfo.writeAsString(val, mode: FileMode.write, flush: true);
  }

  Future checkHtml(String url, String body) async {
    epub.reset();

    if (url.toString().contains('www.aozora.gr.jp/cards/')) {
      await checkAozora(url, body);
    } else if (url.toString().contains('kakuyomu.jp/works/')) {
      await checkKakuyomu(url, body);
    } else if (url.toString().contains('ncode.syosetu.com/')) {
      await checkNarou(url, body);
    }

    if (epub.bookId != null && epub.uriList.isNotEmpty) {
      status = MyEpubStatus.downloadable;
      this.notifyListeners();
    } else if (status != MyEpubStatus.none) {
      status = MyEpubStatus.none;
      this.notifyListeners();
    }
  }

  Future<void> download() async {
    if (epub.uriList.length == 0 || epub.downloadUri == null) {
      log('urlList.length == 0');
      status = MyEpubStatus.failed;
      this.notifyListeners();
      return;
    }
    if (epub.downloadUri.toString().contains('www.aozora.gr.jp/cards/')) {
      await downloadAozora();
    } else if (epub.downloadUri.toString().contains('kakuyomu.jp/works/')) {
      await downloadKakuyomu();
    } else if (epub.downloadUri.toString().contains('ncode.syosetu.com/')) {
      await downloadNarou();
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

  Map<String, String> headers = {'user-agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148'};

  setStatusNone() {
    epub.reset();
    if (status != MyEpubStatus.none) {
      status = MyEpubStatus.none;
      this.notifyListeners();
    }
  }

  //--------
  // Aozora
  //--------

  Future checkAozora(String url, String body) async {
    epub.downloadUri = url;

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
          epub.bookId = fname.substring(0, fname.indexOf('_'));
        } catch (_) {}
        break;
      }
    }
  }

  Future downloadAozora() async {
    if (epub.uriList.length == 0) return;
    if (epub.bookId == null) return;

    status = MyEpubStatus.downloading;
    this.notifyListeners();
    downloaded = 0;

    String uri = epub.uriList[0];
    http.Response res = await http.get(Uri.parse(uri), headers: headers);
    if (res.statusCode == 200) {
      try {
        String text1 = await CharsetConverter.decode("Shift_JIS", res.bodyBytes);
        createAozoraText(text1);

        if (epub.fileList.length >= 2) {
          writeBook();
          status = MyEpubStatus.succeeded;
        } else {
          status = MyEpubStatus.failed;
        }
      } catch (_) {
        status = MyEpubStatus.failed;
      }
    } else {
      status = MyEpubStatus.failed;
    }
    this.notifyListeners();
  }

  Future createAozoraText(String body) async {
    if (epub.bookId == null) return;

    BeautifulSoup bs = BeautifulSoup(body);
    String bookId = epub.bookId!;
    epub.bookTitle = bookId;
    Bs4Element? elTitle = bs.find('meta', attrs: {'name': 'DC.Title'});
    if (elTitle != null) {
      epub.bookTitle = elTitle['content'] ?? bookId;
    }

    Bs4Element? elAuthor = bs.find('meta', attrs: {'name': 'DC.Creator'});
    if (elAuthor != null) {
      epub.bookAuthor = elAuthor['content'] ?? '';
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
        f.chars = text.length;
        epub.fileList.add(f);
      }
    }
  }

  //----------
  // Kakuyomu
  //----------

  Future<void> checkKakuyomu(String url, String body) async {
    epub.downloadUri = url;
    epub.bookId = url.substring(url.indexOf('works/') + 6);

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
                  epub.uriList.add('https://kakuyomu.jp/works/${epub.bookId}/episodes/${value['id']}');
                } else if (value['__typename'] == 'Work') {
                  if (value['id'] == epub.bookId) {
                    epub.bookTitle = value['title'] ?? epub.bookId;
                    var aut = value['author'];
                    var ref = aut['__ref'] ?? '';
                    epub.bookAuthor = ref.toString().substring(ref.toString().indexOf('UserAccount:') + 12);
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  Future<void> downloadKakuyomu() async {
    status = MyEpubStatus.downloading;
    this.notifyListeners();
    downloaded = 0;

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

    for (int i = 0; i < epub.uriList.length; i++) {
      sleep(Duration(milliseconds: 200));
      http.Response res1 = await http.get(Uri.parse(epub.uriList[i]), headers: headers);
      if (res1.statusCode == 200) {
        await createKakuyomuText(res1.body, i + 1);
      } else {
        break;
      }
      downloaded = i;
      if (downloaded % 5 == 0) {
        this.notifyListeners();
      }
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
      f.chars = text.length;
      f.chapNo = chap;
      f.fileName = 'text/ch${f.chapNo000}.txt';
      epub.fileList.add(f);
    }
    return;
  }

  //-------
  // Narou
  //-------

  Future<void> checkNarou(String url, String body) async {
    epub.downloadUri = url;
    epub.bookId = url.substring(url.indexOf('syosetu.com/') + 12);

    BeautifulSoup bs = BeautifulSoup(body);
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
      for (int i = 0; i < epub.uriList.length; i++) {
        sleep(Duration(milliseconds: 200));
        http.Response res1 = await http.get(Uri.parse(epub.uriList[i]), headers: headers);
        log('${res1.statusCode}  ${epub.uriList[i]}');
        if (res1.statusCode == 200) {
          await createNarouText(res1.body, i + 1);
        } else {
          break;
        }
        downloaded = i;
        if (downloaded % 5 == 0) {
          this.notifyListeners();
        }
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
    Bs4Element? et = bs.find('div', class_: 'p-novel__subtitle-episode');
    if (et != null) f.title = et.innerHtml;

    //<div class="js-novel-text p-novel__text">
    Bs4Element? ec = bs.find('div', class_: 'js-novel-text p-novel__text');
    if (ec != null) {
      String text = ec.innerHtml;
      text = text.replaceAll('<br>', '<br />');
      text = text.replaceAll('&nbsp;', '');
      String title = '<h3>${f.title}</h3>\n';

      // delete <p>
      text = deleteTag(text, '<p ');
      text = text.replaceAll('</p>', '<br />');

      f.text = title + text;
      f.chars = text.length;
      f.fileName = 'text/ch${f.chapNo000}.txt';
      epub.fileList.add(f);
    }

    return f;
  }

  //-------
  // Hamel
  //-------
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
