import 'package:flutter/material.dart';

class DashboardCard extends StatelessWidget {
  final Widget child;
  final Color? color;

  DashboardCard({required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(5),
      child: Card(
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(child: child),
        ),
      ),
    );
  }
}
