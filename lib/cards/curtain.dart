import 'package:flutter/material.dart';
import 'package:nexus/cards/value.dart';
import 'package:nexus/providers/state.dart';

class CurtainCard extends StatelessWidget {
  final StateProvider<double> stateProvider;
  final String? name;
  final Color? sliderColor;

  CurtainCard({required this.stateProvider, this.name, this.sliderColor});

  @override
  Widget build(BuildContext context) {
    return ValueCard(
      childFactory: (state) => buildChild(state, context),
      stateProvider: stateProvider,
    );
  }

  Widget buildChild(double? state, BuildContext context) {
    if (state == null) {
      return Center(child: Text('Undefined'));
    }

    List<Widget> widgets = [];

    if (name != null) {
      widgets.add(SizedBox(height: 8));
      widgets.add(Row(
        children: [
          Icon(
            Icons.curtains,
            size: 48,
            color: Colors.deepPurpleAccent[100],
          ),
          SizedBox(width: 4),
          Text(
            name!,
            style: TextStyle(fontSize: 28),
          )
        ],
        mainAxisAlignment: MainAxisAlignment.center,
      ));
    }

    widgets.add(
      Slider(value: state, min: 0, max: 100, onChanged: stateProvider.setValue),
    );

    return Center(
      child: Column(
        children: widgets,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
      ),
    );
  }

  IconData icon(bool? state) {
    if (state == null) {
      return Icons.info;
    }

    return Icons.lightbulb;
  }

  Color iconColor(bool? state) {
    if (state == null) {
      return Colors.white;
    }

    return state ? Colors.yellow : Colors.white;
  }
}
