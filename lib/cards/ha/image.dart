import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nexus/cards/control_button.dart';
import 'package:nexus/cards/plain.dart';
import 'package:nexus/cards/state.dart';
import 'package:nexus/clients/ha/providers/image.dart';
import 'package:nexus/clients/state.dart';
import 'package:nexus/consts.dart';
import 'package:nexus/utils/tint.dart';

const _accent = Color.fromARGB(255, 2, 82, 128);

String _status(HaImage? state) {
  if (state == null) return 'Unavailable';

  final updated = state.updatedAt;

  if (updated == null) return 'Ready';

  // same day is the common case - a bare time reads better than a full date
  final sameDay = DateUtils.isSameDay(updated, DateTime.now());

  return DateFormat(sameDay ? 'HH:mm' : 'd MMM HH:mm').format(updated);
}

/// A picture entity: the card only says it is there and when it last changed,
/// the picture itself lives behind the chevron.
class ImageCard extends StateCard<HaImage> {
  final String? name;

  const ImageCard({required super.stateProvider, this.name});

  @override
  Widget build(BuildContext context, HaImage? state) {
    return PlainCard(
      icon: Icons.image,
      text: _status(state),
      subText: name,
      subAction: state == null
          ? null
          : PlainAction(
              icon: Icons.chevron_right,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ImageDetails(title: name ?? 'Image', stateProvider: stateProvider)),
              ),
            ),
    );
  }
}

/// The picture itself, laid out like the vacuum page: the thing in the middle,
/// its controls along the bottom. Panning and zooming stay off until asked for -
/// a stray swipe on a wall panel should not leave the picture off-centre.
class ImageDetails extends StatefulWidget {
  final String title;
  final StateProvider<HaImage> stateProvider;

  const ImageDetails({super.key, required this.title, required this.stateProvider});

  @override
  State<ImageDetails> createState() => _ImageDetailsState();
}

class _ImageDetailsState extends State<ImageDetails> {
  final _transformation = TransformationController();

  bool _zoom = false;

  /// Bumped to force a reload: the url alone is unchanged, so nothing else would.
  int _reload = 0;

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    setState(() {
      _zoom = !_zoom;
      if (!_zoom) _transformation.value = Matrix4.identity();
    });
  }

  void _fit() => setState(() => _transformation.value = Matrix4.identity());

  void _refresh() {
    final url = widget.stateProvider.getValue()?.url;

    if (url != null) NetworkImage(url).evict();

    setState(() => _reload++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: _Title(title: widget.title, stateProvider: widget.stateProvider)),
      body: Padding(
        padding: EdgeInsets.all(cardPadding * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: _Picture(
                  stateProvider: widget.stateProvider,
                  transformation: _transformation,
                  zoom: _zoom,
                  reload: _reload,
                ),
              ),
            ),
            SizedBox(height: cardPadding),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Row(
                  children: [
                    Expanded(
                      child: ControlButton(
                        icon: _zoom ? Icons.zoom_in : Icons.zoom_in_map,
                        label: _zoom ? 'Zoom on' : 'Zoom off',
                        background: _zoom ? Tint.color(color: _accent, fraction: 0.4) : null,
                        foreground: _zoom ? _accent : null,
                        onTap: _toggleZoom,
                      ),
                    ),
                    SizedBox(width: cardPadding / 2),
                    ControlButton(icon: Icons.fit_screen, onTap: _fit),
                    SizedBox(width: cardPadding / 2),
                    ControlButton(icon: Icons.refresh, onTap: _refresh),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Name and freshness, kept in step with the entity the way the vacuum title is.
class _Title extends StateCard<HaImage> {
  final String title;

  const _Title({required this.title, required super.stateProvider});

  @override
  Widget build(BuildContext context, HaImage? state) {
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: title),
        TextSpan(text: ' · ${_status(state)}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _Picture extends StateCard<HaImage> {
  final TransformationController transformation;
  final bool zoom;
  final int reload;

  const _Picture({required super.stateProvider, required this.transformation, required this.zoom, required this.reload});

  @override
  Widget build(BuildContext context, HaImage? state) {
    if (state == null) return const Icon(Icons.broken_image);

    return InteractiveViewer(
      transformationController: transformation,
      scaleEnabled: zoom,
      panEnabled: zoom,
      maxScale: 5,
      child: Image.network(
        state.url,
        key: ValueKey('${state.url}#$reload'),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      ),
    );
  }
}
