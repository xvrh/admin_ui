import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// A donut chart's legend stands beside the ring where every label fits there
// whole, and under it where one does not. Under the ring a label longer than
// the chart is cut, and a height the chart is given goes to the legend first.

const _channels = [
  ChartSlice('Online store', 48),
  ChartSlice('Market stall', 21),
  ChartSlice('Wholesale', 14),
  ChartSlice('Phone', 6),
];

const _ringSize = 148.0;

/// Between the ring and the legend beside it, and under it.
const _beside = AdminSpacing.xxl;
const _under = AdminSpacing.lg;

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  double? height,
  List<ChartSlice> slices = _channels,
  double textScale = 1,
  TextDirection direction = TextDirection.ltr,
  bool showLegend = true,
  Widget Function(Widget chart)? wrap,
}) async {
  tester.view
    ..physicalSize = const Size(1600, 1200)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final chart = DonutChart(
    size: _ringSize,
    slices: slices,
    showLegend: showLegend,
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: Directionality(textDirection: direction, child: child!),
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          // Loose: the chart is as wide as it asks to be, up to [width].
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: width,
              maxHeight: height ?? double.infinity,
            ),
            child: wrap == null ? chart : wrap(chart),
          ),
        ),
      ),
    ),
  );
}

final _chart = find.byType(DonutChart);
final _ring = find.descendant(of: _chart, matching: find.byType(CustomPaint));

/// The swatch and the name of the entry that reads [label].
Finder _entry(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(Row)).first;

Rect _rect(WidgetTester tester, Finder finder) => tester.getRect(finder);

bool _isCut(WidgetTester tester, String label) =>
    tester.renderObject<RenderParagraph>(find.text(label)).didExceedMaxLines;

/// What the chart asks for with all the room it wants: its ring, the gap and
/// its widest entry.
Future<double> _naturalWidth(
  WidgetTester tester, {
  List<ChartSlice> slices = _channels,
  double textScale = 1,
}) async {
  await _pump(tester, width: 1200, slices: slices, textScale: textScale);
  return _rect(tester, _chart).width;
}

void main() {
  group('with room beside the ring', () {
    testWidgets('the entries are a column beside it', (tester) async {
      await _pump(tester, width: 600);
      expect(tester.takeException(), isNull);

      final chart = _rect(tester, _chart);
      final ring = _rect(tester, _ring);
      expect(ring.size, const Size.square(_ringSize));
      expect(ring.left, chart.left);

      final entries = [
        for (final s in _channels) _rect(tester, _entry(s.label)),
      ];
      for (final entry in entries) {
        expect(entry.left, ring.right + _beside);
      }
      for (var i = 1; i < entries.length; i++) {
        expect(entries[i].top, entries[i - 1].bottom + AdminSpacing.md);
      }
      // As wide as its ring, the gap and its widest entry, and no wider.
      final widest = entries
          .map((e) => e.width)
          .reduce((a, b) => a > b ? a : b);
      expect(chart.width, _ringSize + _beside + widest);
      expect(chart.height, _ringSize);
      for (final s in _channels) {
        expect(_isCut(tester, s.label), isFalse, reason: s.label);
      }
    });

    testWidgets('the ring and the legend are centred on each other, as the '
        'row they were', (tester) async {
      await _pump(tester, width: 600);
      final ring = _rect(tester, _ring);
      final first = _rect(tester, _entry(_channels.first.label));
      final last = _rect(tester, _entry(_channels.last.label));
      // The legend's block is its entries, each with the gap under it.
      final block = last.bottom + AdminSpacing.md - first.top;
      expect(first.top, closeTo(ring.top + (ring.height - block) / 2, 0.01));
    });

    testWidgets('a legend taller than the ring centres the ring', (
      tester,
    ) async {
      final many = [
        for (var i = 1; i <= 12; i++) ChartSlice('Region $i', 1.0 * i),
      ];
      await _pump(tester, width: 600, slices: many);
      expect(tester.takeException(), isNull);
      final chart = _rect(tester, _chart);
      final ring = _rect(tester, _ring);
      expect(chart.height, greaterThan(_ringSize));
      expect(ring.center.dy, closeTo(chart.center.dy, 0.01));
      expect(_rect(tester, _entry('Region 1')).top, chart.top);
    });

    testWidgets('right to left, the ring is at the right and the entries end '
        'at one edge', (tester) async {
      await _pump(tester, width: 600, direction: TextDirection.rtl);
      final chart = _rect(tester, _chart);
      final ring = _rect(tester, _ring);
      expect(ring.right, chart.right);
      for (final s in _channels) {
        expect(_rect(tester, _entry(s.label)).right, ring.left - _beside);
      }
    });

    testWidgets('it is beside at exactly the width it asks for, and under one '
        'pixel short of it', (tester) async {
      final natural = await _naturalWidth(tester);

      await _pump(tester, width: natural);
      expect(
        _rect(tester, _entry('Online store')).left,
        _rect(tester, _ring).right + _beside,
      );

      await _pump(tester, width: natural - 1);
      expect(tester.takeException(), isNull);
      expect(
        _rect(tester, _entry('Online store')).top,
        _rect(tester, _ring).bottom + _under,
      );
    });
  });

  group('without room beside the ring', () {
    testWidgets('the entries go under it, whole, and nothing overflows', (
      tester,
    ) async {
      // The card that found it: 148 of ring and a legend in 238.
      await _pump(tester, width: 238);
      expect(tester.takeException(), isNull);

      final chart = _rect(tester, _chart);
      final ring = _rect(tester, _ring);
      expect(ring.size, const Size.square(_ringSize));
      expect(ring.top, chart.top);
      expect(ring.center.dx, closeTo(chart.center.dx, 0.01));
      expect(chart.width, lessThanOrEqualTo(238));

      for (final s in _channels) {
        final entry = _rect(tester, _entry(s.label));
        expect(entry.top, greaterThanOrEqualTo(ring.bottom + _under));
        expect(entry.left, greaterThanOrEqualTo(chart.left));
        expect(entry.right, lessThanOrEqualTo(chart.right));
        expect(entry.bottom, lessThanOrEqualTo(chart.bottom));
        expect(_isCut(tester, s.label), isFalse, reason: s.label);
      }
    });

    testWidgets('they wrap in runs, each centred under the ring', (
      tester,
    ) async {
      await _pump(tester, width: 238);
      final chart = _rect(tester, _chart);
      final entries = [
        for (final s in _channels) _rect(tester, _entry(s.label)),
      ];

      final runs = <double, List<Rect>>{};
      for (final entry in entries) {
        runs.putIfAbsent(entry.center.dy, () => []).add(entry);
      }
      expect(runs.length, greaterThan(1));
      final tops = runs.values.map((r) => r.first.top).toList()..sort();
      for (final run in runs.values) {
        // In reading order, a gap apart, and centred.
        for (var i = 1; i < run.length; i++) {
          expect(run[i].left, run[i - 1].right + AdminSpacing.xl);
        }
        expect(
          (run.first.left + run.last.right) / 2,
          closeTo(chart.center.dx, 0.01),
        );
      }
      for (var i = 1; i < tops.length; i++) {
        expect(tops[i] - tops[i - 1], entries.first.height + AdminSpacing.md);
      }
      // No gap is left under the last run.
      expect(chart.bottom, entries.last.bottom);
    });

    testWidgets('right to left, a run reads from the right', (tester) async {
      await _pump(tester, width: 238, direction: TextDirection.rtl);
      expect(tester.takeException(), isNull);
      final first = _rect(tester, _entry(_channels[0].label));
      final second = _rect(tester, _entry(_channels[1].label));
      expect(second.center.dy, first.center.dy);
      expect(second.right, first.left - AdminSpacing.xl);
    });

    testWidgets('a label longer than the chart is cut, its swatch is not', (
      tester,
    ) async {
      const long = 'Wholesale partners in the northern and western regions';
      await _pump(
        tester,
        width: 238,
        slices: const [ChartSlice(long, 3), ChartSlice('Phone', 1)],
      );
      expect(tester.takeException(), isNull);

      final chart = _rect(tester, _chart);
      final entry = _rect(tester, _entry(long));
      expect(entry.left, chart.left);
      expect(entry.right, chart.right);
      expect(chart.width, 238);
      expect(_isCut(tester, long), isTrue);
      expect(_isCut(tester, 'Phone'), isFalse);

      final swatch = find.descendant(
        of: _entry(long),
        matching: find.byType(Container),
      );
      expect(tester.getSize(swatch), const Size.square(8));
      // The whole name is still what is read out.
      expect(find.text(long), findsOneWidget);
    });

    testWidgets('at twice the text size the legend that fitted goes under', (
      tester,
    ) async {
      final natural = await _naturalWidth(tester);
      await _pump(tester, width: natural, textScale: 2);
      expect(tester.takeException(), isNull);
      final ring = _rect(tester, _ring);
      for (final s in _channels) {
        expect(
          _rect(tester, _entry(s.label)).top,
          greaterThanOrEqualTo(ring.bottom + _under),
        );
        expect(_isCut(tester, s.label), isFalse, reason: s.label);
      }
    });

    testWidgets('a chart narrower than its ring draws a narrower ring', (
      tester,
    ) async {
      await _pump(tester, width: 100);
      expect(tester.takeException(), isNull);
      final chart = _rect(tester, _chart);
      expect(chart.width, lessThanOrEqualTo(100));
      expect(_rect(tester, _ring).width, 100);
    });
  });

  group('given a height', () {
    testWidgets('the legend under the ring takes its own, the ring the rest', (
      tester,
    ) async {
      await _pump(tester, width: 238);
      final free = _rect(tester, _chart);
      final legend = free.height - _ringSize - _under;

      await _pump(tester, width: 238, height: free.height - 40);
      expect(tester.takeException(), isNull);
      final chart = _rect(tester, _chart);
      final ring = _rect(tester, _ring);
      expect(chart.height, free.height - 40);
      expect(ring.height, _ringSize - 40);
      expect(_rect(tester, _entry(_channels.last.label)).bottom, chart.bottom);
      expect(chart.bottom - ring.bottom, _under + legend);
    });

    testWidgets('one the legend alone does not fit is reported', (
      tester,
    ) async {
      await _pump(tester, width: 238, height: 20);
      final error = tester.takeException();
      expect(error, isFlutterError);
      expect(error.toString(), contains('overflowed'));
    });

    testWidgets('a legend beside the ring taller than it is reported', (
      tester,
    ) async {
      final many = [
        for (var i = 1; i <= 12; i++) ChartSlice('Region $i', 1.0 * i),
      ];
      await _pump(tester, width: 600, height: 160, slices: many);
      final error = tester.takeException();
      expect(error, isFlutterError);
      expect(error.toString(), contains('overflowed'));
    });
  });

  group('where a parent asks what it needs', () {
    testWidgets('at its natural width it is as tall as its ring', (
      tester,
    ) async {
      await _pump(
        tester,
        width: 600,
        wrap: (chart) => IntrinsicWidth(child: IntrinsicHeight(child: chart)),
      );
      expect(tester.takeException(), isNull);
      final chart = _rect(tester, _chart);
      expect(chart.height, _ringSize);
      expect(
        _rect(tester, _entry('Online store')).left,
        _rect(tester, _ring).right + _beside,
      );
    });

    testWidgets('a row as tall as its tallest card counts the legend under '
        'the ring', (tester) async {
      const beside = Key('beside');
      await _pump(
        tester,
        width: 476 + AdminSpacing.md,
        wrap: (chart) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(
                child: ColoredBox(key: beside, color: Colors.teal),
              ),
              const Gap(AdminSpacing.md),
              Expanded(child: Center(child: chart)),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final chart = _rect(tester, _chart);
      expect(chart.width, lessThanOrEqualTo(238));
      expect(chart.height, greaterThan(_ringSize + _under));
      expect(tester.getSize(find.byKey(beside)).height, chart.height);
    });
  });

  testWidgets('with no legend it is its ring', (tester) async {
    await _pump(tester, width: 238, showLegend: false);
    expect(tester.takeException(), isNull);
    expect(_rect(tester, _chart).size, const Size.square(_ringSize));
    expect(find.text('Online store'), findsNothing);
  });

  testWidgets('with no slices it draws its ring and throws nothing', (
    tester,
  ) async {
    await _pump(tester, width: 238, slices: const []);
    expect(tester.takeException(), isNull);
    expect(_rect(tester, _ring).size, const Size.square(_ringSize));
  });

  testWidgets('each name is in the tree once, beside the ring or under it', (
    tester,
  ) async {
    for (final width in [600.0, 238.0]) {
      await _pump(tester, width: width);
      for (final s in _channels) {
        expect(find.text(s.label), findsOneWidget, reason: '$width');
      }
    }
  });

  group('a line or bar chart\'s legend', () {
    const long = 'Returning customers who ordered again within thirty days';

    testWidgets('cuts a series name longer than the chart', (tester) async {
      await _pump(
        tester,
        width: 220,
        wrap: (_) => const LineChart(
          series: [
            ChartSeries(long, [3, 5, 4]),
            ChartSeries('New', [1, 2, 4]),
          ],
          labels: ['Jan', 'Feb', 'Mar'],
        ),
      );
      expect(tester.takeException(), isNull);
      final chart = _rect(tester, find.byType(LineChart));
      final entry = _rect(tester, _entry(long));
      expect(entry.left, chart.left);
      expect(entry.right, lessThanOrEqualTo(chart.right));
      expect(_isCut(tester, long), isTrue);
      expect(_isCut(tester, 'New'), isFalse);
    });

    testWidgets('with room, is a run of whole names', (tester) async {
      await _pump(
        tester,
        width: 900,
        wrap: (_) => const BarChart(
          series: [
            ChartSeries(long, [3, 5, 4]),
            ChartSeries('New', [1, 2, 4]),
          ],
          labels: ['Jan', 'Feb', 'Mar'],
        ),
      );
      expect(tester.takeException(), isNull);
      expect(_isCut(tester, long), isFalse);
      final first = _rect(tester, _entry(long));
      final second = _rect(tester, _entry('New'));
      expect(second.left, first.right + AdminSpacing.xl);
      expect(second.center.dy, first.center.dy);
    });
  });
}
