import 'package:home_assistant_ws/home_assistant_ws.dart';
import 'package:nexus/providers/state.dart';

class SensorStateProvider extends StateProvider<double> {
  final StateProvider<Entity> entityProvider;
  SensorStateProvider({required this.entityProvider});

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
    if (entity == null || entity.state == null) {
      setValue(null);
      return;
    }

    setValue(double.tryParse(entity.state!));
  }
}
