import 'package:flutter/material.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/state.dart';
import 'package:nexus/clients/state.dart';
import 'package:nexus/consts.dart';

/// One automation: what it is called, the category it is filed under, and
/// whether it is armed.
typedef Automation = ({String name, String? category, StateProvider<bool> state});

/// The automations of a room, as one tile: how many are armed, with the
/// switches themselves behind the chevron.
class AutomationsCard extends StatelessWidget {
  final List<Automation> automations;
  final String? room;

  const AutomationsCard({super.key, required this.automations, this.room});

  @override
  Widget build(BuildContext context) {
    return PlainCardBase(
      icon: Icon(Icons.auto_awesome, size: iconSize),
      subAction: PlainAction(
        icon: Icons.chevron_right,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AutomationsDetails(automations: automations, room: room)),
        ),
      ),
      children: [
        StackedLayout(
          primary: _EnabledCount(automations: automations),
          secondary: const SizedBox(),
          name: 'Automations',
        ),
      ],
    );
  }
}

/// "3/5", redrawn whenever any of the automations is switched.
class _EnabledCount extends StatefulWidget {
  final List<Automation> automations;

  const _EnabledCount({required this.automations});

  @override
  State<_EnabledCount> createState() => _EnabledCountState();
}

class _EnabledCountState extends State<_EnabledCount> {
  @override
  void initState() {
    super.initState();
    for (final automation in widget.automations) {
      automation.state.bindValueChanged(_onChanged);
    }
  }

  @override
  void dispose() {
    for (final automation in widget.automations) {
      automation.state.unbind(_onChanged);
    }
    super.dispose();
  }

  void _onChanged(bool? value) => setState(() {});

  @override
  Widget build(BuildContext context) {
    final enabled = widget.automations.where((automation) => automation.state.getValue() == true).length;

    return FittedBox(
      alignment: Alignment.bottomLeft,
      fit: BoxFit.scaleDown,
      child: Text('$enabled/${widget.automations.length}', style: TextStyle(fontSize: primaryTextSize, fontWeight: FontWeight.bold)),
    );
  }
}

/// A switch per automation, nothing else.
class AutomationsDetails extends StatelessWidget {
  final List<Automation> automations;
  final String? room;

  const AutomationsDetails({super.key, required this.automations, this.room});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(room == null ? 'Automations' : 'Automations · $room', maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: ListView(children: _group(context, automations)),
    );
  }
}

/// Automations under the category they belong to, uncategorised ones last.
/// A room where nobody filed anything gets a plain list instead of one header.
List<Widget> _group(BuildContext context, List<Automation> automations) {
  final byCategory = <String?, List<Automation>>{};

  for (final automation in automations) {
    byCategory.putIfAbsent(automation.category, () => []).add(automation);
  }

  if (byCategory.length == 1 && byCategory.keys.single == null) {
    return [for (final automation in automations) _AutomationRow(name: automation.name, stateProvider: automation.state)];
  }

  final categories = byCategory.keys.whereType<String>().toList()..sort();
  final theme = Theme.of(context);

  return [
    for (final category in [...categories, null])
      if (byCategory[category] != null) ...[
        Padding(
          padding: EdgeInsets.fromLTRB(cardPadding, cardPadding, cardPadding, cardPadding / 2),
          child: Text(
            category ?? 'Uncategorized',
            style: TextStyle(fontSize: secondaryTextSize, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
          ),
        ),
        for (final automation in byCategory[category]!) _AutomationRow(name: automation.name, stateProvider: automation.state),
      ],
  ];
}

class _AutomationRow extends StateCard<bool> {
  final String name;

  const _AutomationRow({required this.name, required super.stateProvider});

  @override
  Widget build(BuildContext context, bool? state) {
    return SwitchListTile(
      title: Text(name),
      value: state == true,
      // an automation that never reported cannot be switched blind
      onChanged: state == null ? null : (value) => stateProvider.requestValue(value),
    );
  }
}
