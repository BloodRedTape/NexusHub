import 'package:home_assistant/home_assistant.dart';
import 'package:nexus/providers/state.dart';

class EntityStateProvider extends StateProvider<String> {
  final String entityId;
  final StateProvider<List<Entity>> entitiesStateProvider;

  EntityStateProvider(
      {required this.entityId, required this.entitiesStateProvider});

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
    List<Entity> filtered =
        (entities ?? []).where((e) => e.entityId == entityId).toList();

    if (filtered.isEmpty) {
      setValue(null);
      return;
    }

    setValue(filtered.first.state);
  }
}

class SensorStateProvider extends StateProvider<double> {
  final String entityId;
  final StateProvider<List<Entity>> entitiesStateProvider;

  SensorStateProvider(
      {required this.entityId, required this.entitiesStateProvider});

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
    List<Entity> filtered =
        (entities ?? []).where((e) => e.entityId == entityId).toList();

    if (filtered.isEmpty) {
      //print("Can't find $entityId from ${entities?.length} entities");
      setValue(null);
      return;
    }

    setValue(double.tryParse(filtered.first.state));
  }
}

class SwitchStateProvider extends StateProvider<bool> {
  final String entityId;
  final StateProvider<List<Entity>> entitiesStateProvider;
  final void Function(bool) requestState;

  SwitchStateProvider(
      {required this.entityId,
      required this.entitiesStateProvider,
      required this.requestState});

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
    List<Entity> filtered =
        (entities ?? []).where((e) => e.entityId == entityId).toList();

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

class CurtainStateProvider extends StateProvider<double> {
  final String entityId;
  final StateProvider<List<Entity>> entitiesStateProvider;
  final void Function(double) requestState;

  CurtainStateProvider(
      {required this.entityId,
      required this.entitiesStateProvider,
      required this.requestState});

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
    List<Entity> filtered =
        (entities ?? []).where((e) => e.entityId == entityId).toList();

    if (filtered.isEmpty) {
      setValue(null);
      return;
    }
    setValue(filtered.first.attributes.current_position);
  }
}
