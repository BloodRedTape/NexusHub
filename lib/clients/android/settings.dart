import 'package:flutter/material.dart';
import 'package:nexus/clients/android/config.dart';
import 'package:nexus/providers/state.dart';

/// Android-settings style section header: accent coloured, above its tiles.
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class AndroidConfigWidget extends StatefulWidget {
  final StateProvider<AndroidConfig> stateProvider;

  /// Selectable binary sensors, by entity id and name.
  final Map<String, String> Function() binarySensors;

  /// Live state of one entity: 'on', 'off', 'unavailable', null when unknown.
  final StateProvider<String> Function(String entityId) entityState;

  AndroidConfigWidget({
    required this.stateProvider,
    required this.binarySensors,
    required this.entityState,
  });

  @override
  _AndroidConfigWidgetState createState() => _AndroidConfigWidgetState();
}

class _AndroidConfigWidgetState extends State<AndroidConfigWidget> {
  bool _autoBrightnessEnabled = false;
  double _brightnessThreshold = 70.0;
  List<ScreenOnInterval> _screenOnIntervals = const [];
  List<String> _screenOnSensors = const [];

  @override
  void initState() {
    super.initState();

    widget.stateProvider.bindValueChanged(_onConfigChanged);
  }

  /// Sensor state providers we are subscribed to, by entity id.
  final Map<String, StateProvider<String>> _sensorStates = {};

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

      _sensorStates[entityId] = widget.entityState(entityId)..bindValueChanged(_onSensorStateChanged);
    }
  }

  void _onConfigChanged(AndroidConfig? config) {
    if (config == null) return;

    _bindSensorStates(config.screenOnSensors);

    setState(() {
      _autoBrightnessEnabled = config.autoBrightnessEnabled;
      _brightnessThreshold = config.brightnessThreshold;
      _screenOnIntervals = config.screenOnIntervals;
      _screenOnSensors = config.screenOnSensors;
    });
  }

  void _save() {
    widget.stateProvider.setValue(
      AndroidConfig(
        autoBrightnessEnabled: _autoBrightnessEnabled,
        brightnessThreshold: _brightnessThreshold,
        screenOnIntervals: _screenOnIntervals,
        screenOnSensors: _screenOnSensors,
      ),
    );
  }

  @override
  void dispose() {
    _save();
    widget.stateProvider.unbind(_onConfigChanged);

    for (final provider in _sensorStates.values) {
      provider.unbind(_onSensorStateChanged);
    }

    super.dispose();
  }

  Future<void> _editInterval({required bool blocking, ScreenOnInterval? existing, int? index}) async {
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

    setState(() {
      final intervals = List<ScreenOnInterval>.from(_screenOnIntervals);

      if (index == null) {
        intervals.add(interval);
      } else {
        intervals[index] = interval;
      }

      _screenOnIntervals = intervals;
    });

    _save();
  }

  void _removeInterval(ScreenOnInterval interval) {
    setState(() {
      _screenOnIntervals = List<ScreenOnInterval>.from(_screenOnIntervals)..remove(interval);
    });

    _save();
  }

  Future<void> _addSensor() async {
    final available = widget.binarySensors()..removeWhere((id, _) => _screenOnSensors.contains(id));

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

    final sensors = [..._screenOnSensors, selected];

    _bindSensorStates(sensors);

    setState(() {
      _screenOnSensors = sensors;
    });

    _save();
  }

  void _removeSensor(String entityId) {
    final sensors = List<String>.from(_screenOnSensors)..remove(entityId);

    _bindSensorStates(sensors);

    setState(() {
      _screenOnSensors = sensors;
    });

    _save();
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
  }) {
    final intervals = _screenOnIntervals.where((interval) => interval.blocking == blocking).toList();

    return [
      _SectionHeader(title),
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
            existing: interval,
            index: _screenOnIntervals.indexOf(interval),
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: () => _removeInterval(interval),
          ),
        ),
      ListTile(
        leading: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
        title: Text(
          'Add time range',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        onTap: () => _editInterval(blocking: blocking),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final threshold = _brightnessThreshold.toInt();
    final sensorNames = widget.binarySensors();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: <Widget>[
        _SectionHeader('Display'),
        SwitchListTile(
          secondary: Icon(Icons.brightness_auto),
          title: Text('Auto brightness'),
          subtitle: Text('Adjust screen brightness based on room illuminance'),
          value: _autoBrightnessEnabled,
          onChanged: (bool value) {
            setState(() {
              _autoBrightnessEnabled = value;
            });
            _save();
          },
        ),
        ListTile(
          enabled: _autoBrightnessEnabled,
          leading: Icon(Icons.light_mode_outlined),
          title: Text('Brightness threshold'),
          subtitle: Text('Above $threshold lux full brightness, at or below it minimum'),
          trailing: Text('$threshold lux', style: Theme.of(context).textTheme.bodyMedium),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Slider(
            value: _brightnessThreshold,
            min: 0,
            max: 200,
            divisions: 40,
            label: '$threshold lux',
            onChanged: _autoBrightnessEnabled
                ? (double value) {
                    setState(() {
                      _brightnessThreshold = value;
                    });
                  }
                : null,
            onChangeEnd: (double value) => _save(),
          ),
        ),
        Divider(height: 1),
        ..._intervalSection(
          blocking: false,
          title: 'Keep screen on',
          subtitle: 'Screen stays awake during these times while the launcher is running',
          icon: Icons.lightbulb_outline,
        ),
        Divider(height: 1),
        ..._intervalSection(
          blocking: true,
          title: 'Never turn screen on',
          subtitle: 'Screen stays off during these times, whatever the schedule and the sensor say',
          icon: Icons.block,
        ),
        Divider(height: 1),
        _SectionHeader('Screen on sensors'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            _screenOnSensors.isEmpty
                ? 'Schedule alone decides when the screen turns on'
                : 'Any one of them being on lets the screen turn on',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        for (final sensor in _screenOnSensors)
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
                  onPressed: () => _removeSensor(sensor),
                ),
              ],
            ),
          ),
        ListTile(
          leading: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
          title: Text('Add sensor', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          onTap: _addSensor,
        ),
      ],
    );
  }
}
