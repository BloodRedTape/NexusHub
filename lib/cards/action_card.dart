import 'package:flutter/material.dart';
import 'package:nexus/core/base_card.dart';

class ActionCard extends StatelessWidget {
  final IconData? icon;
  final String? name;
  final Function()? action;

  const ActionCard({this.icon, this.name, this.action});

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];

    if (icon != null) {
      widgets.add(Icon(icon, size: 94));
    }

    if (name != null) {
      if (widgets.isNotEmpty) {
        widgets.add(SizedBox(height: 8));
      }

      widgets.add(Text(name!, style: TextStyle(fontSize: 24)));
    }

    return BaseCard(
      child: ElevatedButton(
        onPressed: call,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widgets,
        ),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero, // Ensure zero padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                30), // Optional: Match the card's border radius
          ),
        ),
      ),
    );
  }

  void call() {
    action?.call();
  }
}
