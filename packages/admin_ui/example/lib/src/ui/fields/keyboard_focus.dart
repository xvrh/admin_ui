import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../assets/asset_library.dart';
import '../collection/table/data_table_selection.dart';
import '../demo_kit.dart';
import 'basic/color_field_view.dart';
import 'basic/date_field_view.dart';
import 'basic/select_field_view.dart';

/// Catalog pages with one control holding real keyboard focus, and the
/// keyboard highlight forced on while the page is up, so a static render
/// shows where the focus ring sits on the control's own shape.
class KeyboardFocusDemo extends StatefulWidget {
  final Widget page;

  /// Picks the control to focus: the first Tab stop, in tree order, whose
  /// context this accepts, past [skip] earlier ones.
  final bool Function(BuildContext context) target;
  final int skip;

  /// [page] with its [skip]-th control that [target] accepts focused.
  const KeyboardFocusDemo({
    super.key,
    required this.page,
    required this.target,
    this.skip = 0,
  });

  @Preview(name: 'Focus · select trigger', wrapper: adminUiPreview)
  const KeyboardFocusDemo.select({super.key})
    : page = const SelectFieldDemo(),
      target = _inTrigger,
      skip = 0;

  @Preview(name: 'Focus · date trigger', wrapper: adminUiPreview)
  const KeyboardFocusDemo.date({super.key})
    : page = const DateFieldDemo(),
      target = _inTrigger,
      skip = 0;

  @Preview(name: 'Focus · colour trigger', wrapper: adminUiPreview)
  const KeyboardFocusDemo.colour({super.key})
    : page = const ColorFieldDemo(),
      target = _inTrigger,
      skip = 0;

  @Preview(name: 'Focus · asset tile', wrapper: adminUiPreview)
  const KeyboardFocusDemo.asset({super.key})
    : page = const AssetLibraryDemo(),
      target = _assetTile,
      skip = 0;

  /// The first row's checkbox, past the header's select-all.
  @Preview(name: 'Focus · row checkbox', wrapper: adminUiPreview)
  const KeyboardFocusDemo.tableCheck({super.key})
    : page = const DataTableSelectionDemo(),
      target = _inCheck,
      skip = 1;

  static bool _inTrigger(BuildContext context) =>
      context.findAncestorWidgetOfExactType<FieldTrigger>() != null;

  static bool _assetTile(BuildContext context) =>
      context.findAncestorWidgetOfExactType<GridView>() != null;

  static bool _inCheck(BuildContext context) =>
      context.findAncestorWidgetOfExactType<Check>() != null;

  @override
  State<KeyboardFocusDemo> createState() => _KeyboardFocusDemoState();
}

class _KeyboardFocusDemoState extends State<KeyboardFocusDemo> {
  final _scope = FocusNode(
    debugLabel: 'keyboard focus demo',
    canRequestFocus: false,
    skipTraversal: true,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pin());
  }

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  void _pin() {
    if (!mounted) return;
    var skip = widget.skip;
    for (final node in _scope.traversalDescendants) {
      final context = node.context;
      if (context == null || !widget.target(context)) continue;
      if (skip-- > 0) continue;
      node.requestFocus();
      return;
    }
  }

  @override
  Widget build(BuildContext context) => KeyboardHighlight(
    child: Focus(focusNode: _scope, child: widget.page),
  );
}
