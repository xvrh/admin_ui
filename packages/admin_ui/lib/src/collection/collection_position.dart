/// @docImport 'collection.dart';
/// @docImport 'collection_controller.dart';
/// @docImport 'ui/collection_cards.dart';
/// @docImport 'ui/collection_table.dart';
library;

import 'package:flutter/foundation.dart';

/// Where a list stood as its view left the screen: how far its rows were
/// scrolled, and the row last opened, while it was still in sight. The view
/// that takes its place starts there, with the focus on that row.
///
/// A view makes one as it goes ([CollectionTable.onLeave],
/// [CollectionCards.onLeave]) and starts from one
/// ([CollectionTable.initialPosition], [CollectionCards.initialPosition]).
/// A [Collection] keeps it on its [CollectionController], which outlives the
/// view when the list gives its place to a record's page and gets it back.
@immutable
class CollectionPosition {
  /// How far down the rows were scrolled.
  final double offset;

  /// How far across a table was scrolled; 0 in a card view.
  final double crossOffset;

  /// The row opened last, by its row key, or null when none was. A table
  /// also leaves it out once the row has been scrolled out of sight.
  final Object? opened;

  /// How far below the top of the rows [opened] sat. A table puts it back
  /// there, so rows that came or went above it while the list was away do
  /// not move it.
  final double openedTop;

  /// Whether the keyboard opened [opened]: a table that rings the row it
  /// comes back to only then ([CollectionTable.ringOnReturn] false) rings
  /// it.
  final bool openedByKeyboard;

  const CollectionPosition({
    this.offset = 0,
    this.crossOffset = 0,
    this.opened,
    this.openedTop = 0,
    this.openedByKeyboard = false,
  });

  @override
  String toString() =>
      'CollectionPosition($offset, $crossOffset, opened: $opened at '
      '$openedTop${openedByKeyboard ? ', by keyboard' : ''})';
}
