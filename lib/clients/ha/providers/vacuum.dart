import 'package:home_assistant_ws/home_assistant_ws.dart';
import 'package:nexus/clients/state.dart';
import 'package:nexus/clients/ha/models/vacuum.dart';

class VacuumStateProvider extends StateProvider<Vacuum> {
  final StateProvider<Entity> entityProvider;
  final void Function(Vacuum) requestState;

  VacuumStateProvider({required this.entityProvider, required this.requestState});

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
  void requestValue(Vacuum value) {
    requestState(value);
  }

  void _onEntityChanged(Entity? entity) {
    if (entity == null || entity.state == null) {
      setValue(null);
      return;
    }

    setValue(Vacuum(
      status: entity.state!,
      fanSpeed: entity.attributes?.fanSpeed,
      fanSpeeds: entity.attributes?.fanSpeedList ?? const [],
    ));
  }
}
