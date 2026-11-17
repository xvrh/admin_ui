import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

enum _Editor { options, yesNo, longOptions }

/// Demo — a [FilterBar] pill with its editor open: the options editor, a
/// multi-select list whose rows are the kit's listbox options (the
/// highlight, the checks, the theme's row height and inset), with the
/// pointer resting on "Draft"; or the yes/no editor, a single choice with
/// the current one checked; or the options editor over options longer than
/// its pill, which it grows to hold: two that differ only at their end, one
/// told apart by its description, and one past the menu's widest that wraps.
class FilterEditorsDemo extends StatefulWidget {
  final _Editor _editor;

  @Preview(name: 'Filter editor · options, open', wrapper: adminUiPreview)
  const FilterEditorsDemo({super.key}) : _editor = _Editor.options;

  @Preview(name: 'Filter editor · yes/no, open', wrapper: adminUiPreview)
  const FilterEditorsDemo.yesNo({super.key}) : _editor = _Editor.yesNo;

  @Preview(name: 'Filter editor · long options, open', wrapper: adminUiPreview)
  const FilterEditorsDemo.longOptions({super.key})
    : _editor = _Editor.longOptions;

  @override
  State<FilterEditorsDemo> createState() => _FilterEditorsDemoState();
}

class _FilterEditorsDemoState extends State<FilterEditorsDemo> {
  late var _active = switch (widget._editor) {
    _Editor.options => const <FilterCondition>[
      OptionsFilter('status', {'Published', 'Archived'}, label: 'Status'),
    ],
    _Editor.yesNo => const <FilterCondition>[
      BoolFilter('featured', true, label: 'Featured'),
    ],
    _Editor.longOptions => const <FilterCondition>[],
  };

  static const _status = OptionsFilterField('status', 'Status', [
    FilterOption('Published', 'Published'),
    FilterOption('Draft', 'Draft'),
    FilterOption('Needs review', 'Needs review'),
    FilterOption('Archived', 'Archived'),
  ]);

  static const _featured = BoolFilterField('featured', 'Featured');

  static const _store = OptionsFilterField('store', 'Store', [
    FilterOption('live', 'Northwind Traders (main account) / Web shop (live)'),
    FilterOption('test', 'Northwind Traders (main account) / Web shop (test)'),
    FilterOption(
      'till',
      'In-store till',
      description: 'Northwind Traders (main account) / Harbour Street',
    ),
    FilterOption(
      'old',
      'Northwind Traders (main account) / Web shop, before the 2024 '
          'migration (archived)',
    ),
  ]);

  @override
  Widget build(BuildContext context) {
    final bar = FilterBar(
      fields: [
        switch (widget._editor) {
          _Editor.options => _status,
          _Editor.yesNo => _featured,
          _Editor.longOptions => _store,
        },
      ],
      active: _active,
      onChanged: (next) => setState(() => _active = next),
    );
    return DemoPage(
      maxWidth: 420,
      children: [
        PinnedOpen(
          makeRoom: true,
          child: widget._editor == _Editor.options
              ? PinnedHover(
                  target: (w) => w is ListboxOption && w.label == 'Draft',
                  child: bar,
                )
              : bar,
        ),
      ],
    );
  }
}
