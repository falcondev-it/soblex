import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({Key? key}) : super(key: key);

  @override
  _InfoPage createState() => _InfoPage();
}

class _InfoPage extends State<InfoPage> {
  late WebViewController _controller;
  bool _loaded = false;

  Future<String> loadHtmlData() async {
    return await rootBundle.loadString("assets/html/impressum.html");
  }

  @override
  Widget build(BuildContext context) {
    print("Info page rebuild!");

    return ClipRRect(
        borderRadius: BorderRadius.all(
          const Radius.circular(20.0),
        ),
        child: Container(child: Builder(builder: (context) {
          return WebView(
            initialUrl: "about:blank",
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) {
              _controller = webViewController;
              if (!_loaded)
                loadHtmlData().then((value) {
                  debugPrint("html data loaded");
                  _loaded = true;
                  webViewController.loadUrl(Uri.dataFromString(value,
                          mimeType: 'text/html',
                          parameters: {"identifier": "test1234"},
                          encoding: Encoding.getByName('utf-8'))
                      .toString());
                });
            },
            navigationDelegate: (navRequest) {
              if (navRequest.url.contains("test1234") ||
                  navRequest.url == "about:blank") {
                return NavigationDecision.navigate;
              } else {
                _launchURL(navRequest.url);
                return NavigationDecision.prevent;
              }
            },
          );
        })));
  }

  void _launchURL(String _url) async => await canLaunch(_url)
      ? await launch(_url)
      : throw 'Could not launch $_url';
}
