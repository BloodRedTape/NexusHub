class HomeAssistantConfig {
  final String url;
  final String token;

  /// Skip devices whose entities report no state at all.
  final bool hideUnavailable;

  /// Skip areas that ended up with nothing to show.
  final bool hideEmptyAreas;

  HomeAssistantConfig({required this.url, required this.token, this.hideUnavailable = true, this.hideEmptyAreas = true});

  Map<String, dynamic> toJson() => {
        'url': url,
        'token': token,
        'hideUnavailable': hideUnavailable,
        'hideEmptyAreas': hideEmptyAreas,
      };

  static HomeAssistantConfig? fromJson(Map<String, dynamic> json) {
    final url = json['url'];
    final token = json['token'];

    if (url is! String || token is! String || url.isEmpty || token.isEmpty) return null;

    return HomeAssistantConfig(
      url: url,
      token: token,
      hideUnavailable: json['hideUnavailable'] as bool? ?? true,
      hideEmptyAreas: json['hideEmptyAreas'] as bool? ?? true,
    );
  }
}
