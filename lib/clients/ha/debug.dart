import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:home_assistant/home_assistant.dart';
import 'package:nexus/cards/base.dart';
import 'package:nexus/cards/state.dart';

class HomeAssistantEntityDebugWidget extends StatefulWidget {
  final Entity entity;

  const HomeAssistantEntityDebugWidget({required this.entity});

  @override
  State<StatefulWidget> createState() => _HomeAssistantEntityDebugWidgetState();
}

class _HomeAssistantEntityDebugWidgetState
    extends State<HomeAssistantEntityDebugWidget> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final main = Text(
      '${widget.entity.entityId} - ${widget.entity.state}',
    );

    final full = Text(JsonEncoder.withIndent('    ')
        .convert(widget.entity.attributes.toJson()));

    return GestureDetector(
      onTap: () {
        setState(() {
          expanded = !expanded;
        });
      },
      child: BaseCard(
        child: Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: !expanded ? [main] : [main, full],
            )),
      ),
    );
  }
}

class HomeAssistantDebugWidget extends StateCard<List<Entity>> {
  HomeAssistantDebugWidget({required super.stateProvider});

  @override
  Widget build(BuildContext context, List<Entity>? state) {
    if (state == null) return Center(child: Text('Null state'));

    return ListView.builder(
      itemBuilder: (BuildContext context, int index) =>
          HomeAssistantEntityDebugWidget(entity: state[index]),
      itemCount: state.length,
      shrinkWrap: true,
    );
  }
}
