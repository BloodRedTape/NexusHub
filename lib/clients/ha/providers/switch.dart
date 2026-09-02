import 'package:home_assistant_ws/home_assistant_ws.dart';
import 'package:nexus/clients/state.dart' show StateProvider;

class SwitchStateProvider extends StateProvider<bool> {
  final StateProvider<Entity> entityProvider;
  final void Function(bool) requestState;

  SwitchStateProvider({required this.entityProvider, required this.requestState});

  @override
  void init() {
    super.init();
    entityProvider.bindValueChanged(_onEntityChanged);
  }

  @override
  void dispose() {
    entityProvider.unbind(_onEntityChanged);
    super.dispose();
  }

  @override
  void requestValue(bool value) {
    requestState(value);
  }

  void _onEntityChanged(Entity? entity) {
    if (entity == null) {
      setValue(null);
      return;
    }

    setValue(_parseState(entity.state));
  }

  bool? _parseState(String? state) {
    if (state == 'on') return true;
    if (state == 'off') return false;
    return null;
  }
}
