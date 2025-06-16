import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/state.dart';
import 'package:nexus/consts.dart';
import 'package:nexus/states/light.dart';
import 'package:nexus/utils/generic_icon.dart';
import 'package:nexus/utils/tint.dart';

class LightCardSettings extends StateCard<LightState> {
  final IconData onIcon;
  final IconData offIcon;

  LightCardSettings({required this.onIcon, required this.offIcon, required super.stateProvider});

  @override
  Widget build(BuildContext context, LightState? state) {
    if (state == null) return Text('Unavailable');

    List<Widget> widgets = [];

    var color = state.color;
    if (color != null) {
      widgets.add(Text('Color', style: TextStyle(fontSize: secondaryTextSize)));
      widgets.add(ColorPicker(
        enableAlpha: false,
        pickerColor: color.value,
        onColorChanged: (newColor) => stateProvider
            .requestValue(LightState(isOn: state.isOn, brightness: state.brightness, color: ColorState(value: newColor), temperature: state.temperature)),
      ));
    }

    var brightness = state.brightness;
    if (brightness != null) {
      widgets.add(Text('Brightness', style: TextStyle(fontSize: secondaryTextSize)));
      widgets.add(Slider(
        value: brightness.value,
        min: brightness.min,
        max: brightness.max,
        onChanged: (value) => stateProvider.requestValue(LightState(
            isOn: state.isOn,
            brightness: LimitedValueState(value: value, min: brightness.min, max: brightness.max),
            color: state.color,
            temperature: state.temperature)),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

class LightCard extends StateCard<LightState> {
  final IconData onIcon;
  final IconData offIcon;
  final String? name;

  LightCard({required super.stateProvider, required this.onIcon, required this.offIcon, this.name});

  @override
  Widget build(BuildContext context, LightState? state) {
    if (state == null)
      return PlainCard(
        icon: Icons.error,
        text: 'Unavailable',
        subText: name,
      );

    return GestureDetector(
      onLongPress: () => _buildControlDialog(context),
      child: PlainCard(
        color: Tint.color(color: state.color?.value, fraction: 0.4),
        icon: _icon(state),
        iconColor: _iconColor(state),
        text: _stateToText(state),
        subText: name,
        action: () => switchState(state),
      ),
    );
  }

  Future<void> _buildControlDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(name ?? 'Light'),
          content: LightCardSettings(onIcon: onIcon, offIcon: offIcon, stateProvider: stateProvider),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(textStyle: Theme.of(context).textTheme.labelLarge),
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void switchState(LightState state) {
    stateProvider.requestValue(
      LightState(
        isOn: !state.isOn,
        brightness: state.brightness,
        color: state.color,
        temperature: state.temperature,
      ),
    );
  }

  String _stateToText(LightState? state) {
    if (state == null) return 'Unavailable';

    return state.isOn ? 'On' : 'Off';
  }

  IconData _icon(LightState? state) {
    if (state == null) {
      return Icons.error;
    }

    return state.isOn ? onIcon : offIcon;
  }

  Color _iconColor(LightState? state) {
    return state?.color?.value ?? Colors.white;
  }
}
