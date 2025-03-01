import 'package:flutter/material.dart';
import 'package:nexus/clients/ha/config.dart';
import 'package:nexus/providers/state.dart';

class HomeAssistantConfigWidget extends StatefulWidget {
  final StateProvider<HomeAssistantConfig> stateProvider;

  HomeAssistantConfigWidget({required this.stateProvider});

  @override
  _HomeAssistantConfigWidgetState createState() =>
      _HomeAssistantConfigWidgetState();
}

class _HomeAssistantConfigWidgetState extends State<HomeAssistantConfigWidget> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();

    widget.stateProvider.bindValueChanged(_onConfigChanged);
  }

  void _onConfigChanged(HomeAssistantConfig? config) {
    if (config == null) return;

    _urlController.text = config.url.toString();
    _tokenController.text = config.token.toString();
  }

  @override
  void dispose() {
    widget.stateProvider.setValue(
      HomeAssistantConfig(
        url: _urlController.text,
        token: _tokenController.text,
      ),
    );
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
            controller: _urlController,
            decoration: InputDecoration(
              labelText: 'Home Assistant Url',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          SizedBox(height: 16),
          TextField(
            controller: _tokenController,
            decoration: InputDecoration(
              labelText: 'Home Assistant Bearer Token',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
