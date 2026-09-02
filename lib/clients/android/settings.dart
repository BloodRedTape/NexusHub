import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexus/clients/android/client.dart';
import 'package:nexus/clients/android/config.dart';
import 'package:nexus/clients/ha/client.dart';
import 'package:nexus/clients/state.dart';
import 'package:nexus/utils/settings_section.dart';

/// The form edits a whole [AndroidConfig], so the config itself is the state.
class AndroidFormCubit extends SettingsFormCubit<AndroidConfig> {
  final AndroidClient client;

  AndroidFormCubit(this.client) : super(client.config);

  void setAutoBrightness(bool value) => emit(state.copyWith(autoBrightnessEnabled: value));

  void setBrightnessThreshold(double value) => emit(state.copyWith(brightnessThreshold: value));

  void setIntervals(List<ScreenOnInterval> intervals) => emit(state.copyWith(screenOnIntervals: intervals));

  void setSensors(List<String> sensors) => emit(state.copyWith(screenOnSensors: sensors));

  /// Compared through JSON - the config carries no equality of its own.
  @override
  bool get dirty => jsonEncode(state.toJson()) != jsonEncode(client.config.toJson());

  @override
  void save() {
    client.saveConfig(state);

    // The client now matches the form; re-emit so the save button follows.
    emit(state.copyWith());
  }
}

class AndroidSettingsPage extends StatelessWidget {
  const AndroidSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AndroidFormCubit(context.read<AndroidClient>()),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Android Settings'),
            actions: [SettingsSaveButton(context.watch<AndroidFormCubit>())],
          ),
          body: const _AndroidForm(),
        ),
      ),
    );
  }
}

class _AndroidForm extends StatefulWidget {
  const _AndroidForm();

  @override
  State<_AndroidForm> createState() => _AndroidFormState();
}

class _AndroidFormState extends State<_AndroidForm> {
  late final AndroidFormCubit _form = context.read<AndroidFormCubit>();
  late final HomeAssistantClient _homeAssistant = context.read<HomeAssistantClient>();

  /// Sensor state providers we are subscribed to, by entity id.
  final Map<String, StateProvider<String>> _sensorStates = {};

  @override
  void initState() {
    super.initState();

    _bindSensorStates(_form.state.screenOnSensors);
  }

  @override
  void dispose() {
    for (final provider in _sensorStates.values) {
      provider.unbind(_onSensorStateChanged);
    }

    super.dispose();
  }

  Map<String, String> _binarySensors() => {
        for (final entry in _homeAssistant.binarySensors()) entry.entityId: entry.displayName,
      };

  void _onSensorStateChanged(String? _) {
    if (!mounted) return;

    // bindValueChanged calls back synchronously, which can land mid build or
    // inside another setState - repaint on the next frame instead.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _bindSensorStates(List<String> entityIds) {
    for (final entityId in _sensorStates.keys.toList()) {
      if (entityIds.contains(entityId)) continue;

      _sensorStates.remove(entityId)?.unbind(_onSensorStateChanged);
    }

    for (final entityId in entityIds) {
      if (_sensorStates.containsKey(entityId)) continue;

      _sensorStates[entityId] = _homeAssistant.entityStateProvider(entityId)..bindValueChanged(_onSensorStateChanged);
    }
  }

  Future<void> _editInterval({
    required bool blocking,
    required List<ScreenOnInterval> intervals,
    ScreenOnInterval? existing,
    int? index,
  }) async {
    final defaultStart = existing?.startMinutes ?? (blocking ? 1320 : 510);
    final defaultEnd = existing?.endMinutes ?? (blocking ? 480 : 600);

    final start = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: defaultStart ~/ 60, minute: defaultStart % 60),
      helpText: blocking ? 'Never turn screen on from' : 'Keep screen on from',
    );

    if (start == null || !mounted) return;

    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: defaultEnd ~/ 60, minute: defaultEnd % 60),
      helpText: blocking ? 'Never turn screen on until' : 'Keep screen on until',
    );

    if (end == null) return;

    final interval = ScreenOnInterval(
      startMinutes: start.hour * 60 + start.minute,
      endMinutes: end.hour * 60 + end.minute,
      blocking: blocking,
    );

    final edited = List<ScreenOnInterval>.from(intervals);

    if (index == null) {
      edited.add(interval);
    } else {
      edited[index] = interval;
    }

    _form.setIntervals(edited);
  }

  Future<void> _addSensor(List<String> sensors) async {
    final available = _binarySensors()..removeWhere((id, _) => sensors.contains(id));

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add screen on sensor'),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        // A shrink-wrapping ListView cannot report intrinsic dimensions, which
        // is what a dialog measures its content with - pin the width instead.
        content: available.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('No other binary sensors available'),
              )
            : SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
                child: ListView(
                  children: [
                    for (final sensor in available.entries)
                      ListTile(
                        title: Text(sensor.value, overflow: TextOverflow.ellipsis),
                        subtitle: Text(sensor.key, overflow: TextOverflow.ellipsis),
                        onTap: () => Navigator.pop(context, sensor.key),
                      ),
                  ],
                ),
              ),
      ),
    );

    if (selected == null) return;

    final edited = [...sensors, selected];

    _bindSensorStates(edited);
    _form.setSensors(edited);
  }

  void _removeSensor(List<String> sensors, String entityId) {
    final edited = List<String>.from(sensors)..remove(entityId);

    _bindSensorStates(edited);
    _form.setSensors(edited);
  }

  /// Current state of a chosen sensor, as an icon: on, off, unavailable, or
  /// missing from Home Assistant altogether.
  Icon _sensorStatus(String entityId) {
    final state = _sensorStates[entityId]?.getValue();
    final scheme = Theme.of(context).colorScheme;

    if (state == 'on') return Icon(Icons.check_circle, color: scheme.primary, size: 20);
    if (state == 'off') return Icon(Icons.circle_outlined, color: scheme.onSurfaceVariant, size: 20);

    return Icon(state == null ? Icons.help_outline : Icons.error_outline, color: scheme.error, size: 20);
  }

  /// Section header plus the intervals of one kind and their add row.
  List<Widget> _intervalSection({
    required bool blocking,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<ScreenOnInterval> all,
  }) {
    final intervals = all.where((interval) => interval.blocking == blocking).toList();

    return [
      SettingsSectionHeader(title),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ),
      for (final interval in intervals)
        ListTile(
          leading: Icon(icon),
          title: Text(
            '${ScreenOnInterval.format(interval.startMinutes)}'
            ' — ${ScreenOnInterval.format(interval.endMinutes)}',
          ),
          onTap: () => _editInterval(
            blocking: blocking,
            intervals: all,
            existing: interval,
            index: all.indexOf(interval),
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: () => _form.setIntervals(List<ScreenOnInterval>.from(all)..remove(interval)),
          ),
        ),
      ListTile(
        leading: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
        title: Text(
          'Add time range',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        onTap: () => _editInterval(blocking: blocking, intervals: all),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AndroidFormCubit>().state;
    final threshold = config.brightnessThreshold.toInt();
    final sensorNames = _binarySensors();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: <Widget>[
        SettingsSectionHeader('Display'),
        SwitchListTile(
          secondary: Icon(Icons.brightness_auto),
          title: Text('Auto brightness'),
          subtitle: Text('Adjust screen brightness based on room illuminance'),
          value: config.autoBrightnessEnabled,
          onChanged: _form.setAutoBrightness,
        ),
        ListTile(
          enabled: config.autoBrightnessEnabled,
          leading: Icon(Icons.light_mode_outlined),
          title: Text('Brightness threshold'),
          subtitle: Text('Above $threshold lux full brightness, at or below it minimum'),
          trailing: Text('$threshold lux', style: Theme.of(context).textTheme.bodyMedium),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Slider(
            value: config.brightnessThreshold,
            min: 0,
            max: 200,
            divisions: 40,
            label: '$threshold lux',
            onChanged: config.autoBrightnessEnabled ? _form.setBrightnessThreshold : null,
          ),
        ),
        ..._intervalSection(
          blocking: false,
          title: 'Keep screen on',
          subtitle: 'Screen stays awake during these times while the launcher is running',
          icon: Icons.lightbulb_outline,
          all: config.screenOnIntervals,
        ),
        ..._intervalSection(
          blocking: true,
          title: 'Never turn screen on',
          subtitle: 'Screen stays off during these times, whatever the schedule and the sensor say',
          icon: Icons.block,
          all: config.screenOnIntervals,
        ),
        SettingsSectionHeader('Screen on sensors'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            config.screenOnSensors.isEmpty ? 'Schedule alone decides when the screen turns on' : 'Any one of them being on lets the screen turn on',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        for (final sensor in config.screenOnSensors)
          ListTile(
            leading: Icon(Icons.sensors),
            title: Text(sensorNames[sensor] ?? sensor, overflow: TextOverflow.ellipsis),
            subtitle: Text(sensor, overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sensorStatus(sensor),
                IconButton(
                  icon: Icon(Icons.delete_outline),
                  onPressed: () => _removeSensor(config.screenOnSensors, sensor),
                ),
              ],
            ),
          ),
        ListTile(
          leading: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
          title: Text('Add sensor', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          onTap: () => _addSensor(config.screenOnSensors),
        ),
      ],
    );
  }
}
