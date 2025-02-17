import 'package:flutter/material.dart';
import 'package:nexus/core/dashboard_details.dart';

class DashboardCard extends StatelessWidget {
  final Widget child;
  final DashboardDetails? details;
  final Color? color;

  DashboardCard({required this.child, this.details, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(5),
      child: GestureDetector(
          onTap: () => navigateDetails(context),
          child: Card(
            color: color,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: child),
            ),
          )),
    );
  }

  void navigateDetails(BuildContext context) {
    if (details == null) return;

    Navigator.push(context, MaterialPageRoute(builder: (context) => details!));
  }
}
