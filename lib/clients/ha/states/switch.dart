import 'package:home_assistant/home_assistant.dart';
import 'package:nexus/providers/state.dart' show StateProvider;

class SwitchStateProvider extends StateProvider<bool> {
  final String entityId;
  final StateProvider<List<Entity>> entitiesStateProvider;
  final void Function(bool) requestState;

  SwitchStateProvider({required this.entityId, required this.entitiesStateProvider, required this.requestState});

  @override
  void init() {
    super.init();
    entitiesStateProvider.bindValueChanged(_onEntitiesChanged);
  }

  @override
  void dispose() {
    entitiesStateProvider.unbind(_onEntitiesChanged);
    super.dispose();
  }

  @override
  void requestValue(bool value) {
    requestState(value);
  }

  void _onEntitiesChanged(List<Entity>? entities) {
    List<Entity> filtered = (entities ?? []).where((e) => e.entityId == entityId).toList();

    if (filtered.isEmpty) {
      setValue(null);
      return;
    }

    setValue(_parseState(filtered.first.state));
  }

  bool? _parseState(String state) {
    if (state == 'on') return true;
    if (state == 'off') return false;
    return null;
  }
}
