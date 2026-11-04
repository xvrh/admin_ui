import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// [theme]'s palette, radii and sizes, without its font.
AdminTokens _tokens(AdminTheme theme, {bool dark = false}) {
  final source = dark ? theme.dark! : theme.tokens;
  return AdminTokens.from(
    palette: source.palette,
    radii: source.radii,
    focus: source.focus,
    sizes: source.sizes,
  );
}

final _iris = _tokens(irisTheme);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  AdminTokens? tokens,
  double width = 1200,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(tokens ?? _iris),
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _fields = [
  OptionsFilterField('status', 'Status', [
    FilterOption('draft', 'Draft'),
    FilterOption('live', 'Live'),
  ]),
  BoolFilterField('featured', 'Featured'),
];

const _active = [
  OptionsFilter('status', {'draft'}, label: 'Status'),
];

Widget _toolbar({double? searchWidth}) => CollectionToolbar(
  onSearch: (_) {},
  searchWidth: searchWidth,
  filterBar: FilterBar(fields: _fields, active: _active, onChanged: (_) {}),
  trailing: [Button.primary('New', onPressed: () {})],
);

BulkActionBar _bar() => BulkActionBar(
  count: 3,
  onClear: () {},
  matchingTotal: 40,
  onSelectAllMatching: () {},
  actions: [
    BulkAction('Publish', icon: Icons.publish_outlined, onPressed: () {}),
    BulkAction('Delete', danger: true, onPressed: () {}),
  ],
);

Rect _rect(WidgetTester tester, Finder finder) => tester.getRect(finder);

Finder _pill(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(Tappable)).first;

void main() {
  group('one height per theme', () {
    for (final theme in adminThemes) {
      for (final dark in [false, true]) {
        if (dark && !theme.hasDark) continue;
        final tokens = _tokens(theme, dark: dark);
        final mode = dark ? 'Dark' : 'Light';
        final line = tokens.sizes.medium;
        testWidgets('${theme.name} $mode: toolbar and bulk bar are one '
            'height, their controls ${line}px', (tester) async {
          await _pump(
            tester,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_toolbar(), _bar()],
            ),
            tokens: tokens,
            width: 1600,
          );
          final toolbar = _rect(tester, find.byType(CollectionToolbar));
          final bar = _rect(tester, find.byType(BulkActionBar));
          final expected = line + 2 * AdminSpacing.xs;
          expect(toolbar.height, expected);
          expect(bar.height, expected);

          for (final control in [
            find.byType(InputDecorator),
            _pill('Status'),
            _pill('Featured'),
            find.ancestor(of: find.text('New'), matching: find.byType(Button)),
          ]) {
            final rect = _rect(tester, control.first);
            expect(rect.height, line, reason: '$control');
            expect(rect.center.dy, closeTo(toolbar.center.dy, 0.5));
          }
          // The bar's controls are the same, centred on it.
          for (final label in ['Clear', 'Publish', 'Delete']) {
            final button = find.ancestor(
              of: find.text(label),
              matching: find.byType(Button),
            );
            final rect = _rect(tester, button);
            expect(rect.height, line, reason: label);
            expect(rect.center.dy, closeTo(bar.center.dy, 0.5));
          }
        });
      }
    }
  });

  testWidgets('the header swap moves nothing while the toolbar is one line', (
    tester,
  ) async {
    final controller = CollectionController<int>(
      fetcher: (q) async =>
          CollectionPage(items: List.generate(5, (i) => i), total: 5),
    );
    addTearDown(controller.dispose);
    for (final width in [1200.0, 420.0]) {
      await _pump(
        tester,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CollectionHeader<int>(
              controller: controller,
              bulkActions: [BulkAction('Delete', onPressed: () {})],
              toolbar: _toolbar(),
            ),
            const Text('below'),
          ],
        ),
        width: width,
      );
      controller.clearSelection();
      await tester.pump();
      final before = _rect(tester, find.text('below'));
      final header = _rect(tester, find.byType(CollectionHeader<int>));
      final line = CollectionToolbar.heightOf(
        tester.element(find.byType(CollectionHeader<int>)),
      );
      final wrapped = header.height > line;
      expect(wrapped, width < 1000, reason: '$width');

      controller.setSelected({1, 2});
      await tester.pump();
      expect(find.byType(BulkActionBar), findsOneWidget);
      final bar = _rect(tester, find.byType(BulkActionBar));
      expect(bar.top, header.top);
      // One line: nothing moves. Wrapped: the header closes up under the
      // bar, with no empty band below it.
      expect(
        _rect(tester, find.byType(CollectionHeader<int>)).height,
        line,
        reason: '$width',
      );
      expect(
        _rect(tester, find.text('below')).top,
        wrapped ? bar.bottom : before.top,
        reason: '$width',
      );

      controller.clearSelection();
      await tester.pump();
      expect(_rect(tester, find.text('below')), before);
    }
  });

  testWidgets('narrow, wrapped filters use the width under the trailing', (
    tester,
  ) async {
    await _pump(
      tester,
      CollectionToolbar(
        onSearch: (_) {},
        filterBar: FilterBar(
          fields: _fields,
          active: const [
            OptionsFilter('status', {'draft'}, label: 'Status'),
            BoolFilter('featured', true, label: 'Featured'),
          ],
          onChanged: (_) {},
        ),
        trailing: [Button.primary('New product', onPressed: () {})],
      ),
      width: 420,
    );
    final search = _rect(tester, find.byType(InputDecorator));
    final add = _rect(
      tester,
      find.ancestor(
        of: find.text('New product'),
        matching: find.byType(Button),
      ),
    );
    expect(add.right, 420);
    expect(add.center.dy, closeTo(search.center.dy, 0.5));
    expect(search.right, lessThanOrEqualTo(add.left - AdminSpacing.md));
    // The filters wrap to a line of their own, which runs under the
    // trailing action rather than stopping short of it.
    final filters = _rect(tester, find.byType(FilterBar));
    expect(filters.top, greaterThan(search.bottom));
    expect(filters.left, 0);
    expect(filters.right, greaterThan(add.left));
  });

  testWidgets('the hidden toolbar leaves the focus order and the semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final controller = CollectionController<int>(
      fetcher: (q) async =>
          CollectionPage(items: List.generate(5, (i) => i), total: 5),
    );
    addTearDown(controller.dispose);
    await _pump(
      tester,
      CollectionHeader<int>(controller: controller, toolbar: _toolbar()),
    );
    expect(find.semantics.byLabel('Status: Draft'), findsOne);
    controller.setSelected({1});
    await tester.pump();
    expect(find.semantics.byLabel('Status: Draft'), findsNothing);
    final search = tester.widget<EditableText>(find.byType(EditableText));
    expect(search.focusNode.canRequestFocus, isFalse);
    handle.dispose();
  });

  testWidgets('narrow, trailing stays level with the first line', (
    tester,
  ) async {
    await _pump(tester, _toolbar(), width: 420);
    final search = _rect(tester, find.byType(InputDecorator));
    final add = _rect(
      tester,
      find.ancestor(of: find.text('New'), matching: find.byType(Button)),
    );
    final status = _rect(tester, _pill('Status'));
    expect(add.center.dy, closeTo(search.center.dy, 0.5));
    expect(status.top, greaterThan(search.bottom));
    expect(search.left, 0);
    expect(status.left, 0);
  });

  testWidgets('the search flexes between its minimum and maximum', (
    tester,
  ) async {
    double searchWidth() => _rect(tester, find.byType(InputDecorator)).width;

    // Room to spare: the search takes its maximum, the filters beside it.
    await _pump(tester, _toolbar(), width: 1600);
    expect(searchWidth(), 320);
    final status = _rect(tester, _pill('Status'));
    final search = _rect(tester, find.byType(InputDecorator));
    expect(status.center.dy, closeTo(search.center.dy, 0.5));

    // Tighter: it gives up width to keep them on its line.
    final filters = tester.getSize(find.byType(FilterBar)).width;
    final add = tester
        .getSize(
          find.ancestor(of: find.text('New'), matching: find.byType(Button)),
        )
        .width;
    final width = 250 + AdminSpacing.sm + filters + AdminSpacing.md + add;
    await _pump(tester, _toolbar(), width: width);
    expect(searchWidth(), closeTo(250, 0.5));
    expect(
      _rect(tester, _pill('Status')).center.dy,
      closeTo(_rect(tester, find.byType(InputDecorator)).center.dy, 0.5),
    );

    // A fixed width still wins.
    await _pump(tester, _toolbar(searchWidth: 240), width: 1600);
    expect(searchWidth(), 240);
  });

  testWidgets('right to left, the search leads from the right', (tester) async {
    await _pump(tester, _toolbar(), width: 1600, direction: TextDirection.rtl);
    final search = _rect(tester, find.byType(InputDecorator));
    final status = _rect(tester, _pill('Status'));
    final add = _rect(
      tester,
      find.ancestor(of: find.text('New'), matching: find.byType(Button)),
    );
    expect(add.left, 0);
    expect(status.right, lessThan(search.left));
  });

  testWidgets('at 320px the bulk bar folds its actions into a menu', (
    tester,
  ) async {
    var published = 0;
    var all = 0;
    await _pump(
      tester,
      BulkActionBar(
        count: 3,
        onClear: () {},
        matchingTotal: 40,
        onSelectAllMatching: () => all++,
        selectedLabel: (n) => '$n products selected in this collection',
        actions: [
          BulkAction('Publish', onPressed: () => published++),
          BulkAction('Delete', danger: true, onPressed: () {}),
        ],
      ),
      width: 320,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Publish'), findsNothing);
    expect(find.bySemanticsLabel('Clear selection'), findsOneWidget);
    final label = tester.widget<Text>(
      find.text('3 products selected in this collection'),
    );
    expect(label.overflow, TextOverflow.ellipsis);

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();
    expect(published, 1);

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select all 40'));
    await tester.pumpAndSettle();
    expect(all, 1);
  });

  testWidgets('the bulk bar never overflows on its way to folding', (
    tester,
  ) async {
    var folded = 0;
    for (var width = 280.0; width <= 900; width += 3) {
      await _pump(tester, _bar(), width: width);
      expect(tester.takeException(), isNull, reason: '$width');
      if (find.byIcon(Icons.more_horiz).evaluate().isNotEmpty) folded++;
    }
    // It folds only where the full row can't fit.
    expect(folded, greaterThan(0));
    expect(folded, lessThan((900 - 280) ~/ 3));
  });

  testWidgets('wide, the bulk bar shows every action at its end', (
    tester,
  ) async {
    await _pump(tester, _bar(), width: 900);
    expect(find.byIcon(Icons.more_horiz), findsNothing);
    final bar = _rect(tester, find.byType(BulkActionBar));
    final delete = _rect(
      tester,
      find.ancestor(of: find.text('Delete'), matching: find.byType(Button)),
    );
    expect(bar.right - delete.right, closeTo(AdminSpacing.md + 1, 0.5));
    expect(find.text('Select all 40'), findsOneWidget);
  });
}
