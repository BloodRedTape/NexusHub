import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:nexus/cards/details.dart';
import 'package:nexus/clients/apps/client.dart';
import 'package:nexus/clients/open_meteo/client.dart';
import 'package:nexus/consts.dart';
import 'package:nexus/dashboard/apps.dart';
import 'package:nexus/dashboard/home.dart';
import 'package:nexus/dashboard/morning.dart';
import 'package:nexus/dashboard/settings.dart';
import 'package:nexus/utils/generic_icon.dart';
import 'dashboard/dashboard.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final OpenMeteoWeatherClient _weatherClient = OpenMeteoWeatherClient();
  final AppsClient _appsClient = AppsClient();

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
      home: Dashboard(
        items: [
          TabItem(
            tab: Tab(text: 'Your morning'),
            child: MorningTab(weatherClient: _weatherClient),
          ),
          const TabItem(
            tab: Tab(text: 'Home control'),
            child: HomeTab(),
          ),
          TabItem(
            tab: Tab(text: 'Apps'),
            child: AppsTab(stateProvider: _appsClient.getStateProvider()),
          ),
          TabItem(
            tab: const Tab(text: 'Settings'),
            child: SettingsTab(items: [
              SettingsItem.fromPackage(
                  name: 'Settings', package: 'com.android.settings'),
              _weatherClient.makeSettings()
            ]),
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
