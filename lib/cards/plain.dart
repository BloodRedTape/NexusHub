import 'package:flutter/material.dart';
import 'package:nexus/cards/base.dart';
import 'package:nexus/consts.dart';

class PlainAction {
  final IconData icon;
  final Color? iconColor;
  final Function() onTap;

  const PlainAction({required this.icon, this.iconColor, required this.onTap});
}

class PlainActionWidget extends StatelessWidget {
  final PlainAction action;
  final double iconSize;

  const PlainActionWidget({required this.action, required this.iconSize});

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: action.onTap,
        iconSize: iconSize,
        padding: EdgeInsets.all(0),
        icon: Icon(action.icon, color: action.iconColor));
  }
}

class PlainLayout extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;

  final PlainAction? subAction;

  final String text;
  final Color? textColor;

  final String? subText;
  final Color? subTextColor;

  const PlainLayout(
      {required this.icon,
      this.iconColor,
      this.subAction,
      required this.text,
      this.textColor,
      required this.subText,
      this.subTextColor});

  @override
  Widget build(BuildContext context) {
    final actionWidget = subAction != null
        ? PlainActionWidget(action: subAction!, iconSize: iconSize)
        : SizedBox();

    final textWidget = FittedBox(
        alignment: Alignment.bottomLeft,
        fit: BoxFit.scaleDown,
        child: Text(text,
            style: TextStyle(
                fontSize: primaryTextSize,
                fontWeight: FontWeight.bold,
                color: textColor)));

    final subTextWidget = subText != null
        ? Text(subText!,
            style: TextStyle(fontSize: secondaryTextSize, color: subTextColor))
        : SizedBox();

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: iconSize, color: iconColor),
            actionWidget
          ],
        ),
        const SizedBox(
          height: 8,
        ),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            textWidget,
            subTextWidget,
          ],
        ))
      ],
    );
  }
}

class PlainCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;

  final Function()? action;
  final PlainAction? subAction;

  final String text;
  final Color? textColor;

  final String? subText;
  final Color? subTextColor;

  final Color? color;

  const PlainCard(
      {required this.icon,
      this.iconColor,
      this.action,
      this.subAction,
      required this.text,
      this.textColor,
      this.subText,
      this.subTextColor,
      this.color});

  @override
  Widget build(BuildContext context) {
    final content = Padding(
        padding: EdgeInsets.all(cardPadding),
        child: PlainLayout(
          icon: icon,
          iconColor: iconColor,
          subAction: subAction,
          text: text,
          textColor: textColor,
          subText: subText,
          subTextColor: subTextColor,
        ));

    final button = ElevatedButton(
      onPressed: () => action?.call(),
      child: content,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: EdgeInsets.zero, // Ensure zero padding
        foregroundColor: Colors.white,
        iconColor: Colors.white,
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardBorderRadius),
        ),
      ),
    );

    return BaseCard(child: action != null ? button : content, color: color);
  }
}
