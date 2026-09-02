import 'package:home_assistant_ws/home_assistant_ws.dart';
import 'package:nexus/providers/state.dart';

/// The live state of every entity the socket has mentioned, one provider each.
/// Providers are handed out before their entity is ever heard of, so a card
/// built for an entity that has not reported yet simply sits on a null state.
class HomeAssistantEntities {
  final Map<String, StateProvider<Entity>> _providers = {};

  StateProvider<Entity> findOrCreate(String entityId) {
    return _providers.putIfAbsent(entityId, () {
      final result = StateProvider<Entity>();
      result.setValue(Entity(entityId: entityId, state: null));
      return result;
    });
  }

  Entity? valueOf(String entityId) => _providers[entityId]?.getValue();

  void onAvailable(EventAvailable available) {
    for (final entity in available.entities) {
      findOrCreate(entity.entityId).setValue(Entity(entityId: entity.entityId, state: entity.state, attributes: entity.attributes));
    }
  }

  void onChange(EventChange change) {
    for (final entity in change.changes) {
      final provider = findOrCreate(entity.entityId);
      final result = provider.getValue()!;

      if (entity.stateChange != null) {
        result.state = entity.stateChange?.newValue;
      }

      final attributes = result.attributes?.toJson() ?? {};

      for (final attributeChange in entity.attributesChange.entries) {
        attributes[attributeChange.key] = attributeChange.value.newValue;
      }

      result.attributes = attributes.isNotEmpty ? EntityAttributes.fromData(attributes) : null;

      provider.setValue(result);
    }
  }
}
