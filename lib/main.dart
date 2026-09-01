import 'package:flutter/material.dart';
import 'package:nexus/clients/android/client.dart';
import 'package:nexus/clients/ha/client.dart';
import 'package:nexus/clients/open_meteo/client.dart';
import 'package:nexus/consts.dart';
import 'package:nexus/dashboard/apps.dart';
import 'package:nexus/dashboard/area.dart';
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
            tab: Tab(text: 'Glance'),
            child: PaddedTab(
              child: MorningTab(
                weatherClient: _weatherClient,
                homeAssistantClient: _homeAssistantClient,
                androidClient: _androidClient,
              ),
            ),
          ),
          TabItem(
            tab: Tab(text: 'Home'),
            child: AreaTabs(
              stateProvider: _homeAssistantClient.areas,
              builder: (area) => AreaTab(homeAssistantClient: _homeAssistantClient, area: area),
            ),
          ),
          TabItem(
            tab: Tab(text: 'Apps'),
            child: PaddedTab(child: AppsTab(stateProvider: _androidClient.getAppsStateProvider())),
          ),
          TabItem(
            tab: const Tab(text: 'Settings'),
            child: PaddedTab(
              child: SettingsTab(items: [
                _androidClient.makeSystemSettings(),
                _androidClient.makeSettings(),
                _weatherClient.makeSettings(),
                _homeAssistantClient.makeSettings(),
              ]),
            ),
          ),
        ],
      ),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        cardTheme: CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardBorderRadius))),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
        cardTheme: CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardBorderRadius))),
      ),
      themeMode: ThemeMode.dark,
    );
  }
}
