import 'package:home_assistant/home_assistant.dart';
import 'package:nexus/providers/state.dart';

class EntityStateProvider extends StateProvider<String> {
  final String entityId;
  final StateProvider<List<Entity>> entitiesStateProvider;

  EntityStateProvider({required this.entityId, required this.entitiesStateProvider});

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

  void _onEntitiesChanged(List<Entity>? entities) {
    List<Entity> filtered = (entities ?? []).where((e) => e.entityId == entityId).toList();

    if (filtered.isEmpty) {
      setValue(null);
      return;
    }

    setValue(filtered.first.state);
  }
}
