import 'package:flutter/material.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/state.dart';
import 'package:nexus/consts.dart';
import 'package:nexus/providers/state.dart';
import 'package:nexus/utils/tint.dart';

/// A smart outlet: switchable, and reporting what it currently draws.
class OutletCard extends StateCard<bool> {
  final StateProvider<double> power;
  final String? name;

  const OutletCard({required super.stateProvider, required this.power, this.name});

  @override
  Widget build(BuildContext context, bool? state) {
    return PlainCardBase(
      icon: Icon(_icon(state), color: _iconColor(state), size: iconSize),
      color: state == true ? _onColor : null,
      action: state == null ? null : () => setState(!state),
      children: [
        StackedLayout(
          primary: FittedBox(
            alignment: Alignment.bottomLeft,
            fit: BoxFit.scaleDown,
            child: Text(_stateText(state), style: TextStyle(fontSize: primaryTextSize, fontWeight: FontWeight.bold)),
          ),
          secondary: _Power(stateProvider: power),
          name: name,
        ),
      ],
    );
  }

  static final _onColor = Tint.color(color: const Color.fromARGB(255, 255, 94, 0));

  String _stateText(bool? state) {
    if (state == null) return 'Unavailable';

    return state ? 'On' : 'Off';
  }

  IconData _icon(bool? state) {
    if (state == null) return Icons.error;

    return state ? Icons.power : Icons.power_off;
  }

  Color? _iconColor(bool? state) => state == true ? Colors.orangeAccent : Colors.white;
}

/// Current draw, redrawn on its own as the sensor updates.
class _Power extends StateCard<double> {
  const _Power({required super.stateProvider});

  @override
  Widget build(BuildContext context, double? state) {
    final text = state == null ? '-' : '${state.toStringAsFixed(state < 10 ? 1 : 0)} W';

    return Text(text, style: TextStyle(fontSize: secondaryTextSize));
  }
}
