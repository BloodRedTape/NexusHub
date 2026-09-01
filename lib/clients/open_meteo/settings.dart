import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexus/clients/open_meteo/client.dart';
import 'package:nexus/config/config.dart';
import 'package:nexus/utils/settings_section.dart';

class OpenMeteoConfigWidget extends StatefulWidget {
  final OpenMeteoConfigCubit configCubit;

  OpenMeteoConfigWidget({Key? key, required this.configCubit}) : super(key: key);

  @override
  _OpenMeteoConfigWidgetState createState() => _OpenMeteoConfigWidgetState();
}

class _OpenMeteoConfigWidgetState extends State<OpenMeteoConfigWidget> implements SettingsSaver {
  StreamSubscription<OpenMeteoConfig>? _configSubscription;
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _longController = TextEditingController();

  @override
  final ValueNotifier<bool> dirty = ValueNotifier(false);

  @override
  void initState() {
    super.initState();

    _onConfigChanged(widget.configCubit.state);
    _configSubscription = widget.configCubit.stream.listen(_onConfigChanged);
    _latController.addListener(_refreshDirty);
    _longController.addListener(_refreshDirty);
  }

  void _refreshDirty() {
    final current = widget.configCubit.state;
    final lat = double.tryParse(_latController.text);
    final long = double.tryParse(_longController.text);

    dirty.value = lat != null && long != null && (lat != current.lat || long != current.long);
  }

  void _onConfigChanged(OpenMeteoConfig config) {
    _latController.text = config.lat.toString();
    _longController.text = config.long.toString();

    _refreshDirty();
  }

  @override
  void save() {
    final current = widget.configCubit.state;
    final lat = double.tryParse(_latController.text);
    final long = double.tryParse(_longController.text);

    // Half typed coordinates would otherwise throw on the way out.
    if (lat != null && long != null && (lat != current.lat || long != current.long)) {
      widget.configCubit.save(OpenMeteoConfig(lat: lat, long: long));
    }

    _refreshDirty();
  }

  @override
  void dispose() {
    _configSubscription?.cancel();
    dirty.dispose();
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
