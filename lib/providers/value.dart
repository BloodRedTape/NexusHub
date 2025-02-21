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
