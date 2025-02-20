import 'package:flutter/material.dart';
import 'package:nexus/core/base_card.dart';

class ValueStateProvider<T> {
  Function(T?)? _onValueChanged;

  void bindSwitchChanged(Function(T?) callback) {
    _onValueChanged = callback;
    onBound();
  }

  void onBound() {}

  void setValue(T? value) {
    _onValueChanged?.call(value);
  }
}

class DummyValueStateProvider<T> extends ValueStateProvider<T> {
  final T initialValue;

  DummyValueStateProvider({required this.initialValue});

  @override
  void onBound() {
    setValue(initialValue);
  }
}

class ValueCard<T> extends StatefulWidget {
  final ValueStateProvider<T> stateProvider;
  final Widget Function(T?) childFactory;
  final Color? Function(T?)? colorFactory;

  ValueCard({
    required this.childFactory,
    required this.stateProvider,
    this.colorFactory,
  });

  @override
  State<StatefulWidget> createState() => _SwitchCardState<T>();
}

class _SwitchCardState<T> extends State<ValueCard<T>> {
  T? _state;

  @override
  void initState() {
    super.initState();

    widget.stateProvider.bindSwitchChanged(onValueChanged);
  }

  void onValueChanged(T? value) {
    setState(() {
      _state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      color: widget.colorFactory?.call(_state),
      child: widget.childFactory(_state),
    );
  }
}
