import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/consts.dart';
import 'package:nexus/providers/state.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class Printer extends StatefulWidget {
  final StateProvider<double> bedTemperature;
  final StateProvider<double> targetBedTemperature;
  final StateProvider<double> extruderTemperature;
  final StateProvider<double> targetExtruderTemperature;
  final StateProvider<double> progress;
  final StateProvider<bool> power;
  final StateProvider<String> status;
  final StateProvider<String> connection;

  Printer({
    required this.bedTemperature,
    required this.targetBedTemperature,
    required this.extruderTemperature,
    required this.targetExtruderTemperature,
    required this.progress,
    required this.power,
    required this.status,
    required this.connection,
  });

  @override
  State<StatefulWidget> createState() => _PrinterState();
}

class _PrinterState extends State<Printer> {
  double? bedTemperature;
  double? targetBedTemperature;
  double? extruderTemperature;
  double? targetExtruderTemperature;
  double? progress;
  bool? power;
  String? status;
  String? connection;

  @override
  void initState() {
    super.initState();

    widget.bedTemperature.bindValueChanged(onBedTemperatureChanged);
    widget.targetBedTemperature.bindValueChanged(onTargetBedTemperatureChanged);
    widget.extruderTemperature.bindValueChanged(onExtruderTemperatureChanged);
    widget.targetExtruderTemperature.bindValueChanged(onTargetExtruderTemperatureChanged);
    widget.progress.bindValueChanged(onProgressChanged);
    widget.power.bindValueChanged(onPowerChanged);
    widget.status.bindValueChanged(onStatusChanged);
    widget.connection.bindValueChanged(onConnectionChanged);
  }

  @override
  void dispose() {
    widget.bedTemperature.unbind(onBedTemperatureChanged);
    widget.targetBedTemperature.unbind(onTargetBedTemperatureChanged);
    widget.extruderTemperature.unbind(onExtruderTemperatureChanged);
    widget.targetExtruderTemperature.unbind(onTargetExtruderTemperatureChanged);
    widget.progress.unbind(onProgressChanged);
    widget.power.unbind(onPowerChanged);
    widget.status.unbind(onStatusChanged);
    widget.connection.unbind(onConnectionChanged);

    super.dispose();
  }

  void onBedTemperatureChanged(double? value) {
    setState(() {
      bedTemperature = value;
    });
  }

  void onTargetBedTemperatureChanged(double? value) {
    setState(() {
      targetBedTemperature = value;
    });
  }

  void onExtruderTemperatureChanged(double? value) {
    setState(() {
      extruderTemperature = value;
    });
  }

  void onTargetExtruderTemperatureChanged(double? value) {
    setState(() {
      targetExtruderTemperature = value;
    });
  }

  void onProgressChanged(double? value) {
    setState(() {
      progress = value;
    });
  }

  void onPowerChanged(bool? value) {
    setState(() {
      power = value;
    });
  }

  void onStatusChanged(String? value) {
    setState(() {
      status = value;
    });
  }

  void onConnectionChanged(String? value) {
    setState(() {
      connection = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _build(context, bedTemperature, targetBedTemperature, extruderTemperature, targetExtruderTemperature, progress, power, status, connection);
  }

  Widget _build(BuildContext context, double? bedTemperature, double? targetBedTemperature, double? extruderTemperature, double? targetExtruderTemperature,
      double? progress, bool? power, String? status, String? connection) {
    if (power == null)
      return PlainCard(
        icon: Icons.error,
        text: 'Unavailable',
        subText: '3d Printer',
      );

    final powerIcon = power ? Icons.power : Icons.power_off;

    final switchPower = () {
      widget.power.requestValue(!power);
    };

    final powerAction = PlainAction(icon: powerIcon, onTap: switchPower);

    final printerIcon = MdiIcons.printer3D;

    if (!power) return PlainCard(icon: printerIcon, text: 'Power Off', subAction: powerAction);

    if (connection == null || status == null || status == 'unknown') return PlainCard(icon: printerIcon, text: 'No Connection', subAction: powerAction);

    bool printing = status == 'Printing' && progress != null;

    return PlainCardBase(
      icon: Icon(printerIcon, size: iconSize),
      color: const Color.fromARGB(255, 25, 70, 146),
      subAction: powerAction,
      children: [
        Text(
          printing ? '${progress.toInt()}%' : status,
          style: TextStyle(fontSize: primaryTextSize, fontWeight: FontWeight.bold),
        ),
        Text(
          '${temperature(bedTemperature)} / ${temperature(targetBedTemperature)}',
          style: TextStyle(fontSize: secondaryTextSize),
        ),
        Text(
          '${temperature(extruderTemperature)} / ${temperature(targetExtruderTemperature)}',
          style: TextStyle(fontSize: secondaryTextSize),
        ),
      ],
    );
  }

  String temperature(double? temp) {
    return temp != null ? '$temp' : '?';
  }
}
