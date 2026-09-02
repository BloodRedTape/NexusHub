import 'package:home_assistant_ws/home_assistant_ws.dart';
import 'package:nexus/clients/state.dart';

/// The picture an `image` entity points at, and when it last changed.
/// The url carries a signed token, so it changes with every new picture.
class HaImage {
  final String url;
  final DateTime? updatedAt;

  const HaImage({required this.url, this.updatedAt});
}

class ImageStateProvider extends StateProvider<HaImage> {
  final StateProvider<Entity> entityProvider;

  /// Pictures arrive as a path off the HA host - this turns them absolute.
  final String Function() baseUrl;

  ImageStateProvider({required this.entityProvider, required this.baseUrl});

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
    final picture = entity?.attributes?.entityPicture;

    if (picture == null) {
      setValue(null);
      return;
    }

    setValue(HaImage(
      url: picture.startsWith('http') ? picture : '${baseUrl().replaceAll(RegExp(r'/+$'), '')}$picture',
      // an image entity keeps the time of its last picture as its state
      updatedAt: DateTime.tryParse(entity!.state ?? '')?.toLocal(),
    ));
  }
}
