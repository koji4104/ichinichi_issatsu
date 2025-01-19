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
import '/controllers/log_controller.dart';

final browserProvider = ChangeNotifierProvider((ref) => BrowserNotifier(ref));

class BrowserNotifier extends ChangeNotifier {
  BrowserNotifier(ref) {}

  InAppWebViewController? webViewController;
  InAppWebViewController? webViewController18;
  String? webBody;
  bool isBrowserDownloading = false;

  Widget browser() {
    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
    return InAppWebView(
      key: GlobalKey(),
      onWebViewCreated: (controller) async {
        webViewController = controller;
      },
      onLoadStart: (controller, url) {},
      onLoadStop: (controller, url) async {
        if (url != null) {
          //if (ref.watch(epubProvider).isBrowserDownloading) {
          //  String? body = await webViewController1!.getHtml();
          //  ref.watch(epubProvider).webBody = body;
          //  return;
          //}
        }
      },
    );
  }

  Widget browser18() {
    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;
    return InAppWebView(
      key: GlobalKey(),
      onWebViewCreated: (controller) async {
        webViewController18 = controller;
      },
      onLoadStart: (controller, url) {},
      onLoadStop: (controller, url) async {
        if (url != null) {
          if (isBrowserDownloading) {
            String? body = await webViewController18!.getHtml();
            webBody = body;
          }
        }
      },
    );
  }
}
