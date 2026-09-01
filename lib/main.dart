import 'package:flutter/material.dart';
import 'package:nexus/clients/android/client.dart';
import 'package:nexus/clients/ha/client.dart';
import 'package:nexus/clients/open_meteo/client.dart';
import 'package:nexus/consts.dart';
import 'package:nexus/dashboard/apps.dart';
import 'package:nexus/dashboard/bedroom.dart';
import 'package:nexus/dashboard/master.dart';
import 'package:nexus/dashboard/morning.dart';
import 'package:nexus/dashboard/settings.dart';
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
  final HomeAssistantClient _homeAssistantClient = HomeAssistantClient();
  late final AndroidClient _androidClient;

  @override
  void initState() {
    super.initState();

    _androidClient = AndroidClient(homeAssistantClient: _homeAssistantClient);

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
            child: MorningTab(
              weatherClient: _weatherClient,
              homeAssistantClient: _homeAssistantClient,
              androidClient: _androidClient,
            ),
          ),
          TabItem(
            tab: Tab(text: 'Master Room'),
            child: MasterTab(
              homeAssistantClient: _homeAssistantClient,
            ),
          ),
          TabItem(
            tab: Tab(text: 'Bedroom'),
            child: BedroomTab(
              homeAssistantClient: _homeAssistantClient,
            ),
          ),
          TabItem(
            tab: Tab(text: 'Apps'),
            child: AppsTab(stateProvider: _androidClient.getAppsStateProvider()),
          ),
          TabItem(
            tab: const Tab(text: 'Settings'),
            child: SettingsTab(items: [
              _androidClient.makeSystemSettings(),
              _androidClient.makeSettings(),
              _weatherClient.makeSettings(),
              _homeAssistantClient.makeSettings(),
            ]),
          ),
        ],
      ),
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        cardTheme: CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardBorderRadius))),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        cardTheme: CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardBorderRadius))),
      ),
      themeMode: ThemeMode.dark,
    );
  }
}
