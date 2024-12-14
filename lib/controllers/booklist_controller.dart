import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:developer';
import 'package:path/path.dart';
import 'dart:convert';

import '/models/book_data.dart';

final booklistProvider = ChangeNotifierProvider((ref) => BookListNotifier(ref));

class BookListNotifier extends ChangeNotifier {
  BookListNotifier(ref) {
    init();
  }

  BookData? selected;

  late String datadir;
  List<BookData> bookList = [];

  Future<void> init() async {
    readBookList();
    this.notifyListeners();
  }

  /// read books.json
  Future readBookList() async {
    String appdir = (await getApplicationDocumentsDirectory()).path;
    if (!Platform.isIOS && !Platform.isAndroid) {
      appdir = appdir + '/test';
    }
    datadir = appdir + '/data';
    await Directory('${datadir}').create(recursive: true);

    bookList.clear();
    List<FileSystemEntity> entities = Directory(datadir).listSync();
    for (var e in entities) {
      if (FileSystemEntity.isDirectorySync(e.path) == true) {
        log('${e.path}');
        String bookId = basename(e.path);
        //if (bookId == 'styles') continue;
        if (File('${e.path}/book.json').existsSync()) {
          String? txt = await File('${e.path}/book.json').readAsString();
          Map<String, dynamic> j = json.decode(txt);
          BookData book = BookData();
          book = BookData.fromJson(j);

          if (book.bookId != bookId) {
            book.bookId = bookId;
          }

          try {
            final infoFile = File('${e.path}/book_info.json');
            if (infoFile.existsSync()) {
              String? txt1 = await infoFile.readAsString();
              Map<String, dynamic> j = json.decode(txt1);
              BookInfoData bi = BookInfoData.fromJson(j);
              book.info = bi;
            }
          } catch (_) {}

          bookList.add(book);
        } else {
          BookData book = BookData();
          book.bookId = e.path.replaceAll('${datadir}/', '');
          book.title = book.bookId;
          bookList.add(book);
        }
      }
    }
    this.notifyListeners();
  }
}
