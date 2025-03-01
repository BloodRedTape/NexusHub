import 'package:nexus/providers/state.dart';

class DummyStateProvider<T> extends StateProvider<T> {
  final T initialValue;

  DummyStateProvider({required this.initialValue}) {
    init();
  }

  @override
  void init() {
    setValue(initialValue);
  }

  @override
  void requestValue(T newValue) {
    setValue(newValue);
  }
}
