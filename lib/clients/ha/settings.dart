import 'package:flutter/material.dart';
import 'package:nexus/clients/ha/config.dart';
import 'package:nexus/providers/state.dart';
import 'package:nexus/utils/settings_section.dart';

class HomeAssistantConfigWidget extends StatefulWidget {
  final StateProvider<HomeAssistantConfig> stateProvider;

  /// Opens the connection diagnostics page.
  final void Function(BuildContext context) openDiagnostics;

  HomeAssistantConfigWidget({required this.stateProvider, required this.openDiagnostics});

  @override
  _HomeAssistantConfigWidgetState createState() =>
      _HomeAssistantConfigWidgetState();
}

class _HomeAssistantConfigWidgetState extends State<HomeAssistantConfigWidget> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();

    widget.stateProvider.bindValueChanged(_onConfigChanged);
  }

  bool _hideUnavailable = true;
  bool _hideEmptyAreas = true;

  void _onConfigChanged(HomeAssistantConfig? config) {
    if (config == null) return;

    _urlController.text = config.url.toString();
    _tokenController.text = config.token.toString();
    _hideUnavailable = config.hideUnavailable;
    _hideEmptyAreas = config.hideEmptyAreas;
  }

  /// Flags apply right away - unlike the text fields, which are saved on close.
  Widget _flag(String title, String subtitle, IconData icon, bool value, void Function(bool) apply) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: (newValue) {
        setState(() => apply(newValue));

        widget.stateProvider.setValue(HomeAssistantConfig(
          url: _urlController.text,
          token: _tokenController.text,
          hideUnavailable: _hideUnavailable,
          hideEmptyAreas: _hideEmptyAreas,
        ));
      },
    );
  }

  @override
  void dispose() {
    final current = widget.stateProvider.getValue();

    if (current?.url != _urlController.text || current?.token != _tokenController.text) {
      widget.stateProvider.setValue(
        HomeAssistantConfig(
          url: _urlController.text,
          token: _tokenController.text,
          hideUnavailable: _hideUnavailable,
          hideEmptyAreas: _hideEmptyAreas,
        ),
      );
    }
    widget.stateProvider.unbind(_onConfigChanged);
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
          helperText: 'Saved when you leave this screen',
          icon: Icons.link,
          keyboardType: TextInputType.url,
        ),
        SettingsTextField(
          controller: _tokenController,
          label: 'Bearer Token',
          helperText: 'Long lived access token from your HA profile',
          icon: Icons.key,
        ),
        Divider(height: 1),
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
        Divider(height: 1),
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
