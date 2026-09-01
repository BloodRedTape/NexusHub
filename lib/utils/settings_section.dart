import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Android-settings style section header: accent coloured, above its tiles.
class SettingsSectionHeader extends StatelessWidget {
  final String title;

  const SettingsSectionHeader(this.title, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// A settings row holding a text field, laid out on the same 16dp/72dp grid
/// as the ListTiles around it.
class SettingsTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? helperText;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;

  const SettingsTextField({
    Key? key,
    required this.controller,
    required this.label,
    required this.icon,
    this.helperText,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20, right: 16),
            child: Icon(icon, color: Theme.of(context).iconTheme.color),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              obscureText: obscureText,
              decoration: InputDecoration(labelText: label, helperText: helperText),
            ),
          ),
        ],
      ),
    );
  }
}

/// Settings pages that the app bar's save button can commit. The page raises
/// [dirty] while it holds edits the provider has not seen yet.
abstract class SettingsSaver {
  ValueNotifier<bool> get dirty;

  /// Writes the edited values through to the config provider.
  void save();
}

/// App bar save button for a settings page, enabled only while that page has
/// unsaved edits.
class SettingsSaveButton extends StatelessWidget {
  final GlobalKey<State> settingsKey;

  const SettingsSaveButton(this.settingsKey, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // The settings page builds after this one, so its state is not reachable
    // on the first frame - rebuild once it is.
    final saver = settingsKey.currentState as SettingsSaver?;

    if (saver == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) (context as Element).markNeedsBuild();
      });

      return IconButton(icon: Icon(Icons.save_outlined), onPressed: null);
    }

    return ValueListenableBuilder<bool>(
      valueListenable: saver.dirty,
      builder: (context, dirty, _) => IconButton(
        icon: Icon(Icons.save_outlined),
        tooltip: dirty ? 'Save' : 'Nothing to save',
        onPressed: dirty
            ? () {
                saver.save();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saved'), duration: Duration(seconds: 1)),
                );
              }
            : null,
      ),
    );
  }
}
