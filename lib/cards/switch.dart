import 'package:flutter/material.dart';
import 'package:nexus/cards/base.dart';
import 'package:nexus/providers/state.dart';

class SwitchCard extends StatefulWidget {
  final StateProvider<bool> stateProvider;
  final Widget Function(bool?) childFactory;
  final Color? Function(bool?)? colorFactory;

  SwitchCard({
    required this.childFactory,
    required this.stateProvider,
    this.colorFactory,
  });

  @override
  State<StatefulWidget> createState() => _SwitchCardState();
}

class _SwitchCardState extends State<SwitchCard> {
  bool? _state;

  void switchState() {
    if (_state == null) return;

    widget.stateProvider.setValue(!_state!);
  }

  @override
  void initState() {
    super.initState();

    widget.stateProvider.bindSwitchChanged(onSwitchChanged);
  }

  void onSwitchChanged(bool? value) {
    setState(() {
      _state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseCard(
        child: ElevatedButton(
          onPressed: switchState,
          child: widget.childFactory(_state),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero, // Ensure zero padding
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  30), // Optional: Match the card's border radius
            ),
          ),
        ),
        color: widget.colorFactory?.call(_state));
  }
}
