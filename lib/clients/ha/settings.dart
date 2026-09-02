import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexus/clients/ha/client.dart';
import 'package:nexus/clients/ha/config.dart';
import 'package:nexus/utils/settings_section.dart';

/// The connection settings as edited. Url and token stay text so a half typed
/// address is something the form can hold.
class HomeAssistantFormState {
  final String url;
  final String token;
  final bool hideUnavailable;
  final bool hideEmptyAreas;
  final bool showAutomations;
  final String calendarEntity;

  const HomeAssistantFormState({
    required this.url,
    required this.token,
    required this.hideUnavailable,
    required this.hideEmptyAreas,
    required this.showAutomations,
    required this.calendarEntity,
  });

  HomeAssistantFormState copyWith({
    String? url,
    String? token,
    bool? hideUnavailable,
    bool? hideEmptyAreas,
    bool? showAutomations,
    String? calendarEntity,
  }) {
    return HomeAssistantFormState(
      url: url ?? this.url,
      token: token ?? this.token,
      hideUnavailable: hideUnavailable ?? this.hideUnavailable,
      hideEmptyAreas: hideEmptyAreas ?? this.hideEmptyAreas,
      showAutomations: showAutomations ?? this.showAutomations,
      calendarEntity: calendarEntity ?? this.calendarEntity,
    );
  }
}

class HomeAssistantFormCubit extends SettingsFormCubit<HomeAssistantFormState> {
  final HomeAssistantClient client;

  HomeAssistantFormCubit(this.client)
      : super(HomeAssistantFormState(
          url: client.config.url,
          token: client.config.token,
          hideUnavailable: client.config.hideUnavailable,
          hideEmptyAreas: client.config.hideEmptyAreas,
          showAutomations: client.config.showAutomations,
          calendarEntity: client.config.calendarEntity,
        ));

  void setUrl(String url) => emit(state.copyWith(url: url));

  void setToken(String token) => emit(state.copyWith(token: token));

  void setHideUnavailable(bool value) => emit(state.copyWith(hideUnavailable: value));

  void setHideEmptyAreas(bool value) => emit(state.copyWith(hideEmptyAreas: value));

  void setShowAutomations(bool value) => emit(state.copyWith(showAutomations: value));

  void setCalendarEntity(String value) => emit(state.copyWith(calendarEntity: value));

  HomeAssistantConfig get _edited => HomeAssistantConfig(
        url: state.url,
        token: state.token,
        hideUnavailable: state.hideUnavailable,
        hideEmptyAreas: state.hideEmptyAreas,
        showAutomations: state.showAutomations,
        calendarEntity: state.calendarEntity,
      );

  @override
  bool get dirty {
    final current = client.config;

    return current.url != state.url ||
        current.token != state.token ||
        current.hideUnavailable != state.hideUnavailable ||
        current.hideEmptyAreas != state.hideEmptyAreas ||
        current.showAutomations != state.showAutomations ||
        current.calendarEntity != state.calendarEntity;
  }

  @override
  void save() {
    client.saveConfig(_edited);

    // The client now matches the form; re-emit so the save button follows.
    emit(state.copyWith());
  }
}

class HomeAssistantSettingsPage extends StatelessWidget {
  const HomeAssistantSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeAssistantFormCubit(context.read<HomeAssistantClient>()),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Home Assistant Settings'),
            actions: [SettingsSaveButton(context.watch<HomeAssistantFormCubit>())],
          ),
          body: const _HomeAssistantForm(),
        ),
      ),
    );
  }
}

class _HomeAssistantForm extends StatefulWidget {
  const _HomeAssistantForm();

  @override
  State<_HomeAssistantForm> createState() => _HomeAssistantFormState();
}

class _HomeAssistantFormState extends State<_HomeAssistantForm> {
  late final HomeAssistantFormCubit _form = context.read<HomeAssistantFormCubit>();
  late final TextEditingController _urlController = TextEditingController(text: _form.state.url);
  late final TextEditingController _tokenController = TextEditingController(text: _form.state.token);

  @override
  void initState() {
    super.initState();

    _urlController.addListener(() => _form.setUrl(_urlController.text));
    _tokenController.addListener(() => _form.setToken(_tokenController.text));
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  /// Calendars, as the registry knows them, with an entry for picking none.
  Future<void> _pickCalendar(String selected) async {
    final calendars = _form.client.entitiesOfDomain('calendar');

    final picked = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Glance calendar'),
        children: calendars.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text('Home Assistant reports no calendar entities'),
                )
              ]
            : [
                ListTile(
                  leading: Icon(Icons.block),
                  title: Text('None'),
                  selected: selected.isEmpty,
                  onTap: () => Navigator.pop(context, ''),
                ),
                for (final calendar in calendars)
                  ListTile(
                    leading: Icon(Icons.event),
                    title: Text(calendar.displayName, overflow: TextOverflow.ellipsis),
                    subtitle: Text(calendar.entityId, overflow: TextOverflow.ellipsis),
                    selected: calendar.entityId == selected,
                    onTap: () => Navigator.pop(context, calendar.entityId),
                  ),
              ],
      ),
    );

    if (picked != null) _form.setCalendarEntity(picked);
  }

  Widget _flag(String title, String subtitle, IconData icon, bool value, void Function(bool) apply) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: apply,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HomeAssistantFormCubit>().state;

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
          state.hideUnavailable,
          _form.setHideUnavailable,
        ),
        _flag(
          'Hide rooms without cards',
          'Areas with nothing to show are skipped',
          Icons.meeting_room_outlined,
          state.hideEmptyAreas,
          _form.setHideEmptyAreas,
        ),
        _flag(
          'Show automations',
          'Rooms with automations get a card for switching them on and off',
          Icons.auto_awesome_outlined,
          state.showAutomations,
          _form.setShowAutomations,
        ),
        ListTile(
          leading: Icon(Icons.event_outlined),
          title: Text('Glance calendar'),
          subtitle: Text(state.calendarEntity.isEmpty ? 'Not selected' : state.calendarEntity),
          trailing: Icon(Icons.chevron_right),
          onTap: () => _pickCalendar(state.calendarEntity),
        ),
        SettingsSectionHeader('Diagnostics'),
        ListTile(
          leading: Icon(Icons.lan_outlined),
          title: Text('Connection status'),
          subtitle: Text('Socket state, reconnect and the message log'),
          trailing: Icon(Icons.chevron_right),
          onTap: () => _form.client.openDiagnostics(context),
        ),
      ],
    );
  }
}
