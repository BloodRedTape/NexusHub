import 'package:flutter/material.dart';
import 'package:nexus/cards/base.dart';

class DetailsPage extends StatelessWidget {
  final Widget body;
  final Widget? title;

  const DetailsPage({required this.body, this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: title), body: body);
  }

  void navigateTo(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => this));
  }
}

class DetailsCard extends StatelessWidget {
  final Widget child;
  final DetailsPage? details;
  final Color? color;

  DetailsCard({required this.child, this.details, this.color});

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: child,
      color: color,
      action: details != null ? () => navigateDetails(context) : null,
    );
  }

  void navigateDetails(BuildContext context) {
    if (details == null) return;

    details!.navigateTo(context);
  }
}
