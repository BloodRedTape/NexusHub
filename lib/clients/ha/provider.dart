import 'dart:async';
import 'dart:convert';

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
      _timer = Timer.periodic(Duration(seconds: 60), (Timer t) async => await fetchData());
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

    if (config.token.isEmpty || config.url.isEmpty) {
      setValue(null);
      return;
    }

    try {
      final homeAssistant = HomeAssistant(
        baseUrl: config.url,
        bearerToken: config.token,
        allowUntrustedSsl: true,
      );

      final entities = await homeAssistant.fetchStates();

      setValue(entities);
    } catch (e) {
      setValue(null);
    }
  }

  Future<bool> executeServiceForEntity(String entityId, String action, {Map<String, dynamic> aditionalActions = const {}, bool refetch = true}) async {
    final config = _config;

    if (config == null) {
      return false;
    }

    try {
      final homeAssistant = HomeAssistant(
        baseUrl: config.url,
        bearerToken: config.token,
        allowUntrustedSsl: true,
      );

      await homeAssistant.executeServiceForEntity(entityId, action, additionalActions: aditionalActions);

      if (refetch) await fetchData();

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<ServiceResponse?> executeService(
      {required String domain, required String service, Map<String, dynamic> serviceData = const {}, bool returnResponse = true, bool refetch = true}) async {
    final config = _config;

    if (config == null) {
      return null;
    }

    try {
      final homeAssistant = HomeAssistant(
        baseUrl: config.url,
        bearerToken: config.token,
        allowUntrustedSsl: true,
      );

      ServiceResponse? response =
          await homeAssistant.executeService(domain: domain, service: service, serviceData: serviceData, returnResponse: returnResponse);

      if (refetch) await fetchData();

      return response;
    } catch (e) {
      print('HomeAssisant $e');
      return null;
    }
  }
}
