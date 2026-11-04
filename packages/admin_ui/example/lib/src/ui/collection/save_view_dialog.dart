import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';

/// Demo — the dialog a [SavedViewsBar] opens itself ([showSaveViewDialog]),
/// pinned open over the bar: naming a new view and saying who sees it, or,
/// with [rename], renaming the active one. Save with an empty name to see
/// the error; Enter saves, Escape cancels. Close it and the bar behind is
/// live: "+" and each tab's Rename open it again.
class SaveViewDialogDemo extends StatefulWidget {
  /// Opens on renaming "Needs review" rather than on a new view.
  final bool rename;

  @Preview(name: 'Save view dialog', wrapper: adminUiPreview)
  const SaveViewDialogDemo({super.key}) : rename = false;

  @Preview(name: 'Rename view dialog', wrapper: adminUiPreview)
  const SaveViewDialogDemo.rename({super.key}) : rename = true;

  @override
  State<SaveViewDialogDemo> createState() => _SaveViewDialogDemoState();
}

class _SaveViewDialogDemoState extends State<SaveViewDialogDemo> {
  var _views = const [
    SavedView(id: 'published', name: 'Published'),
    SavedView(
      id: 'review',
      name: 'Needs review',
      scope: SavedViewScope.shared,
      position: 1,
    ),
  ];
  String? _activeId = 'review';
  var _next = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.rename) {
        _rename(_views.last);
      } else {
        _create();
      }
    });
  }

  Future<void> _create() async {
    final answer = await showSaveViewDialog(context);
    if (answer != null) _add(answer);
  }

  Future<void> _rename(SavedView view) async {
    final answer = await showSaveViewDialog(
      context,
      initialName: view.name,
      initialScope: view.scope,
      askScope: false,
      rename: true,
    );
    if (answer != null) _renamed(view, answer.name);
  }

  void _add(({String name, SavedViewScope scope}) answer) => setState(() {
    final view = SavedView(
      id: 'new-${_next++}',
      name: answer.name,
      scope: answer.scope,
      position: _views.length,
    );
    _views = [..._views, view];
    _activeId = view.id;
  });

  void _renamed(SavedView view, String name) => setState(() {
    _views = [
      for (final v in _views) v.id == view.id ? v.copyWith(name: name) : v,
    ];
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SavedViewsBar(
            views: _views,
            activeId: _activeId,
            dirty: false,
            onSelect: (v) => setState(() => _activeId = v.id),
            onSelectAll: () => setState(() => _activeId = null),
            onCreate: _add,
            onRenamed: _renamed,
          ),
        ],
      ),
    );
  }
}
