# The home_assistant_ws package

Home Assistant is talked to over its websocket API through `home_assistant_ws`,
our own package. It lives outside this repo:

```
x:\Dev\HA\FlutterHomeAssistantSdk\home_assistant_ws
```

`pubspec.yaml` currently points at that working copy:

```yaml
home_assistant_ws:
  path: ../FlutterHomeAssistantSdk/home_assistant_ws
```

That is deliberate but temporary - the changes below are not committed or
pushed yet. Once they are, put the git ref back:

```yaml
home_assistant_ws:
  git:
    url: https://github.com/BloodRedTape/home_assistant_ws
    ref: <new commit>
```

A path dependency also means `flutter pub get` after editing the package, and a
full restart rather than a hot reload.

## What the app uses it for

- `connectOrThrow(unsafe: true)` / `disconnect()` / `ping()`
- `subscribeEntities` - the stream of entity states that feeds every card
- `executeService` / `executeServiceForEntity` - switching lights, covers, plugs
- `getAreas()`, `getDevices()`, `getEntityRegistry()` - the registries the room
  tabs are built from, see `notes/cards.md`

`unsafe: true` accepts self signed certificates, which a local HA instance
usually has. Without it the socket fails the TLS handshake.

## Connection errors

`connect()` used to swallow every failure into a bare `false`, so the settings
screen could only say "Connect failed". It now reports the real reason:

- `ConnectionError` (`lib/src/connection_error.dart`) carries a `kind` -
  `badUrl`, `dnsFailure`, `unreachable`, `tlsFailure`, `handshakeRejected`,
  `closedBeforeAuth`, `authInvalid`, `authTimeout`, `unknown` - plus a
  `description` ready to show in the UI.
- `classifyConnectionError` in `lib/src/web/io.dart` turns a `SocketException`,
  `HandshakeException` or `WebSocketException` into one of those. The browser
  build cannot tell them apart - it always reports `unknown`, on purpose.
- `connectOrThrow` throws it; `connect()` still returns a bool and leaves the
  reason in `lastError`, so old callers keep working.

The client logs the description into the debug list under Home Assistant
settings, next to the reconnect button.

## Registries and entity attributes

Three list commands were added: `config/area_registry/list`,
`config/device_registry/list` and `config/entity_registry/list`, parsed into
`Area`, `Device` and `RegistryEntry`.

`RegistryEntry` carries `entity_category`, which is what tells a real control
from a knob about the device - without it the app once picked a "Power outage
memory" toggle as an outlet's switch.

`EntityAttributes` also learned `device_class` and `unit_of_measurement`. This
matters more than it sounds: the entity registry usually leaves `device_class`
empty and only the entity's own state carries it, so card matching depends on
these attributes rather than on the registry.

## Gotchas

- **Don't import `dart:io` in shared code.** `home_assistant_ws_api.dart` used
  to, which broke the web build; the platform split lives in `lib/src/web/`
  (`io.dart`, `html.dart`, `stub.dart`) behind a conditional import. Every one
  of those files must export the same names.
- **`Message.data['result']`** is where list commands put their payload.
- The package's `example/` and `test/` still hold the generated template that
  references a non-existent `Awesome()` - `dart analyze` complains about it, and
  it has nothing to do with our changes.
