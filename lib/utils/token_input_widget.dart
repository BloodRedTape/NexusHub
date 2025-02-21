import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenInputWidget extends StatefulWidget {
  final String preferencesKey;

  const TokenInputWidget({required this.preferencesKey});

  @override
  _TokenInputWidgetState createState() => _TokenInputWidgetState();
}

class _TokenInputWidgetState extends State<TokenInputWidget> {
  final TextEditingController _controller = TextEditingController();
  String? _storedToken;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  // Load the token from shared preferences when the widget initializes
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _storedToken = prefs.getString(widget.preferencesKey);
    });
  }

  // Save the token to shared preferences
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(widget.preferencesKey, token);
    setState(() {
      _storedToken = token;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter your token',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Save the token when the button is pressed
                _saveToken(_controller.text);
              },
              child: Text('Save Token'),
            ),
            SizedBox(height: 20),
            Text(
              _storedToken != null
                  ? 'Stored Token: $_storedToken'
                  : 'No token saved',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ));
  }
}
