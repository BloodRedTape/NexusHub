import 'dart:async';

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
import 'package:nexus/utils/settings_section.dart';

class AndroidClient {
  final HomeAssistantClient _homeAssistantClient;
  late StateProvider<AndroidConfig> _configStateProvider;
  AlarmStateProvider _alarmStateProvider = AlarmStateProvider();
  StateProvider<List<AppInfo>> _appsStateProvider = AppsStateProvider();
  Timer? _screenOnTimer;
  ScreenOnDecision? _screenOnState;
  ScreenOnInterval? _dismissedInterval;
  final Map<String, StateProvider<bool>> _screenOnSensorProviders = {};

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
    _initScreenOnSchedule();
  }

  void _initScreenOnSchedule() {
    _configStateProvider.bindValueChanged((AndroidConfig? config) {
      _bindScreenOnSensors(config?.screenOnSensors ?? const []);
      _applyScreenOnSchedule();
    });
    _screenOnTimer = Timer.periodic(Duration(minutes: 1), (_) => _applyScreenOnSchedule());
    AndroidClientApi.onScreenOff(_onScreenOff);
    _bindScreenOnSensors(_configStateProvider.getValue()?.screenOnSensors ?? const []);
    _applyScreenOnSchedule();
  }

  /// The screen went dark. Inside a keep-on interval that means the user
  /// dismissed it, so it stays inert until it ends.
  void _onScreenOff() {
    _screenOnState = null;
    _dismissedInterval = _configStateProvider.getValue()?.activeKeepOnInterval(DateTime.now());
  }

  void _onScreenOnSensorChanged(bool? _) => _applyScreenOnSchedule();

  void _bindScreenOnSensors(List<String> entityIds) {
    for (final entityId in _screenOnSensorProviders.keys.toList()) {
      if (entityIds.contains(entityId)) continue;

      _screenOnSensorProviders.remove(entityId)?.unbind(_onScreenOnSensorChanged);
    }

    for (final entityId in entityIds) {
      if (entityId.isEmpty || _screenOnSensorProviders.containsKey(entityId)) continue;

      _screenOnSensorProviders[entityId] = _homeAssistantClient.switchStateProvider(entityId)
        ..bindValueChanged(_onScreenOnSensorChanged);
    }
  }

  void _applyScreenOnSchedule() {
    final config = _configStateProvider.getValue();

    if (config == null) return;

    final now = DateTime.now();

    // A dismissal only lasts as long as the interval it dismissed.
    if (_dismissedInterval != null && !_dismissedInterval!.contains(now)) _dismissedInterval = null;

    final decision = config.screenOnDecision(
      now,
      _screenOnSensorProviders.map((id, provider) => MapEntry(id, provider.getValue())),
      dismissedInterval: _dismissedInterval,
    );

    if (decision == _screenOnState) return;

    _screenOnState = decision;

    // Blocked and idle both mean "stop holding it"; only blocked also forbids
    // waking, which we simply never do outside keepOn.
    AndroidClientApi.setKeepScreenOn(decision == ScreenOnDecision.keepOn);

    if (decision == ScreenOnDecision.keepOn) AndroidClientApi.wakeScreen();
  }

  void dispose() {
    _screenOnTimer?.cancel();
    for (final provider in _screenOnSensorProviders.values) {
      provider.unbind(_onScreenOnSensorChanged);
    }
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

  final GlobalKey<State> _settingsKey = GlobalKey<State>();

  SettingsItem makeSettings() {
    return SettingsItem.details(
      icon: GenericIcon.fromIcon(
        icon: Icons.android,
      ),
      name: 'Android',
      details: DetailsPage(
        title: Text('Android Settings'),
        actions: [SettingsSaveButton(_settingsKey)],
        body: AndroidConfigWidget(
          key: _settingsKey,
          stateProvider: _configStateProvider,
          binarySensors: () => {
            for (final entry in _homeAssistantClient.binarySensors()) entry.entityId: entry.displayName,
          },
          entityState: _homeAssistantClient.entityStateProvider,
        ),
      ),
    );
  }
}
