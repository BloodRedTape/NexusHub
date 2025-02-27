import 'package:flutter/material.dart';

class GenericIcon extends StatelessWidget {
  final Widget icon;
  final double? size;

  const GenericIcon({required this.icon, this.size});

  GenericIcon.fromIcon({required IconData icon, this.size})
      : icon = FittedBox(fit: BoxFit.fill, child: Icon(icon));

  GenericIcon.fromImage({required Image image, this.size}) : icon = image;

  GenericIcon.fromFuture({required Future<Widget> image, this.size})
      : icon = FutureBuilder<Widget>(
            future: image,
            builder: (context, snapshot) =>
                _buildFutureIcon(context, snapshot));

  static Widget _buildFutureIcon(
      BuildContext context, AsyncSnapshot<Widget> snapshot) {
    return snapshot.connectionState == ConnectionState.done
        ? snapshot.hasData
            ? snapshot.data ?? _buildError()
            : _buildError()
        : _buildProgressIndicator();
  }

  static Widget _buildProgressIndicator() {
    return Icon(Icons.timelapse);
  }

  static Widget _buildError() {
    return Icon(Icons.error);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: icon,
    );
  }
}
