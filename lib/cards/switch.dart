import 'package:flutter/material.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/state.dart';

class SwitchCard extends StateCard<bool> {
  final IconData onIcon;
  final IconData offIcon;
  final Color? onIconColor;
  final Color? offIconColor;
  final Color? onColor;
  final Color? offColor;
  final String? room;
  final bool compact;

  SwitchCard(
      {required super.stateProvider,
      required this.onIcon,
      required this.offIcon,
      this.onIconColor,
      this.offIconColor,
      this.onColor,
      this.offColor,
      this.room,
      this.compact = false});

  @override
  Widget build(BuildContext context, bool? state) {
    return PlainCard(
      color: _color(state),
      icon: _icon(state),
      iconColor: _iconColor(state),
      text: _stateToText(state),
      subText: room,
      action: () => switchState(state),
      compact: compact,
    );
  }

  void switchState(bool? state) {
    if (state == null) return;

    setState(!state);
  }

  String _stateToText(bool? state) {
    if (state == null) return 'Unavailable';

    return state ? 'On' : 'Off';
  }

  IconData _icon(bool? state) {
    if (state == null) {
      return Icons.error;
    }

    return state ? onIcon : offIcon;
  }

  Color? _color(bool? state) {
    if (state == null) return null;

    return state ? onColor : offColor;
  }

  Color? _iconColor(bool? state) {
    if (state == null) {
      return Colors.white;
    }

    return state ? onIconColor : offColor;
  }
}
