import 'dart:ui';

import 'package:home_assistant/home_assistant.dart';
import 'package:nexus/providers/state.dart';
import 'package:nexus/states/light.dart';

class LightStateProvider extends StateProvider<LightState> {
  final String entityId;
  final StateProvider<List<Entity>> entitiesStateProvider;
  final void Function(LightState) requestLightState;

  LightStateProvider({required this.entityId, required this.entitiesStateProvider, required this.requestLightState});

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
  void requestValue(LightState value) {
    requestLightState(value);
  }

  void _onEntitiesChanged(List<Entity>? entities) {
    List<Entity> filtered = (entities ?? []).where((e) => e.entityId == entityId).toList();

    if (filtered.isEmpty) {
      setValue(null);
      return;
    }

    Entity light = filtered.first;

    bool? isOn = _parseOnState(light.state);

    if (isOn == null) {
      setValue(null);
      return;
    }

    LightState newState = LightState(
      isOn: isOn,
      brightness: _parseBrightnessState(light.attributes),
      temperature: _parseTemperatureState(light.attributes),
      color: _parseColorState(light.attributes),
    );

    setValue(newState);
  }

  bool? _parseOnState(String state) {
    if (state == 'on') return true;
    if (state == 'off') return false;
    return null;
  }

  LimitedValueState? _parseBrightnessState(EntityAttributes attributes) {
    if (attributes.brightness == null) return null;

    return LimitedValueState(value: attributes.brightness!, min: 0, max: 255);
  }

  LimitedValueState? _parseTemperatureState(EntityAttributes attributes) {
    if (attributes.temperature == null || attributes.minTemp == null || attributes.maxTemp == null) return null;

    return LimitedValueState(value: attributes.temperature!, min: attributes.minTemp!.toDouble(), max: attributes.maxTemp!.toDouble());
  }

  ColorState? _parseColorState(EntityAttributes attributes) {
    if (attributes.rgbColor == null || attributes.rgbColor!.length < 3) return null;

    final rgb = attributes.rgbColor!;

    return ColorState(value: Color.fromRGBO(rgb[0], rgb[1], rgb[2], 1.0));
  }
}
