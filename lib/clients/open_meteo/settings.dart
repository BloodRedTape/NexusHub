import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nexus/clients/open_meteo/client.dart';
import 'package:nexus/utils/settings_section.dart';

/// The coordinates as typed. They stay text until saved, so a half typed
/// number is something the form can hold rather than something that throws.
class OpenMeteoFormState {
  final String lat;
  final String long;

  const OpenMeteoFormState({required this.lat, required this.long});
}

class OpenMeteoFormCubit extends SettingsFormCubit<OpenMeteoFormState> {
  final OpenMeteoWeatherClient client;

  OpenMeteoFormCubit(this.client)
      : super(OpenMeteoFormState(
          lat: client.config.lat.toString(),
          long: client.config.long.toString(),
        ));

  void setLat(String lat) => emit(OpenMeteoFormState(lat: lat, long: state.long));

  void setLong(String long) => emit(OpenMeteoFormState(lat: state.lat, long: long));

  OpenMeteoConfig? get _edited {
    final lat = double.tryParse(state.lat);
    final long = double.tryParse(state.long);

    if (lat == null || long == null) return null;

    return OpenMeteoConfig(lat: lat, long: long);
  }

  @override
  bool get dirty {
    final edited = _edited;

    return edited != null && (edited.lat != client.config.lat || edited.long != client.config.long);
  }

  @override
  void save() {
    final edited = _edited;

    if (edited == null) return;

    client.saveConfig(edited);

    // The client now matches the form; re-emit so the save button follows.
    emit(OpenMeteoFormState(lat: state.lat, long: state.long));
  }
}

class OpenMeteoSettingsPage extends StatelessWidget {
  const OpenMeteoSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OpenMeteoFormCubit(context.read<OpenMeteoWeatherClient>()),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Open Meteo Settings'),
            actions: [SettingsSaveButton(context.watch<OpenMeteoFormCubit>())],
          ),
          body: const _OpenMeteoForm(),
        ),
      ),
    );
  }
}

class _OpenMeteoForm extends StatefulWidget {
  const _OpenMeteoForm();

  @override
  State<_OpenMeteoForm> createState() => _OpenMeteoFormState();
}

class _OpenMeteoFormState extends State<_OpenMeteoForm> {
  late final OpenMeteoFormCubit _form = context.read<OpenMeteoFormCubit>();
  late final TextEditingController _latController = TextEditingController(text: _form.state.lat);
  late final TextEditingController _longController = TextEditingController(text: _form.state.long);

  @override
  void initState() {
    super.initState();

    _latController.addListener(() => _form.setLat(_latController.text));
    _longController.addListener(() => _form.setLong(_longController.text));
  }

  @override
  void dispose() {
    _latController.dispose();
    _longController.dispose();
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
