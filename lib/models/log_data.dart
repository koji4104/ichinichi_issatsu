import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class BooklogData {
  int tabCount = 4;
  String date = '';
  String id = '1';
  String title = '';
  String author = '';

  BooklogData(String? date, String? id, String? title, String? author) {
    this.date = date ?? '';
    this.id = id ?? '';
    this.title = title ?? '';
    this.author = author ?? '';
  }
}
