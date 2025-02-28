import 'package:flutter/material.dart';
import 'package:home_assistant/home_assistant.dart';
import 'package:nexus/cards/details.dart';
import 'package:nexus/clients/ha/config.dart';
import 'package:nexus/clients/ha/provider.dart';
import 'package:nexus/clients/ha/settings.dart';
import 'package:nexus/dashboard/settings.dart';
import 'package:nexus/providers/shared_preferences_state.dart';
import 'package:nexus/providers/state.dart';
import 'package:nexus/utils/generic_icon.dart';

class HomeAssistantClient {
  late StateProvider<HomeAssistantConfig> _configStateProvider;
  late StateProvider<List<Entity>> _entitiesStateProvider;

  HomeAssistantClient() {
    _configStateProvider = SharedPreferencesStateProvider(
      initialValue: HomeAssistantConfig(token: '', url: ''),
      preferencesKey: 'HOME_ASSISTANT_CONFIG',
      serialize: HomeAssistantConfig.serialize,
      deserialize: HomeAssistantConfig.deserialize,
    );

    _configStateProvider.init();

    _entitiesStateProvider =
        HomeAssistantStateProvider(configStateProvider: _configStateProvider);

    _entitiesStateProvider.init();
  }

  StateProvider<List<Entity>> entitiesStateProvider() {
    return _entitiesStateProvider;
  }

  SettingsItem makeSettings() {
    return SettingsItem.details(
        icon: GenericIcon.fromImage(
          image: Image.network(
              'https://community-assets.home-assistant.io/original/3X/6/3/63f75921214e158bc02336dc864c096b11889f14.png'),
        ),
        name: 'Home Assistant',
        details: DetailsPage(
            title: Text('Home Assistant Settings'),
            body: HomeAssistantConfigWidget(
              stateProvider: _configStateProvider,
            )));
  }
}
