import 'package:flutter/material.dart';
import 'package:nexus/clients/android/client.dart';
import 'package:nexus/clients/core/client.dart';
import 'package:nexus/clients/ha/client.dart';
import 'package:nexus/clients/open_meteo/client.dart';
import 'package:provider/provider.dart';
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
  late final CoreClient _coreClient;
  late final OpenMeteoWeatherClient _weatherClient;
  late final HomeAssistantClient _homeAssistantClient;
  late final AndroidClient _androidClient;

  @override
  void initState() {
    super.initState();

    // First: it catches whatever the other clients log on their way up.
    _coreClient = CoreClient();
    _weatherClient = OpenMeteoWeatherClient();
    _homeAssistantClient = HomeAssistantClient();
    _androidClient = AndroidClient(homeAssistantClient: _homeAssistantClient);

    // an area is only worth a tab if some device in it gets a card
    _homeAssistantClient.isDeviceShowable = (device) => matchCard(device) != null;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _androidClient.dispose();
    _homeAssistantClient.dispose();
    _weatherClient.dispose();
    _coreClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The clients outlive every page, so they are provided above the app
    // itself rather than handed down through each tab.
    return MultiProvider(
      providers: [
        Provider<CoreClient>.value(value: _coreClient),
        Provider<OpenMeteoWeatherClient>.value(value: _weatherClient),
        Provider<HomeAssistantClient>.value(value: _homeAssistantClient),
        Provider<AndroidClient>.value(value: _androidClient),
      ],
      child: MaterialApp(
        home: Dashboard(
          items: [
            TabItem(
              tab: Tab(text: 'Glance'),
              child: PaddedTab(
                child: MorningTab(),
              ),
            ),
            TabItem(
              tab: Tab(text: 'Home'),
              child: AreaTabs(
                stateProvider: _homeAssistantClient.areas,
                builder: (area) => AreaTab(area: area),
              ),
            ),
            TabItem(
              tab: Tab(text: 'Apps'),
              child: PaddedTab(child: AppsTab(stateProvider: _androidClient.apps.getStateProvider())),
            ),
            TabItem(
              tab: const Tab(text: 'Settings'),
              child: PaddedTab(
                child: SettingsTab(items: [
                  _androidClient.makeSystemSettings(),
                  _androidClient.makeSettings(),
                  _weatherClient.makeSettings(),
                  _homeAssistantClient.makeSettings(),
                  _coreClient.makeSettings(),
                ]),
              ),
            ),
          ],
        ),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          cardTheme:
              CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardBorderRadius))),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
          useMaterial3: true,
          cardTheme:
              CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardBorderRadius))),
        ),
        themeMode: ThemeMode.dark,
      ),
    );
  }
}
