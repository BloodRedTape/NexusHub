import 'package:flutter/material.dart';
import 'package:nexus/core/dashboard_card.dart';
import 'dart:async';

import 'package:nexus/core/dashboard_details.dart';

class Clock extends StatefulWidget {
  final double size;

  const Clock({required this.size});

  @override
  _ClockState createState() => _ClockState();
}

class _ClockState extends State<Clock> {
  late String _timeString;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timeString = _formatDateTime(DateTime.now());

    _timer =
        Timer.periodic(Duration(seconds: 1), (Timer t) => _getCurrentTime());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _getCurrentTime() {
    final DateTime now = DateTime.now();
    final String formattedDateTime = _formatDateTime(now);
    setState(() {
      _timeString = formattedDateTime;
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _timeString,
        style: TextStyle(
          fontSize: widget.size,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class ClockCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Clock(size: 96),
      details: DashboardDetails(body: Clock(size: 240)),
    );
  }
}
