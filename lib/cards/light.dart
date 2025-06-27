import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/state.dart';
import 'package:nexus/consts.dart';
import 'package:nexus/providers/state.dart';
import 'package:nexus/states/light.dart';
import 'package:nexus/utils/generic_icon.dart';
import 'package:nexus/utils/safe_slider.dart';
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: LightControlContent(
        title: title ?? 'Light',
        subtitle: subtitle,
        stateProvider: stateProvider,
      ),
    );
  }

  // Helper method to show the dialog
  static Future<void> show(
    BuildContext context, {
    String? title,
    String? subtitle,
    required StateProvider<LightState> stateProvider,
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return LightControlDialog(
          title: title,
          subtitle: subtitle,
          stateProvider: stateProvider,
        );
      },
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
  LightState? _light;
  void Function(LightState?)? _valueChangedCallback;
  ControlMode _controlMode = ControlMode.brightness;

  @override
  void initState() {
    super.initState();
    _valueChangedCallback = (value) {
      setState(() {
        _light = value;
      });
    };
    widget.stateProvider.bindValueChanged(_valueChangedCallback!);
  }

  @override
  void dispose() {
    if (_valueChangedCallback != null) {
      widget.stateProvider.unbind(_valueChangedCallback!);
    }
    super.dispose();
  }

  void _updateLightState() {
    if (_light != null) {
      widget.stateProvider.requestValue(_light!);
    }
  }

  double _calculateBrightnessPercentage() {
    if (_light?.brightness == null) return 0;

    final b = _light!.brightness!;
    final range = b.max - b.min;
    if (range <= 0) return 0;

    return (b.value - b.min) / range;
  }

  void _onSliderChanged(double position) {
    if (_light?.brightness != null) {
      final b = _light!.brightness!;
      final range = b.max - b.min;
      final newValue = b.min + (range * position);

      setState(() {
        b.value = newValue.clamp(b.min + 1, b.max);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightnessPercent = (_calculateBrightnessPercentage() * 100).round();

    final isColorPicker = _controlMode == ControlMode.color && _light?.color != null;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header section
          _buildHeader(),

          if (!isColorPicker)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: Column(
                children: [
                  Text(
                    "$brightnessPercent%",
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    height: 300,
                    child: _buildLightSlider(),
                  ),
                ],
              ),
            )
          else
            _buildColorPicker(),

          // Control buttons
          const SizedBox(height: 20),
          _buildControlButtons(),

          // Color picker
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(), // Remove padding
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLightSlider() {
    return LayoutBuilder(builder: (context, constraints) {
      final height = constraints.maxHeight;
      final brightnessPercent = _calculateBrightnessPercentage();
      final sliderHeight = height * 0.8;
      final sliderWidth = sliderHeight * 0.5;
      final zeroOffset = sliderHeight * 0.1;
      final lineHeight = sliderHeight * 0.02;

      final percentPerPixel = 1.0 / sliderHeight;
      final cornerRadius = sliderWidth / 8;

      return GestureDetector(
        onVerticalDragUpdate: (details) {
          if (_controlMode == ControlMode.brightness && _light?.brightness != null) {
            final delta = -details.delta.dy * percentPerPixel;
            _onSliderChanged((brightnessPercent + delta).clamp(0.0, 1.0));
          }
        },
        onVerticalDragEnd: (_) {
          _updateLightState();
        },
        onTapUp: (details) {
          if (_controlMode == ControlMode.brightness && _light?.brightness != null) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final Offset localPosition = box.globalToLocal(details.globalPosition);
            final double dy = localPosition.dy;

            // Calculate relative position from bottom
            final sliderStart = (height - sliderHeight - zeroOffset) / 2;
            final sliderEnd = sliderStart + sliderHeight + zeroOffset;

            if (dy >= sliderStart && dy <= sliderEnd) {
              final position = 1.0 - ((dy - sliderStart - zeroOffset / 2) / sliderHeight);
              _onSliderChanged(position.clamp(0.0, 1.0));
            }

            _updateLightState();
          }
        },
        child: Center(
          child: Container(
            width: sliderWidth,
            height: zeroOffset + sliderHeight,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(cornerRadius), // Less rounded corners
            ),
            clipBehavior: Clip.antiAlias, // Fix for the broken corners
            child: Stack(
              children: [
                // Empty part
                Container(
                  color: Colors.grey[200],
                ),
                // Filled part - position from bottom
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    height: zeroOffset + sliderHeight * brightnessPercent,
                    decoration: BoxDecoration(
                      color: _light?.isOn == true ? (_light?.color?.value ?? Colors.red) : Colors.grey,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(cornerRadius),
                        topRight: Radius.circular(cornerRadius),
                      ),
                    ),
                  ),
                ),
                // Indicator line
                Positioned(
                  bottom: (zeroOffset + sliderHeight * brightnessPercent) - zeroOffset / 2 - lineHeight / 2,
                  left: sliderWidth * 0.1,
                  child: Container(
                    width: sliderWidth * 0.8,
                    height: lineHeight,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildControlButtons() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Power button
          _buildRoundButton(
            icon: Icons.power_settings_new,
            selected: false,
            onTap: () {
              if (_light != null) {
                setState(() {
                  _light!.isOn = !_light!.isOn;
                });
                _updateLightState();
              }
            },
            backgroundColor: Colors.white,
            iconColor: Colors.black54,
          ),

          // Settings button
          _buildRoundButton(
            icon: Icons.wb_sunny_outlined,
            selected: _controlMode == ControlMode.brightness,
            onTap: () {
              setState(() {
                _controlMode = ControlMode.brightness;
              });
            },
          ),

          // Color picker button
          _buildRoundButton(
            icon: Icons.color_lens,
            selected: _controlMode == ControlMode.color,
            onTap: () {
              setState(() {
                _controlMode = ControlMode.color;
              });
            },
            isColorButton: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    Color? backgroundColor,
    Color? iconColor,
    bool isColorButton = false,
    bool isTemperatureButton = false,
  }) {
    final bgColor = selected ? Colors.black : (backgroundColor ?? Colors.transparent);

    final fgColor = selected ? Colors.white : (iconColor ?? Colors.black);

    Widget iconWidget = Icon(icon, color: fgColor, size: 20);

    if (isColorButton) {
      iconWidget = Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: fgColor, size: 20),
          if (!selected)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _light?.color?.value ?? Colors.red,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
        ],
      );
    }

    if (isTemperatureButton) {
      iconWidget = Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: fgColor, size: 20),
          if (!selected)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.white],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
        ],
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          margin: EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Center(child: iconWidget),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    void onColorChanged(Color color) {
      setState(() {
        _light!.color!.value = color;
        _light!.isOn = true; // Turn on when color is changed
      });
      _updateLightState();
    }

    final color = _light!.color!.value;
    return SizedBox(
        width: 300,
        child: ColorPicker(
          pickerColor: color,
          onColorChanged: onColorChanged,
          labelTypes: [],
          paletteType: PaletteType.hueWheel,
          displayThumbColor: true,
          enableAlpha: false,
          portraitOnly: true,
          pickerAreaHeightPercent: 1,
        ));
  }
}

// Enum for control modes
enum ControlMode { brightness, color }

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

class LightCardSettings extends StateCard<LightState> {
  final IconData onIcon;
  final IconData offIcon;

  LightCardSettings({required this.onIcon, required this.offIcon, required super.stateProvider});

  @override
  Widget build(BuildContext context, LightState? state) {
    if (state == null) return Text('Unavailable');

    List<Widget> widgets = [];

    var color = state.color;
    if (color != null) {
      widgets.add(Text('Color', style: TextStyle(fontSize: secondaryTextSize)));
      widgets.add(ColorPicker(
        enableAlpha: false,
        pickerColor: color.value,
        onColorChanged: (newColor) => stateProvider
            .requestValue(LightState(isOn: state.isOn, brightness: state.brightness, color: ColorState(value: newColor), temperature: state.temperature)),
      ));
    }

    var brightness = state.brightness;
    if (brightness != null) {
      widgets.add(Text('Brightness', style: TextStyle(fontSize: secondaryTextSize)));
      widgets.add(SafeSlider(
        value: brightness.value,
        min: brightness.min,
        max: brightness.max,
        onChanged: (value) => stateProvider.requestValue(LightState(
            isOn: state.isOn,
            brightness: LimitedValueState(value: value, min: brightness.min, max: brightness.max),
            color: state.color,
            temperature: state.temperature)),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

class LightCard extends StateCard<LightState> {
  final IconData onIcon;
  final IconData offIcon;
  final String? name;

  LightCard({required super.stateProvider, required this.onIcon, required this.offIcon, this.name});

  @override
  Widget build(BuildContext context, LightState? state) {
    if (state == null)
      return PlainCard(
        icon: Icons.error,
        text: 'Unavailable',
        subText: name,
      );

    return GestureDetector(
      onLongPress: () => _buildControlDialog(context),
      child: PlainCard(
        color: Tint.color(color: state.color?.value, fraction: 0.4),
        icon: _icon(state),
        iconColor: _iconColor(state),
        text: _stateToText(state),
        subText: name,
        action: () => switchState(state),
      ),
    );
  }

  Future<void> _buildControlDialog(BuildContext context) {
    return context.showLightControl(stateProvider: stateProvider, title: name);
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(name ?? 'Light'),
          //content: SingleChildScrollView(child: LightCardSettings(stateProvider: stateProvider, )),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(textStyle: Theme.of(context).textTheme.labelLarge),
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
