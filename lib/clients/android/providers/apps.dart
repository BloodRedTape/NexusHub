import 'dart:io';

import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:nexus/providers/state.dart';

class AppsStateProvider extends StateProvider<List<AppInfo>> {
  @override
  void init() {
    super.init();

    if (Platform.isAndroid) {
      InstalledApps.getInstalledApps(false, true, true).then(onAppsReceived);
    } else {
      onAppsReceived([]);
    }
  }

  void onAppsReceived(List<AppInfo> apps) {
    setValue(apps);
  }
}
