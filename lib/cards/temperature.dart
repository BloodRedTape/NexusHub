import 'package:flutter/material.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/value.dart';
import 'package:nexus/providers/value.dart';

class TemperatureCard extends StatelessWidget {
  final StateProvider<double> stateProvider;

  const TemperatureCard({required this.stateProvider});

  @override
  Widget build(BuildContext context) {
    return ValueCard<double>(
        childFactory: buildChild, stateProvider: this.stateProvider);
  }

  Widget buildChild(double? state) {
    if (state == null) return PlainCard(icon: Icons.error, text: 'Unavailable');

    return Center(child: Text('$state°C', style: TextStyle(fontSize: 24)));
  }
}
