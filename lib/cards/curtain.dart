import 'package:flutter/material.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/consts.dart';
import 'package:nexus/providers/state.dart';

class CurtainCard extends StatefulWidget {
  final StateProvider<double> stateProvider;
  final String? name;

  const CurtainCard({required this.stateProvider, this.name});

  @override
  State<StatefulWidget> createState() => _CurtainCardState();
}

class _CurtainCardState<T> extends State<CurtainCard> {
  double? _state;

  @override
  void initState() {
    super.initState();
    widget.stateProvider.bindValueChanged(onValueChanged);
  }

  @override
  void dispose() {
    widget.stateProvider.unbind(onValueChanged);
    super.dispose();
  }

  void onValueChanged(double? value) {
    setState(() {
      _state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _build(context, _state);
  }

  Widget _build(BuildContext context, double? state) {
    if (state == null) {
      return PlainCard(icon: Icons.error, text: 'Unavailable');
    }
    List<Widget> widgets = [];

    if (widget.name != null) {
      widgets.add(Text(widget.name!,
          style: TextStyle(
              fontSize: primaryTextSize, fontWeight: FontWeight.bold)));
    }

    widgets.add(
      Slider(
          value: state,
          min: 0,
          max: 100,
          onChanged: onValueChanged,
          onChangeEnd: widget.stateProvider.requestValue),
    );

    return PlainCardBase(
        icon: Icon(Icons.curtains,
            size: iconSize, color: Colors.deepPurpleAccent[100]),
        children: widgets);
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
