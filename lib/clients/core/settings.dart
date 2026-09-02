import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:nexus/cards/state.dart';
import 'package:nexus/clients/core/client.dart';
import 'package:nexus/utils/settings_section.dart';
import 'package:provider/provider.dart';

class CoreSettingsPage extends StatelessWidget {
  const CoreSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final client = context.read<CoreClient>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Nexus Settings'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline),
            tooltip: 'Clear log',
            onPressed: client.clearLog,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSectionHeader('Log'),
          Expanded(child: CoreLogWidget(stateProvider: client.getStateProvider())),
        ],
      ),
    );
  }
}

/// The log as a Material list: one tile per record, newest on top.
class CoreLogWidget extends StateCard<List<LogRecord>> {
  const CoreLogWidget({required super.stateProvider});

  @override
  Widget build(BuildContext context, List<LogRecord>? state) {
    final records = state ?? const <LogRecord>[];

    if (records.isEmpty) {
      return Center(
        child: Text(
          'Nothing logged yet',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    // Selectable so a stack trace can leave the panel by copy-paste.
    return SelectionArea(
      child: ListView.separated(
        itemCount: records.length,
        separatorBuilder: (context, index) => Divider(height: 1, indent: 56),
        itemBuilder: (context, index) => _RecordTile(record: records[index]),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  static final _time = DateFormat('HH:mm:ss.SSS');

  final LogRecord record;

  const _RecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = _accent(scheme);

    final details = [
      if (record.error != null) '${record.error}',
      if (record.stackTrace != null) '${record.stackTrace}',
    ].join('\n');

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(_icon(), color: accent, size: 20),
      title: Text(record.message, style: theme.textTheme.bodyMedium),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${record.loggerName}  ·  ${_time.format(record.time)}',
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (details.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(details, style: theme.textTheme.bodySmall?.copyWith(color: accent)),
            ),
        ],
      ),
    );
  }

  IconData _icon() {
    if (record.level >= Level.SEVERE) return Icons.error_outline;
    if (record.level >= Level.WARNING) return Icons.warning_amber_outlined;
    if (record.level >= Level.INFO) return Icons.info_outline;

    return Icons.bug_report_outlined;
  }

  Color _accent(ColorScheme scheme) {
    if (record.level >= Level.SEVERE) return scheme.error;
    if (record.level >= Level.WARNING) return Colors.orange;
    if (record.level >= Level.INFO) return scheme.primary;

    return scheme.onSurfaceVariant;
  }
}
