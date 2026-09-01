import 'package:flutter/material.dart';
import 'package:nexus/clients/android/config.dart';
import 'package:nexus/providers/state.dart';

class AndroidConfigWidget extends StatefulWidget {
  final StateProvider<AndroidConfig> stateProvider;

  AndroidConfigWidget({required this.stateProvider});

  @override
  _AndroidConfigWidgetState createState() => _AndroidConfigWidgetState();
}

class _AndroidConfigWidgetState extends State<AndroidConfigWidget> {
  bool _autoBrightnessEnabled = false;
  double _brightnessThreshold = 70.0;
  List<ScreenOnInterval> _screenOnIntervals = const [];

  @override
  void initState() {
    super.initState();

    widget.stateProvider.bindValueChanged(_onConfigChanged);
  }

  void _onConfigChanged(AndroidConfig? config) {
    if (config == null) return;

    setState(() {
      _autoBrightnessEnabled = config.autoBrightnessEnabled;
      _brightnessThreshold = config.brightnessThreshold;
      _screenOnIntervals = config.screenOnIntervals;
    });
  }

  void _save() {
    widget.stateProvider.setValue(
      AndroidConfig(
        autoBrightnessEnabled: _autoBrightnessEnabled,
        brightnessThreshold: _brightnessThreshold,
        screenOnIntervals: _screenOnIntervals,
      ),
    );
  }

  Future<void> _editInterval({ScreenOnInterval? existing, int? index}) async {
    final start = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (existing?.startMinutes ?? 510) ~/ 60, minute: (existing?.startMinutes ?? 510) % 60),
      helpText: 'Screen on from',
    );

    if (start == null || !mounted) return;

    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (existing?.endMinutes ?? 600) ~/ 60, minute: (existing?.endMinutes ?? 600) % 60),
      helpText: 'Screen on until',
    );

    if (end == null) return;

    final interval = ScreenOnInterval(
      startMinutes: start.hour * 60 + start.minute,
      endMinutes: end.hour * 60 + end.minute,
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

  void _removeInterval(int index) {
    setState(() {
      _screenOnIntervals = List<ScreenOnInterval>.from(_screenOnIntervals)..removeAt(index);
    });

    _save();
  }

  @override
  void dispose() {
    _save();
    widget.stateProvider.unbind(_onConfigChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SwitchListTile(
            title: Text('Auto Brightness'),
            subtitle: Text('Adjust screen brightness based on room illuminance'),
            value: _autoBrightnessEnabled,
            onChanged: (bool value) {
              setState(() {
                _autoBrightnessEnabled = value;
              });
              _save();
            },
          ),
          SizedBox(height: 16),
          Text(
            'Brightness Threshold: ${_brightnessThreshold.toInt()} lux',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: _brightnessThreshold,
            min: 0,
            max: 200,
            divisions: 40,
            label: '${_brightnessThreshold.toInt()} lux',
            onChanged: _autoBrightnessEnabled
                ? (double value) {
                    setState(() {
                      _brightnessThreshold = value;
                    });
                  }
                : null,
            onChangeEnd: (double value) => _save(),
          ),
          SizedBox(height: 8),
          Text(
            'When illuminance > ${_brightnessThreshold.toInt()} lux: 100% brightness\nWhen illuminance ≤ ${_brightnessThreshold.toInt()} lux: 0% brightness',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Keep Screen On', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                icon: Icon(Icons.add),
                label: Text('Add'),
                onPressed: () => _editInterval(),
              ),
            ],
          ),
          Text(
            'Screen stays awake during these times while the launcher is running',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          for (int i = 0; i < _screenOnIntervals.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.schedule),
              title: Text(
                '${ScreenOnInterval.format(_screenOnIntervals[i].startMinutes)}'
                ' — ${ScreenOnInterval.format(_screenOnIntervals[i].endMinutes)}',
              ),
              onTap: () => _editInterval(existing: _screenOnIntervals[i], index: i),
              trailing: IconButton(
                icon: Icon(Icons.delete_outline),
                onPressed: () => _removeInterval(i),
              ),
            ),
        ],
      ),
    );
  }
}
