import 'dart:async';

import 'package:home_assistant/home_assistant.dart';
import 'package:nexus/clients/ha/config.dart';
import 'package:nexus/providers/state.dart';

class HomeAssistantStateProvider extends StateProvider<List<Entity>> {
  final StateProvider<HomeAssistantConfig> configStateProvider;
  HomeAssistantConfig? _config;
  Timer? _timer;

  HomeAssistantStateProvider({required this.configStateProvider});

  void _onConfigChanged(HomeAssistantConfig? config) {
    _config = config;

    _timer?.cancel();
    fetchData().then((_) {
      _timer = Timer.periodic(
          Duration(seconds: 30), (Timer t) async => await fetchData());
    });
  }

  @override
  void init() {
    super.init();

    configStateProvider.bindValueChanged(_onConfigChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();

    configStateProvider.unbind(_onConfigChanged);
    super.dispose();
  }

  Future<void> fetchData() async {
    final config = _config;

    if (config == null) {
      setValue(null);
      return;
    }

    try {
      final homeAssistant = HomeAssistant(
        baseUrl: config.url,
        bearerToken: config.token,
      );

      final entities = await homeAssistant.fetchStates();

      setValue(entities);
    } catch (e) {
      setValue(null);
    }
  }

  Future<bool> executeService(String entityId, String action) async {
    final config = _config;

    if (config == null) {
      return false;
    }

    try {
      final homeAssistant = HomeAssistant(
        baseUrl: config.url,
        bearerToken: config.token,
      );

      await homeAssistant.executeService(entityId, action);
      await fetchData();
      return true;
    } catch (e) {
      return false;
    }
  }
}
