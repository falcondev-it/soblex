import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soblex_ios/widget_dialogs.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:soblex_ios/main.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class OnlinePage extends StatefulWidget {
  const OnlinePage({Key? key}) : super(key: key);

  @override
  _OnlinePage createState() => _OnlinePage();
}

class _OnlinePage extends State<OnlinePage> {
  final GlobalKey<State> _keyLoader = new GlobalKey<State>();
  bool _initialLoad = true;

  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setNavigationDelegate(NavigationDelegate(
      onNavigationRequest: (navRequest) {
        if (_soblexUrl.hasMatch(navRequest.url)) {
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
          Navigator.of(_keyLoader.currentContext ?? context, rootNavigator: true)
              .pop();
        }
        _initialLoad = false;
      },
    ))
    ..loadRequest(Uri.parse((Platform.isIOS)
        ? "https://soblex.de/index_ios2.php"
        : "https://soblex.de/index_android2.php"));

  static final RegExp _soblexUrl = new RegExp(
      r'https?:\/\/(www)?(soblex|hornjoserbsce|obersorbisch)\.de\b([-a-zA-Z0-9()@:%_\+.~#?&\/\/=]*)',
      caseSensitive: false);

  @override
  void initState() {
    super.initState();
    if (_controller.platform is WebKitWebViewController)
      (_controller.platform as WebKitWebViewController)
          .setAllowsBackForwardNavigationGestures(true);
    context.read<MyModel>().addListener(() {
      String url = context.read<MyModel>().getURL;
      print("url received: $url");
      _controller.loadRequest(Uri.parse(url));
    });
  }

  @override
  Widget build(BuildContext context) {
    print("Online page rebuild!");

    return ClipRRect(
        borderRadius: BorderRadius.all(
          const Radius.circular(20.0),
        ),
        child: WebViewWidget(controller: _controller));
  }

  void _launchURL(String _url) async => await canLaunch(_url)
      ? await launch(_url)
      : throw 'Could not launch $_url';
}
