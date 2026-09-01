import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nexus/clients/ha/config.dart';
import 'package:nexus/config/config.dart';
import 'package:nexus/utils/settings_section.dart';

class HomeAssistantConfigWidget extends StatefulWidget {
  final HomeAssistantConfigCubit configCubit;

  /// Opens the connection diagnostics page.
  final void Function(BuildContext context) openDiagnostics;

  HomeAssistantConfigWidget({Key? key, required this.configCubit, required this.openDiagnostics})
      : super(key: key);

  @override
  _HomeAssistantConfigWidgetState createState() =>
      _HomeAssistantConfigWidgetState();
}

class _HomeAssistantConfigWidgetState extends State<HomeAssistantConfigWidget> implements SettingsSaver {
  StreamSubscription<HomeAssistantConfig>? _configSubscription;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  @override
  final ValueNotifier<bool> dirty = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    _onConfigChanged(widget.configCubit.state);
    _configSubscription = widget.configCubit.stream.listen(_onConfigChanged);
    _urlController.addListener(_refreshDirty);
    _tokenController.addListener(_refreshDirty);
  }

  void _refreshDirty() {
    final current = widget.configCubit.state;

    dirty.value = current.url != _urlController.text ||
        current.token != _tokenController.text ||
        current.hideUnavailable != _hideUnavailable ||
        current.hideEmptyAreas != _hideEmptyAreas;
  }

  bool _hideUnavailable = true;
  bool _hideEmptyAreas = true;

  void _onConfigChanged(HomeAssistantConfig config) {
    _urlController.text = config.url.toString();
    _tokenController.text = config.token.toString();
    _hideUnavailable = config.hideUnavailable;
    _hideEmptyAreas = config.hideEmptyAreas;

    _refreshDirty();
  }

  Widget _flag(String title, String subtitle, IconData icon, bool value, void Function(bool) apply) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: (newValue) {
        setState(() => apply(newValue));
        _refreshDirty();
      },
    );
  }

  @override
  void save() {
    widget.configCubit.save(
      HomeAssistantConfig(
        url: _urlController.text,
        token: _tokenController.text,
        hideUnavailable: _hideUnavailable,
        hideEmptyAreas: _hideEmptyAreas,
      ),
    );

    _refreshDirty();
  }

  @override
  void dispose() {
    _configSubscription?.cancel();
    dirty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: <Widget>[
        SettingsSectionHeader('Connection'),
        SettingsTextField(
          controller: _urlController,
          label: 'Home Assistant Url',
          icon: Icons.link,
          keyboardType: TextInputType.url,
        ),
        SettingsTextField(
          controller: _tokenController,
          label: 'Bearer Token',
          helperText: 'Long lived access token from your HA profile',
          icon: Icons.key,
        ),
        SettingsSectionHeader('Dashboard'),
        _flag(
          'Hide unavailable devices',
          'Devices Home Assistant reports as unavailable stay off the dashboard',
          Icons.visibility_off_outlined,
          _hideUnavailable,
          (value) => _hideUnavailable = value,
        ),
        _flag(
          'Hide rooms without devices',
          'Areas with nothing to show are skipped',
          Icons.meeting_room_outlined,
          _hideEmptyAreas,
          (value) => _hideEmptyAreas = value,
        ),
        SettingsSectionHeader('Diagnostics'),
        ListTile(
          leading: Icon(Icons.lan_outlined),
          title: Text('Connection status'),
          subtitle: Text('Socket state, reconnect and the message log'),
          trailing: Icon(Icons.chevron_right),
          onTap: () => widget.openDiagnostics(context),
        ),
      ],
    );
  }
}
