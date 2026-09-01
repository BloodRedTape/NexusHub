class AndroidConfig {
  final bool autoBrightnessEnabled;
  final double brightnessThreshold;

  AndroidConfig({
    this.autoBrightnessEnabled = false,
    this.brightnessThreshold = 70.0,
  });

  static String serialize(AndroidConfig? config) {
    if (config == null) return '';

    return '${config.autoBrightnessEnabled ? '1' : '0'}~${config.brightnessThreshold}';
  }

  static AndroidConfig? deserialize(String string) {
    if (string.isEmpty) return AndroidConfig();

    final parts = string.split('~');

    if (parts.length != 2) return AndroidConfig();

    final enabled = parts[0] == '1';
    final threshold = double.tryParse(parts[1]) ?? 70.0;

    return AndroidConfig(
      autoBrightnessEnabled: enabled,
      brightnessThreshold: threshold,
    );
  }
}
