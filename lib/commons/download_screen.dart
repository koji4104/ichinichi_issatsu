import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:io';
import 'dart:developer';

import '/localizations.dart';
import '/commons/widgets.dart';
import '/controllers/env_controller.dart';
import '/controllers/epub_controller.dart';
import '/commons/base_screen.dart';

/// DownloadScreen
class DownloadScreen extends BaseScreen {
  EpubController epubCtrl = EpubController();
  bool isDownloadFinished = false;
  MyEpubStatus status = MyEpubStatus.none;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    super.build(context, ref);
    ref.watch(epubProvider);
    epubCtrl.ref = ref;
    status = epubCtrl.status;
    return Container();
  }

  @override
  Future onDownloadFinished() async {}

  /// ダウンロードバー
  Widget downloadBar() {
    double barHeight = Platform.isIOS ? 260 : 200;
    double ffBottom = 0;
    if (status == MyEpubStatus.none) {
      ffBottom = -1.0 * barHeight;
    } else if (status == MyEpubStatus.downloading) {
      ffBottom = -1.0 * 80;
    } else {
      ffBottom = 0;
    }

    int DL_COUNT1 = 10;
    int DL_COUNT2 = 100;
    int DL_SPARE = 10;

    bool isClose = false;
    String label1 = '';
    String label2 = '';
    //int already = ref.watch(epubProvider).existingIndex;
    int already = epubCtrl.alreadyIndex;
    //int done = ref.watch(epubProvider).doneIndex;
    int done = epubCtrl.doneIndex;
    //int all = ref.watch(epubProvider).epub.uriList.length;
    int all = epubCtrl.epub.uriList.length;
    int req1 = 0;
    int req2 = 0;

    //label1 =
    //    '${ref.watch(epubProvider).epub.bookTitle ?? ref.watch(epubProvider).epub.bookId}';
    label1 = '${epubCtrl.epub.bookTitle ?? epubCtrl.epub.bookId}';

    if (status == MyEpubStatus.downloadable) {
      if (all == 1) {
        // 全1話
        req1 = all;
        req2 = 0;
      } else if (all > 0 && already == 0) {
        // 初回ダウンロード
        if (all < DL_COUNT1 + DL_SPARE) {
          req1 = all;
          req2 = 0;
        } else if (all < DL_COUNT2 + DL_SPARE) {
          req1 = DL_COUNT1;
          req2 = all;
        } else {
          req1 = DL_COUNT1;
          req2 = DL_COUNT2;
        }
      } else if (all > 0 && already > 0) {
        // 追加ダウンロード
        if (all < already + DL_COUNT1 + DL_SPARE) {
          req1 = all;
          req2 = 0;
        } else if (all < already + DL_COUNT2 + DL_SPARE) {
          req1 = already + DL_COUNT1;
          req2 = all;
        } else {
          req1 = already + DL_COUNT1;
          req2 = already + DL_COUNT2;
        }
      }
      if (all > 1 && already > 1) {
        label2 += '${already} / ${all} ${l10n('episode')}';
      } else if (all > 1) {
        label2 += '${all} ${l10n('episode')}';
      }
    } else if (status == MyEpubStatus.succeeded) {
      // 成功
      label2 = '${l10n('download_complete')} ${done} / ${all}';
      isClose = true;
    } else if (status == MyEpubStatus.same) {
      // 最新
      label2 = '${l10n('already_downloaded')} ${already} / ${all}';
      isClose = true;
    } else if (status == MyEpubStatus.failed) {
      // 失敗
      label2 = '${l10n('download_failed')}';
      isClose = true;
    } else if (status == MyEpubStatus.downloading) {
      // ダウンロード中
      label1 = 'Downloading';
      if (done > 0) {
        label1 += ' ${done} / ${all}';
      }
    }

    Widget h = SizedBox(height: 4);
    Widget btn = Column(children: []);
    double btnWidth = 240;

    if (isClose) {
      btn = Column(children: [
        MyTextButton(
          noScale: true,
          width: btnWidth,
          title: l10n('close'),
          onPressed: () {
            //ref.read(epubProvider).setStatusNone();
            epubCtrl.setStatusNone();
          },
        ),
      ]);
    } else if (req1 > 0) {
      // 10 話 まで ダウンロード
      String btnTitle1 =
          '${req1} ${l10n('episode')} ${l10n('up_to')} ${l10n('download')}';
      if (req1 == 1) btnTitle1 = '${l10n('download')}';
      String btnTitle2 =
          '${req2} ${l10n('episode')} ${l10n('up_to')} ${l10n('download')}';

      btn = Column(children: [
        MyTextButton(
          noScale: true,
          width: btnWidth,
          commit: true,
          title: btnTitle1,
          onPressed: () {
            //ref.read(epubProvider).download(req1).then((ret) {
            epubCtrl.download(req1).then((ret) {
              if (ret) {
                onDownloadFinished();
              }
            });
          },
        ),
        if (req2 > 0) h,
        if (req2 > 0)
          MyTextButton(
            noScale: true,
            width: btnWidth,
            commit: true,
            title: btnTitle2,
            onPressed: () {
              //ref.read(epubProvider).download(req2).then((ret) {
              epubCtrl.download(req2).then((ret) {
                if (ret) {
                  onDownloadFinished();
                }
              });
            },
          ),
        h,
        MyTextButton(
          noScale: true,
          width: btnWidth,
          title: l10n('cancel'),
          onPressed: () {
            //ref.read(epubProvider).setStatusNone();
            epubCtrl.setStatusNone();
          },
        ),
      ]);
    }

    Widget bar = Container(
      color: myTheme.cardColor,
      child: Column(
        children: [
          closeButtonRow(),
          Row(children: [
            SizedBox(width: 20),
            Expanded(child: MyText(label1, noScale: true, center: true)),
            SizedBox(width: 20),
          ]),
          if (label2 != '') SizedBox(height: 4),
          if (label2 != '')
            Row(children: [
              SizedBox(width: 20),
              Expanded(child: MyText(label2, noScale: true, center: true)),
              SizedBox(width: 20),
            ]),
          SizedBox(height: 6),
          btn,
          Expanded(child: SizedBox(height: 1)),
        ],
      ),
    );

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 500),
      curve: Curves.linear,
      left: 0,
      top: null,
      right: 0,
      bottom: ffBottom,
      height: barHeight,
      child: bar,
    );
  }
}
