import 'package:flutter/material.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/state.dart';
import 'package:nexus/states/light.dart';

class LightCard extends StateCard<LightState> {
  final IconData onIcon;
  final IconData offIcon;
  final String? name;

  LightCard({required super.stateProvider, required this.onIcon, required this.offIcon, this.name});

  @override
  Widget build(BuildContext context, LightState? state) {
    if (state == null) return PlainCard(icon: Icons.error, text: 'Unavailable');

    return PlainCard(
      color: _color(state),
      icon: _icon(state),
      iconColor: _iconColor(state),
      text: _stateToText(state),
      subText: name,
      action: () => switchState(state),
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

  Color? _color(LightState? state) {
    final double fraction = 0.4;
    final Color? color = state?.color?.value;

    if (color == null) return null;

    return Color.fromARGB(255, (color.r * fraction * 255).toInt(), (color.g * fraction * 255).toInt(), (color.b * fraction * 255).toInt());
  }

  Color _iconColor(LightState? state) {
    return state?.color?.value ?? Colors.white;
  }
}
