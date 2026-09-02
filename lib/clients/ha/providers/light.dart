import 'dart:ui';

import 'package:home_assistant_ws/home_assistant_ws.dart';
import 'package:nexus/providers/state.dart';
import 'package:nexus/clients/ha/models/light.dart';

class LightStateProvider extends StateProvider<Light> {
  final StateProvider<Entity> entityProvider;
  final void Function(Light) requestLightState;

  LightStateProvider({required this.entityProvider, required this.requestLightState});

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
  void requestValue(Light value) {
    requestLightState(value);
  }

  void _onEntityChanged(Entity? entity) {
    if (entity == null) {
      setValue(null);
      return;
    }

    Entity light = entity;

    bool? isOn = _parseOnState(light.state);

    if (isOn == null) {
      setValue(null);
      return;
    }

    Light newState = Light(
      isOn: isOn,
      brightness: _parseBrightnessState(light.attributes),
      temperature: _parseTemperatureState(light.attributes),
      color: _parseColorState(light.attributes),
    );

    setValue(newState);
  }

  bool? _parseOnState(String? state) {
    if (state == 'on') return true;
    if (state == 'off') return false;
    return null;
  }

  LimitedValue? _parseBrightnessState(EntityAttributes? attributes) {
    if (attributes?.brightness == null) return null;

    return LimitedValue(value: attributes!.brightness!, min: 0, max: 255);
  }

  LimitedValue? _parseTemperatureState(EntityAttributes? attributes) {
    if (attributes?.temperature == null || attributes?.minTemp == null || attributes?.maxTemp == null) return null;

    return LimitedValue(value: attributes!.temperature!, min: attributes.minTemp!.toDouble(), max: attributes.maxTemp!.toDouble());
  }

  LightColor? _parseColorState(EntityAttributes? attributes) {
    if (attributes?.rgbColor == null || (attributes?.rgbColor?.length ?? 0) < 3) return null;

    final rgb = attributes!.rgbColor!;

    return LightColor(value: Color.fromRGBO(rgb[0], rgb[1], rgb[2], 1.0));
  }
}
