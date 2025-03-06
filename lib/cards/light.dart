import 'package:flutter/material.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/state.dart';
import 'package:nexus/states/light.dart';
import 'package:nexus/utils/tint.dart';

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

    return PlainCard(
      color: Tint.color(color: state.color?.value, fraction: 0.4),
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

  Color _iconColor(LightState? state) {
    return state?.color?.value ?? Colors.white;
  }
}
