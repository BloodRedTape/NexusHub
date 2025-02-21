import 'package:flutter/material.dart';
import 'package:nexus/cards/base.dart';

class PlainCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? subtext;
  final Color? color;
  final Color? iconColor;

  const PlainCard(
      {required this.icon,
      required this.text,
      this.subtext,
      this.color,
      this.iconColor});

  @override
  Widget build(BuildContext context) {
    return BaseCard(
        color: color,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 80,
                color: iconColor,
              ),
              const SizedBox(height: 8),
              Text(text, style: TextStyle(fontSize: 20))
            ],
          ),
        ));
  }
}
