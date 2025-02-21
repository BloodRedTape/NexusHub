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
      onTap: () => navigateDetails(context),
    );
  }

  void navigateDetails(BuildContext context) {
    if (details == null) return;

    Navigator.push(context, MaterialPageRoute(builder: (context) => details!));
  }
}
