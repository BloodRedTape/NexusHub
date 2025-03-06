import 'package:installed_apps/app_info.dart';
import 'package:nexus/clients/android/providers/alarm.dart';
import 'package:nexus/clients/android/providers/apps.dart';
import 'package:nexus/dashboard/settings.dart';
import 'package:nexus/providers/state.dart';
import 'package:nexus/states/alarm.dart';

class AndroidClient {
  AlarmStateProvider _alarmStateProvider = AlarmStateProvider();
  StateProvider<List<AppInfo>> _appsStateProvider = AppsStateProvider();

  StateProvider<List<AppInfo>> getAppsStateProvider() {
    return _appsStateProvider;
  }

  AndroidClient() {
    _alarmStateProvider.init();
    _appsStateProvider.init();
  }

  StateProvider<AlarmState> getAlarmProvider() {
    return _alarmStateProvider;
  }

  SettingsItem makeSettings() {
    return SettingsItem.fromPackage(name: 'Settings', package: 'com.android.settings');
  }
}
