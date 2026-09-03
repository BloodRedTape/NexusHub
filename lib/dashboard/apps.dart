import 'package:flutter/material.dart';
import 'package:nexus/cards/base.dart';
import 'package:nexus/cards/state.dart';
import 'package:nexus/clients/android/models.dart';
import 'package:nexus/consts.dart';
import 'package:nexus/dashboard/dashboard.dart';
import 'package:nexus/utils/generic_icon.dart';

class AppsTab extends StateCard<List<LauncherApp>> {
  AppsTab({required super.stateProvider});

  @override
  Widget build(BuildContext context, List<LauncherApp>? state) {
    if (state == null) return _buildProgressIndicator();

    return _buildGridView(state);
  }

  Widget _buildGridView(List<LauncherApp> apps) {
    return GridView.builder(
      padding: tabPadding,
      itemCount: apps.length,
      itemBuilder: (context, index) => _buildGridItem(context, apps[index]),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, LauncherApp app) {
    return BaseCard(
      action: () => app.launch(context),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: GenericIcon.fromFuture(image: app.icon.then((image) => Image(image: image, fit: BoxFit.contain)))),
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
