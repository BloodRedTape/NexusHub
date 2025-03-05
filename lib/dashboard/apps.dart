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
        crossAxisCount: 3,
        mainAxisExtent: cardPadding + iconSize * 2 + cardPadding,
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, AppInfo app) {
    return BaseCard(
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 80, height: 80, child: Image.memory(app.icon!)),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                app.name,
                style: TextStyle(fontSize: secondaryTextSize),
                textAlign: TextAlign.left,
                overflow: TextOverflow.ellipsis,
              ),
            )
          ],
        ),
      ),
      action: () => InstalledApps.startApp(app.packageName),
    );
  }

  Widget _buildProgressIndicator() {
    return Center(child: Text("Loading apps ...."));
  }
}
