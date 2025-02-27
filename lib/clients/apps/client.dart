import 'package:installed_apps/app_info.dart';
import 'package:nexus/clients/apps/provider.dart';
import 'package:nexus/providers/state.dart';

class AppsClient {
  StateProvider<List<AppInfo>> _appsStateProvider = AppsStateProvider();

  AppsClient() {
    _appsStateProvider.init();
  }

  StateProvider<List<AppInfo>> getStateProvider() {
    return _appsStateProvider;
  }
}
