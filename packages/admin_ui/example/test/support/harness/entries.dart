import 'package:material_ui/material_ui.dart';

/// One demo a test can pump: a catalog page or a preview-only demo.
class DemoEntry {
  /// Where the demo lives: its catalog path (`Primitives / Button`), or
  /// `Preview / <@Preview name>` for a demo only the previews show.
  final String id;

  /// Builds the demo's widget.
  final Widget Function() build;

  DemoEntry(this.id, this.build);

  @override
  String toString() => id;
}

/// A `@Preview` constructor the catalog does not list, which the tests pump
/// all the same: the pinned-state demos (a focused trigger, an open menu, a
/// narrow window) are the states most worth guarding.
class PreviewOnlyDemo {
  /// The constructor as the source spells it: `ShellDemo.narrow`.
  final String constructor;

  /// The `name:` its `@Preview` gives.
  final String name;

  final Widget Function() build;

  const PreviewOnlyDemo(this.constructor, this.name, this.build);
}

/// The pages of [catalog], a group tree as `genericCatalog()` returns it, in
/// catalog order, each id its group path.
List<DemoEntry> catalogEntriesOf(Map<String, dynamic> catalog) {
  final entries = <DemoEntry>[];
  void walk(String path, Object? node) {
    switch (node) {
      case Map<String, dynamic>():
        for (final MapEntry(:key, :value) in node.entries) {
          walk(path.isEmpty ? key : '$path / $key', value);
        }
      case Widget():
        entries.add(DemoEntry(path, () => node));
      default:
        throw StateError('$path is neither a group nor a demo: $node');
    }
  }

  walk('', catalog);
  return entries;
}

/// [previewOnly] as entries, each id `Preview / <name>`.
List<DemoEntry> previewEntriesOf(List<PreviewOnlyDemo> previewOnly) => [
  for (final demo in previewOnly)
    DemoEntry('Preview / ${demo.name}', demo.build),
];

/// [entries], after checking that no two share an id, since a sweep names
/// its tests by id.
List<DemoEntry> uniqueEntries(List<DemoEntry> entries) {
  final ids = <String>{};
  for (final entry in entries) {
    if (!ids.add(entry.id)) {
      throw StateError('Two demos share the id "${entry.id}"');
    }
  }
  return entries;
}

/// The entry of [entries] with [id]; throws when there is none, so a list of
/// ids to pump never drops a renamed demo silently.
DemoEntry entryWithId(List<DemoEntry> entries, String id) => entries.firstWhere(
  (entry) => entry.id == id,
  orElse: () => throw ArgumentError.value(id, 'id', 'No such demo entry'),
);
