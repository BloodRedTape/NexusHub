/// What a vacuum can be asked to do. `start` doubles as resume from a pause.
enum VacuumCommand { start, pause, stop, returnToBase, locate }

class Vacuum {
  /// Raw state from the `vacuum` domain: cleaning, docked, returning, paused,
  /// idle, error.
  final String status;

  /// Null when the vacuum has no speed setting at all.
  final String? fanSpeed;
  final List<String> fanSpeeds;

  /// Set instead of a command to change the speed.
  final String? requestedFanSpeed;
  final VacuumCommand? command;

  const Vacuum({
    required this.status,
    this.fanSpeed,
    this.fanSpeeds = const [],
    this.requestedFanSpeed,
    this.command,
  });

  bool get isRunning => status == 'cleaning' || status == 'returning';
}
