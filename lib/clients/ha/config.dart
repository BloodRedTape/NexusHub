class HomeAssistantConfig {
  final String url;
  final String token;

  /// Skip devices whose entities report no state at all.
  final bool hideUnavailable;

  /// Skip areas that ended up with nothing to show.
  final bool hideEmptyAreas;

  /// Give every room with automations a card for them. Off by default - most
  /// rooms have more automations than anyone wants on a wall panel.
  final bool showAutomations;

  /// Entity the Glance calendar card reads, empty when none is picked.
  final String calendarEntity;

  HomeAssistantConfig({
    required this.url,
    required this.token,
    this.hideUnavailable = true,
    this.hideEmptyAreas = true,
    this.showAutomations = false,
    this.calendarEntity = '',
  });

  Map<String, dynamic> toJson() => {
        'url': url,
        'token': token,
        'hideUnavailable': hideUnavailable,
        'hideEmptyAreas': hideEmptyAreas,
        'showAutomations': showAutomations,
        'calendarEntity': calendarEntity,
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
      showAutomations: json['showAutomations'] as bool? ?? false,
      calendarEntity: json['calendarEntity'] as String? ?? '',
    );
  }
}
