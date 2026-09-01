import 'package:nexus/config/cubits.dart';

export 'package:nexus/config/cubits.dart';

/// The one way into the app's settings: every client and settings page reads
/// and writes through here rather than reaching for preferences itself.
class AppConfig {
  final HomeAssistantConfigCubit homeAssistant;
  final AndroidConfigCubit android;
  final OpenMeteoConfigCubit openMeteo;

  AppConfig()
      : homeAssistant = HomeAssistantConfigCubit(),
        android = AndroidConfigCubit(),
        openMeteo = OpenMeteoConfigCubit();

  Future<void> close() async {
    await homeAssistant.close();
    await android.close();
    await openMeteo.close();
  }
}
