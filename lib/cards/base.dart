import 'package:flutter/material.dart';

class BaseCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Function()? onTap;

  BaseCard({required this.child, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(5),
      child: GestureDetector(
          onTap: onTap,
          child: Card(
            color: color,
            child: child,
          )),
    );
  }
}
