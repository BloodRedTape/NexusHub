import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:home_assistant_ws/home_assistant_ws.dart';
import 'package:intl/intl.dart';
import 'package:nexus/cards/details.dart';
import 'package:nexus/clients/ha/config.dart';
import 'package:nexus/clients/ha/debug.dart';
import 'package:nexus/clients/ha/settings.dart';
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

class HomeAssistantClientState {
  String status;

  HomeAssistantClientState({required this.status});
}

class HomeAssistantClient {
  late StateProvider<HomeAssistantConfig> _configStateProvider;
  HomeAssistantWs? _homeAssistantWs = null;
  Timer? _pingPongTimer;

  final _clientState = StateProvider<HomeAssistantClientState>();

  Map<String, StateProvider<Entity>> _entityProviders = {};

  Map<String, EntityStateProvider> _entityStateProviders = {};
  Map<String, SensorStateProvider> _sensorStateProviders = {};
  Map<String, SwitchStateProvider> _switchStateProviders = {};
  Map<String, CurtainStateProvider> _curtainStateProviders = {};
  Map<String, CalendarStateProvider> _calendarStateProviders = {};
  Map<String, LightStateProvider> _lightStateProviders = {};

  Future<void>? _restartFuture;

  HomeAssistantClient() {
    _configStateProvider = SharedPreferencesStateProvider(
      initialValue: HomeAssistantConfig(token: '', url: 'https://192.168.1.209:8443'),
      preferencesKey: 'HOME_ASSISTANT_CONFIG',
      serialize: HomeAssistantConfig.serialize,
      deserialize: HomeAssistantConfig.deserialize,
    );

    _configStateProvider.init();
    _configStateProvider.bindValueChanged(_reconnect);

    _clientState.setValue(HomeAssistantClientState(status: 'Initialized'));
  }

  Future<void> _restartConnection(HomeAssistantConfig? config) async {
    _clientState.setValue(HomeAssistantClientState(status: 'disconnecting...'));

    _pingPongTimer?.cancel();
    await _homeAssistantWs?.disconnect();

    if (config == null) return;

    _clientState.setValue(HomeAssistantClientState(status: 'connecting...'));

    final uri = Uri.parse(config.url);
    _homeAssistantWs = HomeAssistantWs(
      token: config.token,
      baseUrl: 'wss://${uri.host}${uri.hasPort ? ':' + uri.port.toString() : ''}/api/websocket',
      onDone: _onDone,
      onError: _onError,
    );
    final ha = _homeAssistantWs!;

    if (!await ha.connect()) {
      _clientState.setValue(HomeAssistantClientState(status: 'Connect failed'));
    }

    ha.subscribeEntities(_onEvent);

    _pingPongTimer = Timer.periodic(Duration(seconds: 30), (_) async {
      try {
        await ha.ping();
      } catch (e) {}
    });

    _clientState.setValue(HomeAssistantClientState(status: 'connected'));
  }

  void _reconnect(HomeAssistantConfig? config) {
    if (_restartFuture != null) return;

    _restartFuture = _restartConnection(config);
    _restartFuture?.whenComplete(() {
      _restartFuture = null;
    });
  }

  void _onDone() {
    //_clientState.setValue(HomeAssistantClientState(status: 'done'));
  }

  void _onError(dynamic error) {
    _clientState.setValue(HomeAssistantClientState(status: error.toString()));
  }

  void _onEvent(EventMessage event) {
    if (event.available != null) {
      _onAvailable(event.available!);
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

  SettingsItem makeSettings() {
    return SettingsItem.details(
      icon: GenericIcon.fromImage(
        image: Image.network('https://community-assets.home-assistant.io/original/3X/6/3/63f75921214e158bc02336dc864c096b11889f14.png'),
      ),
      name: 'Home Assistant',
      details: DetailsPage(
        title: Text('Home Assistant Settings'),
        body: Column(
          children: [
            HomeAssistantConfigWidget(
              stateProvider: _configStateProvider,
            ),
            Flexible(
              child: HomeAssistantDebugWidget(stateProvider: _clientState),
            ),
          ],
        ),
      ),
    );
  }
}
