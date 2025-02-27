import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:nexus/cards/details.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/consts.dart';
import 'package:nexus/utils/generic_icon.dart';

Future<GenericIcon> _getAppIcon(String package) async {
  AppInfo? info = await InstalledApps.getAppInfo(package, null);

  final icon = info?.icon;

  if (icon == null) return GenericIcon.fromIcon(icon: Icons.error);

  return GenericIcon.fromImage(image: Image.memory(icon));
}

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

  SettingsItem.fromPackage({required String package, required this.name})
      : icon = GenericIcon.fromFuture(image: _getAppIcon(package)),
        action = makeStartAction(package);

  static void Function(BuildContext context) makeStartAction(String package) {
    return (BuildContext context) => {InstalledApps.startApp(package)};
  }
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
