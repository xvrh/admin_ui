import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// Demo — a [FilterBar] pill with its editor open: the options editor, a
/// multi-select list whose rows are the kit's listbox options (the
/// highlight, the checks, the theme's row height and inset), with the
/// pointer resting on "Draft"; or the yes/no editor, a single choice with
/// the current one checked.
class FilterEditorsDemo extends StatefulWidget {
  final bool _yesNo;

  @Preview(name: 'Filter editor · options, open', wrapper: adminUiPreview)
  const FilterEditorsDemo({super.key}) : _yesNo = false;

  @Preview(name: 'Filter editor · yes/no, open', wrapper: adminUiPreview)
  const FilterEditorsDemo.yesNo({super.key}) : _yesNo = true;

  @override
  State<FilterEditorsDemo> createState() => _FilterEditorsDemoState();
}

class _FilterEditorsDemoState extends State<FilterEditorsDemo> {
  late var _active = widget._yesNo
      ? const <FilterCondition>[BoolFilter('featured', true, label: 'Featured')]
      : const <FilterCondition>[
          OptionsFilter('status', {'Published', 'Archived'}, label: 'Status'),
        ];

  static const _status = OptionsFilterField('status', 'Status', [
    FilterOption('Published', 'Published'),
    FilterOption('Draft', 'Draft'),
    FilterOption('Needs review', 'Needs review'),
    FilterOption('Archived', 'Archived'),
  ]);

  static const _featured = BoolFilterField('featured', 'Featured');

  @override
  Widget build(BuildContext context) {
    final bar = FilterBar(
      fields: [widget._yesNo ? _featured : _status],
      active: _active,
      onChanged: (next) => setState(() => _active = next),
    );
    return DemoPage(
      maxWidth: 420,
      children: [
        PinnedOpen(
          makeRoom: true,
          child: widget._yesNo
              ? bar
              : PinnedHover(
                  target: (w) => w is ListboxOption && w.label == 'Draft',
                  child: bar,
                ),
        ),
      ],
    );
  }
}
