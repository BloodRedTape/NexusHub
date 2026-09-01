import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:home_assistant_ws/home_assistant_ws.dart';
import 'package:intl/intl.dart';
import 'package:nexus/cards/details.dart';
import 'package:nexus/clients/ha/config.dart';
import 'package:nexus/clients/ha/debug.dart';
import 'package:nexus/clients/ha/settings.dart';
import 'package:nexus/utils/settings_section.dart';
import 'package:nexus/clients/ha/states/calendar.dart';
import 'package:nexus/clients/ha/states/curtain.dart';
import 'package:nexus/clients/ha/states/entity.dart';
import 'package:nexus/clients/ha/states/light.dart';
import 'package:nexus/clients/ha/states/sensor.dart';
import 'package:nexus/clients/ha/states/switch.dart';
import 'package:nexus/dashboard/settings.dart';
import 'package:nexus/providers/shared_preferences_state.dart';
import 'package:nexus/providers/state.dart';
import 'package:nexus/states/calendar.dart';
import 'package:nexus/states/light.dart';
import 'package:nexus/utils/generic_icon.dart';

EntityAttributes applyAttributes(EntityAttributes target, EntityAttributes source) {
  if (source.editable != null) target.editable = source.editable;
  if (source.id != null) target.id = source.id;
  if (source.userId != null) target.userId = source.userId;
  if (source.deviceTrackers.isNotEmpty) target.deviceTrackers = List.from(source.deviceTrackers);
  if (source.friendlyName != null) target.friendlyName = source.friendlyName;
  if (source.deviceClass != null) target.deviceClass = source.deviceClass;
  if (source.unitOfMeasurement != null) target.unitOfMeasurement = source.unitOfMeasurement;

  if (source.options != null) target.options = List.from(source.options!);
  if (source.supportedColorModes != null) target.supportedColorModes = List.from(source.supportedColorModes!);
  if (source.brightness != null) target.brightness = source.brightness;
  if (source.rgbColor != null) target.rgbColor = List.from(source.rgbColor!);

  if (source.hvacModes != null) target.hvacModes = List.from(source.hvacModes!);
  if (source.minTemp != null) target.minTemp = source.minTemp;
  if (source.maxTemp != null) target.maxTemp = source.maxTemp;
  if (source.currentTemperature != null) target.currentTemperature = source.currentTemperature;
  if (source.temperature != null) target.temperature = source.temperature;
  if (source.targetTempLow != null) target.targetTempLow = source.targetTempLow;
  if (source.targetTempHigh != null) target.targetTempHigh = source.targetTempHigh;
  if (source.presetMode != null) target.presetMode = source.presetMode;
  if (source.hvacAction != null) target.hvacAction = source.hvacAction;
  if (source.fanMode != null) target.fanMode = source.fanMode;

  if (source.videoUrl != null) target.videoUrl = source.videoUrl;
  if (source.entityPicture != null) target.entityPicture = source.entityPicture;

  if (source.mediaTitle != null) target.mediaTitle = source.mediaTitle;
  if (source.mediaArtist != null) target.mediaArtist = source.mediaArtist;

  if (source.currentPosition != null) target.currentPosition = source.currentPosition;

  return target;
}

/// A device of an area together with the entities it exposes.
class DeviceEntities {
  final String? deviceId;
  final String name;
  final List<RegistryEntry> entities;

  /// Kind of every entity, by entity id - see [HomeAssistantClient.kindOf].
  final Map<String, String> kindsById;

  const DeviceEntities({required this.deviceId, required this.name, required this.entities, required this.kindsById});

  /// Entity kinds this device exposes.
  Set<String> get kinds => kindsById.values.toSet();

  /// First entity whose id ends with [suffix] - for integrations that name
  /// their entities meaningfully but leave the device class empty.
  RegistryEntry? entityEndingWith(String suffix) {
    for (final entry in entities) {
      if (entry.entityId.endsWith(suffix)) return entry;
    }

    return null;
  }

  RegistryEntry? entityOf(String kind) {
    for (final entry in entities) {
      if (kindsById[entry.entityId] == kind) return entry;
    }

    return null;
  }
}

class HomeAssistantClientState {
  String status;
  String? url;
  bool hasToken;
  DateTime? lastConnected;
  final List<String> log;

  HomeAssistantClientState({required this.status, this.url, this.hasToken = false, this.lastConnected, List<String>? log}) : log = log ?? [];
}

class HomeAssistantClient {
  late StateProvider<HomeAssistantConfig> _configStateProvider;
  HomeAssistantWs? _homeAssistantWs = null;
  Timer? _pingPongTimer;

  final _clientState = StateProvider<HomeAssistantClientState>();
  final _areas = StateProvider<List<Area>>();
  final List<String> _log = [];

  /// Areas (rooms) as configured in Home Assistant, null until the first successful connect.
  StateProvider<List<Area>> get areas => _areas;

  List<RegistryEntry> _registry = [];
  List<Device> _devices = [];
  Map<String, String?> _deviceAreas = {};

  List<Area>? _pendingAreas;
  bool _hasStates = false;

  /// Areas become visible once both the registries and the first states are in.
  void _publishAreas() {
    final areas = _pendingAreas;

    if (areas == null || !_hasStates) return;

    _pendingAreas = null;

    final counts = {for (final area in areas) area.areaId: _cardCount(area.areaId)};

    final result = areas.where((area) => !_hideEmptyAreas || counts[area.areaId]! > 0).toList();

    // busiest rooms first, alphabetical among equals
    result.sort((a, b) {
      final byCount = counts[b.areaId]!.compareTo(counts[a.areaId]!);

      return byCount != 0 ? byCount : a.name.compareTo(b.name);
    });

    _areas.setValue(result);
  }

  /// How many devices of an area would end up with a card.
  int _cardCount(String areaId) {
    final showable = isDeviceShowable;
    final devices = devicesOfArea(areaId);

    if (showable == null) return devices.length;

    return devices.where(showable).length;
  }

  /// What a card is matched against: the entity domain, and for sensors the
  /// device class too - 'light', 'sensor.temperature', ...
  ///
  /// The registry often leaves the device class empty, so fall back to the one
  /// the entity reports in its own state.
  String kindOf(RegistryEntry entry) {
    // diagnostics are readouts about the device - keep them out of the plain kinds
    final prefix = entry.entityCategory == 'diagnostic' ? 'diagnostic:' : '';

    if (entry.domain != 'sensor' && entry.domain != 'binary_sensor') return '$prefix${entry.domain}';

    final deviceClass = entry.effectiveDeviceClass ?? _entityProviders[entry.entityId]?.getValue()?.attributes?.deviceClass;

    return '$prefix${deviceClass == null ? entry.domain : '${entry.domain}.$deviceClass'}';
  }

  /// Devices of [areaId] with the entities that belong to them, sorted by name.
  /// Entities without a device of their own are grouped under a synthetic one.
  List<DeviceEntities> devicesOfArea(String areaId) {
    final Map<String?, List<RegistryEntry>> byDevice = {};

    for (final entry in entitiesOfArea(areaId)) {
      byDevice.putIfAbsent(entry.deviceId, () => []).add(entry);
    }

    final names = {for (final device in _devices) device.deviceId: device.displayName};

    final result = byDevice.entries
        .map((e) => DeviceEntities(
              deviceId: e.key,
              name: names[e.key] ?? e.value.first.displayName,
              entities: e.value,
              kindsById: {for (final entry in e.value) entry.entityId: kindOf(entry)},
            ))
        .toList();

    result.sort((a, b) => a.name.compareTo(b.name));

    return result;
  }

  bool _hideUnavailable = true;
  bool _hideEmptyAreas = true;

  /// Tells whether a device can be shown at all. Set by the dashboard, which
  /// owns the card matchers; without it every device counts as showable.
  bool Function(DeviceEntities device)? isDeviceShowable;

  /// True unless Home Assistant says the entity has no usable state.
  bool _isAvailable(String entityId) {
    final state = _entityProviders[entityId]?.getValue()?.state;

    return state != null && state != 'unavailable' && state != 'unknown';
  }

  /// Every binary sensor in the registry, sorted by name.
  List<RegistryEntry> binarySensors() {
    final result = _registry
        .where((entry) => entry.domain == 'binary_sensor' && !entry.disabled && !entry.hidden)
        .toList();

    result.sort((a, b) => a.displayName.compareTo(b.displayName));

    return result;
  }

  /// Registry entries that live in [areaId], sorted by name.
  /// An entity without an area of its own inherits the one of its device.
  List<RegistryEntry> entitiesOfArea(String areaId) {
    final result = _registry
        // config entities are knobs about the device, not the device itself.
        // diagnostics stay, marked by kindOf, so only cards that ask get them.
        .where((entry) => !entry.disabled && !entry.hidden && entry.entityCategory != 'config')
        .where((entry) => (entry.areaId ?? _deviceAreas[entry.deviceId]) == areaId)
        .where((entry) => !_hideUnavailable || _isAvailable(entry.entityId))
        .toList();

    result.sort((a, b) => a.displayName.compareTo(b.displayName));

    return result;
  }
  String? _wsUrl;
  bool _hasToken = false;
  DateTime? _lastConnected;

  void _setStatus(String status, {String? detail}) {
    if (detail != null) {
      _log.add('${DateFormat('HH:mm:ss').format(DateTime.now())}  $detail');
      if (_log.length > 500) _log.removeRange(0, _log.length - 500);
    }

    _clientState.setValue(
      HomeAssistantClientState(
        status: status,
        url: _wsUrl,
        hasToken: _hasToken,
        lastConnected: _lastConnected,
        log: List.from(_log.reversed),
      ),
    );
  }

  Map<String, StateProvider<Entity>> _entityProviders = {};

  Map<String, EntityStateProvider> _entityStateProviders = {};
  Map<String, SensorStateProvider> _sensorStateProviders = {};
  Map<String, SwitchStateProvider> _switchStateProviders = {};
  Map<String, CurtainStateProvider> _curtainStateProviders = {};
  Map<String, CalendarStateProvider> _calendarStateProviders = {};
  Map<String, LightStateProvider> _lightStateProviders = {};

  Future<void>? _restartFuture;
  HomeAssistantConfig? _pendingConfig;

  HomeAssistantClient() {
    _configStateProvider = SharedPreferencesStateProvider(
      initialValue: HomeAssistantConfig(token: '', url: 'https://192.168.1.209:8443'),
      preferencesKey: 'HOME_ASSISTANT_CONFIG',
      serialize: HomeAssistantConfig.serialize,
      deserialize: HomeAssistantConfig.deserialize,
    );

    _configStateProvider.init();
    _configStateProvider.bindValueChanged(_reconnect);

    _setStatus('Initialized', detail: 'Client initialized');
  }

  Future<void> _restartConnection(HomeAssistantConfig? config) async {
    _setStatus('disconnecting...');

    _hasStates = false;
    _pendingAreas = null;

    _hideUnavailable = config?.hideUnavailable ?? true;
    _hideEmptyAreas = config?.hideEmptyAreas ?? true;

    _pingPongTimer?.cancel();
    await _homeAssistantWs?.disconnect();

    if (config == null) {
      _setStatus('No config', detail: 'No config: url/token are empty or malformed');
      return;
    }

    _hasToken = config.token.isNotEmpty;

    final uri = Uri.tryParse(config.url);
    if (uri == null || uri.host.isEmpty) {
      _wsUrl = null;
      _setStatus('Bad url', detail: 'Cannot parse url "${config.url}" - expected something like https://host:8123');
      return;
    }

    _wsUrl = 'wss://${uri.host}${uri.hasPort ? ':' + uri.port.toString() : ''}/api/websocket';

    if (!_hasToken) {
      _setStatus('No token', detail: 'Bearer token is empty - create a long-lived token in HA profile');
      return;
    }

    _setStatus('connecting...', detail: 'Connecting to $_wsUrl');

    _homeAssistantWs = HomeAssistantWs(
      token: config.token,
      baseUrl: _wsUrl!,
      onDone: _onDone,
      onError: _onError,
    );
    final ha = _homeAssistantWs!;

    try {
      await ha.connectOrThrow(unsafe: true);
    } on ConnectionError catch (e) {
      _setStatus(e.kind.name, detail: e.description);
      return;
    } catch (e) {
      _setStatus('Connect failed', detail: 'connect() threw: ${_describe(e)}');
      return;
    }

    ha.subscribeEntities(_onEvent);

    try {
      final devices = await ha.getDevices();
      _devices = devices;
      _deviceAreas = {for (final device in devices) device.deviceId: device.areaId};
      _registry = await ha.getEntityRegistry();

      // entity states carry the device class the registry usually omits, so
      // hold the areas back until the first batch of states has arrived
      _pendingAreas = await ha.getAreas();
      _publishAreas();

      _setStatus('connected', detail: 'Loaded ${_pendingAreas?.length ?? 0} areas, ${devices.length} devices, ${_registry.length} entities');
    } catch (e) {
      _setStatus('connected', detail: 'Failed to load registries: ${_describe(e)}');
    }

    _pingPongTimer = Timer.periodic(Duration(seconds: 30), (_) async {
      try {
        await ha.ping();
      } catch (e) {
        _setStatus('ping failed', detail: 'Ping failed: ${_describe(e)}');
      }
    });

    _lastConnected = DateTime.now();
    _setStatus('connected', detail: 'Connected to $_wsUrl');
  }

  String _describe(dynamic e) => '${e.runtimeType}: $e';

  void _reconnect(HomeAssistantConfig? config) {
    _pendingConfig = config;

    if (_restartFuture != null) return;

    _restartFuture = _restartConnection(config);
    _restartFuture?.whenComplete(() {
      _restartFuture = null;

      // config changed while we were connecting - redo it with the latest one
      if (!identical(_pendingConfig, config)) _reconnect(_pendingConfig);
    });
  }

  void reconnect() {
    _setStatus('reconnecting...', detail: 'Manual reconnect requested');
    _reconnect(_configStateProvider.getValue());
  }

  void _onDone() {
    _setStatus('disconnected', detail: 'Socket closed by the other side');
  }

  void _onError(dynamic error) {
    _setStatus('Error', detail: 'Socket error: ${_describe(error)}');
  }

  void _onEvent(EventMessage event) {
    if (event.available != null) {
      _onAvailable(event.available!);

      _hasStates = true;
      _publishAreas();
    }

    if (event.change != null) {
      _onChange(event.change!);
    }
  }

  StateProvider<Entity> findOrCreate(String entityId) {
    return _entityProviders.putIfAbsent(entityId, () {
      final result = StateProvider<Entity>();
      result.setValue(Entity(entityId: entityId, state: null));
      return result;
    });
  }

  void _onAvailable(EventAvailable available) {
    for (final entity in available.entities) {
      findOrCreate(entity.entityId).setValue(Entity(entityId: entity.entityId, state: entity.state, attributes: entity.attributes));
    }
  }

  void _onChange(EventChange change) {
    for (final entity in change.changes) {
      final provider = findOrCreate(entity.entityId);
      Entity result = provider.getValue()!;

      if (entity.stateChange != null) {
        result.state = entity.stateChange?.newValue;
      }

      final oldAttributes = result.attributes?.toJson() ?? {};

      for (final attribtueChange in entity.attributesChange.entries) {
        oldAttributes[attribtueChange.key] = attribtueChange.value.newValue;
      }

      result.attributes = oldAttributes.isNotEmpty ? EntityAttributes.fromData(oldAttributes) : null;

      provider.setValue(result);
    }
  }

  StateProvider<String> entityStateProvider(String entityId) {
    return _entityStateProviders.putIfAbsent(entityId, () => _buildEntityStateProvider(entityId));
  }

  EntityStateProvider _buildEntityStateProvider(String entityId) {
    final provider = EntityStateProvider(
      entityProvider: findOrCreate(entityId),
    );

    provider.init();

    return provider;
  }

  StateProvider<double> sensorStateProvider(String entityId) {
    return _sensorStateProviders.putIfAbsent(entityId, () => _buildSensorStateProvider(entityId));
  }

  SensorStateProvider _buildSensorStateProvider(String entityId) {
    final provider = SensorStateProvider(
      entityProvider: findOrCreate(entityId),
    );

    provider.init();

    return provider;
  }

  StateProvider<bool> switchStateProvider(String entityId) {
    return _switchStateProviders.putIfAbsent(entityId, () => _buildSwitchStateProvider(entityId));
  }

  SwitchStateProvider _buildSwitchStateProvider(String entityId) {
    final provider = SwitchStateProvider(entityProvider: findOrCreate(entityId), requestState: (state) => _requestSwitchState(entityId, state));

    provider.init();

    return provider;
  }

  void _requestSwitchState(String entityId, bool state) {
    _homeAssistantWs?.executeServiceForEntity(entityId, state ? 'turn_on' : 'turn_off');
  }

  StateProvider<double> curtainStateProvider(String entityId) {
    return _curtainStateProviders.putIfAbsent(entityId, () => _buildCurtainStateProvider(entityId));
  }

  CurtainStateProvider _buildCurtainStateProvider(String entityId) {
    final provider = CurtainStateProvider(entityProvider: findOrCreate(entityId), requestState: (state) => _requestCurtainState(entityId, state));

    provider.init();

    return provider;
  }

  void _requestCurtainState(String entityId, double state) {
    _homeAssistantWs?.executeServiceForEntity(entityId, 'set_cover_position', additionalData: {'position': state.toInt()});
  }

  StateProvider<CalendarState> calendarStateProvider(String entityId) {
    return _calendarStateProviders.putIfAbsent(entityId, () => _buildCalendarStateProvider(entityId));
  }

  CalendarStateProvider _buildCalendarStateProvider(String entityId) {
    final provider = CalendarStateProvider(entityProvider: findOrCreate(entityId), getCalendarEvents: _getCalendarEvents, rangeFromNow: Duration(days: 3));

    provider.init();

    return provider;
  }

  Future<ServiceResponse?> _getCalendarEvents(String entityId, DateTime start, DateTime end) async {
    final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    ServiceResponse? response = await _homeAssistantWs?.executeService(
      domain: 'calendar',
      service: 'get_events',
      serviceData: {
        'entity_id': entityId,
        'start_date_time': dateFormat.format(start),
        'end_date_time': dateFormat.format(end),
      },
      returnResponse: true,
    );

    return response;
  }

  StateProvider<LightState> lightStateProvider(String entityId) {
    return _lightStateProviders.putIfAbsent(entityId, () => _buildLightStateProvider(entityId));
  }

  LightStateProvider _buildLightStateProvider(String entityId) {
    final provider = LightStateProvider(entityProvider: findOrCreate(entityId), requestLightState: (state) => _requestLightState(entityId, state));

    provider.init();

    return provider;
  }

  void _requestLightState(String entityId, LightState state) {
    Map<String, dynamic> data = {};
    data['entity_id'] = entityId;

    if (state.color != null && state.isOn) {
      //data['rgb_color'] = [state.color!.value.r, state.color!.value.g, state.color!.value.b];
      final HSVColor color = HSVColor.fromColor(state.color!.value);
      data['hs_color'] = [color.hue, color.saturation * 100];
    }

    if (state.brightness != null && state.isOn) {
      data['brightness_pct'] = (state.brightness!.value / (state.brightness!.max - state.brightness!.min)) * 100;
    }

    _homeAssistantWs?.executeService(
      domain: 'light',
      service: state.isOn ? 'turn_on' : 'turn_off',
      serviceData: data,
      returnResponse: false,
    );
  }

  final GlobalKey<State> _settingsKey = GlobalKey<State>();

  SettingsItem makeSettings() {
    return SettingsItem.details(
      icon: GenericIcon.fromImage(
        image: Image.network('https://community-assets.home-assistant.io/original/3X/6/3/63f75921214e158bc02336dc864c096b11889f14.png'),
      ),
      name: 'Home Assistant',
      details: DetailsPage(
        title: Text('Home Assistant Settings'),
        actions: [SettingsSaveButton(_settingsKey)],
        body: HomeAssistantConfigWidget(
          key: _settingsKey,
          stateProvider: _configStateProvider,
          // Its own page: the log has a scroll of its own and does not belong
          // inside the settings list.
          openDiagnostics: (context) => DetailsPage(
            title: Text('Connection'),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: HomeAssistantDebugWidget(stateProvider: _clientState, onReconnect: reconnect),
            ),
          ).navigateTo(context),
        ),
      ),
    );
  }
}
