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

/// The type size the forecast is built from - everything else is a multiple.
const _fontSize = 20.0;

/// A titled Material surface, the way the reference lays a forecast out: the
/// section name with its icon sits inside the card, above the content.
class _ForecastPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _ForecastPanel({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      color: colors.surfaceContainer,
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: _fontSize * 0.9, color: colors.onSurfaceVariant),
                SizedBox(width: _fontSize * 0.4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _fontSize * 0.8,
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: cardPadding * 0.75),
            Expanded(child: child),
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

  /// Material blue at the cold end, green through the middle, orange at the hot
  /// end, so a colour means the same temperature on every row. These stay fixed
  /// rather than following the seed colour: they carry meaning, not branding.
  static const _cold = Color(0xFF42A5F5);
  static const _mild = Color(0xFF66BB6A);
  static const _hot = Color(0xFFFFA726);

  static Color _colorAt(double fraction) {
    final f = fraction.clamp(0.0, 1.0);

    return f < 0.5
        ? Color.lerp(_cold, _mild, f * 2)!
        : Color.lerp(_mild, _hot, (f - 0.5) * 2)!;
  }

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
                    gradient: LinearGradient(
                      colors: [_colorAt(start), _colorAt(end)],
                    ),
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
  final double? now;

  const _WeatherDayRow({
    required this.day,
    required this.isToday,
    required this.minimum,
    required this.maximum,
    this.now,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rain = day.precipitationChance;

    return Row(
      children: [
        SizedBox(
          width: _fontSize * 3.2,
          child: Text(
            isToday ? 'Today' : DateFormat('EEE').format(day.date),
            style: TextStyle(
              fontSize: _fontSize,
              fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
              color: colors.onSurface,
            ),
          ),
        ),
        // Icon and rain chance stack, so a wet day says how wet without a
        // column standing empty on every dry one.
        SizedBox(
          width: _fontSize * 2.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(day.icon, size: _fontSize * 1.1, color: colors.onSurface),
              if (rain != null && rain >= _rainThreshold)
                Text(
                  '${rain.round()}%',
                  style: TextStyle(
                    fontSize: _fontSize * 0.6,
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          width: _fontSize * 1.9,
          child: Text(
            '${day.minimalTemperature.round()}°',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: _fontSize, color: colors.onSurfaceVariant),
          ),
        ),
        SizedBox(width: _fontSize * 0.5),
        Expanded(
          child: _RangeBar(
            day: day,
            minimum: minimum,
            maximum: maximum,
            height: _fontSize * 0.28,
            now: now,
          ),
        ),
        SizedBox(width: _fontSize * 0.5),
        SizedBox(
          width: _fontSize * 1.9,
          child: Text(
            '${day.maximumTemperature.round()}°',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: _fontSize, color: colors.onSurface),
          ),
        ),
      ],
    );
  }
}

/// One hour, as a column the way the reference draws it: temperature on top,
/// the sky in the middle, the time underneath.
class _WeatherHourColumn extends StatelessWidget {
  final WeatherHour hour;
  final bool isNow;

  const _WeatherHourColumn({required this.hour, required this.isNow});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: _fontSize * 3.4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${hour.temperature.round()}°',
            style: TextStyle(
              fontSize: _fontSize,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          Icon(hour.icon, size: _fontSize * 1.3, color: colors.onSurface),
          Text(
            isNow ? 'Now' : DateFormat('HH:mm').format(hour.time),
            style: TextStyle(
              fontSize: _fontSize * 0.75,
              color: isNow ? colors.onSurface : colors.onSurfaceVariant,
              fontWeight: isNow ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// What the sky is doing right now: the reading the rest of the page is
/// context for.
class _CurrentConditions extends StatelessWidget {
  final WeatherState state;

  const _CurrentConditions({required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          state.label,
          style: TextStyle(fontSize: _fontSize * 1.2, color: colors.onSurfaceVariant),
        ),
        SizedBox(height: cardPadding * 0.5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${state.temperature.round()}°',
              style: TextStyle(
                fontSize: _fontSize * 4,
                fontWeight: FontWeight.w400,
                height: 1,
                color: colors.onSurface,
              ),
            ),
            SizedBox(width: _fontSize * 0.4),
            Icon(state.icon, size: _fontSize * 2.4, color: colors.onSurface),
          ],
        ),
        SizedBox(height: cardPadding * 0.75),
        Text(
          'High ${state.maximumTemperature.round()}° · Low ${state.minimalTemperature.round()}°',
          style: TextStyle(fontSize: _fontSize * 0.9, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// The forecast page, laid out for a landscape screen: what it is doing now on
/// the left, the two forecast panels stacked on the right.
class WeatherForecast extends StatelessWidget {
  /// Far enough ahead to plan the day around; past that the daily panel says it
  /// better than another twenty columns of hours would.
  static const hoursShown = 16;

  final WeatherState state;

  const WeatherForecast({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final hours = state.hourly.take(hoursShown).toList();

    final hourly = _ForecastPanel(
      icon: Icons.schedule,
      title: 'Hourly forecast',
      // However wide the panel lands, the strip cuts through a column. Fading
      // that edge out says "there is more" instead of looking clipped.
      child: ShaderMask(
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [Colors.white, Colors.white, Colors.transparent],
          stops: const [0.0, 0.9, 1.0],
        ).createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: hours.length,
          separatorBuilder: (_, __) => SizedBox(width: cardPadding * 0.5),
          itemBuilder: (context, i) => _WeatherHourColumn(hour: hours[i], isNow: i == 0),
        ),
      ),
    );

    final minimum = state.forecastMinimum;
    final maximum = state.forecastMaximum;

    final daily = _ForecastPanel(
      icon: Icons.calendar_month,
      title: 'Daily forecast',
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: state.forecast.length,
        separatorBuilder: (_, __) => SizedBox(height: cardPadding * 0.5),
        itemBuilder: (context, i) => _WeatherDayRow(
          day: state.forecast[i],
          isToday: i == 0,
          minimum: minimum,
          maximum: maximum,
          now: i == 0 ? state.temperature : null,
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.all(cardPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 2, child: _CurrentConditions(state: state)),
          SizedBox(width: cardPadding),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The hourly strip only needs the height of one column; the days
                // take whatever is left.
                SizedBox(height: _fontSize * 7.5, child: hourly),
                SizedBox(height: cardPadding),
                Expanded(child: daily),
              ],
            ),
          ),
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
                title: Text.rich(TextSpan(children: [
                  const TextSpan(text: 'Forecast'),
                  TextSpan(
                    text: ' · ${state.label}',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ])),
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
