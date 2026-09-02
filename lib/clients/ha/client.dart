import 'package:flutter/material.dart';
import 'package:home_assistant_ws/home_assistant_ws.dart';
import 'package:intl/intl.dart';
import 'package:nexus/clients/ha/clients/connection.dart';
import 'package:nexus/clients/ha/clients/entities.dart';
import 'package:nexus/clients/ha/clients/registry.dart';
import 'package:nexus/clients/ha/config.dart';
import 'package:nexus/clients/ha/models/calendar.dart';
import 'package:nexus/clients/ha/models/light.dart';
import 'package:nexus/clients/ha/models/vacuum.dart';
import 'package:nexus/clients/ha/providers/calendar.dart';
import 'package:nexus/clients/ha/providers/curtain.dart';
import 'package:nexus/clients/ha/providers/entity.dart';
import 'package:nexus/clients/ha/providers/light.dart';
import 'package:nexus/clients/ha/providers/sensor.dart';
import 'package:nexus/clients/ha/providers/switch.dart';
import 'package:nexus/clients/ha/providers/vacuum.dart';
import 'package:nexus/clients/ha/settings.dart';
import 'package:nexus/dashboard/settings.dart';
import 'package:nexus/providers/state.dart';
import 'package:nexus/utils/generic_icon.dart';

export 'package:nexus/clients/ha/clients/registry.dart' show DeviceEntities;

/// Home Assistant as the dashboard talks to it: a socket, the entities it
/// reports and the registry describing them. This class owns the three and
/// turns raw entities into the typed providers the cards are built on.
class HomeAssistantClient {
  static const _calendarRange = Duration(days: 3);

  final connection = HomeAssistantConnection();
  final entities = HomeAssistantEntities();
  late final HomeAssistantRegistry registry;

  HomeAssistantClient() {
    registry = HomeAssistantRegistry(entityOf: entities.valueOf);

    connection.onEvent = _onEvent;
    connection.onReset = registry.reset;
    connection.onConnected = registry.load;

    connection.start();
  }

  void _onEvent(EventMessage event) {
    if (event.available != null) {
      entities.onAvailable(event.available!);
      registry.onStatesArrived();
    }

    if (event.change != null) entities.onChange(event.change!);
  }

  // The dashboard and the settings pages talk to the client, not to its parts.
  HomeAssistantConfig get config => connection.config;
  StateProvider<List<Area>> get areas => registry.areas;

  set isDeviceShowable(bool Function(DeviceEntities device)? showable) => registry.isDeviceShowable = showable;

  void saveConfig(HomeAssistantConfig config) => connection.saveConfig(config);
  void reconnect() => connection.reconnect();
  void openDiagnostics(BuildContext context) => connection.openDiagnostics(context);

  String kindOf(RegistryEntry entry) => registry.kindOf(entry);
  List<DeviceEntities> devicesOfArea(String areaId) => registry.devicesOfArea(areaId);
  List<RegistryEntry> entitiesOfArea(String areaId) => registry.entitiesOfArea(areaId);
  List<RegistryEntry> binarySensors() => registry.binarySensors();

  void dispose() => connection.dispose();

  final Map<String, EntityStateProvider> _entityStateProviders = {};
  final Map<String, SensorStateProvider> _sensorStateProviders = {};
  final Map<String, SwitchStateProvider> _switchStateProviders = {};
  final Map<String, CurtainStateProvider> _curtainStateProviders = {};
  final Map<String, CalendarStateProvider> _calendarStateProviders = {};
  final Map<String, LightStateProvider> _lightStateProviders = {};
  final Map<String, VacuumStateProvider> _vacuumStateProviders = {};

  StateProvider<String> entityStateProvider(String entityId) => _entityStateProviders.putIfAbsent(
      entityId, () => EntityStateProvider(entityProvider: entities.findOrCreate(entityId))..init());

  StateProvider<double> sensorStateProvider(String entityId) => _sensorStateProviders.putIfAbsent(
      entityId, () => SensorStateProvider(entityProvider: entities.findOrCreate(entityId))..init());

  StateProvider<bool> switchStateProvider(String entityId) => _switchStateProviders.putIfAbsent(
      entityId,
      () => SwitchStateProvider(
            entityProvider: entities.findOrCreate(entityId),
            requestState: (state) => connection.ws?.executeServiceForEntity(entityId, state ? 'turn_on' : 'turn_off'),
          )..init());

  StateProvider<double> curtainStateProvider(String entityId) => _curtainStateProviders.putIfAbsent(
      entityId,
      () => CurtainStateProvider(
            entityProvider: entities.findOrCreate(entityId),
            requestState: (state) =>
                connection.ws?.executeServiceForEntity(entityId, 'set_cover_position', additionalData: {'position': state.toInt()}),
          )..init());

  StateProvider<Calendar> calendarStateProvider(String entityId) => _calendarStateProviders.putIfAbsent(
      entityId,
      () => CalendarStateProvider(
            entityProvider: entities.findOrCreate(entityId),
            getCalendarEvents: _getCalendarEvents,
            rangeFromNow: _calendarRange,
          )..init());

  StateProvider<Light> lightStateProvider(String entityId) => _lightStateProviders.putIfAbsent(
      entityId,
      () => LightStateProvider(
            entityProvider: entities.findOrCreate(entityId),
            requestLightState: (state) => _requestLightState(entityId, state),
          )..init());

  StateProvider<Vacuum> vacuumStateProvider(String entityId) => _vacuumStateProviders.putIfAbsent(
      entityId,
      () => VacuumStateProvider(
            entityProvider: entities.findOrCreate(entityId),
            requestState: (state) => _requestVacuumState(entityId, state),
          )..init());

  Future<ServiceResponse?> _getCalendarEvents(String entityId, DateTime start, DateTime end) async {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return await connection.ws?.executeService(
      domain: 'calendar',
      service: 'get_events',
      serviceData: {
        'entity_id': entityId,
        'start_date_time': dateFormat.format(start),
        'end_date_time': dateFormat.format(end),
      },
      returnResponse: true,
    );
  }

  void _requestLightState(String entityId, Light state) {
    final Map<String, dynamic> data = {'entity_id': entityId};

    if (state.color != null && state.isOn) {
      final color = HSVColor.fromColor(state.color!.value);
      data['hs_color'] = [color.hue, color.saturation * 100];
    }

    if (state.brightness != null && state.isOn) {
      data['brightness_pct'] = (state.brightness!.value / (state.brightness!.max - state.brightness!.min)) * 100;
    }

    connection.ws?.executeService(
      domain: 'light',
      service: state.isOn ? 'turn_on' : 'turn_off',
      serviceData: data,
      returnResponse: false,
    );
  }

  void _requestVacuumState(String entityId, Vacuum state) {
    if (state.requestedFanSpeed != null) {
      connection.ws?.executeServiceForEntity(entityId, 'set_fan_speed', additionalData: {'fan_speed': state.requestedFanSpeed!});
      return;
    }

    const services = {
      VacuumCommand.start: 'start',
      VacuumCommand.pause: 'pause',
      VacuumCommand.stop: 'stop',
      VacuumCommand.returnToBase: 'return_to_base',
      VacuumCommand.locate: 'locate',
    };

    final service = services[state.command];

    if (service != null) connection.ws?.executeServiceForEntity(entityId, service);
  }

  SettingsItem makeSettings() {
    return SettingsItem.action(
      icon: GenericIcon.fromImage(
        image: Image.network('https://community-assets.home-assistant.io/original/3X/6/3/63f75921214e158bc02336dc864c096b11889f14.png'),
      ),
      name: 'Home Assistant',
      action: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HomeAssistantSettingsPage()),
      ),
    );
  }
}
