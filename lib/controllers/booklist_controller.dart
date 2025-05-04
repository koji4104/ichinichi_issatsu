import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:developer';
import 'package:path/path.dart';
import 'dart:convert';

import '/models/book_data.dart';
import '/constants.dart';
import '/controllers/applog_controller.dart';

final booklistProvider = ChangeNotifierProvider((ref) => BookListNotifier(ref));

class BookListNotifier extends ChangeNotifier {
  BookListNotifier(ref) {
    readBookList();
  }

  BookData? selected;
  late String bookdir;
  List<BookData> bookList = [];
  List<PropData> propList = [];
  bool isReading = false;

  /// read books.json
  Future readBookList() async {
    if (APP_DIR == '') {
      APP_DIR = (await getApplicationDocumentsDirectory()).path;
      if (!Platform.isIOS && !Platform.isAndroid) {
        APP_DIR = APP_DIR + '/test';
      }
    }

    bookdir = APP_DIR + '/book';
    await Directory('${bookdir}').create(recursive: true);

    isReading = true;
    bookList.clear();

    List<FileSystemEntity> entities = Directory(bookdir).listSync();
    for (var e in entities) {
      if (FileSystemEntity.isDirectorySync(e.path) == true) {
        //log('readBookList ${e.path}');
        String bookId = basename(e.path);

        if (File('${e.path}/data/book.json').existsSync()) {
          try {
            String? txt = await File('${e.path}/data/book.json').readAsString();
            Map<String, dynamic> j = json.decode(txt);
            BookData book = BookData();
            book = BookData.fromJson(j);
            //log('${book.title}');

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

  Future saveFlag(String bookId, int flag) async {
    try {
      String dir = bookdir + '/${bookId}';
      if (Directory(dir).existsSync()) {
        PropData prop = PropData();
        final file = File('${dir}/data/prop.json');
        if (file.existsSync()) {
          String? txt1 = await file.readAsString();
          Map<String, dynamic> j = json.decode(txt1);
          prop = PropData.fromJson(j);
          prop.flag = flag;
        }
        String jsonText = json.encode(prop.toJson());
        await file.writeAsString(jsonText, mode: FileMode.write, flush: true);
        this.notifyListeners();
      }
    } on Exception catch (e) {
      MyLog.err('saveFlag() ${e.toString()}');
    }
  }

  Future saveLastAccess(int index) async {
    try {
      String dir = bookdir + '/${bookList[index].bookId}';
      if (Directory(dir).existsSync()) {
        PropData prop = PropData();
        final file = File('${dir}/data/prop.json');
        if (file.existsSync()) {
          String? txt1 = await file.readAsString();
          Map<String, dynamic> j = json.decode(txt1);
          prop = PropData.fromJson(j);
          prop.atime = DateTime.now();
        }
        String jsonText = json.encode(prop.toJson());
        file.writeAsString(jsonText, mode: FileMode.write, flush: true);
        this.notifyListeners();
      }
    } on Exception catch (e) {
      MyLog.err('saveLastAccess() ${e.toString()}');
    }
  }

  Future AddDownload(int index) async {
    bookList[index].dluri;
  }
}
