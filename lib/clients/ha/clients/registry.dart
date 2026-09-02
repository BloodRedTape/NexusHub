import 'package:home_assistant_ws/home_assistant_ws.dart';
import 'package:nexus/clients/ha/config.dart';
import 'package:nexus/providers/state.dart';

/// A device of an area together with the entities it exposes.
class DeviceEntities {
  final String? deviceId;
  final String name;
  final List<RegistryEntry> entities;

  /// Kind of every entity, by entity id - see [HomeAssistantRegistry.kindOf].
  final Map<String, String> kindsById;

  const DeviceEntities({required this.deviceId, required this.name, required this.entities, required this.kindsById});

  /// Entity kinds this device exposes.
  Set<String> get kinds => kindsById.values.toSet();

  /// First entity whose id ends with [suffix] - for integrations that name
  /// their entities meaningfully but leave the device class empty.
  RegistryEntry? entityEndingWith(String suffix) {
    for (final entry in entities) {
      if (entry.entityId.endsWith(suffix)) return entry;
    }

    return null;
  }

  RegistryEntry? entityOf(String kind) {
    for (final entry in entities) {
      if (kindsById[entry.entityId] == kind) return entry;
    }

    return null;
  }
}

/// What Home Assistant is made of, as the dashboard sees it: areas, the devices
/// in them and the entities of those devices. Every question it answers needs
/// the live entity state too, which it reads through [entityOf] rather than
/// keeping a copy of.
class HomeAssistantRegistry {
  final Entity? Function(String entityId) entityOf;

  HomeAssistantRegistry({required this.entityOf});

  final _areas = StateProvider<List<Area>>();

  /// Areas (rooms) as configured in Home Assistant, null until the first successful connect.
  StateProvider<List<Area>> get areas => _areas;

  /// Tells whether a device can be shown at all. Set by the dashboard, which
  /// owns the card matchers; without it every device counts as showable.
  bool Function(DeviceEntities device)? isDeviceShowable;

  List<RegistryEntry> _registry = [];
  List<Device> _devices = [];
  Map<String, String?> _deviceAreas = {};

  List<Area>? _pendingAreas;
  bool _hasStates = false;

  bool _hideUnavailable = true;
  bool _hideEmptyAreas = true;

  /// A new connection is starting: nothing loaded yet, and the filters come
  /// from the config that connection is about to use.
  void reset(HomeAssistantConfig? config) {
    _hasStates = false;
    _pendingAreas = null;

    _hideUnavailable = config?.hideUnavailable ?? true;
    _hideEmptyAreas = config?.hideEmptyAreas ?? true;
  }

  Future<String> load(HomeAssistantWs ha) async {
    final devices = await ha.getDevices();

    _devices = devices;
    _deviceAreas = {for (final device in devices) device.deviceId: device.areaId};
    _registry = await ha.getEntityRegistry();

    // entity states carry the device class the registry usually omits, so
    // hold the areas back until the first batch of states has arrived
    _pendingAreas = await ha.getAreas();
    _publishAreas();

    return 'Loaded ${_pendingAreas?.length ?? 0} areas, ${devices.length} devices, ${_registry.length} entities';
  }

  /// The first batch of entity states is in - the last thing areas waited on.
  void onStatesArrived() {
    _hasStates = true;
    _publishAreas();
  }

  /// Areas become visible once both the registries and the first states are in.
  void _publishAreas() {
    final areas = _pendingAreas;

    if (areas == null || !_hasStates) return;

    _pendingAreas = null;

    final counts = {for (final area in areas) area.areaId: _cardCount(area.areaId)};

    final result = areas.where((area) => !_hideEmptyAreas || counts[area.areaId]! > 0).toList();

    // busiest rooms first, alphabetical among equals
    result.sort((a, b) {
      final byCount = counts[b.areaId]!.compareTo(counts[a.areaId]!);

      return byCount != 0 ? byCount : a.name.compareTo(b.name);
    });

    _areas.setValue(result);
  }

  /// How many devices of an area would end up with a card.
  int _cardCount(String areaId) {
    final showable = isDeviceShowable;
    final devices = devicesOfArea(areaId);

    if (showable == null) return devices.length;

    return devices.where(showable).length;
  }

  /// What a card is matched against: the entity domain, and for sensors the
  /// device class too - 'light', 'sensor.temperature', ...
  ///
  /// The registry often leaves the device class empty, so fall back to the one
  /// the entity reports in its own state.
  String kindOf(RegistryEntry entry) {
    // diagnostics are readouts about the device - keep them out of the plain kinds
    final prefix = entry.entityCategory == 'diagnostic' ? 'diagnostic:' : '';

    if (entry.domain != 'sensor' && entry.domain != 'binary_sensor') return '$prefix${entry.domain}';

    final deviceClass = entry.effectiveDeviceClass ?? entityOf(entry.entityId)?.attributes?.deviceClass;

    return '$prefix${deviceClass == null ? entry.domain : '${entry.domain}.$deviceClass'}';
  }

  /// Devices of [areaId] with the entities that belong to them, sorted by name.
  /// Entities without a device of their own are grouped under a synthetic one.
  List<DeviceEntities> devicesOfArea(String areaId) {
    final Map<String?, List<RegistryEntry>> byDevice = {};

    for (final entry in entitiesOfArea(areaId)) {
      byDevice.putIfAbsent(entry.deviceId, () => []).add(entry);
    }

    final names = {for (final device in _devices) device.deviceId: device.displayName};

    final result = byDevice.entries
        .map((e) => DeviceEntities(
              deviceId: e.key,
              name: names[e.key] ?? e.value.first.displayName,
              entities: e.value,
              kindsById: {for (final entry in e.value) entry.entityId: kindOf(entry)},
            ))
        .toList();

    result.sort((a, b) => a.name.compareTo(b.name));

    return result;
  }

  /// Registry entries that live in [areaId], sorted by name.
  /// An entity without an area of its own inherits the one of its device.
  List<RegistryEntry> entitiesOfArea(String areaId) {
    final result = _registry
        // config entities are knobs about the device, not the device itself.
        // diagnostics stay, marked by kindOf, so only cards that ask get them.
        .where((entry) => !entry.disabled && !entry.hidden && entry.entityCategory != 'config')
        .where((entry) => (entry.areaId ?? _deviceAreas[entry.deviceId]) == areaId)
        .where((entry) => !_hideUnavailable || _isAvailable(entry.entityId))
        .toList();

    result.sort((a, b) => a.displayName.compareTo(b.displayName));

    return result;
  }

  /// Every binary sensor in the registry, sorted by name.
  List<RegistryEntry> binarySensors() {
    final result = _registry.where((entry) => entry.domain == 'binary_sensor' && !entry.disabled && !entry.hidden).toList();

    result.sort((a, b) => a.displayName.compareTo(b.displayName));

    return result;
  }

  /// True unless Home Assistant says the entity has no usable state.
  bool _isAvailable(String entityId) {
    final state = entityOf(entityId)?.state;

    return state != null && state != 'unavailable' && state != 'unknown';
  }
}
