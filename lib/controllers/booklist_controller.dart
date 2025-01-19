import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:developer';
import 'package:path/path.dart';
import 'dart:convert';

import '/models/book_data.dart';
import '/models/log_data.dart';
import '/controllers/log_controller.dart';

final booklistProvider = ChangeNotifierProvider((ref) => BookListNotifier(ref));

class BookListNotifier extends ChangeNotifier {
  BookListNotifier(ref) {
    readBookList();
  }

  BookData? selected;
  late String datadir;
  List<BookData> bookList = [];
  List<PropData> propList = [];
  bool isReading = false;

  /// read books.json
  Future readBookList() async {
    String appdir = (await getApplicationDocumentsDirectory()).path;
    if (!Platform.isIOS && !Platform.isAndroid) {
      appdir = appdir + '/test';
    }
    datadir = appdir + '/book';
    await Directory('${datadir}').create(recursive: true);

    log('readBookList()');
    isReading = true;
    bookList.clear();

    List<FileSystemEntity> entities = Directory(datadir).listSync();
    for (var e in entities) {
      if (FileSystemEntity.isDirectorySync(e.path) == true) {
        log('readBookList ${e.path}');
        String bookId = basename(e.path);
        if (File('${e.path}/data/book.json').existsSync()) {
          try {
            String? txt = await File('${e.path}/data/book.json').readAsString();
            Map<String, dynamic> j = json.decode(txt);
            BookData book = BookData();
            book = BookData.fromJson(j);
            log('${book.title}');

            try {
              final indexFile = File('${e.path}/data/index.json');
              if (indexFile.existsSync()) {
                String? txt1 = await indexFile.readAsString();
                Map<String, dynamic> j = json.decode(txt1);
                IndexData bi = IndexData.fromJson(j);
                book.index = bi;
              }
            } catch (_) {}

            try {
              final propFile = File('${e.path}/data/prop.json');
              if (propFile.existsSync()) {
                String? txt1 = await propFile.readAsString();
                Map<String, dynamic> j = json.decode(txt1);
                PropData bi = PropData.fromJson(j);
                book.prop = bi;
              }
            } catch (_) {}

            bookList.add(book);
          } catch (_) {
            continue;
          }
        }
      }
    }
    await Future.delayed(Duration(milliseconds: 500));
    isReading = false;
    this.notifyListeners();
  }

  Future saveFlag(int index, int flag) async {
    String dir = datadir + '/${bookList[index].bookId}';
    if (Directory(dir).existsSync()) {
      final infoFile = File('${dir}/data/prop.json');
      if (infoFile.existsSync()) {
        String? txt1 = await infoFile.readAsString();
        Map<String, dynamic> j = json.decode(txt1);
        PropData prop = PropData.fromJson(j);
        prop.flag = flag;

        String jsonText = json.encode(prop.toJson());
        final file = File('${dir}/data/prop.json');
        file.writeAsString(jsonText, mode: FileMode.write, flush: true);
        this.notifyListeners();
      }
    }
  }

  Future saveLastAccess(int index) async {
    String dir = datadir + '/${bookList[index].bookId}';
    if (Directory(dir).existsSync()) {
      final infoFile = File('${dir}/book_info.json');
      if (infoFile.existsSync()) {
        String? txt1 = await infoFile.readAsString();
        Map<String, dynamic> j = json.decode(txt1);
        PropData prop = PropData.fromJson(j);
        prop.atime = DateTime.now();

        String jsonText = json.encode(prop.toJson());
        final file = File('${dir}/data/prop.json');
        file.writeAsString(jsonText, mode: FileMode.write, flush: true);
        this.notifyListeners();
      }
    }
  }

  Future AddDownload(int index) async {
    bookList[index].dluri;
  }
}
