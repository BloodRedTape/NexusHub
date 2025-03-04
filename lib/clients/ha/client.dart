import 'package:flutter/material.dart';
import 'package:home_assistant/home_assistant.dart';
import 'package:intl/intl.dart';
import 'package:nexus/cards/details.dart';
import 'package:nexus/clients/ha/config.dart';
import 'package:nexus/clients/ha/debug.dart';
import 'package:nexus/clients/ha/provider.dart';
import 'package:nexus/clients/ha/settings.dart';
import 'package:nexus/clients/ha/state.dart';
import 'package:nexus/dashboard/settings.dart';
import 'package:nexus/providers/shared_preferences_state.dart';
import 'package:nexus/providers/state.dart';
import 'package:nexus/states/calendar.dart';
import 'package:nexus/utils/generic_icon.dart';

class HomeAssistantClient {
  late StateProvider<HomeAssistantConfig> _configStateProvider;
  late HomeAssistantStateProvider _entitiesStateProvider;

  Map<String, EntityStateProvider> _entityStateProviders = {};
  Map<String, SensorStateProvider> _sensorStateProviders = {};
  Map<String, SwitchStateProvider> _switchStateProviders = {};
  Map<String, CurtainStateProvider> _curtainStateProviders = {};
  Map<String, CalendarStateProvider> _calendarStateProviders = {};

  HomeAssistantClient() {
    _configStateProvider = SharedPreferencesStateProvider(
      initialValue: HomeAssistantConfig(token: '', url: 'https://192.168.1.211:8443'),
      preferencesKey: 'HOME_ASSISTANT_CONFIG',
      serialize: HomeAssistantConfig.serialize,
      deserialize: HomeAssistantConfig.deserialize,
    );

    _configStateProvider.init();

    _entitiesStateProvider = HomeAssistantStateProvider(configStateProvider: _configStateProvider);

    _entitiesStateProvider.init();
  }

  StateProvider<List<Entity>> entitiesStateProvider() {
    return _entitiesStateProvider;
  }

  StateProvider<String> entityStateProvider(String entityId) {
    return _entityStateProviders.putIfAbsent(entityId, () => _buildEntityStateProvider(entityId));
  }

  EntityStateProvider _buildEntityStateProvider(String entityId) {
    final provider = EntityStateProvider(
      entityId: entityId,
      entitiesStateProvider: entitiesStateProvider(),
    );

    provider.init();

    return provider;
  }

  StateProvider<double> sensorStateProvider(String entityId) {
    return _sensorStateProviders.putIfAbsent(entityId, () => _buildSensorStateProvider(entityId));
  }

  SensorStateProvider _buildSensorStateProvider(String entityId) {
    final provider = SensorStateProvider(
      entityId: entityId,
      entitiesStateProvider: entitiesStateProvider(),
    );

    provider.init();

    return provider;
  }

  StateProvider<bool> switchStateProvider(String entityId) {
    return _switchStateProviders.putIfAbsent(entityId, () => _buildSwitchStateProvider(entityId));
  }

  SwitchStateProvider _buildSwitchStateProvider(String entityId) {
    final provider =
        SwitchStateProvider(entityId: entityId, entitiesStateProvider: entitiesStateProvider(), requestState: (state) => _requestSwitchState(entityId, state));

    provider.init();

    return provider;
  }

  void _requestSwitchState(String entityId, bool state) {
    _entitiesStateProvider.executeServiceForEntity(entityId, state ? 'turn_on' : 'turn_off');
  }

  StateProvider<double> curtainStateProvider(String entityId) {
    return _curtainStateProviders.putIfAbsent(entityId, () => _buildCurtainStateProvider(entityId));
  }

  CurtainStateProvider _buildCurtainStateProvider(String entityId) {
    final provider = CurtainStateProvider(
        entityId: entityId, entitiesStateProvider: entitiesStateProvider(), requestState: (state) => _requestCurtainState(entityId, state));

    provider.init();

    return provider;
  }

  void _requestCurtainState(String entityId, double state) {
    _entitiesStateProvider.executeServiceForEntity(entityId, 'set_cover_position', aditionalActions: {'position': state.toInt()}, refetch: false);
  }

  StateProvider<CalendarState> calendarStateProvider(String entityId) {
    return _calendarStateProviders.putIfAbsent(entityId, () => _buildCalendarStateProvider(entityId));
  }

  CalendarStateProvider _buildCalendarStateProvider(String entityId) {
    final provider = CalendarStateProvider(
        entityId: entityId, entitiesStateProvider: entitiesStateProvider(), getCalendarEvents: _getCalendarEvents, rangeFromNow: Duration(days: 3));

    provider.init();

    return provider;
  }

  Future<ServiceResponse?> _getCalendarEvents(String entityId, DateTime start, DateTime end) async {
    final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    ServiceResponse? response = await _entitiesStateProvider.executeService(
      domain: 'calendar',
      service: 'get_events',
      serviceData: {
        'entity_id': entityId,
        'start_date_time': dateFormat.format(start),
        'end_date_time': dateFormat.format(end),
      },
      returnResponse: true,
      refetch: false,
    );

    return response;
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
              child: HomeAssistantDebugWidget(stateProvider: _entitiesStateProvider),
            ),
          ],
        ),
      ),
    );
  }
}
