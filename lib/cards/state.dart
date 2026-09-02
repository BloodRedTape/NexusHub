import 'package:flutter/material.dart';
import 'package:nexus/clients/state.dart';

abstract class StateCard<T> extends StatefulWidget {
  final StateProvider<T> stateProvider;

  const StateCard({
    required this.stateProvider,
  });

  @override
  State<StatefulWidget> createState() => _SwitchCardState<T>();

  Widget build(BuildContext context, T? state);

  void setState(T state) {
    stateProvider.requestValue(state);
  }
}

class _SwitchCardState<T> extends State<StateCard<T>> {
  T? _state;

  @override
  void initState() {
    super.initState();
    widget.stateProvider.bindValueChanged(onValueChanged);
  }

  @override
  void dispose() {
    widget.stateProvider.unbind(onValueChanged);
    super.dispose();
  }

  void onValueChanged(T? value) {
    setState(() {
      _state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.build(context, _state);
  }
}
