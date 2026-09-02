import 'dart:async';

import 'package:flutter/material.dart';
import 'package:home_assistant_ws/home_assistant_ws.dart';
import 'package:intl/intl.dart';
import 'package:nexus/cards/details.dart';
import 'package:nexus/clients/config_storage.dart';
import 'package:nexus/clients/ha/config.dart';
import 'package:nexus/clients/ha/debug.dart';
import 'package:nexus/clients/state.dart';

class HomeAssistantClientState {
  String status;
  String? url;
  bool hasToken;
  DateTime? lastConnected;
  final List<String> log;

  HomeAssistantClientState({required this.status, this.url, this.hasToken = false, this.lastConnected, List<String>? log}) : log = log ?? [];
}

/// The socket and the config behind it: connecting, reconnecting, keeping the
/// connection alive and writing down what happened. It knows nothing about
/// entities or areas - whoever needs those hangs off [onConnected].
class HomeAssistantConnection {
  static const _pingInterval = Duration(seconds: 30);
  static const _logLimit = 500;

  static final _fallback = HomeAssistantConfig(token: '', url: 'https://ha.raspberry.lan');

  final _storage = const ConfigStorage('HOME_ASSISTANT_CONFIG');
  final _state = StateProvider<HomeAssistantClientState>();
  final List<String> _log = [];

  HomeAssistantConfig _config = _fallback;
  HomeAssistantWs? _ws;
  Timer? _pingPongTimer;

  String? _wsUrl;
  bool _hasToken = false;
  DateTime? _lastConnected;

  Future<void>? _restartFuture;
  HomeAssistantConfig? _pendingConfig;

  HomeAssistantConfig get config => _config;

  /// Null whenever the socket is down - every service call has to cope with it.
  HomeAssistantWs? get ws => _ws;

  /// Entity updates, straight off the socket.
  void Function(EventMessage event)? onEvent;

  /// Dropped state: called before every connect attempt, with the config that
  /// is about to be used, or null when there is none.
  void Function(HomeAssistantConfig? config)? onReset;

  /// The socket is up. Whatever it loads is reported back as the log line.
  Future<String> Function(HomeAssistantWs ha)? onConnected;

  /// Kept out of the constructor so the callbacks above are wired first.
  void start() {
    _loadConfig();

    _setStatus('Initialized', detail: 'Client initialized');
  }

  Future<void> _loadConfig() async {
    final stored = await _storage.read();

    // Settings written by an older build can stop parsing; the default stands.
    final loaded = stored == null ? null : HomeAssistantConfig.deserialize(stored);

    if (loaded != null) _config = loaded;

    _reconnect(_config);
  }

  void saveConfig(HomeAssistantConfig config) {
    _config = config;

    _storage.write(HomeAssistantConfig.serialize(config));
    _reconnect(config);
  }

  void reconnect() {
    _setStatus('reconnecting...', detail: 'Manual reconnect requested');
    _reconnect(_config);
  }

  void _setStatus(String status, {String? detail}) {
    if (detail != null) {
      _log.add('${DateFormat('HH:mm:ss').format(DateTime.now())}  $detail');
      if (_log.length > _logLimit) _log.removeRange(0, _log.length - _logLimit);
    }

    _state.setValue(
      HomeAssistantClientState(
        status: status,
        url: _wsUrl,
        hasToken: _hasToken,
        lastConnected: _lastConnected,
        log: List.from(_log.reversed),
      ),
    );
  }

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

  Future<void> _restartConnection(HomeAssistantConfig? config) async {
    _setStatus('disconnecting...');

    onReset?.call(config);

    _pingPongTimer?.cancel();
    await _ws?.disconnect();

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

    _ws = HomeAssistantWs(
      token: config.token,
      baseUrl: _wsUrl!,
      onDone: _onDone,
      onError: _onError,
    );
    final ha = _ws!;

    try {
      await ha.connectOrThrow(unsafe: true);
    } on ConnectionError catch (e) {
      _setStatus(e.kind.name, detail: e.description);
      return;
    } catch (e) {
      _setStatus('Connect failed', detail: 'connect() threw: ${describe(e)}');
      return;
    }

    ha.subscribeEntities((event) => onEvent?.call(event));

    try {
      _setStatus('connected', detail: await onConnected?.call(ha));
    } catch (e) {
      _setStatus('connected', detail: 'Failed to load registries: ${describe(e)}');
    }

    _pingPongTimer = Timer.periodic(_pingInterval, (_) async {
      try {
        await ha.ping();
      } catch (e) {
        _setStatus('ping failed', detail: 'Ping failed: ${describe(e)}');
      }
    });

    _lastConnected = DateTime.now();
    _setStatus('connected', detail: 'Connected to $_wsUrl');
  }

  void _onDone() {
    _setStatus('disconnected', detail: 'Socket closed by the other side');
  }

  void _onError(dynamic error) {
    _setStatus('Error', detail: 'Socket error: ${describe(error)}');
  }

  /// The connection log. Its own page: it has a scroll of its own and does not
  /// belong inside the settings list.
  void openDiagnostics(BuildContext context) {
    DetailsPage(
      title: Text('Connection'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: HomeAssistantDebugWidget(stateProvider: _state, onReconnect: reconnect),
      ),
    ).navigateTo(context);
  }

  void dispose() {
    _pingPongTimer?.cancel();
    _ws?.disconnect();
  }
}

String describe(dynamic e) => '${e.runtimeType}: $e';
