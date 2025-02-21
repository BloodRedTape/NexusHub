import 'package:flutter/material.dart';
import 'package:nexus/cards/base.dart';

class AlarmCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseCard(
        child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.alarm, size: 80),
          const SizedBox(height: 8),
          Text('Next - 9:00 AM', style: TextStyle(fontSize: 20))
        ],
      ),
    ));
  }
}
