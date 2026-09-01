import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nexus/cards/details.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/state.dart';
import 'package:nexus/consts.dart';
import 'package:nexus/states/weather.dart';

/// Chance of rain is only worth a line once it is worth planning around.
const _rainThreshold = 10.0;

/// The card is painted on whatever the sky is doing, and a pale gradient - snow,
/// fog - leaves white text with nothing to sit against. A soft drop shadow
/// keeps every reading legible without darkening the gradient itself.
const _cardShadow = [Shadow(color: Color(0x99000000), blurRadius: 6, offset: Offset(0, 1))];

/// One of the two panels the forecast is split into: a titled Material surface
/// with a scrolling list of rows.
class _ForecastPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final double fontSize;
  final List<Widget> children;

  const _ForecastPanel({
    required this.icon,
    required this.title,
    required this.fontSize,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      color: colors.surfaceContainer,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: cardPadding, vertical: cardPadding * 0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: cardPadding * 0.5),
              child: Row(
                children: [
                  Icon(icon, size: fontSize * 0.9, color: colors.onSurfaceVariant),
                  SizedBox(width: fontSize * 0.4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: fontSize * 0.7,
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: children.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: colors.outlineVariant),
                itemBuilder: (context, i) => Padding(
                  padding: EdgeInsets.symmetric(vertical: cardPadding * 0.5),
                  child: children[i],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The temperature range of one day, drawn against the range of the whole
/// forecast so the bars are comparable down the column. On the row for today a
/// marker shows where the temperature is right now.
class _RangeBar extends StatelessWidget {
  final WeatherDay day;
  final double minimum;
  final double maximum;
  final double height;

  /// Current temperature, marked on the bar. Only the row for today passes it.
  final double? now;

  const _RangeBar({
    required this.day,
    required this.minimum,
    required this.maximum,
    required this.height,
    this.now,
  });

  /// Cool blue at the cold end of the forecast, warm amber at the hot end, so a
  /// colour means the same temperature on every row. These stay fixed rather
  /// than following the seed colour: they carry meaning, not branding.
  static Color _colorAt(double fraction) =>
      Color.lerp(const Color(0xFF4FC3F7), const Color(0xFFFFB74D), fraction.clamp(0.0, 1.0))!;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // A flat forecast would divide by zero - give it one full-width bar.
    final span = maximum - minimum;
    final start = span == 0 ? 0.0 : (day.minimalTemperature - minimum) / span;
    final end = span == 0 ? 1.0 : (day.maximumTemperature - minimum) / span;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // The bar is never thinner than it is tall, or it stops looking round.
        final barWidth = ((end - start) * width).clamp(height, width);
        final marker = height * 1.6;

        return SizedBox(
          height: marker,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
              Positioned(
                left: start * width,
                width: barWidth,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(height),
                    gradient: LinearGradient(colors: [_colorAt(start), _colorAt(end)]),
                  ),
                ),
              ),
              if (now != null)
                Positioned(
                  // Centre the marker on the reading, then keep it inside the bar.
                  left: (((span == 0 ? 1.0 : (now! - minimum) / span) * width) - marker / 2)
                      .clamp(0.0, width - marker),
                  child: Container(
                    width: marker,
                    height: marker,
                    decoration: BoxDecoration(
                      color: colors.onSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.surfaceContainer, width: height * 0.3),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// One day: name, icon over its chance of rain, low - range bar - high.
class _WeatherDayRow extends StatelessWidget {
  final WeatherDay day;
  final bool isToday;
  final double minimum;
  final double maximum;
  final double fontSize;
  final double? now;

  const _WeatherDayRow({
    required this.day,
    required this.isToday,
    required this.minimum,
    required this.maximum,
    required this.fontSize,
    this.now,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rain = day.precipitationChance;

    return Row(
      children: [
        SizedBox(
          width: fontSize * 3.2,
          child: Text(
            isToday ? 'Today' : DateFormat('EEE').format(day.date),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
              color: colors.onSurface,
            ),
          ),
        ),
        // Icon and rain chance stack, so a wet day says how wet without a
        // column standing empty on every dry one.
        SizedBox(
          width: fontSize * 2.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(day.icon, size: fontSize * 1.1, color: colors.onSurface),
              if (rain != null && rain >= _rainThreshold)
                Text(
                  '${rain.round()}%',
                  style: TextStyle(
                    fontSize: fontSize * 0.6,
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          width: fontSize * 1.9,
          child: Text(
            '${day.minimalTemperature.round()}°',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: fontSize, color: colors.onSurfaceVariant),
          ),
        ),
        SizedBox(width: fontSize * 0.5),
        Expanded(
          child: _RangeBar(
            day: day,
            minimum: minimum,
            maximum: maximum,
            height: fontSize * 0.28,
            now: now,
          ),
        ),
        SizedBox(width: fontSize * 0.5),
        SizedBox(
          width: fontSize * 1.9,
          child: Text(
            '${day.maximumTemperature.round()}°',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: fontSize, color: colors.onSurface),
          ),
        ),
      ],
    );
  }
}

/// One hour: the time, the sky, the temperature.
class _WeatherHourRow extends StatelessWidget {
  final WeatherHour hour;
  final bool isNow;
  final double fontSize;

  const _WeatherHourRow({required this.hour, required this.isNow, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        SizedBox(
          width: fontSize * 3.2,
          child: Text(
            isNow ? 'Now' : DateFormat('HH:mm').format(hour.time),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isNow ? FontWeight.w600 : FontWeight.w500,
              color: colors.onSurface,
            ),
          ),
        ),
        Expanded(child: Icon(hour.icon, size: fontSize * 1.1, color: colors.onSurface)),
        Text(
          '${hour.temperature.round()}°',
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: fontSize, color: colors.onSurface),
        ),
      ],
    );
  }
}

/// The forecast page: the coming hours on the left, the coming days on the
/// right.
class WeatherForecast extends StatelessWidget {
  /// Far enough ahead to plan the day around; past that the daily column says
  /// it better than another twenty rows of hours would.
  static const hoursShown = 16;

  final WeatherState state;

  const WeatherForecast({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    const fontSize = 20.0;

    final hours = state.hourly.take(hoursShown).toList();

    final hourly = _ForecastPanel(
      icon: Icons.schedule,
      title: 'HOURLY FORECAST',
      fontSize: fontSize,
      children: [
        for (var i = 0; i < hours.length; i++)
          _WeatherHourRow(hour: hours[i], isNow: i == 0, fontSize: fontSize),
      ],
    );

    final minimum = state.forecastMinimum;
    final maximum = state.forecastMaximum;

    final daily = _ForecastPanel(
      icon: Icons.calendar_month,
      title: 'DAILY FORECAST',
      fontSize: fontSize,
      children: [
        for (var i = 0; i < state.forecast.length; i++)
          _WeatherDayRow(
            day: state.forecast[i],
            isToday: i == 0,
            minimum: minimum,
            maximum: maximum,
            fontSize: fontSize,
            now: i == 0 ? state.temperature : null,
          ),
      ],
    );

    return Padding(
      padding: EdgeInsets.all(cardPadding),
      // The hourly column carries one number per row against the daily
      // column's five, so it takes the narrower share of the width.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 2, child: hourly),
          SizedBox(width: cardPadding),
          Expanded(flex: 3, child: daily),
        ],
      ),
    );
  }
}

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

    // Without a details page of its own, the card opens its forecast.
    final page = details ??
        (state.forecast.isEmpty
            ? null
            : DetailsPage(
                title: const Text('Forecast'),
                body: WeatherForecast(state: state)));

    return DetailsCard(
        details: page,
        child: buildGradient(
            state,
            Padding(
                padding: EdgeInsets.all(30),
                child: buildCardContent(context, state))));
  }

  Widget buildGradient(WeatherState state, Widget child) {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          gradient: LinearGradient(
            colors: state.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: child);
  }

  Widget buildCardContent(BuildContext context, WeatherState state) {
    final fixed = 0;
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Icon(state.icon, size: iconSize * 0.9, shadows: _cardShadow),
        ),
        Text(
          '${state.temperature.toStringAsFixed(fixed)}°',
          style: TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.bold,
            shadows: _cardShadow,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${state.maximumTemperature.toStringAsFixed(fixed)}°',
              style: TextStyle(
                fontSize: 28,
                shadows: _cardShadow,
              ),
            ),
            const SizedBox(
              width: 8,
            ),
            Text(
              '${state.minimalTemperature.toStringAsFixed(fixed)}°',
              style: TextStyle(
                fontSize: 28,
                color: Colors.grey[400],
                shadows: _cardShadow,
              ),
            )
          ],
        )
      ],
    );
  }
}
