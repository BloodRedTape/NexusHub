import 'package:flutter/material.dart';
import 'package:nexus/cards/plain.dart';

class AlarmCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PlainCard(
        icon: Icons.alarm,
        text: '9:00',
        subText: 'Next - 10:00',
        subAction: PlainAction(
            icon: Icons.arrow_right_rounded, onTap: () => print('cancel')));
  }
}
