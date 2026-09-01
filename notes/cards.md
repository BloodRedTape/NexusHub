# Room cards

The `Home` tab has one sub tab per Home Assistant area. Each tab is filled
automatically: the client walks the devices of that area and picks a card for
every device it knows how to draw. Nothing is hardcoded per room.

## The pipeline

1. **Registries.** On connect the client pulls three lists over the websocket:
   `config/area_registry/list`, `config/device_registry/list` and
   `config/entity_registry/list` (`lib/clients/ha/client.dart`).
2. **Grouping.** `devicesOfArea(areaId)` groups the area's entities by their
   device. An entity with no area of its own inherits the area of its device;
   an entity with no device at all becomes a group of one.
3. **Matching.** `matchCard(device)` in `lib/dashboard/area.dart` finds the best
   card for the device's set of entities.
4. **Layout.** The chosen cards are laid onto `TileGrid` - a fixed 2x4 grid of
   square tiles (`lib/dashboard/grid.dart`).

## Kinds

A card is matched against *kinds*, not raw entity ids. `HomeAssistantClient.kindOf`
turns an entity into one:

| Entity                                     | Kind                        |
|--------------------------------------------|-----------------------------|
| `light.bed_led`                             | `light`                     |
| `sensor.*` with device class `temperature`  | `sensor.temperature`        |
| `binary_sensor.*` with class `occupancy`    | `binary_sensor.occupancy`   |
| anything marked `entity_category: diagnostic` | prefixed `diagnostic:...` |

Two details worth knowing:

- **The device class usually comes from the state, not the registry.** Home
  Assistant leaves `device_class` empty in the entity registry for most
  integrations and only reports it in the entity's own attributes. `kindOf`
  reads the registry first and falls back to the state. This is why the client
  holds the area list back until the first batch of states has arrived
  (`_publishAreas`) - matching before that would see every sensor as a bare
  `sensor`.
- **Config entities are dropped, diagnostics are marked.** `entity_category:
  config` entities are knobs about a device (a "Power outage memory" toggle,
  say), never the device itself - they are filtered out entirely. Diagnostics
  are readouts about a device ("Total power" on an outlet, everything System
  Monitor exposes); they stay, but their kind carries a `diagnostic:` prefix so
  a normal card cannot pick them up by accident.

## Matchers

A `CardMatcher` declares what it needs and how to build itself:

```dart
CardMatcher(requires: {'sensor.temperature', 'sensor.humidity'}, build: _buildClimate)
```

A device matches when it exposes **all** the required kinds. When several
matchers fit, the one with the highest `coverage` wins - that is, the one
accounting for more of the device's entities. A sensor exposing temperature,
humidity and a light would get the climate card (2) over the light card (1).

For devices that kinds cannot describe, a matcher can carry an `accepts`
predicate and a `weight` that stands in for the entities it covers. System
Monitor is the case that needs it: none of its sensors have a device class, so
it is recognised by an entity id ending in `processor_use`.

`matchCard` returning null means the device is not shown at all.

## Adding a card

1. Write the widget in `lib/cards/`. Use `PlainCardBase` for the frame and
   `StackedLayout` for the usual shape: big value, second line right under it,
   device name pinned to the bottom. Each reading is a `Reading` widget bound to
   its own provider, so values update independently.
2. Add a `CardMatcher` to `cardMatchers` in `lib/dashboard/area.dart`.
3. Pull the entities it needs with `device.entityOf('<kind>')` (or
   `device.entityEndingWith('<suffix>')` when there is no usable device class),
   and turn them into providers via the client:
   `sensorStateProvider`, `switchStateProvider`, `lightStateProvider`,
   `curtainStateProvider`, `entityStateProvider`.

Prefer reusing `SensorCard` over writing a new widget when a single value with
an icon is all that is needed - CO2 and illuminance are just matchers.

## Grid

`TileGrid` places tiles left to right, row by row. Tiles are always square: a
short last row is padded with empty space rather than stretched, and anything
past `rows * columns` is dropped. `SplitTile` divides one cell into two stacked
halves, for pairs of compact readings.

## Settings

Two switches under Home Assistant settings, both on by default, both applied
immediately:

- **Hide unavailable devices** - entities reporting `unavailable`/`unknown` (or
  no state at all) are ignored, both for cards and for recognising a device.
- **Hide rooms without devices** - an area that produced no cards gets no tab.

Rooms are ordered by how many cards they produced, most first, alphabetically
among equals.
