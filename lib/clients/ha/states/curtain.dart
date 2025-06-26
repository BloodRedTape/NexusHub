import 'package:home_assistant_ws/home_assistant_ws.dart';
import 'package:nexus/providers/state.dart';

class CurtainStateProvider extends StateProvider<double> {
  final StateProvider<Entity> entityProvider;
  final void Function(double) requestState;

  CurtainStateProvider({required this.entityProvider, required this.requestState});

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
  void requestValue(double newValue) {
    requestState(newValue);
  }

  void _onEntityChanged(Entity? entity) {
    if (entity == null) {
      setValue(null);
      return;
    }
    setValue(entity.attributes?.currentPosition);
  }
}
