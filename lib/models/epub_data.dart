import 'dart:convert' as convert;
import 'package:archive/archive.dart';

class EpubFileData {
  EpubFileData({this.fileName, this.text}) {}
  String? title;
  String? text;
  String? fileName;
  int chapNo = -1;
  int chars = 0;

  String get chapNo000 {
    return chapNo.toString().padLeft(3, '0');
  }
}

class EpubData {
  EpubData() {}
  String? bookId;
  String? bookTitle;
  String? bookAuthor;
  String? siteId;

  List<EpubFileData> fileList = [];
  List<String> uriList = [];
  String? dluri;

  reset() {
    bookId = null;
    bookTitle = null;
    bookAuthor = null;
    siteId = null;
    dluri = null;
    fileList.clear();
    uriList.clear();
  }

  static const containerFile = """<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="EPUB/content.opf" media-type="application/oebps-package+xml" />
  </rootfiles>
</container>
""";

  /// text/title_page.html
  addTitle() {
    fileList.add(EpubFileData(fileName: titleFile, text: titleText));
  }

  String titleFile = 'text/title_page.html';
  String titleText = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="ja-JP">
<head>
  <meta charset="utf-8" />
  <meta name="generator" content="pandoc" />
  <title>TITLE</title>
  <style>
  </style>
  <link rel="stylesheet" type="text/css" href="../styles/stylesheet1.css" />
</head>
<body epub:type="frontmatter">
<section epub:type="titlepage" class="titlepage">
  <h1 class="title">TITLE</h1>
  <p class="author">author</p>
</section>
</body>
</html>
""";

  /// styles/stylesheet1.css
  addStyle() {
    fileList.add(EpubFileData(fileName: styleFile, text: styleText));
  }

  String styleFile = 'styles/stylesheet1.css';
  String styleText = """html {
  -webkit-writing-mode: vertical-rl;
  -epub-writing-mode: tb-rl;
  writing-mode: vertical-rl;
  text-orientation: upright;
  -webkit-text-orientation: upright;
}
body {
  font-size: 16px;
  font-family: sans-serif;
}
p {
  margin: 0;
}
""";

  /// content.opf
  addOpf() {
    String text = opf1;

    // <item id="ch001_xhtml" href="text/ch001.xhtml" media-type="application/xhtml+xml" />
    for (EpubFileData f in fileList) {
      if (f.fileName!.contains('text/ch')) {
        text += '<item id="ch${f.chapNo000}_xhtml" href="${f.fileName}" media-type="application/xhtml+xml" />\n';
      }
    }
    text += opf2;

    // <itemref idref="ch001_xhtml" />
    for (EpubFileData f in fileList) {
      if (f.fileName!.contains('text/ch')) {
        text += '<itemref idref="ch${f.chapNo000}_xhtml" />\n';
      }
    }
    text += opf3;
    fileList.add(EpubFileData(fileName: opfFile, text: text));
  }

  String opfFile = 'content.opf';
  String opf1 = """<?xml version="1.0" encoding="UTF-8"?>
<package version="3.0" xmlns="http://www.idpf.org/2007/opf" unique-identifier="epub-id-1" prefix="ibooks: http://vocabulary.itunes.apple.com/rdf/ibooks/vocabulary-extensions-1.0/">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
    <dc:identifier id="epub-id-1">urn:uuid:685a3766-bed6-40b7-9eb5-6095678465b7</dc:identifier>
    <dc:title id="epub-title-1">TITLE</dc:title>
    <dc:date id="epub-date">2023-11-12T15:25:34Z</dc:date>
    <dc:language>ja-JP</dc:language>
    <dc:creator id="epub-creator-1">TITLE</dc:creator>
    <meta refines="#epub-creator-1" property="role" scheme="marc:relators">aut</meta>
    <meta name="cover" content="cover_jpg" />
    <meta property="dcterms:modified">2023-11-12T15:25:34Z</meta>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav" />
    <item id="stylesheet1" href="styles/stylesheet1.css" media-type="text/css" />
    <item id="title_page_xhtml" href="text/title_page.xhtml" media-type="application/xhtml+xml" />
""";

  // <item id="ch001_xhtml" href="text/ch001.xhtml" media-type="application/xhtml+xml" />
  String opf2 = """</manifest>
  <spine toc="ncx" page-progression-direction="rtl">
  <itemref idref="title_page_xhtml" linear="yes" />
""";

  //<itemref idref="ch001_xhtml" />
  String opf3 = """</spine>
  <guide>
  <reference type="toc" title="TTILE" href="nav.xhtml" />
  </guide>
  </package>
""";

  /// nav.xhtml
  addNav() {
    String navHtml = nav1;
    for (EpubFileData f in fileList) {
      if (f.chapNo > 0) {
        navHtml += '<li id="toc-li-${f.chapNo}"><a href="${f.fileName}">${f.title}</a></li>\n';
      }
    }
    navHtml += nav2;
    EpubFileData d1 = EpubFileData();
    d1.text = navHtml;
    d1.fileName = 'nav.xhtml';
    fileList.add(d1);
  }

  String nav1 = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="ja-JP">
<head>
  <meta charset="utf-8" />
  <meta name="generator" content="pandoc" />
  <title>TITLE</title>
  <style>
  </style>
  <link rel="stylesheet" type="text/css" href="styles/stylesheet1.css" />
</head>
<body epub:type="frontmatter">
<nav epub:type="toc" id="toc"><h1 id="toc-title">TITLE</h1>
<ol class="toc">
""";

  String nav2 = """</ol></nav><nav epub:type="landmarks" id="landmarks" hidden="hidden">
<ol>
<li>
<a href="text/title_page.xhtml" epub:type="titlepage">Title Page</a>
</li>
</ol>
</nav></body></html>
""";

  String head1 = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" xml:lang="ja-JP">
<head>
  <meta charset="utf-8" />
  <style>
  </style>
  <link rel="stylesheet" type="text/css" href="../styles/stylesheet1.css" />
</head>
<body>
""";

  String head2 = '</body></html>';

  /// toc.ncx
  addTocncx() {
    String text = toc1;
    text += """<navPoint id="navPoint-0">
<navLabel>
  <text>TITLE</text>
</navLabel>
<content src="text/title_page.xhtml" />
</navPoint>
""";

    for (EpubFileData f in fileList) {
      if (f.fileName!.contains('text/ch')) {
        text += """
<navPoint id="navPoint-${f.chapNo}">
  <navLabel>
    <text></text>
  </navLabel>
  <content src="text/ch${f.chapNo000}.xhtml" />
</navPoint>""";
      }
    }
    text += """</navMap>
</ncx>""";

    fileList.add(EpubFileData(fileName: tocFile, text: text));
  }

  String tocFile = 'toc.ncx';
  String toc1 = """<?xml version="1.0" encoding="UTF-8"?>
  <ncx version="2005-1" xmlns="http://www.daisy.org/z3986/2005/ncx/">
  <head>
  <meta name="dtb:uid" content="urn:uuid:685a3766-bed6-40b7-9eb5-6095678465b7" />
  <meta name="dtb:depth" content="1" />
  <meta name="dtb:totalPageCount" content="0" />
  <meta name="dtb:maxPageNumber" content="0" />
  <meta name="cover" content="cover_jpg" />
  </head>
  <docTitle>
    <text>TITLE</text>
  </docTitle> 
  <navMap> 
""";
  String toc2 = '';

  Archive _createArchive() {
    var arch = Archive();
    arch.addFile(ArchiveFile.noCompress('mimetype', 20, convert.utf8.encode('application/epub+zip')));
    arch.addFile(ArchiveFile('META-INF/container.xml', containerFile.length, convert.utf8.encode(containerFile)));
    for (EpubFileData f in fileList) {
      List<int> content = convert.utf8.encode(f.text!);
      arch.addFile(ArchiveFile('EPUB/${f.fileName}', content.length, content));
    }
    return arch;
  }

  // Serializes the EpubBook into a byte array
  List<int>? writeBook() {
    var arch = _createArchive();
    return ZipEncoder().encode(arch);
  }

  static String deleteInvalidStrInJson(String str) {
    str = str.replaceAll('"', '');
    str = str.replaceAll('\\', '');
    str = str.replaceAll('/', '');
    str = str.replaceAll('\b', '');
    str = str.replaceAll('\f', '');
    str = str.replaceAll('\n', '');
    str = str.replaceAll('\r', '');
    str = str.replaceAll('\t', '');
    str = deleteRuby(str);
    return str;
  }

  static String deleteRuby(String str) {
    // <ruby><rb>獅子</rb><rp>（</rp><rt>しし</rt><rp>）</rp></ruby>
    // <ruby><rb>卍<rb><rp>（<rp><rt>まんじ<rt><rp>）<rp><ruby>
    str = str.replaceAll('<ruby>', '');
    str = str.replaceAll('</ruby>', '');
    str = str.replaceAll('<rb>', '');
    str = str.replaceAll('</rb>', '');
    str = str.replaceAll('<rp>', '');
    str = str.replaceAll('</rp>', '');
    str = str.replaceAll('<rt>', '');
    str = str.replaceAll('</rt>', '');
    return str;
  }
}
