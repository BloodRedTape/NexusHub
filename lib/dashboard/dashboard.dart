import 'package:flutter/material.dart';

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
        children: widget.items.map((item) => Padding(padding: tabPadding, child: item.child)).toList(),
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
          // SubTabs pads its own content, so its bottom bar can span the full width
          children: items
              .map((item) => item.child is SubTabs ? item.child : Padding(padding: tabPadding, child: item.child))
              .toList(),
        ),
      ),
    );
  }
}
