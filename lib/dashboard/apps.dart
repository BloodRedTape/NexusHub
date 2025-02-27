import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:nexus/cards/base.dart';
import 'package:nexus/consts.dart';

class AppsTab extends StatelessWidget {
  const AppsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppInfo>>(
      future: InstalledApps.getInstalledApps(false, true, true),
      builder: (
        BuildContext buildContext,
        AsyncSnapshot<List<AppInfo>> snapshot,
      ) {
        return snapshot.connectionState == ConnectionState.done
            ? snapshot.hasData
                ? _buildGridView(snapshot.data ?? [])
                : _buildError()
            : _buildProgressIndicator();
      },
    );
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
      onTap: () => InstalledApps.startApp(app.packageName),
    );
  }

  Widget _buildProgressIndicator() {
    return Center(child: Text("Loading apps ...."));
  }

  Widget _buildError() {
    return Center(
      child: Text("Error occurred while loading apps ...."),
    );
  }
}
