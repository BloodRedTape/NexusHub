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
    return IconButton(onPressed: action.onTap, iconSize: iconSize, padding: EdgeInsets.all(0), icon: Icon(action.icon, color: action.iconColor));
  }
}

class PlainLayoutBase extends StatelessWidget {
  final Widget icon;

  final PlainAction? subAction;

  final List<Widget> children;

  const PlainLayoutBase({required this.icon, this.subAction, required this.children});

  @override
  Widget build(BuildContext context) {
    final actionWidget = subAction != null ? PlainActionWidget(action: subAction!, iconSize: iconSize) : SizedBox();

    return Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [icon, actionWidget],
            ),
            const SizedBox(
              height: 8,
            ),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: children,
            ))
          ],
        ));
  }
}

class PlainLayout extends StatelessWidget {
  final Widget icon;

  final PlainAction? subAction;

  final String text;
  final Color? textColor;

  final String? subText;
  final Color? subTextColor;

  const PlainLayout({required this.icon, this.subAction, required this.text, this.textColor, required this.subText, this.subTextColor});

  @override
  Widget build(BuildContext context) {
    final textWidget = FittedBox(
        alignment: Alignment.bottomLeft,
        fit: BoxFit.scaleDown,
        child: Text(text, style: TextStyle(fontSize: primaryTextSize, fontWeight: FontWeight.bold, color: textColor)));

    final subTextWidget = subText != null ? Text(subText!, style: TextStyle(fontSize: secondaryTextSize, color: subTextColor)) : SizedBox();

    return PlainLayoutBase(icon: icon, subAction: subAction, children: [textWidget, subTextWidget]);
  }
}

class PlainCardBase extends StatelessWidget {
  final Widget icon;

  final Function()? action;
  final PlainAction? subAction;

  final List<Widget> children;

  final Color? color;

  PlainCardBase({
    required this.icon,
    this.action,
    this.subAction,
    required this.children,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final content = PlainLayoutBase(
      icon: icon,
      subAction: subAction,
      children: children,
    );

    return BaseCard(child: content, action: action, color: color);
  }
}

class PlainCard extends StatelessWidget {
  final Widget iconWidget;

  final Function()? action;
  final PlainAction? subAction;

  final String text;
  final Color? textColor;

  final String? subText;
  final Color? subTextColor;

  final Color? color;

  PlainCard({
    required IconData icon,
    Color? iconColor,
    this.action,
    this.subAction,
    required this.text,
    this.textColor,
    this.subText,
    this.subTextColor,
    this.color,
  }) : iconWidget = Icon(icon, color: iconColor, size: iconSize);

  PlainCard.fromIconWidget({
    required this.iconWidget,
    this.action,
    this.subAction,
    required this.text,
    this.textColor,
    this.subText,
    this.subTextColor,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textWidget = FittedBox(
      alignment: Alignment.bottomLeft,
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        style: TextStyle(fontSize: primaryTextSize, fontWeight: FontWeight.bold, color: textColor),
      ),
    );

    final subTextWidget = subText != null ? Text(subText!, style: TextStyle(fontSize: secondaryTextSize, color: subTextColor)) : SizedBox();

    return PlainCardBase(
      icon: iconWidget,
      subAction: subAction,
      action: action,
      color: color,
      children: [
        textWidget,
        subTextWidget,
      ],
    );
  }
}

class SmallPlainCard extends StatelessWidget {
  final Widget iconWidget;
  final String text;
  final void Function()? action;
  final Color? color;

  SmallPlainCard({required IconData icon, Color? iconColor, this.color, required this.text, this.action})
      : iconWidget = Icon(icon, size: iconSize, color: iconColor);

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      action: action,
      color: color,
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(width: cardPadding * 0.25),
            Expanded(
              child: Text(text, style: TextStyle(fontSize: primaryTextSize, fontWeight: FontWeight.bold, overflow: TextOverflow.ellipsis)),
            ),
          ],
        ),
      ),
    );
  }
}
