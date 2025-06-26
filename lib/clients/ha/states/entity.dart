import 'package:home_assistant_ws/home_assistant_ws.dart';
import 'package:nexus/providers/state.dart';

class EntityStateProvider extends StateProvider<String> {
  final StateProvider<Entity> entityProvider;
  EntityStateProvider({required this.entityProvider});

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

  void _onEntityChanged(Entity? entity) {
    if (entity == null) {
      setValue(null);
      return;
    }

    setValue(entity.state);
  }
}
