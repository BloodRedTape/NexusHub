import 'package:home_assistant/home_assistant.dart';
import 'package:nexus/providers/state.dart';

class CurtainStateProvider extends StateProvider<double> {
  final String entityId;
  final StateProvider<List<Entity>> entitiesStateProvider;
  final void Function(double) requestState;

  CurtainStateProvider({required this.entityId, required this.entitiesStateProvider, required this.requestState});

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
  void requestValue(double newValue) {
    requestState(newValue);
  }

  void _onEntitiesChanged(List<Entity>? entities) {
    List<Entity> filtered = (entities ?? []).where((e) => e.entityId == entityId).toList();

    if (filtered.isEmpty) {
      setValue(null);
      return;
    }
    setValue(filtered.first.attributes.current_position);
  }
}
