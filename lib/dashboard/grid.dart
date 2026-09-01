import 'package:flutter/material.dart';
import 'package:nexus/utils/expanded_column.dart';

/// One square cell of a [TileGrid].
class Tile {
  final Widget child;

  const Tile(this.child);
}

/// A cell split into two stacked halves, for pairs of small cards.
class SplitTile extends StatelessWidget {
  final Widget top;
  final Widget bottom;

  const SplitTile({super.key, required this.top, required this.bottom});

  @override
  Widget build(BuildContext context) => ExpandedColumn(children: [top, bottom]);
}

/// Fixed grid of square tiles, filled left to right, row by row.
///
/// Every cell keeps the same size: a short last row is padded with empty space
/// instead of stretching its tiles. Tiles beyond [rows] x [columns] are dropped.
class TileGrid extends StatelessWidget {
  final List<Tile> tiles;
  final int rows;
  final int columns;

  const TileGrid({super.key, required this.tiles, this.rows = 2, this.columns = 4});

  /// Tiles laid out per row, in order, dropping whatever does not fit.
  List<List<Tile>> layout() {
    final fitting = tiles.take(rows * columns).toList();

    return [
      for (int start = 0; start < fitting.length; start += columns) fitting.sublist(start, (start + columns).clamp(0, fitting.length)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final grid = layout();

    return ExpandedColumn(
      children: [
        for (final row in grid)
          Row(
            children: [
              for (final tile in row) Expanded(child: tile.child),
              // keep the cells square by filling the row up
              for (int i = row.length; i < columns; i++) Spacer(),
            ],
          ),
        // ... and by filling the grid down
        for (int i = grid.length; i < rows; i++) SizedBox.shrink(),
      ],
    );
  }
}
