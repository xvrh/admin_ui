import 'dart:async';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child, {AdminTokens? tokens, double width = 900}) =>
    MaterialApp(
      theme: buildAppTheme(tokens ?? defaultTokens),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: width, child: child),
        ),
      ),
    );

/// Every shipped theme's sizes and table metrics, without its font (a test
/// has no network to fetch it).
List<(String, AdminTokens)> _themes() {
  final out = <(String, AdminTokens)>[];
  for (final theme in adminThemes) {
    late AdminTokens tokens;
    runZonedGuarded(
      () => tokens = theme.tokens,
      (_, _) {},
      zoneSpecification: ZoneSpecification(print: (_, _, _, _) {}),
    );
    out.add((
      theme.name,
      AdminTokens.from(
        palette: tokens.palette,
        radii: tokens.radii,
        focus: tokens.focus,
        sizes: tokens.sizes,
        table: tokens.table,
      ),
    ));
  }
  return out;
}

void main() {
  testWidgets('numbered pages around a grouped, tabular range', (tester) async {
    final picked = <int>[];
    await tester.pumpWidget(
      _host(
        Pager(
          from: 21,
          to: 30,
          total: 1234,
          hasPrev: true,
          hasNext: true,
          page: 3,
          onPage: picked.add,
          pageSize: 10,
        ),
      ),
    );

    final range = tester.widget<Text>(find.text('21–30 of 1,234'));
    expect(
      range.style!.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
    for (final n in ['1', '2', '3', '4', '124']) {
      expect(find.text(n), findsOneWidget, reason: 'page $n');
    }
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);

    await tester.tap(find.text('124'));
    await tester.tap(find.bySemanticsLabel('Next page'));
    await tester.tap(find.bySemanticsLabel('Previous page'));
    expect(picked, [124, 4, 2]);
  });

  testWidgets('an unknown total: the range alone and hasNext', (tester) async {
    final picked = <int>[];
    await tester.pumpWidget(
      _host(
        Pager(
          from: 11,
          to: 20,
          total: null,
          hasPrev: true,
          hasNext: false,
          page: 2,
          onPage: picked.add,
          pageSize: 10,
        ),
      ),
    );
    expect(find.text('11–20'), findsOneWidget);
    expect(find.text('2'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Next page'));
    await tester.tap(find.bySemanticsLabel('Previous page'));
    expect(picked, [1]);
  });

  testWidgets('a page past the end never reads "21–20 of 20"', (tester) async {
    await tester.pumpWidget(
      _host(
        const Pager(from: 21, to: 20, total: 20, hasPrev: true, hasNext: false),
      ),
    );
    expect(find.textContaining('21–20'), findsNothing);
    expect(find.text('0 of 20'), findsOneWidget);
  });

  testWidgets('the arrows-only constructor still pages with onPrev/onNext', (
    tester,
  ) async {
    var prev = 0, next = 0;
    await tester.pumpWidget(
      _host(
        Pager(
          from: 11,
          to: 20,
          total: 42,
          hasPrev: true,
          hasNext: true,
          onPrev: () => prev++,
          onNext: () => next++,
        ),
      ),
    );
    expect(find.text('11–20 of 42'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Previous page'));
    await tester.tap(find.bySemanticsLabel('Next page'));
    expect((prev, next), (1, 1));
  });

  testWidgets('the page-size select lists "N / page" and reports a pick', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final sizes = <int>[];
    await tester.pumpWidget(
      _host(
        Pager(
          from: 1,
          to: 25,
          total: 300,
          hasPrev: false,
          hasNext: true,
          page: 1,
          onPage: (_) {},
          pageSize: 25,
          pageSizes: const [10, 25, 50, 100],
          onPageSize: sizes.add,
        ),
      ),
    );
    expect(find.bySemanticsLabel(RegExp('Rows per page')), findsOneWidget);
    await tester.tap(find.text('25 / page'));
    await tester.pumpAndSettle();
    expect(find.text('100 / page'), findsOneWidget);
    await tester.tap(find.text('50 / page'));
    await tester.pumpAndSettle();
    expect(sizes, [50]);
    handle.dispose();
  });

  for (final (name, tokens) in _themes()) {
    testWidgets('$name: every footer control is the small control height', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Pager(
            from: 41,
            to: 60,
            total: 900,
            hasPrev: true,
            hasNext: true,
            page: 3,
            onPage: (_) {},
            pageSize: 20,
            onPageSize: (_) {},
          ),
          tokens: tokens,
          width: 1000,
        ),
      );
      final small = tokens.sizes.small;
      final controls = [
        find.bySemanticsLabel('Previous page'),
        find.bySemanticsLabel('Next page'),
        find.bySemanticsLabel('Page 3'),
        find.bySemanticsLabel('Page 45'),
        find.byType(FieldTrigger),
      ];
      final centre = tester.getCenter(find.byType(FieldTrigger)).dy;
      for (final control in controls) {
        final rect = tester.getRect(control);
        expect(rect.height, small, reason: '$control in $name');
        expect(rect.center.dy, closeTo(centre, 0.5), reason: '$control');
      }
      final ellipsis = tester.getRect(
        find
            .ancestor(
              of: find.byIcon(Icons.more_horiz).first,
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(ellipsis.height, small);
      expect(ellipsis.center.dy, closeTo(centre, 0.5));
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [600.0, 420.0, 320.0]) {
    testWidgets('fits $width px: drops pages, then numbers, then the select', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Pager(
            from: 101,
            to: 125,
            total: 12345,
            hasPrev: true,
            hasNext: true,
            page: 5,
            onPage: (_) {},
            pageSize: 25,
            onPageSize: (_) {},
          ),
          width: width,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('Next page'), findsOneWidget);
    });
  }

  group('Pagination', () {
    testWidgets('size maps to the control heights', (tester) async {
      for (final size in ControlSize.values) {
        await tester.pumpWidget(
          _host(
            Center(
              child: Pagination(
                page: 5,
                pageCount: 20,
                size: size,
                onChanged: (_) {},
              ),
            ),
          ),
        );
        final height = defaultTokens.sizes.height(size);
        expect(tester.getSize(find.bySemanticsLabel('Page 5')).height, height);
        expect(
          tester.getSize(find.bySemanticsLabel('Previous page')).height,
          height,
        );
      }
    });

    testWidgets('the ellipsis is a glyph centred on the digits', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Center(child: Pagination(page: 10, pageCount: 20, onChanged: (_) {})),
        ),
      );
      expect(find.text('…'), findsNothing);
      final glyph = tester.getCenter(find.byIcon(Icons.more_horiz).first);
      final digit = tester.getCenter(find.text('10'));
      expect(glyph.dy, closeTo(digit.dy, 0.5));
    });

    testWidgets('widthOf matches the laid-out width', (tester) async {
      late double estimate;
      await tester.pumpWidget(
        _host(
          Center(
            child: Builder(
              builder: (context) {
                estimate = Pagination.widthOf(
                  context,
                  page: 57,
                  pageCount: 120,
                  size: ControlSize.small,
                );
                return Pagination(
                  page: 57,
                  pageCount: 120,
                  size: ControlSize.small,
                  onChanged: (_) {},
                );
              },
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(Pagination)).width,
        closeTo(estimate, 1),
      );
    });

    testWidgets('a null pageCount shows only the arrows', (tester) async {
      final picked = <int>[];
      await tester.pumpWidget(
        _host(
          Center(
            child: Pagination(
              page: 4,
              pageCount: null,
              hasNext: true,
              onChanged: picked.add,
            ),
          ),
        ),
      );
      expect(find.text('4'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Next page'));
      await tester.tap(find.bySemanticsLabel('Previous page'));
      expect(picked, [5, 3]);
    });
  });
}
