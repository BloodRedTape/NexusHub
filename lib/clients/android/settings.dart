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
    });
  }

  @override
  void dispose() {
    widget.stateProvider.setValue(
      AndroidConfig(
        autoBrightnessEnabled: _autoBrightnessEnabled,
        brightnessThreshold: _brightnessThreshold,
      ),
    );
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
              widget.stateProvider.setValue(
                AndroidConfig(
                  autoBrightnessEnabled: value,
                  brightnessThreshold: _brightnessThreshold,
                ),
              );
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
            onChangeEnd: (double value) {
              widget.stateProvider.setValue(
                AndroidConfig(
                  autoBrightnessEnabled: _autoBrightnessEnabled,
                  brightnessThreshold: value,
                ),
              );
            },
          ),
          SizedBox(height: 8),
          Text(
            'When illuminance > ${_brightnessThreshold.toInt()} lux: 100% brightness\nWhen illuminance ≤ ${_brightnessThreshold.toInt()} lux: 0% brightness',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
