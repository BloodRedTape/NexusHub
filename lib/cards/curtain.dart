import 'package:flutter/material.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/consts.dart';
import 'package:nexus/providers/state.dart';

enum CurtainControlType { Button, Slider }

class CurtainCard extends StatefulWidget {
  final StateProvider<double> stateProvider;
  final String? name;
  final CurtainControlType control;

  const CurtainCard({required this.stateProvider, required this.control, this.name});

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

    if (widget.control == CurtainControlType.Slider) {
      if (widget.name != null) {
        widgets.add(Text(widget.name!, style: TextStyle(fontSize: primaryTextSize, fontWeight: FontWeight.bold)));
      }

      widgets.add(
        Slider(value: state, min: 0, max: 100, onChanged: onValueChanged, onChangeEnd: widget.stateProvider.requestValue),
      );
    }

    if (widget.control == CurtainControlType.Button) {
      if (widget.name != null) {
        String stateString;
        if (state.toInt() == 100)
          stateString = "Open";
        else if (state.toInt() == 0)
          stateString = "Closed";
        else
          stateString = "${state.toInt()}%";

        widgets.add(Text("${stateString}", style: TextStyle(fontSize: primaryTextSize, fontWeight: FontWeight.bold)));
      }

      widgets.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 0,
        children: [
          Expanded(
            child: ElevatedButton(onPressed: () => widget.stateProvider.requestValue(100), child: Icon(Icons.arrow_upward)),
          ),
          Expanded(
            child: ElevatedButton(onPressed: () => widget.stateProvider.requestValue(0), child: Icon(Icons.arrow_downward)),
          )
        ],
      ));
    }

    return PlainCardBase(icon: Icon(Icons.curtains, size: iconSize, color: Colors.deepPurpleAccent[100]), children: widgets);
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
