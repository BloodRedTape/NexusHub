import 'package:flutter/material.dart';
import 'package:nexus/consts.dart';

/// The control-row button the detail pages share: neutral ground, tinted when
/// it is the thing currently happening.
class ControlButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color? background;
  final Color? foreground;
  final VoidCallback onTap;

  const ControlButton({super.key, required this.icon, required this.onTap, this.label, this.background, this.foreground});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(cardBorderRadius);
    final content = foreground ?? theme.colorScheme.onSurfaceVariant;
    final size = 56.0;

    return Material(
      color: background ?? theme.colorScheme.surfaceContainerHighest,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: size,
          constraints: BoxConstraints(minWidth: size),
          padding: EdgeInsets.symmetric(horizontal: label == null ? 0 : cardPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize * 0.7, color: content),
              if (label != null) ...[
                const SizedBox(width: 8),
                Text(label!, style: TextStyle(fontSize: secondaryTextSize, color: content)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
