import 'dart:math' as math;

import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui/src/common/ui/chart.dart' show chartSeriesColors;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import 'shipped_palettes.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];

Widget _host(
  Widget child, {
  AdminPalette palette = irisPalette,
  double width = 400,
  double textScale = 1,
}) => MaterialApp(
  theme: buildAppTheme(AdminTokens.from(palette: palette)),
  home: MediaQuery.withClampedTextScaling(
    minScaleFactor: textScale,
    maxScaleFactor: textScale,
    child: Scaffold(
      body: Center(
        child: SizedBox(width: width, child: child),
      ),
    ),
  ),
);

/// Every call [T]'s painter made on the canvas, as (method, arguments).
List<(Symbol, List<dynamic>)> _calls<T extends Widget>() {
  final calls = <(Symbol, List<dynamic>)>[];
  expect(
    find.descendant(of: find.byType(T), matching: find.byType(CustomPaint)),
    paints..everything((method, args) {
      calls.add((method, args));
      return true;
    }),
  );
  return calls;
}

/// The corner a bar's far end takes: the theme's small radius, within half
/// its width and its length.
double _cap(RRect bar) =>
    math.min(defaultRadii.radiusSmall, math.min(bar.width / 2, bar.height));

List<RRect> _rrects<T extends Widget>() => [
  for (final (method, args) in _calls<T>())
    if (method == #drawRRect) args[0] as RRect,
];

/// The rects of the category labels the chart shows, left to right.
List<Rect> _xLabels(WidgetTester tester, List<String> labels) {
  final rects = [
    for (final label in labels)
      if (find.text(label).evaluate().isNotEmpty)
        tester.getRect(find.text(label)),
  ];
  return rects..sort((a, b) => a.left.compareTo(b.left));
}

void main() {
  group('LineChart axis', () {
    testWidgets('shows the first and last labels inside the chart', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const LineChart(
            series: [
              ChartSeries('Visits', [3, 5, 4, 6, 5, 7]),
            ],
            labels: _months,
          ),
        ),
      );

      final chart = tester.getRect(find.byType(LineChart));
      final jan = tester.getRect(find.text('Jan'));
      final jun = tester.getRect(find.text('Jun'));
      expect(jan.left, greaterThanOrEqualTo(chart.left));
      expect(jun.right, lessThanOrEqualTo(chart.right));

      // Each label stays centred on its point: the points are evenly spaced,
      // so the label centres are too.
      final centres = [for (final r in _xLabels(tester, _months)) r.center.dx];
      expect(centres, hasLength(6));
      final step = centres[1] - centres[0];
      for (var i = 1; i < centres.length; i++) {
        expect(centres[i] - centres[i - 1], closeTo(step, 0.01));
      }
    });

    testWidgets('keeps long end labels inside a narrow chart', (tester) async {
      const labels = [
        'Q1 2025 (actual)',
        'Q2 2025',
        'Q3 2025',
        'Q4 2025',
        'Q1 2026',
        'Q2 2026 (forecast)',
      ];
      await tester.pumpWidget(
        _host(
          width: 420,
          const LineChart(
            series: [
              ChartSeries('Visits', [3, 5, 4, 6, 5, 7]),
            ],
            labels: labels,
          ),
        ),
      );

      final chart = tester.getRect(find.byType(LineChart));
      final shown = _xLabels(tester, labels);
      expect(find.text(labels.last), findsOneWidget);
      expect(shown.first.left, greaterThanOrEqualTo(chart.left));
      expect(shown.last.right, lessThanOrEqualTo(chart.right));
      for (var i = 1; i < shown.length; i++) {
        expect(shown[i].left, greaterThanOrEqualTo(shown[i - 1].right));
      }
    });

    testWidgets('thins a crowded axis to every k-th label, from the last', (
      tester,
    ) async {
      final labels = [for (var i = 1; i <= 24; i++) 'W$i'];
      await tester.pumpWidget(
        _host(
          width: 300,
          LineChart(
            series: [
              ChartSeries('Visits', [for (var i = 0; i < 24; i++) i % 5.0]),
            ],
            labels: labels,
          ),
        ),
      );

      final shown = [
        for (final (i, label) in labels.indexed)
          if (find.text(label).evaluate().isNotEmpty) i,
      ];
      expect(shown.last, 23, reason: 'the latest point is named');
      expect(shown.length, inInclusiveRange(2, labels.length - 1));
      final stride = shown[1] - shown[0];
      for (var i = 1; i < shown.length; i++) {
        expect(shown[i] - shown[i - 1], stride, reason: 'evenly spaced');
      }
      final rects = _xLabels(tester, labels);
      for (var i = 1; i < rects.length; i++) {
        expect(rects[i].left, greaterThanOrEqualTo(rects[i - 1].right));
      }
    });

    testWidgets('an empty label is neither shown nor counted', (tester) async {
      // Every 14th of 90 days named, counted back from the last: blanks
      // between them must not crowd the names out.
      final labels = [
        for (var i = 0; i < 90; i++) (89 - i) % 14 == 0 ? 'Day ${i + 1}' : '',
      ];
      await tester.pumpWidget(
        _host(
          width: 600,
          LineChart(
            series: [
              ChartSeries('Visits', [for (var i = 0; i < 90; i++) i % 7.0]),
            ],
            labels: labels,
          ),
        ),
      );
      for (final label in labels.where((l) => l.isNotEmpty)) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('a curve stays between the two points it joins', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const LineChart(
            showDots: true,
            series: [
              ChartSeries('Score', [2, 8, 8, 3, 9, 1, 1.5]),
            ],
            labels: ['a', 'b', 'c', 'd', 'e', 'f', 'g'],
          ),
        ),
      );
      final calls = _calls<LineChart>();
      final points = [
        for (final (method, args) in calls)
          if (method == #drawCircle && (args[2] as Paint).style == .fill)
            args[0] as Offset,
      ];
      final line = [
        for (final (method, args) in calls)
          if (method == #drawPath) args[0] as Path,
      ].single;
      expect(points, hasLength(7));
      for (final metric in line.computeMetrics()) {
        for (var at = 0.0; at <= metric.length; at += 0.5) {
          final p = metric.getTangentForOffset(at)!.position;
          final k = points.lastIndexWhere((q) => q.dx <= p.dx + 1e-6);
          final a = points[k], b = points[math.min(k + 1, points.length - 1)];
          expect(
            p.dy,
            inInclusiveRange(
              math.min(a.dy, b.dy) - 0.01,
              math.max(a.dy, b.dy) + 0.01,
            ),
            reason: 'at x ${p.dx}, between $a and $b',
          );
        }
      }
    });

    testWidgets('minY and maxY fix the value axis whatever the data', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const LineChart(
            minY: 0,
            maxY: 10,
            series: [
              ChartSeries('Score', [6, 7.5, 8, 7]),
            ],
            labels: ['Q1', 'Q2', 'Q3', 'Q4'],
          ),
        ),
      );
      for (final tick in ['0', '2', '4', '6', '8', '10']) {
        expect(find.text(tick), findsOneWidget, reason: tick);
      }
      expect(find.text('12'), findsNothing);
      // The 10 line is the plot's top edge: its label centres on it.
      final ten = tester.getRect(find.text('10'));
      final grid = [
        for (final (method, args) in _calls<LineChart>())
          if (method == #drawLine) (args[0] as Offset).dy,
      ]..sort();
      expect(
        grid.first,
        closeTo(
          ten.center.dy - tester.getRect(find.byType(LineChart)).top,
          0.5,
        ),
      );
    });

    testWidgets('a value past a fixed range is cut at the plot', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const LineChart(
            maxY: 10,
            series: [
              ChartSeries('Score', [4, 14, 6]),
            ],
            labels: ['a', 'b', 'c'],
          ),
        ),
      );
      expect(find.text('10'), findsOneWidget);
      expect(find.text('14'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(LineChart),
          matching: find.byType(CustomPaint),
        ),
        paints..clipRect(),
      );
    });

    testWidgets('an area closes on the zero line, not the axis floor', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const LineChart(
            area: true,
            curved: false,
            series: [
              ChartSeries('Net', [4, -3, 6]),
            ],
            labels: ['Jan', 'Feb', 'Mar'],
          ),
        ),
      );

      final calls = _calls<LineChart>();
      final floor = [
        for (final (method, args) in calls)
          if (method == #drawLine) (args[0] as Offset).dy,
      ].reduce((a, b) => a > b ? a : b);
      final fill = [
        for (final (method, args) in calls)
          if (method == #drawPath && (args[1] as Paint).shader != null)
            args[0] as Path,
      ].single;
      // The lowest point is -3, above the scale's -4 floor.
      expect(fill.getBounds().bottom, lessThan(floor - 1));
    });

    testWidgets('lays labels out with the ambient text direction', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Directionality(
            textDirection: TextDirection.rtl,
            child: LineChart(
              series: [
                ChartSeries('Visits', [3, 5, 4]),
              ],
              labels: ['يناير', 'فبراير', 'مارس'],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('يناير'), findsOneWidget);
    });
  });

  group('LineChart.time', () {
    /// A reading a day from [first], [days] of them, in UTC.
    List<(DateTime, double)> daily(DateTime first, int days) => [
      for (var i = 0; i < days; i++)
        (first.add(Duration(days: i)), (i * 7 % 10).toDouble()),
    ];

    testWidgets('places each reading at its instant, in any order', (
      tester,
    ) async {
      final start = DateTime.utc(2026, 3, 2, 9);
      await tester.pumpWidget(
        _host(
          width: 600,
          LineChart.time(
            showDots: true,
            series: [
              ChartTimeSeries('Score', [
                (start.add(const Duration(days: 7, hours: 1)), 5),
                (start, 6),
                (start.add(const Duration(hours: 1)), 7),
              ]),
            ],
          ),
        ),
      );
      final xs = [
        for (final (method, args) in _calls<LineChart>())
          if (method == #drawCircle && (args[2] as Paint).style == .fill)
            (args[0] as Offset).dx,
      ];
      expect(xs, hasLength(3));
      // An hour, then a week: 1 to 168.
      expect((xs[1] - xs[0]) * 168, closeTo(xs[2] - xs[1], 0.5));
    });

    testWidgets('ticks a month of days by the week, from its first day', (
      tester,
    ) async {
      // 1 March 2026 is a Sunday, where an American week starts.
      await tester.pumpWidget(
        _host(
          width: 600,
          LineChart.time(
            series: [
              ChartTimeSeries('Revenue', daily(DateTime.utc(2026, 3), 30)),
            ],
          ),
        ),
      );
      final ticks = ['Mar 1', 'Mar 8', 'Mar 15', 'Mar 22', 'Mar 29'];
      for (final tick in ticks) {
        expect(find.text(tick), findsOneWidget, reason: tick);
      }
      expect(find.text('Mar 2'), findsNothing);
      final centres = [
        for (final t in ticks) tester.getCenter(find.text(t)).dx,
      ];
      for (var i = 2; i < centres.length; i++) {
        expect(
          centres[i] - centres[i - 1],
          closeTo(centres[1] - centres[0], 0.5),
        );
      }
    });

    testWidgets('names months, and January by its year', (tester) async {
      await tester.pumpWidget(
        _host(
          width: 600,
          LineChart.time(
            series: [
              ChartTimeSeries('Visits', [
                for (var m = 10; m <= 16; m++)
                  (DateTime.utc(2025, m, 1), m.toDouble()),
              ]),
            ],
          ),
        ),
      );
      for (final tick in ['Oct', 'Nov', 'Dec', '2026', 'Feb', 'Mar', 'Apr']) {
        expect(find.text(tick), findsOneWidget, reason: tick);
      }
      expect(find.text('Jan'), findsNothing);
    });

    testWidgets('ticks hours of the day, and midnight by its date', (
      tester,
    ) async {
      final from = DateTime.utc(2026, 3, 2, 18);
      await tester.pumpWidget(
        _host(
          width: 600,
          LineChart.time(
            series: [
              ChartTimeSeries('Load', [
                (from, 3),
                (from.add(const Duration(hours: 5)), 4),
                (from.add(const Duration(hours: 12)), 2),
              ]),
            ],
          ),
        ),
      );
      final hour = DateFormat.j('en_US');
      for (final h in [18, 21, 27, 30]) {
        final tick = hour.format(DateTime.utc(2026, 3, 2, h));
        expect(find.text(tick), findsOneWidget, reason: tick);
      }
      expect(find.text('Mar 3'), findsOneWidget);
    });

    testWidgets('a single reading is named by its day', (tester) async {
      await tester.pumpWidget(
        _host(
          LineChart.time(
            series: [
              ChartTimeSeries('Score', [(DateTime.utc(2026, 3, 2, 9), 6)]),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Mar 2'), findsOneWidget);
    });

    testWidgets('no points draws an empty chart', (tester) async {
      await tester.pumpWidget(
        _host(const LineChart.time(series: [ChartTimeSeries('Score', [])])),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byType(LineChart),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    });
  });

  group('BarChart', () {
    testWidgets('rounds the top drawn segment when the last series is 0', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const BarChart(
            stacked: true,
            series: [
              ChartSeries('Direct', [4, 4]),
              ChartSeries('Referral', [3, 3]),
              ChartSeries('Social', [2, 0]),
            ],
            labels: ['Q1', 'Q2'],
          ),
        ),
      );

      final columns = <double, List<RRect>>{};
      for (final r in _rrects<BarChart>()) {
        columns.putIfAbsent(r.left, () => []).add(r);
      }
      expect(columns.values.map((c) => c.length), [3, 2]);
      for (final column in columns.values) {
        final top = column.reduce((a, b) => a.top < b.top ? a : b);
        for (final segment in column) {
          final rounded = segment == top;
          expect(segment.tlRadiusX, rounded ? _cap(segment) : 0);
          expect(segment.trRadiusX, rounded ? _cap(segment) : 0);
          expect(segment.blRadiusX, 0);
        }
      }
    });

    testWidgets('hangs negative bars down from the zero line', (tester) async {
      await tester.pumpWidget(
        _host(
          const BarChart(
            series: [
              ChartSeries('Net', [5, -5]),
            ],
            labels: ['Jan', 'Feb'],
          ),
        ),
      );

      final [up, down] = _rrects<BarChart>();
      expect(down.top, closeTo(up.bottom, 0.01));
      expect(down.bottom - down.top, closeTo(up.bottom - up.top, 0.01));
      expect(up.tlRadiusX, _cap(up));
      expect(up.blRadiusX, 0);
      expect(down.tlRadiusX, 0);
      expect(down.blRadiusX, _cap(down));
    });
  });

  group('loading', () {
    for (final scale in [1.0, 2.0]) {
      testWidgets('a bar list is as tall as it is loaded, text x$scale', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            const BarList(
              sort: false,
              items: [
                BarListItem('Signed up', 12),
                BarListItem('Paid', 5),
                BarListItem('Refunded', 1),
              ],
            ),
            textScale: scale,
          ),
        );
        final loaded = tester.getSize(find.byType(BarList)).height;

        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          _host(
            const BarList(
              sort: false,
              loading: true,
              items: [
                BarListItem('Signed up', 0),
                BarListItem('Paid', 0),
                BarListItem('', 0),
              ],
            ),
            textScale: scale,
          ),
        );
        expect(tester.getSize(find.byType(BarList)).height, loaded);
        expect(find.text('Signed up'), findsOneWidget);
        expect(find.text('0'), findsNothing);
        expect(find.byType(SkeletonGroup), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('^Loading…')), findsOneWidget);
        semantics.dispose();
      });
    }

    testWidgets('a chart keeps its legend and its height', (tester) async {
      const series = [
        ChartSeries('This year', [12, 19, 14]),
        ChartSeries('Last year', [9, 11, 13]),
      ];
      final labels = _months.sublist(0, 3);
      for (final chart in [
        (bool loading) =>
            LineChart(series: series, labels: labels, loading: loading),
        (bool loading) =>
            BarChart(series: series, labels: labels, loading: loading),
      ]) {
        await tester.pumpWidget(_host(KeyedSubtree(child: chart(false))));
        final loaded = tester.getSize(find.byType(KeyedSubtree).last).height;

        await tester.pumpWidget(_host(KeyedSubtree(child: chart(true))));
        expect(tester.getSize(find.byType(KeyedSubtree).last).height, loaded);
        expect(find.text('This year'), findsOneWidget);
        expect(find.text('Jan'), findsNothing);
        expect(find.byType(Skeleton), findsWidgets);
      }
    });
  });

  group('series colours', () {
    for (final (name, palette) in [
      ('Iris Light', irisPalette),
      ('shadcn Dark', shadcnDarkPalette),
      ('Carbon Light', carbonPalette),
    ]) {
      testWidgets('$name series take the categorical ramp', (tester) async {
        await tester.pumpWidget(
          _host(
            palette: palette,
            const LineChart(
              series: [
                ChartSeries('A', [1, 2, 3]),
                ChartSeries('B', [2, 3, 1]),
                ChartSeries('C', [3, 1, 2]),
              ],
              labels: ['Jan', 'Feb', 'Mar'],
            ),
          ),
        );

        final strokes = [
          for (final (method, args) in _calls<LineChart>())
            if (method == #drawPath &&
                (args[1] as Paint).style == PaintingStyle.stroke)
              (args[1] as Paint).color.toARGB32(),
        ];
        expect(strokes, [for (final c in palette.chart.take(3)) c.toARGB32()]);
      });

      testWidgets('$name sparklines match the first chart colour', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(palette: palette, const Sparkline([1, 3, 2, 4], area: false)),
        );
        final stroke = [
          for (final (method, args) in _calls<Sparkline>())
            if (method == #drawPath) (args[1] as Paint).color.toARGB32(),
        ].single;
        expect(stroke, palette.chart.first.toARGB32());
      });
    }

    for (final MapEntry(key: name, value: palette) in shippedPalettes.entries) {
      testWidgets('$name muted sparkline bars hold 2:1 on the page', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            palette: palette,
            const BarSparkline([3, 5, 2, 6, 4], highlightLast: true),
          ),
        );
        final fills = [
          for (final (method, args) in _calls<BarSparkline>())
            if (method == #drawRRect) (args[1] as Paint).color,
        ];
        expect(fills, hasLength(5));
        expect(fills.last.toARGB32(), palette.chart.first.toARGB32());
        final muted = fills.first;
        expect(
          {for (final c in fills.take(4)) c.toARGB32()},
          {muted.toARGB32()},
        );
        for (final surface in [palette.surface, palette.background]) {
          expect(contrastRatio(muted, surface), greaterThanOrEqualTo(2));
        }
        expect(muted.toARGB32(), isNot(fills.last.toARGB32()));
      });
    }

    test('chartSeriesColors cycles the palette ramp', () {
      final ramp = irisPalette.chart;
      final colors = chartSeriesColors(irisPalette, ramp.length + 2);
      expect(colors.take(ramp.length), ramp);
      expect(colors.skip(ramp.length), ramp.take(2));
    });

    test('an empty ramp falls back to hues at 3:1 on surface', () {
      for (final palette in [irisPalette, shadcnDarkPalette, antPalette]) {
        final bare = palette.copyWith(chart: const []);
        for (final c in chartSeriesColors(bare, 8)) {
          expect(contrastRatio(c, bare.surface), greaterThanOrEqualTo(3));
        }
      }
    });
  });
}
