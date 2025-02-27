import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexus/clients/open_meteo/client.dart';
import 'package:nexus/providers/state.dart';

class OpenMeteoConfigWidget extends StatefulWidget {
  final StateProvider<OpenMeteoConfig> stateProvider;

  OpenMeteoConfigWidget({required this.stateProvider});

  @override
  _HomeAssistantConfigWidgetState createState() =>
      _HomeAssistantConfigWidgetState();
}

class _HomeAssistantConfigWidgetState extends State<OpenMeteoConfigWidget> {
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _longController = TextEditingController();

  @override
  void initState() {
    super.initState();

    widget.stateProvider.bindValueChanged(_onConfigChanged);
  }

  void _onConfigChanged(OpenMeteoConfig? config) {
    if (config == null) return;

    _latController.text = config.lat.toString();
    _longController.text = config.long.toString();
  }

  @override
  void dispose() {
    widget.stateProvider.setValue(OpenMeteoConfig(
        lat: double.parse(_latController.text),
        long: double.parse(_longController.text)));
    widget.stateProvider.unbind(_onConfigChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          TextField(
            controller: _latController,
            decoration: InputDecoration(
              labelText: 'Latitude',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
          ),
          SizedBox(height: 16),
          TextField(
            controller: _longController,
            decoration: InputDecoration(
              labelText: 'Longitude',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
          ),
        ],
      ),
    );
  }
}
