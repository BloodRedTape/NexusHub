import 'package:flutter/material.dart';
import 'package:nexus/cards/base.dart';

class PlainCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const PlainCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return BaseCard(
        child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80),
          const SizedBox(height: 8),
          Text(text, style: TextStyle(fontSize: 20))
        ],
      ),
    ));
  }
}
