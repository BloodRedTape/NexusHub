class StateProvider<T> {
  final List<void Function(T?)> _onValueChanged = [];
  T? _state;

  void bindValueChanged(Function(T?) callback) {
    _onValueChanged.add(callback);
    callback(_state);
  }

  void unbind(Function(T?) callback) {
    _onValueChanged.remove(callback);
  }

  void init() {}

  void dispose() {}

  void setValue(T? value) {
    _state = value;

    for (final callback in _onValueChanged) {
      callback.call(value);
    }
  }

  void requestValue(T newValue) {}
}
