import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:nexus/cards/details.dart';
import 'package:nexus/clients/android/api.dart';
import 'package:nexus/clients/android/config.dart';
import 'package:nexus/clients/android/providers/alarm.dart';
import 'package:nexus/clients/android/providers/apps.dart';
import 'package:nexus/clients/android/settings.dart';
import 'package:nexus/clients/ha/client.dart';
import 'package:nexus/dashboard/settings.dart';
import 'package:nexus/providers/shared_preferences_state.dart';
import 'package:nexus/providers/state.dart';
import 'package:nexus/states/alarm.dart';
import 'package:nexus/utils/generic_icon.dart';

class AndroidClient {
  final HomeAssistantClient _homeAssistantClient;
  late StateProvider<AndroidConfig> _configStateProvider;
  AlarmStateProvider _alarmStateProvider = AlarmStateProvider();
  StateProvider<List<AppInfo>> _appsStateProvider = AppsStateProvider();

  StateProvider<List<AppInfo>> getAppsStateProvider() {
    return _appsStateProvider;
  }

  AndroidClient({required HomeAssistantClient homeAssistantClient})
      : _homeAssistantClient = homeAssistantClient {
    _configStateProvider = SharedPreferencesStateProvider(
      initialValue: AndroidConfig(),
      preferencesKey: 'ANDROID_CONFIG',
      serialize: AndroidConfig.serialize,
      deserialize: AndroidConfig.deserialize,
    );

    _configStateProvider.init();
    _alarmStateProvider.init();
    _appsStateProvider.init();

    _initAutoBrightness();
  }

  void _initAutoBrightness() {
    // Get illuminance sensor provider
    final illuminanceProvider = _homeAssistantClient.sensorStateProvider('sensor.illuminance_mi_bedroom');

    // Subscribe to config changes
    _configStateProvider.bindValueChanged((AndroidConfig? config) {
      if (config == null || !config.autoBrightnessEnabled) return;

      // Re-subscribe to illuminance with new threshold
      _updateBrightness(illuminanceProvider.getValue(), config);
    });

    // Subscribe to illuminance changes
    illuminanceProvider.bindValueChanged((double? lux) {
      final config = _configStateProvider.getValue();
      if (config == null || !config.autoBrightnessEnabled) return;

      _updateBrightness(lux, config);
    });
  }

  void _updateBrightness(double? lux, AndroidConfig config) {
    if (lux == null) return;

    // Set brightness based on lux value and threshold
    // > threshold = 100% brightness
    // <= threshold = 0% brightness (minimum)
    double brightness = lux > config.brightnessThreshold ? 1.0 : 0.0;
    AndroidClientApi.setBrightness(brightness);
  }

  StateProvider<AlarmState> getAlarmProvider() {
    return _alarmStateProvider;
  }

  SettingsItem makeSystemSettings() {
    return SettingsItem.fromPackage(name: 'System Settings', package: 'com.android.settings');
  }

  SettingsItem makeSettings() {
    return SettingsItem.details(
      icon: GenericIcon.fromIcon(
        icon: Icons.android,
      ),
      name: 'Android',
      details: DetailsPage(
        title: Text('Android Settings'),
        body: Column(
          children: [
            AndroidConfigWidget(stateProvider: _configStateProvider),
          ],
        ),
      ),
    );
  }
}
