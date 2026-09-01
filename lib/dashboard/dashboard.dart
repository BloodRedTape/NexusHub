import 'package:flutter/material.dart';
import 'package:home_assistant_ws/home_assistant_ws.dart';
import 'package:nexus/cards/state.dart';
import 'package:nexus/providers/state.dart';

const tabPadding = EdgeInsets.all(24.0);

// Define a class to hold a pair of Tab and its corresponding Widget.
class TabItem {
  final Tab tab;
  final Widget child;

  const TabItem({
    required this.tab,
    required this.child,
  });
}

// Tab content inset from the screen edges. Tabs opt in - Dashboard never pads.
class PaddedTab extends StatelessWidget {
  final Widget child;

  const PaddedTab({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Padding(padding: tabPadding, child: child);
}

// A tab that hosts its own sub tabs, switched by a bottom bar.
class SubTabs extends StatefulWidget {
  final List<TabItem> items;

  const SubTabs({super.key, required this.items});

  @override
  State<SubTabs> createState() => _SubTabsState();
}

class _SubTabsState extends State<SubTabs> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: IndexedStack(
        index: _index,
        children: widget.items.map((item) => item.child).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: widget.items
            .map((item) => NavigationDestination(
                  icon: item.tab.icon ?? Icon(Icons.chevron_right),
                  label: item.tab.text ?? '',
                ))
            .toList(),
      ),
    );
  }
}

/// Material icon for a Home Assistant `mdi:` name. Only the ones actually in
/// use are here - anything else falls back to a generic room.
const Map<String, IconData> _mdiIcons = {
  'bathtub': Icons.bathtub,
  'shower': Icons.shower,
  'bed': Icons.bed,
  'bed-king': Icons.bed,
  'bed-queen': Icons.bed,
  'sofa': Icons.weekend,
  'fridge': Icons.kitchen,
  'countertop': Icons.countertops,
  'silverware-fork-knife': Icons.restaurant,
  'toilet': Icons.wc,
  'door': Icons.door_front_door,
  'door-open': Icons.door_front_door,
  'door-closed': Icons.door_front_door,
  'space-invaders': Icons.videogame_asset,
  'television': Icons.tv,
  'television-classic': Icons.tv,
  'desk': Icons.desktop_windows,
  'desktop-tower-monitor': Icons.desktop_windows,
  'garage': Icons.garage,
  'tree': Icons.park,
  'flower': Icons.local_florist,
  'washing-machine': Icons.local_laundry_service,
  'stairs': Icons.stairs,
  'server': Icons.dns,
  'home': Icons.home,
};

/// Area icons come from Home Assistant as `mdi:<name>`.
IconData roomIcon(String? icon) {
  if (icon == null) return Icons.meeting_room;

  // mdi ships outline variants of most icons - they map to the same thing here
  final name = icon.replaceFirst('mdi:', '').replaceFirst(RegExp(r'-outline$'), '');

  return _mdiIcons[name] ?? Icons.meeting_room;
}

// One sub tab per Home Assistant area, rebuilt whenever the area list arrives.
class AreaTabs extends StateCard<List<Area>> {
  final Widget Function(Area area) builder;

  AreaTabs({required super.stateProvider, required this.builder});

  @override
  Widget build(BuildContext context, List<Area>? areas) {
    if (areas == null) return Center(child: Text('Loading rooms...'));

    if (areas.isEmpty) return Center(child: Text('No areas configured in Home Assistant'));

    return SubTabs(
      // rebuild the sub tab state when the set of rooms actually changes
      key: ValueKey(areas.map((area) => area.areaId).join(',')),
      items: areas
          .map((area) => TabItem(
                tab: Tab(text: area.name, icon: Icon(roomIcon(area.icon))),
                child: PaddedTab(child: builder(area)),
              ))
          .toList(),
    );
  }
}

// Rename TabBarExample to Dashboard and use TabItem for input.
class Dashboard extends StatelessWidget {
  final List<TabItem> items;

  const Dashboard({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: items.length,
      child: Scaffold(
        appBar: TabBar(
          tabs: items.map((item) => item.tab).toList(),
        ),
        body: TabBarView(
          children: items.map((item) => item.child).toList(),
        ),
      ),
    );
  }
}
