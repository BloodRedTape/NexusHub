import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexus/clients/open_meteo/client.dart';
import 'package:nexus/providers/state.dart';
import 'package:nexus/utils/settings_section.dart';

class OpenMeteoConfigWidget extends StatefulWidget {
  final StateProvider<OpenMeteoConfig> stateProvider;

  OpenMeteoConfigWidget({required this.stateProvider});

  @override
  _OpenMeteoConfigWidgetState createState() => _OpenMeteoConfigWidgetState();
}

class _OpenMeteoConfigWidgetState extends State<OpenMeteoConfigWidget> {
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
    final current = widget.stateProvider.getValue();
    final lat = double.tryParse(_latController.text);
    final long = double.tryParse(_longController.text);

    // Half typed coordinates would otherwise throw on the way out.
    if (lat != null && long != null && (lat != current?.lat || long != current?.long)) {
      widget.stateProvider.setValue(OpenMeteoConfig(lat: lat, long: long));
    }

    widget.stateProvider.unbind(_onConfigChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: <Widget>[
        SettingsSectionHeader('Location'),
        SettingsTextField(
          controller: _latController,
          label: 'Latitude',
          helperText: 'Saved when you leave this screen',
          icon: Icons.my_location,
          keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
          ],
        ),
        SettingsTextField(
          controller: _longController,
          label: 'Longitude',
          icon: Icons.explore_outlined,
          keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
          ],
        ),
      ],
    );
  }
}
