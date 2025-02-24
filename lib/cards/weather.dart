import 'package:flutter/material.dart';
import 'package:nexus/cards/details.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/state.dart';
import 'package:nexus/consts.dart';
import 'package:nexus/providers/weather.dart';
import 'package:nexus/utils/token_input_widget.dart';
import 'package:open_weather_client/open_weather.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_icons/weather_icons.dart';

class WeatherCard extends StateCard<WeatherState> {
  final DetailsPage? details;
  WeatherCard({required super.stateProvider, this.details});

  @override
  Widget build(BuildContext context, WeatherState? state) {
    if (state == null)
      return PlainCard(
        icon: Icons.error,
        text: 'Unavailable',
        action: () => details?.navigateTo(context),
      );

    return DetailsCard(
        details: details,
        child: buildGradient(Padding(
            padding: EdgeInsets.all(30),
            child: buildCardContent(context, state))));
  }

  Widget buildGradient(Widget child) {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          gradient: LinearGradient(
            colors: [
              Colors.blue.withOpacity(0.7),
              const Color.fromARGB(255, 122, 213, 255).withOpacity(0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: child);
  }

  Widget buildCardContent(BuildContext context, WeatherState state) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Icon(state.icon, size: iconSize),
        ),
        SizedBox(height: 10),
        Text(
          '${state.temperature.toStringAsFixed(1)}°',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 10),
        Text(
          '${state.minimalTemperature.toStringAsFixed(1)}° ${state.maximumTemperature.toStringAsFixed(1)}°',
          style: TextStyle(
            fontSize: 28,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}
