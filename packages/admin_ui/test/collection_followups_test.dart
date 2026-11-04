import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// [theme]'s light or dark tokens in the default type, so no font loads.
AdminTokens _tokens(AdminTheme theme, {bool dark = false, Color? brand}) {
  final source = dark ? theme.dark! : theme.tokens;
  return AdminTokens.from(
    palette: brand == null ? source.palette : source.palette.branded(brand),
    radii: source.radii,
    focus: source.focus,
    sizes: source.sizes,
    table: source.table,
  );
}

/// The client accents the catalog's Brand control offers.
const _brands = <String, Color?>{
  'Default': null,
  'Crimson': Color(0xFFE11D48),
  'Violet': Color(0xFF7C3AED),
  'Teal': Color(0xFF0D9488),
  'Amber': Color(0xFFD97706),
};

class _Item {
  final int id;
  final String name;
  final String brand;
  const _Item(this.id, this.name, this.brand);
}

final _items = [for (var i = 0; i < 6; i++) _Item(i, 'Item $i', 'Maker $i')];

Future<void> _pump(WidgetTester tester, AdminTokens tokens, Widget child) {
  tester.view.physicalSize = const Size(1000, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(tokens),
      home: Scaffold(
        body: Align(alignment: Alignment.topLeft, child: child),
      ),
    ),
  );
}

/// A selectable table between two buttons, 800 × 400.
class _Harness extends StatefulWidget {
  final void Function(_Item row)? onRowTap;
  final void Function(_Item row)? onChipTap;
  final bool selectable;

  const _Harness({this.onRowTap, this.onChipTap, this.selectable = true});

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  Set<_Item> selected = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(onPressed: () {}, child: const Text('Before')),
        SizedBox(
          width: 800,
          height: 400,
          child: CollectionTable<_Item>(
            rows: _items,
            rowKey: (r) => r.id,
            selected: widget.selectable ? selected : null,
            onSelectionChanged: widget.selectable
                ? (s) => setState(() => selected = s)
                : null,
            onRowTap: widget.onRowTap,
            columns: [
              TableColumn(id: 'name', label: 'Name', cell: (r) => Text(r.name)),
              TableColumn(
                id: 'brand',
                label: 'Brand',
                fixed: 200,
                cell: (r) => RelationChip(
                  label: r.brand,
                  onTap: widget.onChipTap == null
                      ? null
                      : () => widget.onChipTap!(r),
                ),
              ),
            ],
          ),
        ),
        TextButton(onPressed: () {}, child: const Text('After')),
      ],
    );
  }
}

Set<int> _selectedIds(WidgetTester tester) => {
  for (final r in tester.state<_HarnessState>(find.byType(_Harness)).selected)
    r.id,
};

/// The cell [check] sits in: the nearest ancestor as wide as the column.
Rect _cellOf(WidgetTester tester, Finder check, double width) {
  final cell = find
      .ancestor(of: check, matching: find.byType(Stack))
      .evaluate()
      .map((e) => tester.getRect(find.byElementPredicate((x) => x == e)))
      .firstWhere((r) => r.width == width);
  return cell;
}

Finder _rowCheck(int row) => find.byWidgetPredicate(
  (w) => w is Check && w.semanticLabel == 'Select row $row',
);

Finder get _allCheck => find.byWidgetPredicate(
  (w) => w is Check && w.semanticLabel == 'Select all on page',
);

void main() {
  group('the selection cell is the target', () {
    for (final theme in adminThemes) {
      final tokens = _tokens(theme);
      final metrics = tokens.table;

      testWidgets('${theme.name}: a tap anywhere in the cell toggles the row, '
          'and only the row', (tester) async {
        final opened = <int>[];
        await _pump(
          tester,
          tokens,
          _Harness(onRowTap: (r) => opened.add(r.id)),
        );

        final cell = _cellOf(
          tester,
          _rowCheck(1),
          metrics.selectionColumnWidth,
        );
        expect(
          cell.size,
          Size(metrics.selectionColumnWidth, metrics.rowStandard),
        );
        // Well past the 18px box: a row tall and the theme's selection column
        // wide (32 in Ant, 40 or more elsewhere).
        expect(cell.height, greaterThanOrEqualTo(44));
        expect(cell.width, greaterThanOrEqualTo(32));

        const inset = 4.0;
        final corners = [
          cell.topLeft + const Offset(inset, inset),
          cell.topRight + const Offset(-inset, inset),
          cell.bottomRight + const Offset(-inset, -inset),
          cell.bottomLeft + const Offset(inset, -inset),
        ];
        for (final (i, corner) in corners.indexed) {
          await tester.tapAt(corner);
          await tester.pump();
          expect(
            _selectedIds(tester),
            i.isEven ? {0} : isEmpty,
            reason: 'tap ${i + 1}, 4px from a corner',
          );
        }
        expect(opened, isEmpty, reason: 'the selection cell opens no row');

        // The box itself toggles once, not once for it and once for the cell.
        await tester.tap(_rowCheck(1));
        await tester.pump();
        expect(_selectedIds(tester), {0});

        // Just past the cell is the row's own tap.
        await tester.tapAt(cell.centerRight + const Offset(inset, 0));
        await tester.pump();
        expect(opened, [0]);
        expect(_selectedIds(tester), {0});
      });

      testWidgets('${theme.name}: a tap anywhere in the header cell toggles '
          'the page', (tester) async {
        await _pump(tester, tokens, const _Harness());
        final cell = _cellOf(tester, _allCheck, metrics.selectionColumnWidth);
        expect(
          cell.size,
          Size(metrics.selectionColumnWidth, metrics.headerHeight),
        );

        await tester.tapAt(cell.topLeft + const Offset(4, 4));
        await tester.pump();
        expect(_selectedIds(tester), {for (final r in _items) r.id});

        await tester.tapAt(cell.bottomRight - const Offset(4, 4));
        await tester.pump();
        expect(_selectedIds(tester), isEmpty);
      });
    }

    testWidgets('each row keeps one checkbox, and the cell adds no action to '
        'assistive technology', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, defaultTokens, const _Harness());

      for (var row = 1; row <= _items.length; row++) {
        final node = find.semantics.byLabel('Select row $row');
        expect(node, findsOne, reason: 'row $row');
        expect(
          node.evaluate().single,
          isSemantics(hasCheckedState: true, hasTapAction: true),
        );
      }
      // Without a row tap, every tap action in the table is a checkbox's:
      // the rows' and the header's.
      final checks = find.semantics.byFlag(SemanticsFlag.hasCheckedState);
      expect(checks.evaluate(), hasLength(_items.length + 1));
      final taps = find.semantics.byPredicate((node) {
        final data = node.getSemanticsData();
        return data.hasAction(SemanticsAction.tap) &&
            data.label != 'Before' &&
            data.label != 'After';
      });
      expect(taps.evaluate(), hasLength(_items.length + 1));
      semantics.dispose();
    });
  });

  group('a relation chip is a link', () {
    setUp(() {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
    });
    tearDown(() {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic;
    });

    testWidgets('Enter on its cell reaches the chip, and Enter there opens '
        'the chip, not the row', (tester) async {
      final rows = <int>[];
      final chips = <int>[];
      await _pump(
        tester,
        defaultTokens,
        _Harness(
          selectable: false,
          onRowTap: (r) => rows.add(r.id),
          onChipTap: (r) => chips.add(r.id),
        ),
      );

      // Tab past the button before the table, onto its first body cell.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'CollectionTable');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(rows, isEmpty, reason: 'Enter enters the cell');
      expect(chips, isEmpty);
      final focused = FocusManager.instance.primaryFocus!.context!;
      expect(
        find.ancestor(
          of: find.byElementPredicate((e) => e == focused),
          matching: find.byType(RelationChip),
        ),
        findsOne,
        reason: 'focus is on the chip',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(chips, [0]);
      expect(rows, isEmpty);

      // Escape hands focus back to the cell; Enter there enters the chip
      // again rather than opening the row.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'CollectionTable');
    });

    testWidgets('a click opens the chip, not the row; it is announced as a '
        'focusable link', (tester) async {
      final semantics = tester.ensureSemantics();
      final rows = <int>[];
      final chips = <int>[];
      await _pump(
        tester,
        defaultTokens,
        _Harness(
          selectable: false,
          onRowTap: (r) => rows.add(r.id),
          onChipTap: (r) => chips.add(r.id),
        ),
      );
      await tester.tap(find.text('Maker 2'));
      await tester.pump();
      expect(chips, [2]);
      expect(rows, isEmpty);

      expect(
        find.semantics.byLabel('Maker 2').evaluate().single,
        isSemantics(isLink: true, isFocusable: true, hasTapAction: true),
      );
      semantics.dispose();
    });

    testWidgets('keyboard focus rings the chip', (tester) async {
      await _pump(
        tester,
        defaultTokens,
        _Harness(selectable: false, onChipTap: (_) {}),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      final ring = find.descendant(
        of: find.byType(RelationChip).first,
        matching: find.byWidgetPredicate((w) => w is FocusRing && w.focused),
      );
      expect(ring, findsOne);
    });
  });

  group('muted text on a selected card', () {
    for (final theme in [irisTheme, shadcnTheme, antTheme]) {
      for (final MapEntry(key: brand, value: seed) in _brands.entries) {
        testWidgets('${theme.name} Light, brand $brand: a caption in '
            'foregroundMutedOnTint reads at 4.5:1 on the selection fill', (
          tester,
        ) async {
          final tokens = _tokens(theme, brand: seed);
          final rows = _items.take(2).toList();
          await _pump(
            tester,
            tokens,
            SizedBox(
              width: 600,
              height: 400,
              child: CollectionCards<_Item>(
                rows: rows,
                rowKey: (r) => r.id,
                selected: {rows.first},
                onSelectionChanged: (_) {},
                cardBuilder: (context, r) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'SKU-${r.id}',
                    style: context.type.caption.copyWith(
                      color: context.colors.foregroundMutedOnTint,
                    ),
                  ),
                ),
              ),
            ),
          );
          final palette = tokens.palette;
          Color fillOf(String sku) {
            final box = tester
                .widgetList<AnimatedContainer>(
                  find.ancestor(
                    of: find.text(sku),
                    matching: find.byType(AnimatedContainer),
                  ),
                )
                .first;
            return (box.decoration! as BoxDecoration).color!;
          }

          final caption = tester.widget<Text>(find.text('SKU-0')).style!.color!;
          expect(fillOf('SKU-0'), palette.tableRowSelected);
          expect(fillOf('SKU-1'), palette.surface);
          expect(
            contrastRatio(caption, fillOf('SKU-0')),
            greaterThanOrEqualTo(4.5),
            reason: 'on the selected card',
          );
          expect(
            contrastRatio(caption, fillOf('SKU-1')),
            greaterThanOrEqualTo(4.5),
            reason: 'on an unselected card',
          );
        });
      }
    }
  });

  group('a filter pill outlines like the search box beside it', () {
    for (final theme in adminThemes) {
      for (final dark in [false, true]) {
        testWidgets('${theme.name} ${dark ? 'Dark' : 'Light'}', (tester) async {
          final tokens = _tokens(theme, dark: dark);
          await _pump(
            tester,
            tokens,
            SizedBox(
              width: 900,
              child: CollectionToolbar(
                searchValue: '',
                onSearch: (_) {},
                filterBar: FilterBar(
                  fields: const [
                    OptionsFilterField('status', 'Status', [
                      FilterOption('draft', 'Draft'),
                    ]),
                  ],
                  active: const [],
                  onChanged: (_) {},
                ),
              ),
            ),
          );
          final field = tester.widget<TextField>(
            find.descendant(
              of: find.byType(SearchField),
              matching: find.byType(TextField),
            ),
          );
          final border = field.decoration!.border!;
          final searchOutline =
              (border is WidgetStateInputBorder
                      ? border.resolve(const {})
                      : border)
                  .borderSide
                  .color;

          final pill = tester
              .widgetList<Container>(
                find.ancestor(
                  of: find.text('Status'),
                  matching: find.byType(Container),
                ),
              )
              .map((c) => c.decoration)
              .whereType<BoxDecoration>()
              .firstWhere((d) => d.border != null);
          final outline = (pill.border! as Border).top.color;
          expect(outline, searchOutline);
          expect(outline, tokens.palette.controlBorder);
        });
      }
    }
  });
}
