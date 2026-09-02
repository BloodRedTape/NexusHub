import 'package:flutter/material.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/state.dart';
import 'package:nexus/consts.dart';
import 'package:nexus/clients/state.dart';
import 'package:nexus/clients/ha/models/vacuum.dart';
import 'package:nexus/utils/material_design_icons.dart';
import 'package:nexus/utils/tint.dart';

const _labels = {
  'cleaning': 'Cleaning',
  'docked': 'Docked',
  'returning': 'Returning',
  'paused': 'Paused',
  'idle': 'Idle',
  'error': 'Error',
};

const _accent = Color.fromARGB(255, 2, 82, 128);

String _label(String status) => _labels[status] ?? status;

// Anything but sitting on its dock is something happening: it wears the accent.
Color? _statusColor(String status) {
  if (status == 'error') return Colors.red;

  return status == 'docked' ? null : _accent;
}

class VacuumCard extends StateCard<Vacuum> {
  final String? name;

  const VacuumCard({required super.stateProvider, this.name});

  @override
  Widget build(BuildContext context, Vacuum? state) {
    if (state == null) return PlainCard(icon: Icons.error, text: 'Unavailable', subText: name);

    final color = _statusColor(state.status);

    return PlainCard(
      color: Tint.color(color: color, fraction: 0.4),
      icon: MaterialDesignIcons.robotVacuum,
      iconColor: color ?? Colors.white,
      text: _label(state.status),
      subText: name,
      subAction: PlainAction(
        icon: Icons.chevron_right,
        onTap: () => VacuumControlDialog.show(context, title: name, stateProvider: stateProvider),
      ),
    );
  }
}

/// The controls behind the chevron, laid out like the light dialog: a header, the
/// vacuum itself in the middle, its commands along the bottom.
class VacuumControlDialog extends StatelessWidget {
  final String? title;
  final StateProvider<Vacuum> stateProvider;

  const VacuumControlDialog({super.key, this.title, required this.stateProvider});

  @override
  Widget build(BuildContext context) {
    return VacuumControlContent(title: title ?? 'Vacuum', stateProvider: stateProvider);
  }

  /// A page rather than a dialog: the app bar's back button is the way out.
  static Future<void> show(BuildContext context, {String? title, required StateProvider<Vacuum> stateProvider}) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VacuumControlDialog(title: title, stateProvider: stateProvider)),
    );
  }
}

class VacuumControlContent extends StateCard<Vacuum> {
  final String title;

  const VacuumControlContent({required this.title, required super.stateProvider});

  @override
  Widget build(BuildContext context, Vacuum? state) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: _buildTitle(context, state)),
      body: Padding(
        padding: EdgeInsets.all(cardPadding * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: Icon(
                  MaterialDesignIcons.robotVacuum,
                  size: iconSize * 3,
                  color: state == null ? null : _statusColor(state.status) ?? theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _buildControlButtons(context, state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, Vacuum? state) {
    final theme = Theme.of(context);

    return Text.rich(
      TextSpan(children: [
        TextSpan(text: title),
        TextSpan(
          text: ' · ${state == null ? 'Unavailable' : _label(state.status)}',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildControlButtons(BuildContext context, Vacuum? state) {
    if (state == null) return const SizedBox();

    void send(VacuumCommand command) => stateProvider.requestValue(Vacuum(status: state.status, command: command));

    final running = state.isRunning;

    return Row(
      children: [
        // Start doubles as resume, so a vacuum already out gets a pause instead.
        Expanded(
          child: _VacuumButton(
            icon: running ? Icons.pause : Icons.play_arrow,
            label: running ? 'Pause' : 'Start',
            background: running ? Tint.color(color: _accent, fraction: 0.4) : null,
            foreground: running ? _accent : null,
            onTap: () => send(running ? VacuumCommand.pause : VacuumCommand.start),
          ),
        ),
        SizedBox(width: cardPadding / 2),
        _VacuumButton(icon: Icons.stop, onTap: () => send(VacuumCommand.stop)),
        SizedBox(width: cardPadding / 2),
        _VacuumButton(icon: Icons.home, onTap: () => send(VacuumCommand.returnToBase)),
        SizedBox(width: cardPadding / 2),
        _VacuumButton(icon: Icons.place, onTap: () => send(VacuumCommand.locate)),
        if (state.fanSpeeds.isNotEmpty) ...[
          SizedBox(width: cardPadding / 2),
          _FanSpeedButton(
            state: state,
            onPicked: (speed) => stateProvider.requestValue(Vacuum(status: state.status, requestedFanSpeed: speed)),
          ),
        ],
      ],
    );
  }
}

/// The light dialog's button treatment: neutral ground, tinted when it is the
/// thing currently happening.
class _VacuumButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color? background;
  final Color? foreground;
  final VoidCallback onTap;

  const _VacuumButton({required this.icon, required this.onTap, this.label, this.background, this.foreground});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(cardBorderRadius);
    final content = foreground ?? theme.colorScheme.onSurfaceVariant;
    final size = 56.0;

    return Material(
      color: background ?? theme.colorScheme.surfaceContainerHighest,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: size,
          constraints: BoxConstraints(minWidth: size),
          padding: EdgeInsets.symmetric(horizontal: label == null ? 0 : cardPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize * 0.7, color: content),
              if (label != null) ...[
                const SizedBox(width: 8),
                Text(label!, style: TextStyle(fontSize: secondaryTextSize, color: content)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FanSpeedButton extends StatelessWidget {
  final Vacuum state;
  final void Function(String) onPicked;

  const _FanSpeedButton({required this.state, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(cardBorderRadius);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: radius,
      child: PopupMenuButton<String>(
        onSelected: onPicked,
        initialValue: state.fanSpeed,
        tooltip: state.fanSpeed ?? 'Fan speed',
        itemBuilder: (context) => [for (final speed in state.fanSpeeds) PopupMenuItem(value: speed, child: Text(speed))],
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(MaterialDesignIcons.fan, size: iconSize * 0.7, color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
