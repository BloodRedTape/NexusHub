import 'package:flutter/material.dart';

// Define a class to hold a pair of Tab and its corresponding Widget.
class TabItem {
  final Tab tab;
  final Widget child;

  const TabItem({
    required this.tab,
    required this.child,
  });
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
          children: items
              .map((item) =>
                  Padding(padding: EdgeInsets.all(24.0), child: item.child))
              .toList(),
        ),
      ),
    );
  }
}
