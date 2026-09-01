import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/state.dart';
import 'package:nexus/consts.dart';
import 'package:nexus/providers/state.dart';
import 'package:nexus/states/light.dart';
import 'package:nexus/utils/tint.dart';

// The main light control dialog
class LightControlDialog extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final StateProvider<LightState> stateProvider;

  const LightControlDialog({
    super.key,
    this.title,
    this.subtitle,
    required this.stateProvider,
  });

  @override
  Widget build(BuildContext context) {
    return LightControlContent(
      title: title ?? 'Light',
      subtitle: subtitle,
      stateProvider: stateProvider,
    );
  }

  /// A page rather than a dialog: the app bar's back button is the way out.
  static Future<void> show(
    BuildContext context, {
    String? title,
    String? subtitle,
    required StateProvider<LightState> stateProvider,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return LightControlDialog(
            title: title,
            subtitle: subtitle,
            stateProvider: stateProvider,
          );
        },
      ),
    );
  }
}

class LightControlContent extends StatefulWidget {
  final String title;
  final String? subtitle;
  final StateProvider<LightState> stateProvider;

  const LightControlContent({
    super.key,
    required this.title,
    this.subtitle,
    required this.stateProvider,
  });

  @override
  State<LightControlContent> createState() => _LightControlContentState();
}

class _LightControlContentState extends State<LightControlContent> {
  // What Home Assistant last told us.
  LightState? _confirmed;
  // What the user asked for and HA has not echoed back yet. Null when in sync.
  LightState? _pending;
  // The state at the moment the command went out: anything HA repeats that still
  // equals this is a stale echo, anything else is news and outranks _pending.
  LightState? _pendingWasBefore;
  Timer? _pendingTimeout;
  // Open while a throttled commit is cooling down; holds the drag's last frame
  // so the final colour still goes out after the user lets go.
  Timer? _throttleCooldown;
  bool _throttleMissed = false;
  void Function(LightState?)? _valueChangedCallback;
  ControlMode _controlMode = ControlMode.brightness;

  // A light reports no brightness while it is off, and none for the first frame
  // or two after being switched on either. Stand a zero in whenever it is
  // missing, so the slider never blinks out to the bare bulb mid-transition.
  static LightState? _withZeroes(LightState? s) {
    if (s == null || s.brightness != null) return s;

    return LightState(
      isOn: s.isOn,
      brightness: LimitedValueState(value: 0, min: 0, max: 255),
      temperature: s.temperature,
      color: s.color,
    );
  }

  // A light takes a moment to answer, and the answer often arrives with the old
  // value first. Until then the user's choice wins - but not forever, or a
  // command the light ignored would leave the dialog lying about its state.
  static const _pendingLifetime = Duration(seconds: 4);

  // The colour wheel reports every frame of a drag and has no end-of-gesture
  // callback, so commits are throttled to this and the last frame is flushed
  // when the drag stops arriving.
  static const _throttleInterval = Duration(milliseconds: 200);

  // What the UI draws: the user's intent while it is in flight, else the truth.
  LightState? get _light => _pending ?? _confirmed;

  @override
  void initState() {
    super.initState();
    _valueChangedCallback = (value) {
      setState(() {
        _confirmed = _withZeroes(value);
        // Hold the user's choice only while HA is still repeating the old value.
        if (_pending != null && !_matches(value, _pendingWasBefore)) _clearPending();
        // First state in: land on a mode the light actually has.
        if (!_supports(_controlMode)) {
          _controlMode = ControlMode.values.firstWhere(_supports, orElse: () => ControlMode.brightness);
        }
      });
    };
    widget.stateProvider.bindValueChanged(_valueChangedCallback!);
  }

  @override
  void dispose() {
    _pendingTimeout?.cancel();
    _throttleCooldown?.cancel();
    if (_valueChangedCallback != null) {
      widget.stateProvider.unbind(_valueChangedCallback!);
    }
    super.dispose();
  }

  // HA rounds brightness on its way through, so compare with a little slack.
  bool _matches(LightState? a, LightState? b) {
    if (a == null || b == null) return false;

    bool near(LimitedValueState? x, LimitedValueState? y) =>
        x == null || y == null || (x.value - y.value).abs() <= (x.max - x.min) * 0.02;

    return a.isOn == b.isOn &&
        near(a.brightness, b.brightness) &&
        near(a.temperature, b.temperature) &&
        (a.color?.value.toARGB32() == b.color?.value.toARGB32());
  }

  void _clearPending() {
    _pendingTimeout?.cancel();
    _pendingTimeout = null;
    _pending = null;
    _pendingWasBefore = null;
  }

  // Edit the pending copy, never the object the provider handed us.
  void _edit(void Function(LightState) change) {
    final base = _light;
    if (base == null) return;

    setState(() {
      _pending = _copy(base);
      change(_pending!);
    });
  }

  // Send what the user picked and hold it on screen until HA agrees.
  void _commit({bool dropZeroBrightness = false}) {
    if (_pending == null) return;

    final request = _copy(_pending!);
    if (dropZeroBrightness && request.brightness?.value == 0) request.brightness = null;

    _pendingWasBefore ??= _confirmed == null ? null : _copy(_confirmed!);
    widget.stateProvider.requestValue(request);
    _pendingTimeout?.cancel();
    _pendingTimeout = Timer(_pendingLifetime, () {
      if (mounted) setState(_clearPending);
    });
  }

  // Commit at most once per _throttleInterval. A change arriving mid-cooldown is
  // not dropped: it is remembered and sent when the cooldown ends, so whatever
  // the user landed on is always the last thing the light hears.
  void _commitThrottled() {
    if (_throttleCooldown != null) {
      _throttleMissed = true;
      return;
    }

    _commit();
    _throttleCooldown = Timer(_throttleInterval, () {
      _throttleCooldown = null;
      if (!_throttleMissed) return;

      _throttleMissed = false;
      if (mounted) _commitThrottled();
    });
  }

  LightState _copy(LightState s) => LightState(
        isOn: s.isOn,
        brightness: _copyLimited(s.brightness),
        temperature: _copyLimited(s.temperature),
        color: s.color == null ? null : ColorState(value: s.color!.value),
      );

  LimitedValueState? _copyLimited(LimitedValueState? v) =>
      v == null ? null : LimitedValueState(value: v.value, min: v.min, max: v.max);

  double _fraction(LimitedValueState? v) => v?.fraction ?? 0;

  // Sliders are addressed by mode, because after _edit the object identity of
  // the value the user is dragging changes with every copy.
  void _setFraction(ControlMode mode, double position) {
    _edit((light) {
      final v = mode == ControlMode.temperature ? light.temperature : light.brightness;
      if (v == null) return;

      v.value = (v.min + (v.max - v.min) * position).clamp(v.min, v.max);
      // Dragging brightness up is also a way to switch the light on.
      if (mode == ControlMode.brightness) light.isOn = v.value > v.min;
    });
  }

  bool _supports(ControlMode mode) {
    switch (mode) {
      case ControlMode.brightness:
        return _light?.brightness != null;
      case ControlMode.temperature:
        return _light?.temperature != null;
      case ControlMode.color:
        return _light?.color != null;
    }
  }

  // The light's own colour, or a warm default: what the cards paint icons with.
  Color _accent() {
    final base = _light?.color?.value ?? const Color(0xFFFFC46B);
    if (_light?.isOn == true) return base;

    return Color.lerp(base, Theme.of(context).colorScheme.surfaceContainerHighest, 0.75)!;
  }

  // The card treatment: the same colour dimmed down to sit behind content.
  // Only the controls wear it - the dialog itself stays neutral.
  Color _tint() => Tint.color(color: _accent(), fraction: 0.4)!;

  void _togglePower() {
    if (_light == null) return;

    _edit((light) => light.isOn = !light.isOn);
    // The zero standing in for a missing brightness is a display value, not a
    // command: switching on at zero would turn the light straight back off. Drop
    // it from the request only - _pending keeps it, so the slider stays put.
    _commit(dropZeroBrightness: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: _buildTitle()),
      body: Padding(
        padding: EdgeInsets.all(cardPadding * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The controls stay a comfortable width even on a wide tablet.
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: cardPadding * 2),
                    child: _buildBody(),
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _buildControlButtons(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    final theme = Theme.of(context);
    final brightness = _light?.brightness;

    final status = _light == null
        ? 'Unavailable'
        : !_light!.isOn
            ? 'Off'
            : brightness != null
                ? '${(_fraction(brightness) * 100).round()}%'
                : 'On';

    return Text.rich(
      TextSpan(children: [
        TextSpan(text: widget.title),
        TextSpan(
          text: ' · ${widget.subtitle ?? status}',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildBody() {
    switch (_controlMode) {
      case ControlMode.color:
        // Colour and temperature say nothing about a light that is off: keep the
        // layout, but show it as unavailable until there is light to tune.
        return _disabledWhenOff(_supports(ControlMode.color) ? _buildColorPicker() : _buildBrightness());
      case ControlMode.temperature:
        return _disabledWhenOff(_supports(ControlMode.temperature) ? _buildTemperature() : _buildBrightness());
      case ControlMode.brightness:
        // Brightness stays live - dragging it up is how the light comes back on.
        return _buildBrightness();
    }
  }

  Widget _disabledWhenOff(Widget child) {
    if (_light?.isOn != false) return child;

    return IgnorePointer(child: Opacity(opacity: 0.4, child: child));
  }

  Widget _buildBrightness() {
    // Truly no dimmer on this light: a big tappable bulb instead of a fake
    // slider. An off dimmable light reports no brightness either, but _supports
    // remembers it, so it keeps the slider - reading zero.
    if (!_supports(ControlMode.brightness)) {
      return Center(
        child: GestureDetector(
          onTap: _togglePower,
          child: Icon(Icons.lightbulb, size: iconSize * 3, color: _accent()),
        ),
      );
    }

    final on = _light?.isOn == true;
    final fraction = _fraction(_light?.brightness);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: _stepButton(Icons.remove, on && fraction > 0 ? () => _step(-0.1) : null)),
        _VerticalSlider(
          value: fraction,
          fill: _accent(),
          trough: _tint(),
          // With the light off there is no brightness to drag: the slider shows
          // the state but the power button is what brings it back.
          onChanged: on ? (v) => _setFraction(ControlMode.brightness, v) : null,
          onChangeEnd: _commit,
          icon: on ? Icons.light_mode : Icons.light_mode_outlined,
        ),
        Expanded(child: _stepButton(Icons.add, on && fraction < 1 ? () => _step(0.1) : null)),
      ],
    );
  }

  // Nudge brightness by a tenth - easier than aiming on a tablet.
  void _step(double delta) {
    _setFraction(ControlMode.brightness, (_fraction(_light?.brightness) + delta).clamp(0.0, 1.0));
    _commit();
  }

  Widget _stepButton(IconData icon, VoidCallback? onTap) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(cardBorderRadius);

    return Center(
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: onTap == null ? 0.4 : 1),
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              icon,
              size: iconSize * 0.8,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: onTap == null ? 0.4 : 1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemperature() {
    final temperature = _light!.temperature!;

    return Column(
      children: [
        Expanded(
          child: _VerticalSlider(
            value: _fraction(temperature),
            // Mireds: low is cold light, high is warm - so the bar warms upwards.
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xFFCFE6FF), Color(0xFFFFF1DC), Color(0xFFFFB65C)],
            ),
            onChanged: (v) => _setFraction(ControlMode.temperature, v),
            onChangeEnd: _commit,
            icon: Icons.thermostat,
            iconColor: Colors.black54,
          ),
        ),
        SizedBox(height: cardPadding / 2),
        Text('${temperature.value.round()} mired', style: TextStyle(fontSize: secondaryTextSize)),
      ],
    );
  }

  Widget _buildColorPicker() {
    void onColorChanged(Color color) {
      _edit((light) {
        light.color!.value = color;
        light.isOn = true; // Turn on when color is changed
      });
      _commitThrottled();
    }

    // The picker sizes its wheel from colorPickerWidth and stacks its own slider
    // row (a 50px indicator in 5/5 padding, plus the row's own slack) under it,
    // so the wheel has to give that row up out of the height available. It needs
    // a bounded width of its own - the row inside uses Expanded.
    return LayoutBuilder(builder: (context, constraints) {
      const sliderRow = 80.0;
      final width = (constraints.maxHeight - sliderRow).clamp(0.0, constraints.maxWidth).floorToDouble();

      return SizedBox(
        width: width,
        child: ColorPicker(
          pickerColor: _light!.color!.value,
          onColorChanged: onColorChanged,
          labelTypes: const [],
          paletteType: PaletteType.hueWheel,
          displayThumbColor: true,
          enableAlpha: false,
          portraitOnly: true,
          colorPickerWidth: width,
          pickerAreaHeightPercent: 1,
        ),
      );
    });
  }

  Widget _buildControlButtons() {
    final theme = Theme.of(context);
    final on = _light?.isOn == true;
    // Only offer a mode switch when there is more than one mode to switch to.
    final modes = ControlMode.values.where(_supports).toList();

    return Row(
      children: [
        // The power button wears the card treatment: tinted ground, lit content.
        Expanded(
          child: _ModeButton(
            icon: Icons.power_settings_new,
            label: on ? 'On' : 'Off',
            selected: on,
            background: on ? _tint() : null,
            foreground: on ? _accent() : null,
            onTap: _togglePower,
          ),
        ),
        if (modes.length > 1)
          for (final mode in modes) ...[
            SizedBox(width: cardPadding / 2),
            _ModeButton(
              icon: _modeIcon(mode),
              selected: _controlMode == mode,
              background: _controlMode == mode ? theme.colorScheme.primary : null,
              swatch: mode == ControlMode.color ? _light?.color?.value : null,
              // Nothing to tune on a light that is off - except its brightness.
              enabled: on || mode == ControlMode.brightness,
              onTap: () => setState(() => _controlMode = mode),
            ),
          ],
      ],
    );
  }

  IconData _modeIcon(ControlMode mode) {
    switch (mode) {
      case ControlMode.brightness:
        return Icons.brightness_6;
      case ControlMode.temperature:
        return Icons.thermostat;
      case ControlMode.color:
        return Icons.palette;
    }
  }
}

// A fat vertical bar filled from the bottom: drag anywhere on it, or tap a spot.
class _VerticalSlider extends StatelessWidget {
  final double value;
  final Color? fill;
  final Color? trough;
  final Gradient? gradient;
  // Null leaves the bar readable but inert.
  final ValueChanged<double>? onChanged;
  final VoidCallback onChangeEnd;
  final IconData? icon;
  final Color? iconColor;

  const _VerticalSlider({
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
    this.fill,
    this.trough,
    this.gradient,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(builder: (context, constraints) {
      final height = constraints.maxHeight;
      // Wide enough to hit comfortably, but it must not grow into a slab on a
      // tall fullscreen dialog.
      final width = (height * 0.42).clamp(0.0, constraints.maxWidth.clamp(0.0, 140.0));
      final radius = cardBorderRadius;

      final enabled = onChanged != null;

      void fromLocal(Offset local) => onChanged!((1 - local.dy / height).clamp(0.0, 1.0));

      return Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (d) => fromLocal(d.localPosition) : null,
          onTapUp: enabled ? (_) => onChangeEnd() : null,
          onVerticalDragUpdate: enabled ? (d) => fromLocal(d.localPosition) : null,
          onVerticalDragEnd: enabled ? (_) => onChangeEnd() : null,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: trough ?? theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(radius),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Keep a stub of fill at zero so the bar stays readable.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  height: (height * value).clamp(width * 0.55, height),
                  decoration: BoxDecoration(color: gradient == null ? fill : null, gradient: gradient),
                ),
                if (icon != null)
                  Positioned(
                    bottom: width * 0.25,
                    child: Icon(icon, size: iconSize, color: iconColor ?? Colors.white70),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool selected;
  final bool enabled;
  // Both default to the neutral surface treatment when not given.
  final Color? background;
  final Color? foreground;
  final Color? swatch;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    this.background,
    this.foreground,
    this.label,
    this.swatch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(cardBorderRadius);
    final ground = background ?? theme.colorScheme.surfaceContainerHighest;
    final content = foreground ??
        (selected
            ? (ThemeData.estimateBrightnessForColor(ground) == Brightness.dark ? Colors.white : Colors.black87)
            : theme.colorScheme.onSurfaceVariant);
    final size = 56.0;
    // Same dimming as the step buttons, so "unavailable" reads the same
    // everywhere in the dialog.
    final fade = enabled ? 1.0 : 0.4;

    return Material(
      color: ground.withValues(alpha: fade),
      borderRadius: radius,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: radius,
        child: Container(
          height: size,
          constraints: BoxConstraints(minWidth: size),
          padding: EdgeInsets.symmetric(horizontal: label == null ? 0 : cardPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: iconSize * 0.7, color: content.withValues(alpha: fade)),
                  if (swatch != null && !selected)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: swatch,
                          border: Border.all(color: theme.colorScheme.surfaceContainerHighest, width: 1),
                        ),
                      ),
                    ),
                ],
              ),
              if (label != null) ...[
                const SizedBox(width: 8),
                Text(label!, style: TextStyle(fontSize: secondaryTextSize, color: content.withValues(alpha: fade))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Enum for control modes
enum ControlMode { brightness, temperature, color }

// Extension method to easily show the dialog
extension LightControlExtension on BuildContext {
  Future<void> showLightControl({
    String? title,
    String? subtitle,
    required StateProvider<LightState> stateProvider,
  }) {
    return LightControlDialog.show(
      this,
      title: title,
      subtitle: subtitle,
      stateProvider: stateProvider,
    );
  }
}

class LightCard extends StateCard<LightState> {
  final IconData onIcon;
  final IconData offIcon;
  final String? name;

  LightCard({
    required super.stateProvider,
    required this.onIcon,
    required this.offIcon,
    this.name,
  });

  @override
  Widget build(BuildContext context, LightState? state) {
    return PlainCard(
      color: _color(state),
      icon: _icon(state),
      iconColor: _iconColor(state),
      text: _stateToText(state),
      subText: name,
      action: () {
        if (state != null) switchState(state);
      },
      subAction: state == null
          ? null
          : PlainAction(
              icon: Icons.chevron_right,
              onTap: () => _buildControlDialog(context),
            ),
      // An off light reports no brightness - nothing to show a level for.
      percent: state != null && state.isOn ? state.brightness?.fraction : null,
      // Filled in the light's own colour, the rest the same colour tinted
      // further down than the card behind it (which sits at 0.4).
      percentColor: _iconColor(state),
      percentBackgroundColor: Tint.color(color: state?.color?.value, fraction: 0.3),
    );
  }

  Color? _color(LightState? state) {
    return state != null ? Tint.color(color: state.color?.value, fraction: 0.4) : null;
  }

  Future<void> _buildControlDialog(BuildContext context) {
    return context.showLightControl(stateProvider: stateProvider, title: name);
  }

  void switchState(LightState state) {
    stateProvider.requestValue(
      LightState(
        isOn: !state.isOn,
        brightness: state.brightness,
        color: state.color,
        temperature: state.temperature,
      ),
    );
  }

  String _stateToText(LightState? state) {
    if (state == null) return 'Unavailable';

    return state.isOn ? 'On' : 'Off';
  }

  IconData _icon(LightState? state) {
    if (state == null) {
      return Icons.error;
    }

    return state.isOn ? onIcon : offIcon;
  }

  Color _iconColor(LightState? state) {
    return state?.color?.value ?? Colors.white;
  }
}
