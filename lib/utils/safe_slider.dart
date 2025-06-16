import 'package:flutter/material.dart';

class SafeSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? divisions;
  final Color? activeColor;
  final Color? inactiveColor;
  final String? label;

  const SafeSlider({
    Key? key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.activeColor,
    this.inactiveColor,
    this.label,
  }) : super(key: key);

  @override
  _SafeSliderState createState() => _SafeSliderState();
}

class _SafeSliderState extends State<SafeSlider> {
  late double _internalValue;

  @override
  void initState() {
    super.initState();
    _internalValue = widget.value;
  }

  @override
  void didUpdateWidget(SafeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _internalValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: _internalValue.clamp(widget.min, widget.max),
      onChanged: (value) {
        setState(() {
          _internalValue = value;
        });
      },
      onChangeEnd: (value) {
        widget.onChanged(value);
      },
      min: widget.min,
      max: widget.max,
      divisions: widget.divisions,
      activeColor: widget.activeColor,
      inactiveColor: widget.inactiveColor,
      label: widget.label,
    );
  }
}
