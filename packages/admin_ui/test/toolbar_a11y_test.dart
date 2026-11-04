import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// WCAG 2.2 SC 2.5.8: a pointer target of at least 24 by 24 CSS pixels.
const _targetSize = MinimumTapTargetGuideline(
  size: Size(24, 24),
  link: 'https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum',
);

/// The client accents the catalog's Brand control offers.
const _brands = <String, Color>{
  'Crimson': Color(0xFFE11D48),
  'Violet': Color(0xFF7C3AED),
  'Teal': Color(0xFF0D9488),
  'Amber': Color(0xFFD97706),
};

void _noop() {}

const _fields = [
  OptionsFilterField('status', 'Status', [
    FilterOption('draft', 'Draft'),
    FilterOption('live', 'Live'),
    FilterOption('archived', 'Archived'),
  ]),
  NumberRangeFilterField('price', 'Price'),
];

const _active = [
  OptionsFilter('status', {'draft', 'live', 'archived'}, label: 'Status'),
];

final _actions = [
  const BulkAction('Publish', icon: Icons.publish_outlined, onPressed: _noop),
  const BulkAction('Delete', danger: true, onPressed: _noop),
];

const _views = [
  SavedView(id: 'all', name: 'All', isDefault: true),
  SavedView(id: 'pub', name: 'Published', scope: SavedViewScope.shared),
];

/// The toolbar, filter pills and bulk bar, the column chooser, the saved
/// views bar and a kanban board, each on a page of its own.
final _exhibits = <(String, Widget Function())>[
  (
    'Toolbar with active filters',
    () => CollectionToolbar(
      onSearch: (_) {},
      filterBar: FilterBar(fields: _fields, active: _active, onChanged: (_) {}),
      trailing: const [Button.primary('New', onPressed: _noop)],
    ),
  ),
  (
    'Bulk bar',
    () => BulkActionBar(
      count: 3,
      onClear: _noop,
      matchingTotal: 40,
      onSelectAllMatching: _noop,
      actions: _actions,
    ),
  ),
  (
    'Bulk bar, all matching',
    () => BulkActionBar(
      count: 40,
      onClear: _noop,
      matchingTotal: 40,
      allMatchingSelected: true,
      actions: _actions,
    ),
  ),
  (
    'Bulk bar at 320',
    () => SizedBox(
      width: 320,
      child: BulkActionBar(count: 3, onClear: _noop, actions: _actions),
    ),
  ),
  (
    'Column chooser',
    () => SizedBox(
      width: 268,
      height: 320,
      child: ColumnChooser(
        columns: const [
          ColumnChoice(key: 'name', label: 'Name', locked: true),
          ColumnChoice(key: 'status', label: 'Status'),
          ColumnChoice(key: 'updated', label: 'Updated'),
        ],
        layout: const ColumnLayout(hidden: {'updated'}),
        onChanged: (_) {},
        onReset: _noop,
      ),
    ),
  ),
  (
    'Column chooser triggers',
    () => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final size in [ControlSize.medium, ControlSize.small])
          ColumnChooserButton(
            columns: const [
              ColumnChoice(key: 'name', label: 'Name'),
              ColumnChoice(key: 'status', label: 'Status'),
            ],
            layout: const ColumnLayout(hidden: {'status'}),
            onChanged: (_) {},
            size: size,
          ),
      ],
    ),
  ),
  (
    'Saved views bar',
    () => SavedViewsBar(
      views: _views,
      activeId: 'all',
      dirty: true,
      onSelect: (_) {},
      onSaveChanges: _noop,
      onDiscardChanges: _noop,
      onCreate: (_) {},
      onRenamed: (_, _) {},
      onDelete: (_) {},
      error: Exception('status 503'),
      onRetry: _noop,
      onDismissError: _noop,
    ),
  ),
  (
    'Kanban board',
    () => SizedBox(
      height: 320,
      child: KanbanBoard<String>(
        columns: const [
          KanbanColumn(id: 'todo', title: 'To do', items: ['Coat']),
          KanbanColumn(
            id: 'done',
            title: 'Done',
            subtitle: 'Shipped',
            items: [],
          ),
        ],
        itemKey: (s) => s,
        onMove: (_, _, _) {},
        onCardTap: (_) {},
        cardBuilder: (_, s) =>
            Padding(padding: const EdgeInsets.all(12), child: Text(s)),
      ),
    ),
  ),
];

void main() {
  for (final theme in adminThemes) {
    for (final dark in [false, true]) {
      if (dark && !theme.hasDark) continue;
      final mode = dark ? 'Dark' : 'Light';
      final tokens = dark ? theme.dark! : theme.tokens;
      ThemeData themed(AdminPalette palette) => buildAppTheme(
        AdminTokens.from(
          palette: palette,
          radii: tokens.radii,
          focus: tokens.focus,
          sizes: tokens.sizes,
        ),
      );

      group('${theme.name} $mode', () {
        _check(themed(tokens.palette), const [
          (labeledTapTargetGuideline, 'labelled targets'),
          (_targetSize, '24px targets'),
          (textContrastGuideline, 'text contrast'),
        ]);
      });
      for (final MapEntry(key: brand, value: seed) in _brands.entries) {
        group('${theme.name} $mode + $brand', () {
          _check(themed(tokens.palette.branded(seed)), const [
            (textContrastGuideline, 'text contrast'),
          ]);
        });
      }
    }
  }
}

void _check(
  ThemeData theme,
  List<(AccessibilityGuideline, String)> guidelines,
) {
  for (final (name, build) in _exhibits) {
    for (final (guideline, what) in guidelines) {
      testWidgets('$name: $what', (tester) async {
        final handle = tester.ensureSemantics();
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: build(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(guideline));
        handle.dispose();
      });
    }
  }
}
