import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soblex_ios/widget_dialogs.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:soblex_ios/main.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OnlinePage extends StatefulWidget {
  const OnlinePage({Key? key}) : super(key: key);

  @override
  _OnlinePage createState() => _OnlinePage();
}

class _OnlinePage extends State<OnlinePage> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid)
      WebView.platform = SurfaceAndroidWebView(); // Enable hybrid composition.
  }

  final GlobalKey<State> _keyLoader = new GlobalKey<State>();

  @override
  Widget build(BuildContext context) {
    print("Online page rebuild!");

    context.read<MyModel>().addListener(() {
      String url = context.read<MyModel>().getURL;
      print("url received: $url");
      if (_controller != null) _controller!.loadUrl(url);
    });

    bool _initialLoad = true;

    RegExp regExp = new RegExp(
        r'https?:\/\/(www)?(soblex|hornjoserbsce|obersorbisch)\.de\b([-a-zA-Z0-9()@:%_\+.~#?&\/\/=]*)',
        caseSensitive: false);

    return ClipRRect(
        borderRadius: BorderRadius.all(
          const Radius.circular(20.0),
        ),
        child: Builder(builder: (context) {
          return WebView(
            initialUrl: (Platform.isIOS)
                ? "https://soblex.de/index_ios2.php"
                : "https://soblex.de/index_android2.php",
            javascriptMode: JavascriptMode.unrestricted,
            gestureNavigationEnabled: true,
            onWebViewCreated: (WebViewController webViewController) {
              _controller = webViewController;
            },
            navigationDelegate: (navRequest) {
              if (regExp.hasMatch(navRequest.url)) {
                return NavigationDecision.navigate;
              } else {
                _launchURL(navRequest.url);
                return NavigationDecision.prevent;
              }
            },
            onPageStarted: (s) {
              if (!_initialLoad) Dialogs.showLoadingDialog(context, _keyLoader);
            },
            onPageFinished: (s) {
              if (_keyLoader.currentContext != null) {
                Navigator.of(_keyLoader.currentContext ?? context,
                        rootNavigator: true)
                    .pop();
              }
              _initialLoad = false;
            },
          );
        }));
  }

  void _launchURL(String _url) async => await canLaunch(_url)
      ? await launch(_url)
      : throw 'Could not launch $_url';
}
