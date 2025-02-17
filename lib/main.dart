import 'package:flutter/material.dart';
import 'package:nexus/tabs/morning.dart';
import 'core/dashboard.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const Dashboard(
        items: [
          TabItem(tab: Tab(text: 'Your morning'), child: MorningTab()),
          TabItem(
            tab: Tab(text: 'Home control'),
            child: Center(child: Text('Home control content')),
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
                borderRadius: BorderRadius.circular(30))),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        cardTheme: CardTheme(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30))),
      ),
      themeMode: ThemeMode.dark,
    );
  }
}
