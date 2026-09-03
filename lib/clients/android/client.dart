import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:nexus/clients/android/api.dart';
import 'package:nexus/clients/android/config.dart';
import 'package:nexus/clients/android/models.dart';
import 'package:nexus/clients/android/settings.dart';
import 'package:nexus/clients/core/log.dart';
import 'package:nexus/clients/ha/client.dart';
import 'package:nexus/dashboard/settings.dart';
import 'package:nexus/clients/state.dart';
import 'package:nexus/clients/config_storage.dart';
import 'package:nexus/utils/generic_icon.dart';

/// The launcher list. The installed apps only change when the user installs
/// something, which this launcher is not around to see - one read at startup.
class AndroidAppsClient {
  final _apps = StateProvider<List<LauncherApp>>();

  static const _systemSettingsPackage = 'com.android.settings';
  static const _debugIconUrl = 'https://developer.android.com/static/develop/ui/compose/images/adaptive-icon-mask-applied.png';

  AndroidAppsClient() {
    _load();
  }

  Future<void> _load() async {
    final installed = Platform.isAndroid ? await InstalledApps.getInstalledApps(false, true, true) : <AppInfo>[];

    final apps = installed.where((info) => info.icon != null).map(_installedApp).toList();

    _apps.setValue(apps.isEmpty ? _debugApps() : apps);
  }

  static LauncherApp _installedApp(AppInfo info) {
    return LauncherApp(
      name: info.name,
      icon: Future.value(MemoryImage(info.icon!)),
      launch: (context) => _launch(context, info.name, info.packageName),
    );
  }

  LauncherApp findSystemSettings() {
    if (!Platform.isAndroid && !kReleaseMode) return _debugApp('System Settings');

    return LauncherApp(
      name: 'System Settings',
      icon: _packageIcon(_systemSettingsPackage),
      launch: (context) => _launch(context, 'System Settings', _systemSettingsPackage),
    );
  }

  static Future<ImageProvider> _packageIcon(String package) async {
    final info = await InstalledApps.getAppInfo(package, null);
    final bytes = info?.icon;

    if (bytes == null) throw StateError('no icon for $package');

    return MemoryImage(bytes);
  }

  static Future<void> _launch(BuildContext context, String name, String package) async {
    String reason;

    try {
      if (await InstalledApps.startApp(package) == true) return;

      reason = 'refused by $package';
    } catch (error) {
      reason = '$error';
    }

    logAndroid.warning('could not start $package: $reason');

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not start $name: $reason')));
  }

  static List<LauncherApp> _debugApps() {
    if (kReleaseMode) return [];

    return [
      'Calculator', 'Calendar', 'Camera', 'Chrome', 'Clock', //
      'Contacts', 'Files', 'Gallery', 'Gmail', 'Home Assistant',
      'Maps', 'Messages', 'Music', 'Netflix', 'Phone',
      'Photos', 'Settings', 'Spotify', 'Telegram', 'YouTube',
    ]
        .map(_debugApp)
        .toList();
  }

  static LauncherApp _debugApp(String name) {
    return LauncherApp(
      name: name,
      icon: Future.value(NetworkImage(_debugIconUrl)),
      launch: (context) => _launch(context, name, 'debug.${name.toLowerCase().replaceAll(' ', '_')}'),
    );
  }

  StateProvider<List<LauncherApp>> getStateProvider() {
    return _apps;
  }
}

/// The next alarm clock, polled - the platform has no callback for one being
/// set, so the card would otherwise show a stale time until the next rebuild.
class AndroidAlarmClient {
  static const _pollInterval = Duration(seconds: 5);

  final _alarm = StateProvider<Alarm>();
  Timer? _timer;

  AndroidAlarmClient() {
    _fetch().then((_) {
      _timer = Timer.periodic(_pollInterval, (_) => _fetch());
    });
  }

  Future<void> _fetch() async {
    final next = await AndroidClientApi.getNextAlarmClockTriggerTime();
    final canDismiss = await AndroidClientApi.canDismissAlarm();

    _alarm.setValue(Alarm(next: next == null ? null : AlarmInfo(fire: next), canDismiss: canDismiss));
  }

  Future<bool> dismissNext() async {
    final dismissed = await AndroidClientApi.dismissNextAlarm();

    if (dismissed) await _fetch();

    return dismissed;
  }

  StateProvider<Alarm> getStateProvider() {
    return _alarm;
  }

  void dispose() {
    _timer?.cancel();
    _alarm.dispose();
  }
}

/// Everything that decides what the panel is doing when nobody is touching it:
/// how bright it is, and whether it is allowed to sleep. Both answers come from
/// the config plus Home Assistant sensors, so they share a client.
class AndroidScreenClient {
  static const _scheduleInterval = Duration(minutes: 1);
  static const _illuminanceSensor = 'sensor.illuminance_mi_bedroom';

  final HomeAssistantClient _homeAssistantClient;

  AndroidConfig _config = AndroidConfig();

  Timer? _scheduleTimer;
  ScreenOnDecision? _screenOnState;
  ScreenOnInterval? _dismissedInterval;
  final Map<String, StateProvider<bool>> _sensors = {};
  StateProvider<double>? _illuminance;

  AndroidScreenClient({required HomeAssistantClient homeAssistantClient}) : _homeAssistantClient = homeAssistantClient {
    // Kept so a config change can re-apply the brightness right away.
    _illuminance = _homeAssistantClient.sensorStateProvider(_illuminanceSensor);
    _illuminance!.bindValueChanged(_onIlluminanceChanged);

    _scheduleTimer = Timer.periodic(_scheduleInterval, (_) => _applySchedule());
    AndroidClientApi.onScreenOff(_onScreenOff);
    _applySchedule();
  }

  /// The client starts on defaults and is handed the stored config once it is
  /// loaded, and again on every save; each time re-decides both.
  void setConfig(AndroidConfig config) {
    _config = config;

    _bindSensors(config.screenOnSensors);
    _applySchedule();

    if (config.autoBrightnessEnabled) _applyBrightness(_illuminance?.getValue());
  }

  void _onIlluminanceChanged(double? lux) {
    if (!_config.autoBrightnessEnabled) return;

    _applyBrightness(lux);
  }

  void _applyBrightness(double? lux) {
    if (lux == null) return;

    // Above the threshold the panel goes to full, below it to the minimum -
    // there is nothing in between worth the flicker of tracking it.
    AndroidClientApi.setBrightness(lux > _config.brightnessThreshold ? 1.0 : 0.0);
  }

  /// The screen went dark. Inside a keep-on interval that means the user
  /// dismissed it, so it stays inert until it ends.
  void _onScreenOff() {
    _screenOnState = null;
    _dismissedInterval = _config.activeKeepOnInterval(DateTime.now());
  }

  void _onSensorChanged(bool? _) => _applySchedule();

  void _bindSensors(List<String> entityIds) {
    for (final entityId in _sensors.keys.toList()) {
      if (entityIds.contains(entityId)) continue;

      _sensors.remove(entityId)?.unbind(_onSensorChanged);
    }

    for (final entityId in entityIds) {
      if (entityId.isEmpty || _sensors.containsKey(entityId)) continue;

      _sensors[entityId] = _homeAssistantClient.switchStateProvider(entityId)..bindValueChanged(_onSensorChanged);
    }
  }

  void _applySchedule() {
    final now = DateTime.now();

    // A dismissal only lasts as long as the interval it dismissed.
    if (_dismissedInterval != null && !_dismissedInterval!.contains(now)) _dismissedInterval = null;

    final decision = _config.screenOnDecision(
      now,
      _sensors.map((id, provider) => MapEntry(id, provider.getValue())),
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
    _scheduleTimer?.cancel();
    _illuminance?.unbind(_onIlluminanceChanged);

    for (final provider in _sensors.values) {
      provider.unbind(_onSensorChanged);
    }
  }
}

class AndroidClient {
  final _storage = const ConfigStorage('ANDROID_CONFIG');

  final apps = AndroidAppsClient();
  final alarms = AndroidAlarmClient();
  final AndroidScreenClient screen;

  AndroidConfig _config = AndroidConfig();

  AndroidConfig get config => _config;

  AndroidClient({required HomeAssistantClient homeAssistantClient}) : screen = AndroidScreenClient(homeAssistantClient: homeAssistantClient) {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final stored = await _storage.read();

    // Settings written by an older build can stop parsing; the default stands.
    final loaded = stored == null ? null : AndroidConfig.fromJson(stored);

    if (loaded != null) _applyConfig(loaded);
  }

  void saveConfig(AndroidConfig config) {
    _applyConfig(config);
    _storage.write(config.toJson());
  }

  void _applyConfig(AndroidConfig config) {
    _config = config;

    screen.setConfig(config);
  }

  void dispose() {
    alarms.dispose();
    screen.dispose();
  }

  SettingsItem makeSystemSettings() {
    return SettingsItem.fromLauncherApp(apps.findSystemSettings());
  }

  SettingsItem makeSettings() {
    return SettingsItem.action(
      icon: GenericIcon.fromIcon(
        icon: Icons.android,
      ),
      name: 'Android',
      action: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AndroidSettingsPage()),
      ),
    );
  }
}
