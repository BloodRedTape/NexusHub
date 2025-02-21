import 'package:flutter/material.dart';
import 'package:nexus/cards/plain.dart';

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final Function()? action;

  const ActionCard({required this.icon, required this.name, this.action});

  @override
  Widget build(BuildContext context) {
    return PlainCard(action: call, text: name, icon: icon);
  }

  void call() {
    action?.call();
  }
}
