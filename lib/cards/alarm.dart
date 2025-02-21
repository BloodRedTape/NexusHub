import 'package:flutter/material.dart';
import 'package:nexus/cards/plain.dart';

class AlarmCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PlainCard(icon: Icons.alarm, text: 'Next - 9:00 AM');
  }
}
