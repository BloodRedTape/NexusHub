class HomeAssistantConfig {
  final String url;
  final String token;

  /// Skip devices whose entities report no state at all.
  final bool hideUnavailable;

  /// Skip areas that ended up with nothing to show.
  final bool hideEmptyAreas;

  HomeAssistantConfig({required this.url, required this.token, this.hideUnavailable = true, this.hideEmptyAreas = true});

  static String serialize(HomeAssistantConfig? config) {
    if (config == null) return '';

    return '${config.url}~${config.token}~${config.hideUnavailable}~${config.hideEmptyAreas}';
  }

  static HomeAssistantConfig? deserialize(String string) {
    final parts = string.split('~');

    // older formats carried fewer fields - the flags then keep their defaults
    if (parts.length < 2 || parts.length > 4) return null;

    if (parts[0].isEmpty || parts[1].isEmpty) return null;

    bool flag(int index) => parts.length <= index || parts[index] != 'false';

    return HomeAssistantConfig(
      url: parts[0],
      token: parts[1],
      hideUnavailable: flag(2),
      hideEmptyAreas: flag(3),
    );
  }
}
