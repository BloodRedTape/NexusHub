import 'package:flutter/material.dart';
import 'package:nexus/cards/base.dart';
import 'package:nexus/cards/state.dart';
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
              // a lone child would be centered otherwise - let it fill instead
              children: children.length == 1 ? [Expanded(child: children.single)] : children,
            ))
          ],
        ));
  }
}

/// One sensor value, redrawn on its own as the sensor updates.
class Reading extends StateCard<double> {
  final String Function(double) formatter;
  final bool primary;
  final Color? color;

  const Reading({required super.stateProvider, required this.formatter, this.primary = false, this.color});

  @override
  Widget build(BuildContext context, double? state) {
    final text = state == null ? '-' : formatter(state);

    final style = TextStyle(
      fontSize: primary ? primaryTextSize : secondaryTextSize,
      fontWeight: primary ? FontWeight.bold : FontWeight.normal,
      color: color,
    );

    if (!primary) return Text(text, style: style);

    return FittedBox(alignment: Alignment.bottomLeft, fit: BoxFit.scaleDown, child: Text(text, style: style));
  }
}

/// Big value with a second line right under it, and a name pinned to the bottom.
/// Both lines are widgets so each reading can update on its own.
class StackedLayout extends StatelessWidget {
  final Widget primary;
  final Widget secondary;
  final String? name;

  const StackedLayout({super.key, required this.primary, required this.secondary, this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [primary, secondary],
        ),
        if (name != null)
          Text(
            name!,
            style: TextStyle(fontSize: secondaryTextSize),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

class PlainCardBase extends StatelessWidget {
  final Widget icon;

  final Function()? action;
  final PlainAction? subAction;

  final List<Widget> children;

  final Color? color;

  /// 0..1, drawn as a bar across the bottom edge. Null hides it.
  final double? percent;

  /// Filled and unfilled parts of the [percent] bar. Default to the theme.
  final Color? percentColor;
  final Color? percentBackgroundColor;

  PlainCardBase({
    required this.icon,
    this.action,
    this.subAction,
    required this.children,
    this.color,
    this.percent,
    this.percentColor,
    this.percentBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final content = PlainLayoutBase(
      icon: icon,
      subAction: subAction,
      children: children,
    );

    // The bar sits outside the layout's padding so it reaches both edges. The
    // whole stack is clipped, not just the bar: a few pixels tall, the bar has
    // no room for the card radius on its own and would square off the corners.
    final child = percent == null
        ? content
        : ClipRRect(
            borderRadius: BorderRadius.circular(cardBorderRadius),
            child: Stack(
              children: [
                content,
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LinearProgressIndicator(
                    value: percent!.clamp(0.0, 1.0),
                    minHeight: percentBarHeight,
                    color: percentColor,
                    backgroundColor: percentBackgroundColor ?? Theme.of(context).cardColor,
                  ),
                ),
              ],
            ),
          );

    return BaseCard(child: child, action: action, color: color);
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

  /// 0..1, drawn as a bar across the bottom edge. Null hides it.
  final double? percent;

  /// Filled and unfilled parts of the [percent] bar. Default to the theme.
  final Color? percentColor;
  final Color? percentBackgroundColor;

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
    this.percent,
    this.percentColor,
    this.percentBackgroundColor,
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
    this.percent,
    this.percentColor,
    this.percentBackgroundColor,
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

    final subTextWidget = subText != null
        ? Text(subText!, style: TextStyle(fontSize: secondaryTextSize, color: subTextColor), maxLines: 1, overflow: TextOverflow.ellipsis)
        : SizedBox();

    return PlainCardBase(
      icon: iconWidget,
      subAction: subAction,
      action: action,
      color: color,
      percent: percent,
      percentColor: percentColor,
      percentBackgroundColor: percentBackgroundColor,
      children: [
        textWidget,
        subTextWidget,
      ],
    );
  }
}
