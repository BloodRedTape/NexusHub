import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:nexus/cards/base.dart';
import 'package:nexus/cards/state.dart';
import 'package:nexus/consts.dart';

class AppsTab extends StateCard<List<AppInfo>> {
  AppsTab({required super.stateProvider});

  @override
  Widget build(BuildContext context, List<AppInfo>? state) {
    if (state == null) return _buildProgressIndicator();

    return _buildGridView(state);
  }

  Widget _buildGridView(List<AppInfo> apps) {
    return GridView.builder(
      itemCount: apps.length,
      itemBuilder: (context, index) => _buildGridItem(context, apps[index]),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
      ),
    );
  }

  /// The dashboard cards put their icon and label in opposite corners; a
  /// launcher tile reads better stacked and centred, like every other launcher.
  Widget _buildGridItem(BuildContext context, AppInfo app) {
    return BaseCard(
      action: () => InstalledApps.startApp(app.packageName),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Whatever the tile leaves over after the label, the icon takes -
            // a fixed size overflows as soon as the grid gets a little narrower.
            Flexible(child: Image.memory(app.icon!, fit: BoxFit.contain)),
            SizedBox(height: cardPadding / 2),
            Text(
              app.name,
              style: TextStyle(fontSize: secondaryTextSize),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Center(child: Text("Loading apps ...."));
  }
}
