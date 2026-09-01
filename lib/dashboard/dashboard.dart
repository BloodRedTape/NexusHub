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
                tab: Tab(text: area.name, icon: Icon(Icons.meeting_room)),
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
