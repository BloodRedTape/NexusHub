import 'package:flutter/material.dart';

class DashboardDetails extends StatelessWidget {
  final Widget body;
  final Widget title;

  const DashboardDetails({required this.body, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: title), body: body);
  }
}
