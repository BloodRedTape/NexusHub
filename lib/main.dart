import 'package:flutter/material.dart';
import 'package:nexus/cards/calendar.dart';
import 'package:nexus/consts.dart';
import 'package:nexus/dashboard/home.dart';
import 'package:nexus/dashboard/morning.dart';
import 'dashboard/dashboard.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const Dashboard(
        items: [
          TabItem(tab: Tab(text: 'Your morning'), child: MorningTab()),
          TabItem(
            tab: Tab(text: 'Home control'),
            child: HomeTab(),
          ),
          TabItem(
            tab: Tab(text: 'Media'),
            child: Center(child: Text('Media content')),
          ),
          TabItem(
            tab: Tab(text: 'Communicate'),
            child: Center(child: Text('Communicate content')),
          ),
          TabItem(
            tab: Tab(text: 'Discover'),
            child: Center(child: Text('Discover content')),
          ),
        ],
      ),
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        cardTheme: CardTheme(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(cardBorderRadius))),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        cardTheme: CardTheme(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(cardBorderRadius))),
      ),
      themeMode: ThemeMode.dark,
    );
  }
}
