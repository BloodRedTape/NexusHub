class StateProvider<T> {
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

class DummyStateProvider<T> extends StateProvider<T> {
  final T initialValue;

  DummyStateProvider({required this.initialValue});

  @override
  void onBound() {
    setValue(initialValue);
  }
}
