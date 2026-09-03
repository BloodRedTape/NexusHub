import 'package:flutter/material.dart';
import 'package:nexus/cards/details.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/clients/android/models.dart';
import 'package:nexus/consts.dart';
import 'package:nexus/utils/generic_icon.dart';

class SettingsItem {
  final GenericIcon icon;
  final String name;
  final void Function(BuildContext context)? action;

  SettingsItem({required this.icon, required this.name, this.action});

  SettingsItem.action(
      {required this.icon, required this.name, required this.action});

  SettingsItem.details(
      {required this.icon, required this.name, required DetailsPage details})
      : action = details.navigateTo;

  SettingsItem.fromLauncherApp(LauncherApp app)
      : name = app.name,
        icon = GenericIcon.fromFuture(image: app.icon.then((image) => Image(image: image))),
        action = app.launch;
}

class SettingsTab extends StatelessWidget {
  final List<SettingsItem> items;

  const SettingsTab({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => _buildGridItem(context, items[index]),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: cardPadding * 2 + iconSize * 2 + primaryTextSize),
    );
  }

  Widget _buildGridItem(BuildContext context, SettingsItem item) {
    return PlainCard.fromIconWidget(
      iconWidget: SizedBox(width: iconSize, height: iconSize, child: item.icon),
      text: item.name,
      action: () => item.action?.call(context),
    );
  }
}
