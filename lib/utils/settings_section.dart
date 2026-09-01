import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

/// A settings form's own state: what the fields hold right now, and whether
/// that differs from what the client was given. The values live here rather
/// than in the client, which only hears about them on [save].
abstract class SettingsFormCubit<T> extends Cubit<T> {
  SettingsFormCubit(super.initialState);

  /// Whether the form holds edits the client has not been given yet.
  bool get dirty;

  /// Hands the edited values to the client, which persists them.
  void save();
}

/// App bar save button for a settings page, enabled only while that page has
/// unsaved edits.
class SettingsSaveButton extends StatelessWidget {
  final SettingsFormCubit form;

  const SettingsSaveButton(this.form, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dirty = form.dirty;

    return IconButton(
      icon: Icon(Icons.save_outlined),
      tooltip: dirty ? 'Save' : 'Nothing to save',
      onPressed: dirty
          ? () {
              form.save();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Saved'), duration: Duration(seconds: 1)),
              );
            }
          : null,
    );
  }
}
