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
  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setNavigationDelegate(NavigationDelegate(
      onNavigationRequest: (navRequest) {
        if (navRequest.url == "about:blank") {
          return NavigationDecision.navigate;
        } else {
          _launchURL(navRequest.url);
          return NavigationDecision.prevent;
        }
      },
    ));

  @override
  void initState() {
    super.initState();
    rootBundle
        .loadString("assets/html/impressum.html")
        .then((html) => _controller.loadHtmlString(html));
  }

  @override
  Widget build(BuildContext context) {
    print("Info page rebuild!");

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
