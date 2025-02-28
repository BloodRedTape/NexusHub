class HomeAssistantConfig {
  final String url;
  final String token;

  HomeAssistantConfig({required this.url, required this.token});

  static String serialize(HomeAssistantConfig? config) {
    if (config == null) return '';

    return '${config.url}:${config.token}';
  }

  static HomeAssistantConfig? deserialize(String string) {
    final parts = string.split(':');

    if (parts.length != 2) return null;

    if (parts[0].isEmpty || parts[1].isEmpty) return null;

    return HomeAssistantConfig(url: parts[0], token: parts[1]);
  }
}
