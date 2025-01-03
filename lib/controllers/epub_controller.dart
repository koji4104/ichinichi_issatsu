import 'dart:convert' as convert;
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:charset_converter/charset_converter.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '/models/book_data.dart';
import '/models/epub_data.dart';

enum MyEpubStatus {
  none,
  downloading,
  succeeded,
  failed,
}

class MyEpubController {
  MyEpubController() {}
  EpubData epub = new EpubData();
  MyEpubStatus status = MyEpubStatus.none;

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
    //await Directory('${datadir}/${epub.bookId}/styles').create(recursive: true);
    for (EpubFileData f in epub.fileList) {
      List<int> content = convert.utf8.encode(f.text!);
      final file = File('${datadir}/${epub.bookId}/${f.fileName}');
      await file.writeAsBytes(content);
    }

    BookData book = BookData();
    book.title = epub.bookTitle ?? epub.bookId!;
    book.bookId = epub.bookId!;
    book.author = epub.bookAuther ?? '';
    for (EpubFileData f in epub.fileList) {
      if (f.chapNo > 0) {
        IndexData ch = IndexData();
        ch.title = f.title ?? '';
        ch.index = f.chapNo;
        ch.charCount = f.charCount;
        book.indexList.add(ch);
      }
    }

    String jsonText = json.encode(book.toJson());
    final file = File('${datadir}/${epub.bookId}/book.json');
    await file.writeAsString(jsonText, mode: FileMode.write, flush: true);

    BookInfoData bi = BookInfoData();
    var val = json.encode(bi.toJson());
    final fileInfo = File('${datadir}/${epub.bookId}/book_info.json');
    await fileInfo.writeAsString(val, mode: FileMode.write, flush: true);
  }

  Future checkHtml(String url, String body) async {
    epub.reset();
    status = MyEpubStatus.none;

    if (url.toString().contains('www.aozora.gr.jp/cards/')) {
      await checkAozora(url, body);
    } else if (url.toString().contains('kakuyomu.jp/works/')) {
      await checkKakuyomu(url, body);
    } else if (url.toString().contains('ncode.syosetu.com/')) {
      await checkNarou(url, body);
    }
  }

  Future<void> download() async {
    if (epub.urlList.length == 0 || epub.contentUrl == null) {
      log('urlList.length == 0');
      return;
    }
    if (epub.contentUrl.toString().contains('www.aozora.gr.jp/cards/')) {
      await downloadAozora();
    } else if (epub.contentUrl.toString().contains('kakuyomu.jp/works/')) {
      await downloadKakuyomu();
    } else if (epub.contentUrl.toString().contains('ncode.syosetu.com/')) {
      await downloadNarou();
    }
  }

  //--------
  // Aozora
  //--------

  Future checkAozora(String url, String body) async {
    epub.reset();
    epub.contentUrl = url;

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
        epub.urlList.add(dl);

        try {
          String fname = dl.substring(dl.lastIndexOf('/files/') + 7);
          epub.bookId = fname.substring(0, fname.indexOf('_'));
        } catch (_) {}
        break;
      }
    }
  }

  Future downloadAozora() async {
    if (epub.urlList.length == 0) return;
    if (epub.bookId == null) return;

    String url = epub.urlList[0];
    http.Response res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
      try {
        String text1 = await CharsetConverter.decode("Shift_JIS", res.bodyBytes);
        createAozoraFromText(text1);
        writeBook();
        status = MyEpubStatus.succeeded;
      } catch (_) {
        status = MyEpubStatus.failed;
      }
    } else {
      status = MyEpubStatus.failed;
    }
  }

  Future createAozoraFromText(String text1) async {
    if (epub.bookId == null) return;

    BeautifulSoup bs = BeautifulSoup(text1);
    String bookId = epub.bookId!;
    epub.bookTitle = bookId;
    Bs4Element? elTitle = bs.find('meta', attrs: {'name': 'DC.Title'});
    if (elTitle != null) {
      epub.bookTitle = elTitle['content'] ?? bookId;
    }

    String bookAuthor = bookId;
    Bs4Element? elAuthor = bs.find('meta', attrs: {'name': 'DC.Creator'});
    if (elAuthor != null) {
      bookAuthor = elAuthor['content'] ?? '';
    }

    Bs4Element? el = bs.find('div', class_: 'main_text');
    String t1 = el!.innerHtml;
    t1 = t1.replaceAll('<br>', '<br />');

    // delete div
    for (int i = 0; i < 1000; i++) {
      int s1 = t1.indexOf('<div');
      int e1 = (s1 > 0) ? t1.indexOf(r'>', s1 + 4) + 1 : 0;
      if (s1 > 0 && e1 > 0) {
        t1 = t1.substring(0, s1) + t1.substring(e1);
      } else {
        break;
      }
    }
    t1 = t1.replaceAll('</div>', '');

    String hd = '<h3';
    List<String> textList3 = t1.split('<h3');
    List<String> textList4 = t1.split('<h4');
    if (textList3.length < textList4.length) hd = '<h4';

    List<String> listText = t1.split(hd);
    if (listText.length <= 1) {
      listText.clear();
      for (int i = 0; i < 100; i++) {
        if (t1.length < 50000) {
          listText.add(t1);
          break;
        }
        int sk = t1.indexOf('\n<br />', 20000) + 8;
        listText.add(t1.substring(0, sk));
        t1 = t1.substring(sk);
      }
      hd = '';
    }

    for (int i = 0; i < listText.length; i++) {
      String text = listText[i];
      if (i == 0 && listText.length > 1) continue; // 0 is header
      text = hd + text;
      String title = '${i + 1}';

      BeautifulSoup bs1 = BeautifulSoup(text);
      Bs4Element? el1 = bs1.find('a');
      if (el1 != null) {
        title = el1!.innerHtml;
      } else {
        text += '<h3>${title}</h3>';
      }

      EpubFileData f = EpubFileData();

      f.chapNo = listText.length == 1 ? 1 : i;
      f.fileName = 'text/ch${f.chapNo000}.xhtml';
      f.text = epub.head1 + text + epub.head2;
      f.title = title;
      f.charCount = text.length;
      epub.fileList.add(f);
    }
  }

  //----------
  // Kakuyomu
  //----------

  Future<void> checkKakuyomu(String url, String body) async {
    epub.reset();
    epub.contentUrl = url;
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
                  epub.urlList
                      .add('https://kakuyomu.jp/works/${epub.bookId}/episodes/${value['id']}');
                } else if (value['__typename'] == 'Work') {
                  if (value['id'] == epub.bookId) {
                    epub.bookTitle = value['title'] ?? epub.bookId;
                    var aut = value['author'];
                    var ref = aut['__ref'] ?? '';
                    epub.bookAuther =
                        ref.toString().substring(ref.toString().indexOf('UserAccount:') + 12);
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
    for (int i = 0; i < epub.urlList.length; i++) {
      if (i > 10) break;
      sleep(Duration(milliseconds: 500));
      http.Response res1 = await http.get(Uri.parse(epub.urlList[i]));
      if (res1.statusCode == 200) {
        await createKakuyomuFromText(res1.body, i + 1);
      }
    }
    writeBook();
  }

  Future createKakuyomuFromText(String text1, int chap) async {
    EpubFileData f = new EpubFileData();
    f.chapNo = chap;
    BeautifulSoup bs = BeautifulSoup(text1);
    Bs4Element? et = bs.find('p', class_: 'widget-episodeTitle');
    if (et != null) f.title = et.innerHtml;

    Bs4Element? ec = bs.find('div', class_: 'widget-episodeBody js-episode-body');
    if (ec != null) {
      String t1 = ec.innerHtml;
      t1 = t1.replaceAll('<br>', '<br />');
      t1 = t1.replaceAll('&nbsp;', '');
      String title = '<h3>${f.title}</h3>';
      f.text = epub.head1 + title + t1 + epub.head2;
      f.charCount = t1.length;
    }
    f.chapNo = chap;
    f.fileName = 'text/ch${f.chapNo000}.xhtml';
    epub.fileList.add(f);
    return f;
  }

  //-------
  // Narou
  //-------

  Future<void> checkNarou(String url, String body) async {
    epub.reset();
    epub.bookId = url.substring(url.indexOf('syosetu.com/') + 12);

    BeautifulSoup bs = BeautifulSoup(body);
    List<Bs4Element> els = bs.findAll('a', class_: 'p-eplist__subtitle');
    for (Bs4Element e in els) {
      String? s = e.getAttrValue('href');
      if (s != null) {
        String u = 'https://ncode.syosetu.com' + s;
        epub.urlList.add(u);
      }
    }
  }

  Future<void> downloadNarou() async {
    if (epub.urlList.length > 0) {
      for (int i = 0; i < epub.urlList.length; i++) {
        sleep(Duration(seconds: 2));
        http.Response res1 = await http.get(Uri.parse(epub.urlList[i]));
        log('${res1.statusCode}  ${epub.urlList[i]}');
        if (res1.statusCode == 200) {
          await createNarouFromText(res1.body, i + 1);
          break;
        } else {
          break;
        }
      }
    }
    writeBook();
  }

  Future createNarouFromText(String text1, int chap) async {
    EpubFileData f = new EpubFileData();
    f.chapNo = chap;
    BeautifulSoup bs = BeautifulSoup(text1);
    Bs4Element? et = bs.find('h1', class_: 'p-novel__title p-novel__title--rensai');
    if (et != null) f.title = et.innerHtml;

    //<div class="js-novel-text p-novel__text">
    Bs4Element? ec = bs.find('div', class_: 'js-novel-text p-novel__text');
    if (ec != null) {
      String t1 = ec.innerHtml;
      t1 = t1.replaceAll('<br>', '<br />');
      t1 = t1.replaceAll('&nbsp;', '');
      String title = '<h3>${f.title}</h3>';
      f.text = epub.head1 + title + t1 + epub.head2;
      f.charCount = t1.length;
    }

    f.chapNo = chap;
    f.fileName = 'text/ch${f.chapNo000}.xhtml';

    epub.fileList.add(f);
    return f;
  }
}
