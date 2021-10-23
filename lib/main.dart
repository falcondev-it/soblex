import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soblex_ios/widget_online.dart';
import 'package:soblex_ios/widget_info.dart';
import 'package:soblex_ios/widget_offline.dart';
import 'package:provider/provider.dart';
import 'package:connectivity/connectivity.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_performance/firebase_performance.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  final ThemeData lightTheme = ThemeData();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Soblex',
        theme: lightTheme.copyWith(
            colorScheme: lightTheme.colorScheme.copyWith(
                primary: Colors.indigo,
                secondary: Color(0xFFFF4081),
                brightness: Brightness.light),
            scaffoldBackgroundColor: Colors.indigo),
        themeMode: ThemeMode.light,
        home: ChangeNotifierProvider(
          create: (context) => MyModel(),
          child: MyHomePage(title: 'Soblex Wörterbuch'),
        ));
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static List<Widget> _pages = <Widget>[
    OfflinePage(),
    OnlinePage(),
    InfoPage()
  ];

  @override
  Widget build(BuildContext context) {
    print("Main page rebuild!");
    context.read<MyModel>().addListener(() {
      setState(() {
        FocusScope.of(context).unfocus();
        _selectedIndex = 1;
      });
    });

    return OrientationBuilder(builder: (context, orientation) {
      return Scaffold(
          appBar: (orientation == Orientation.landscape)
              ? null
              : AppBar(
                  // title: Text(widget.title),
                  title: Image(
                    image: AssetImage('assets/images/icon.png'),
                    fit: BoxFit.contain,
                    height: 48,
                  ),
                  elevation: 0,
                  centerTitle: true,
                  actions: (_selectedIndex == 1)
                      ? [
                          IconButton(
                            onPressed: () {
                              Provider.of<MyModel>(context, listen: false)
                                  .setURL(
                                      context.read<MyModel>().getURL, context);
                            },
                            icon: Icon(Icons.refresh),
                            tooltip: "Webseite neu laden",
                          )
                        ]
                      : [],
                ),
          bottomNavigationBar: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.indigo,
            selectedItemColor: Colors.white,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                  icon: Icon(Icons.explore_off), label: "Offline"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.explore), label: "Online"),
              BottomNavigationBarItem(icon: Icon(Icons.info), label: "Info"),
            ],
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          body: Container(
            color: Colors.indigo,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.only(
                    bottom: 14.0, left: 5, right: 5, top: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                        color: Colors.black54,
                        blurRadius: 8.0,
                        offset: Offset(0.0, 0.75),
                        spreadRadius: 0)
                  ],
                  borderRadius: BorderRadius.all(
                    const Radius.circular(20.0),
                  ),
                ),
                // color: Theme.of(context).scaffoldBackgroundColor,
                child: Material(
                  color: Colors.transparent,
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _pages,
                  ),
                ),
              ),
            ),
          ));
    });
  }
}

class MyModel extends ChangeNotifier {
  /// Internal, private state of the cart.
  String _url = "";

  void setURL(String url, BuildContext context) async {
    this._url = url;
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      try {
        final result = await InternetAddress.lookup('soblex.de');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          notifyListeners();
          print('connected');
        }
      } on SocketException catch (_) {
        print('not connected');
      }
    } else {
      Fluttertoast.showToast(
          msg: "Details nur mit Internetverbindung einsehbar.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.indigo.shade800,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  String get getURL => _url;
}
