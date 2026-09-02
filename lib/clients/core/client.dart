import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nexus/clients/core/log.dart';
import 'package:nexus/clients/core/settings.dart';
import 'package:nexus/clients/state.dart';
import 'package:nexus/dashboard/settings.dart';
import 'package:nexus/utils/generic_icon.dart';

/// The app's own settings. A wall panel has no console attached, so every log
/// record is kept in memory and shown in the Settings tab.
class CoreClient {
  static const _logLimit = 500;

  final _records = <LogRecord>[];
  final _state = StateProvider<List<LogRecord>>();

  CoreClient() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen(_onRecord);

    // Framework prints and errors are logs too - routed here so they show up
    // on the panel rather than only on a console nobody has attached.
    debugPrint = (String? message, {int? wrapWidth}) => logFlutter.info(message ?? '');

    FlutterError.onError = (details) => logFlutter.severe(details.exceptionAsString(), details.exception, details.stack);

    // Errors thrown outside the framework - a failed future, a platform
    // channel - never reach FlutterError.onError.
    PlatformDispatcher.instance.onError = (error, stack) {
      logFlutter.severe('$error', error, stack);

      return false;
    };

    logCore.info('Log started');
  }

  /// Newest record first - the list is what the log page renders.
  StateProvider<List<LogRecord>> getStateProvider() => _state;

  void _onRecord(LogRecord record) {
    _records.add(record);

    if (_records.length > _logLimit) _records.removeRange(0, _records.length - _logLimit);

    _state.setValue(List.from(_records.reversed));

    developer.log(
      record.message,
      time: record.time,
      level: record.level.value,
      name: record.loggerName,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  }

  void clearLog() {
    _records.clear();
    _state.setValue(const []);
  }

  void dispose() {
    _state.dispose();
  }

  SettingsItem makeSettings() {
    return SettingsItem.action(
      icon: GenericIcon.fromIcon(icon: Icons.settings),
      name: 'Nexus',
      action: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CoreSettingsPage()),
      ),
    );
  }
}
