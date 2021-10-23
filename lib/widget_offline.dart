import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:async' show Future;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:soblex_ios/main.dart';
// import 'package:firebase_performance/firebase_performance.dart';

class OfflinePage extends StatefulWidget {
  const OfflinePage({Key? key}) : super(key: key);

  @override
  State createState() => new _OfflinePage();
}

class _SearchEntry {
  final String html;
  final Uint8List? key;
  final Uint8List? extLink;

  _SearchEntry(this.html, this.key, this.extLink);

  @override
  String toString() {
    return "Key: ${this.key} - Link: ${this.extLink} - HTML: ${this.html}";
  }
}

enum _SearchStatus {
  NO_MATCH,
  SOME_MATCH,
  BEGIN_MATCH,
  FULL_MATCH,
}

class VLexemes {
  Uint8List? key;
  Uint8List? hsb;
  Uint8List? de;
  Uint8List? bsp;
  String? lemma;
}

class PLemmata {
  Uint8List? key;
  Uint8List? de;
  String? lemma;
  Uint8List? link;
}

class _OfflinePage extends State<OfflinePage> {
  var _controller = TextEditingController();

  String appVersion = "";

  // final Trace loadFilesTrace = FirebasePerformance.instance.newTrace("load_files_trace");

  Future<void> _loadData() async {
    if (vLexemes.isEmpty || pLemmeta.isEmpty) {
      int start = DateTime.now().millisecondsSinceEpoch;

      // loadFilesTrace.start();

      final ByteData pLemmataByteData =
          await rootBundle.load('assets/raw/plemmata.dat');
      final ByteData vLemmataByteData =
          await rootBundle.load('assets/raw/vlemmata.dat');
      final ByteData vLexemesByteData =
          await rootBundle.load('assets/raw/vlexemes.dat');

      final Uint8List pLemmataByteList = pLemmataByteData.buffer.asUint8List();
      final Uint8List vLemmataByteList = vLemmataByteData.buffer.asUint8List();
      final Uint8List vLexemesByteList = vLexemesByteData.buffer.asUint8List();

      pLemmeta.clear();
      int lastIndex = -1;
      do {
        int newLineIndex = pLemmataByteList.indexOf(0x0A, lastIndex + 1);
        if (newLineIndex == -1) newLineIndex = pLemmataByteList.length;
        if (newLineIndex > -1) {
          Uint8List lineBuffer =
              pLemmataByteList.sublist(lastIndex + 1, newLineIndex);

          PLemmata lineList = new PLemmata();

          int lastTabIndex = -1;
          int tabCounter = 0;
          do {
            int newTabIndex = lineBuffer.indexOf(0x09, lastTabIndex + 1);
            if (newTabIndex == -1) newTabIndex = lineBuffer.length;
            if (newTabIndex > -1 && tabCounter < 4) {
              Uint8List tabBuffer =
                  lineBuffer.sublist(lastTabIndex + 1, newTabIndex);

              if (tabCounter == 0)
                lineList.key = tabBuffer;
              else if (tabCounter == 1)
                lineList.de = tabBuffer;
              else if (tabCounter == 2)
                lineList.lemma = utf8.decode(tabBuffer);
              else if (tabCounter == 3) lineList.link = tabBuffer;

              tabCounter += 1;
            }
            lastTabIndex = newTabIndex;
          } while (lastTabIndex > -1 && lastTabIndex < lineBuffer.length);
          if (lineList.key != null &&
              lineList.de != null &&
              lineList.lemma != null) pLemmeta.add(lineList);
        }
        lastIndex = newLineIndex;
      } while (lastIndex > -1 && lastIndex < pLemmataByteList.length);

      List<String> vLemmataList = [];
      lastIndex = -1;
      do {
        int newLineIndex = vLemmataByteList.indexOf(0x0A, lastIndex + 1);
        if (newLineIndex == -1) newLineIndex = vLemmataByteList.length;
        if (newLineIndex > -1) {
          Uint8List lineBuffer =
              vLemmataByteList.sublist(lastIndex + 1, newLineIndex);
          String s = utf8.decode(lineBuffer);
          if (s.isNotEmpty) vLemmataList.add(s);
        }
        lastIndex = newLineIndex;
      } while (lastIndex > -1 && lastIndex < vLemmataByteList.length);
      vLemmataList.removeAt(0);

      vLexemes.clear();
      lastIndex = -1;
      do {
        int newLineIndex = vLexemesByteList.indexOf(0x0A, lastIndex + 1);
        if (newLineIndex == -1) newLineIndex = vLexemesByteList.length;
        if (newLineIndex > -1) {
          Uint8List lineBuffer =
              vLexemesByteList.sublist(lastIndex + 1, newLineIndex);

          VLexemes lineList = new VLexemes();

          int lastTabIndex = -1;
          int tabCounter = 0;
          do {
            int newTabIndex = lineBuffer.indexOf(0x09, lastTabIndex + 1);
            if (newTabIndex == -1) newTabIndex = lineBuffer.length;
            if (newTabIndex > -1 && tabCounter < 5) {
              Uint8List tabBuffer =
                  lineBuffer.sublist(lastTabIndex + 1, newTabIndex);

              if (tabCounter == 0)
                lineList.key = tabBuffer;
              else if (tabCounter == 1)
                lineList.hsb = tabBuffer;
              else if (tabCounter == 2)
                lineList.de = tabBuffer;
              else if (tabCounter == 3)
                lineList.bsp = tabBuffer;
              else if (tabCounter == 4) {
                int? index = int.tryParse(utf8.decode(tabBuffer));
                if (index != null &&
                    index >= 0 &&
                    index < vLemmataList.length) {
                  lineList.lemma = vLemmataList.elementAt(index);
                }
              }
              tabCounter += 1;
            }
            lastTabIndex = newTabIndex;
          } while (lastTabIndex > -1 && lastTabIndex < lineBuffer.length);
          if (lineList.key != null &&
              lineList.hsb != null &&
              lineList.de != null &&
              lineList.lemma != null) vLexemes.add(lineList);
        }
        lastIndex = newLineIndex;
      } while (lastIndex > -1 && lastIndex < vLexemesByteList.length);

      // loadFilesTrace.stop();

      int ende = DateTime.now().millisecondsSinceEpoch;
      print(
          "all files loaded - it took ${(ende - start).toString()} ms (VLexemes: ${vLexemes.length}; PLemmata: ${pLemmeta.length})");
    }
  }

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      appVersion = packageInfo.version;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<VLexemes> vLexemes = [];
  List<PLemmata> pLemmeta = [];

  @override
  Widget build(BuildContext context) {
    print("Offline page rebuild!");

    return ClipRRect(
        borderRadius: BorderRadius.all(
          const Radius.circular(20.0),
        ),
        child: FutureBuilder(
            future: _loadData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return ChangeNotifierProvider(
                  create: (context) => SearchModel(),
                  builder: (context, w) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          // margin: const EdgeInsets.only(bottom: 20.0),
                          decoration: BoxDecoration(
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                  color: Colors.black,
                                  blurRadius: 8.0,
                                  offset: Offset(0.0, 0.0))
                            ],
                            color: Colors.indigo,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.zero,
                              topRight: Radius.zero,
                              bottomLeft: Radius.circular(20.0),
                              bottomRight: Radius.circular(20.0),
                            ),
                          ),
                          child: Container(
                            // margin: EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 5),
                            decoration: BoxDecoration(
                              color: Colors.red.shade900,
                              // color: Colors.black38.withAlpha(20),
                              // color: Colors.black38.withAlpha(50),
                              borderRadius: BorderRadius.all(
                                Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                // Icon(
                                //   Icons.search,
                                //   color: Colors.black.withAlpha(120),
                                // ),
                                Expanded(
                                  child: TextField(
                                    key: const Key('inputText'),
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 20),
                                    decoration: InputDecoration(
                                      hintText: "Suche...",
                                      hintStyle: TextStyle(
                                        color: Colors.white.withAlpha(120),
                                      ),
                                      border: InputBorder.none,
                                      prefixIcon: const Icon(Icons.search,
                                          color: Colors.white),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.clear),
                                        color: Colors.white,
                                        onPressed: () {
                                          _controller.clear();
                                          Provider.of<SearchModel>(context,
                                                  listen: false)
                                              .clear();
                                        },
                                      ),
                                    ),
                                    controller: _controller,
                                    onChanged: (String value) {
                                      Provider.of<SearchModel>(context,
                                              listen: false)
                                          .search(value, vLexemes, pLemmeta);
                                    },
                                    enabled: true,
                                    autocorrect: false,
                                    autofocus: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Consumer<SearchModel>(
                              builder: (context, item, child) {
                            if (item.getCount == 0) {
                              return Center(
                                child: (_controller.text.isEmpty)
                                    ? Text("Suchbegriff eingeben!")
                                    : Text("Keine Einträge!"),
                              );
                            } else
                              return ListView.builder(
                                  itemCount: item.getCount,
                                  itemBuilder: (context, index) {
                                    return InkWell(
                                      splashColor: Colors.black26,
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: <Widget>[
                                            Padding(
                                                padding: EdgeInsets.all(4.0),
                                                child: Html(
                                                  data: item.getResults
                                                      .elementAt(index)
                                                      .html
                                                      .replaceAll(
                                                          "%%d", "<de></de>")
                                                      .replaceAll(
                                                          "%%h", "<hsb></hsb>"),
                                                  customRender: {
                                                    "hsb":
                                                        (RenderContext context,
                                                            Widget child) {
                                                      return Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      5.0),
                                                          child: Image(
                                                            image: AssetImage(
                                                                'assets/images/hsb.png'),
                                                            fit: BoxFit.contain,
                                                            height: 16,
                                                          ));
                                                    },
                                                    "de":
                                                        (RenderContext context,
                                                            Widget child) {
                                                      return Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      5.0),
                                                          child: Image(
                                                            image: AssetImage(
                                                                'assets/images/de.png'),
                                                            fit: BoxFit.contain,
                                                            height: 16,
                                                          ));
                                                    },
                                                  },
                                                  style: {
                                                    "*": Style(
                                                      fontSize: FontSize(16.0),
                                                    ),
                                                  },
                                                  tagsList: Html.tags
                                                    ..addAll(["hsb", "de"]),
                                                )),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 20.0),
                                              child: Container(
                                                height: 1,
                                                // width: 150.0,
                                                color: Colors.black38
                                                    .withAlpha(20),
                                                // margin: EdgeInsets.only(
                                                //     bottom: 8.0, top: 6.0),
                                              ),
                                            ),
                                          ]),
                                      onTap: () {
                                        _SearchEntry se =
                                            item.getResults.elementAt(index);
                                        print(se.toString());

                                        if (se.key != null &&
                                            se.key!.isNotEmpty) {
                                          String key = utf8.decode(se.key!);

                                          String? extLink;
                                          if (se.extLink != null)
                                            extLink = utf8.decode(se.extLink!);

                                          print(extLink);
                                          if (extLink != null &&
                                              extLink.isNotEmpty &&
                                              extLink.contains(
                                                  RegExp(r'\(.*\)'))) {
                                            // is not empty -> https://hornjoserbsce.de/dow/artikel/${LemmaKey}
                                            int startPos = extLink.indexOf('(');
                                            if (startPos > -1) {
                                              int endPos = extLink.indexOf(
                                                  ')', startPos);
                                              if (endPos > startPos) {
                                                String lemmaKey =
                                                    extLink.substring(
                                                        startPos + 1, endPos);
                                                lemmaKey = Uri.encodeComponent(
                                                    lemmaKey);
                                                String url =
                                                    "https://hornjoserbsce.de/dow/artikel/$lemmaKey";
                                                Provider.of<MyModel>(context,
                                                        listen: false)
                                                    .setURL(url, context);
                                              }
                                            }
                                          } else {
                                            //is empty -> https://soblex.de/index_ios2.php/?cmd=addinfo_show&appversion=1&p_slkey=%5B${LemmaKey}%5D !!VERSION!!
                                            // v1.abdomen1-m1 -> Lemma Key: v1.abdomen1
                                            String lemmaKey =
                                                key.split('-').first;
                                            lemmaKey =
                                                Uri.encodeComponent(lemmaKey);
                                            String url = (Platform.isIOS)
                                                ? "https://soblex.de/index_ios2.php/?cmd=addinfo_show&appversion=$appVersion&p_slkey=%5B$lemmaKey%5D"
                                                : "https://soblex.de/index_android2.php/?cmd=addinfo_show&appversion=$appVersion&p_slkey=%5B$lemmaKey%5D";
                                            Provider.of<MyModel>(context,
                                                    listen: false)
                                                .setURL(url, context);
                                          }
                                        }
                                      },
                                    );
                                  });
                          }),
                        )
                      ],
                    );
                  },
                );
              } else {
                return Center(
                    child: SizedBox(
                        child: Text("Loading"), width: 60, height: 60));
              }
            }));
  }
}

class _Commons {
  static final Map<String, String> _noDiacritics = {
    "à": "a",
    "ć": "c",
    "č": "c",
    "é": "e",
    "ź": "z",
    "ž": "z",
    "ł": "l",
    "ń": "n",
    "ě": "e",
    "é": "e",
    "ó": "o",
    "š": "s",
    "ś": "s",
    "ř": "r",
    "ŕ": "r"
  };

  static final Map<String, String> _noUmlaut = {
    "ö": "oe",
    "ü": "ue",
    "ä": "ae",
    "ß": "ss"
  };

  static String _replaceAll(String query, Map<String, String> map) {
    for (var c in map.keys) {
      query = query.replaceAll(c, map[c] ?? "");
    }
    return query;
  }

  static String toNoDiacriticsAndNoUmlautsAndLowerCase(String query) {
    query = query.toLowerCase();
    query = _replaceAll(query, _noUmlaut);
    query = _replaceAll(query, _noDiacritics);
    return query;
  }
}

class SearchModel extends ChangeNotifier {
  List<_SearchEntry> _litems = [];

  List<_SearchEntry> _sorbischFullMatch = [];
  List<_SearchEntry> _sorbischPartMatch = [];
  List<_SearchEntry> _sorbischBeginMatch = [];

  List<_SearchEntry> _deutschFullMatch = [];
  List<_SearchEntry> _deutschPartMatch = [];
  List<_SearchEntry> _deutschBeginMatch = [];

  List<_SearchEntry> _exampleMatch = [];

  // final Trace searchTrace = FirebasePerformance.instance.newTrace("search_trace");

  void _addResultItem(List<_SearchEntry> list, String? html, Uint8List? key,
      Uint8List? extLink) {
    if (html != null) list.add(new _SearchEntry(html, key, extLink));
  }

  int seachQueryInByteList(Uint8List? target, Uint8List query) {
    if (target == null || query.isEmpty) return -1;

    int indexFound = -1;

    int i = -1;
    do {
      i = target.indexOf(query.first, i + 1);
      if (i > -1) {
        int found = 0;
        for (var j = 0; j < query.length; j++) {
          if (i + j < target.length && target[i + j] == query[j]) {
            found++;
          }
        }
        if (found == query.length) indexFound = i;
      }
    } while (i > -1 && indexFound == -1);

    return indexFound;
  }

  _SearchStatus _evalMatchType(
      int queryTargetFoundIndex, int lengthQuery, Uint8List? queryTarget) {
    if (queryTarget == null) return _SearchStatus.NO_MATCH;

    int valueLength = queryTarget.length;
    if (queryTargetFoundIndex == 0) {
      if (lengthQuery == valueLength)
        return _SearchStatus.FULL_MATCH;
      else if (queryTarget[queryTargetFoundIndex + lengthQuery] == 0x2C)
        return _SearchStatus.FULL_MATCH;
      else
        return _SearchStatus.BEGIN_MATCH;
    } else if (queryTargetFoundIndex > 0) {
      if (queryTarget[queryTargetFoundIndex - 1] == 0x20 &&
          (queryTargetFoundIndex + lengthQuery == valueLength ||
              (queryTarget[queryTargetFoundIndex + lengthQuery] == 0x2C)))
        return _SearchStatus.FULL_MATCH;
      else
        return _SearchStatus.SOME_MATCH;
    } else
      return _SearchStatus.NO_MATCH;
  }

  void search(
      String queryString, List<VLexemes> vLexemes, List<PLemmata> pLemmata) {
    if (queryString.isEmpty) {
      clear();
    } else {
      int start = DateTime.now().millisecondsSinceEpoch;

      // searchTrace.start();

      queryString =
          _Commons.toNoDiacriticsAndNoUmlautsAndLowerCase(queryString);
      Uint8List query = Uint8List.fromList(utf8.encode(queryString));

      _litems.clear();
      _sorbischFullMatch.clear();
      _sorbischPartMatch.clear();
      _sorbischBeginMatch.clear();
      _deutschFullMatch.clear();
      _deutschPartMatch.clear();
      _deutschBeginMatch.clear();
      _exampleMatch.clear();

      for (var i = 0; i < pLemmata.length; i++) {
        PLemmata pl = pLemmata.elementAt(i);
        int di = seachQueryInByteList(pl.de, query);
        _SearchStatus matchType = _evalMatchType(di, query.length, pl.de);
        switch (matchType) {
          case _SearchStatus.FULL_MATCH:
            _addResultItem(_deutschFullMatch, pl.lemma, pl.key, pl.link);
            break;
          case _SearchStatus.BEGIN_MATCH:
            _addResultItem(_deutschBeginMatch, pl.lemma, pl.key, pl.link);
            break;
          case _SearchStatus.SOME_MATCH:
            _addResultItem(_deutschPartMatch, pl.lemma, pl.key, pl.link);
            break;
          default:
            break;
        }
      }

      String lastLemma = "";
      bool treffer = false;

      for (var i = 0; i < vLexemes.length; i++) {
        VLexemes vi = vLexemes.elementAt(i);
        String? currentLemma = vi.lemma;

        if (currentLemma == null || (treffer && currentLemma == lastLemma))
          continue;
        else {
          treffer = false;
          lastLemma = currentLemma;
        }

        int wi = seachQueryInByteList(vi.hsb, query);
        int di = seachQueryInByteList(vi.de, query);
        int examplei = seachQueryInByteList(vi.bsp, query);

        if (wi == 0 && vi.hsb!.length == query.length) {
          treffer = true;
          _addResultItem(_sorbischFullMatch, currentLemma, vi.key, null);
        } else if (wi == 0) {
          treffer = true;
          _addResultItem(_sorbischBeginMatch, currentLemma, vi.key, null);
        } else if (wi > 0) {
          treffer = true;
          _addResultItem(_sorbischPartMatch, currentLemma, vi.key, null);
        } else if (di >= 0) {
          _SearchStatus matchType = _evalMatchType(di, query.length, vi.de);
          switch (matchType) {
            case _SearchStatus.FULL_MATCH:
              treffer = true;
              _addResultItem(_deutschFullMatch, currentLemma, vi.key, null);
              break;
            case _SearchStatus.BEGIN_MATCH:
              treffer = true;
              _addResultItem(_deutschBeginMatch, currentLemma, vi.key, null);
              break;
            case _SearchStatus.SOME_MATCH:
              treffer = true;
              _addResultItem(_deutschPartMatch, currentLemma, vi.key, null);
              break;
            default:
              break;
          }
        } else if (examplei > -1) {
          treffer = true;
          _addResultItem(_exampleMatch, currentLemma, vi.key, null);
        }
      }

      _litems.addAll(_sorbischFullMatch);
      _litems.addAll(_deutschFullMatch);
      _litems.addAll(_sorbischBeginMatch);
      _litems.addAll(_deutschBeginMatch);
      _litems.addAll(_sorbischPartMatch);
      _litems.addAll(_deutschPartMatch);
      _litems.addAll(_exampleMatch);

      // searchTrace.stop();

      int ende = DateTime.now().millisecondsSinceEpoch;
      print("searching took ${(ende - start).toString()} ms");

      notifyListeners();
    }
  }

  void clear() {
    _litems.clear();
    notifyListeners();
  }

  List<_SearchEntry> get getResults => _litems;

  int get getCount => _litems.length;
}
