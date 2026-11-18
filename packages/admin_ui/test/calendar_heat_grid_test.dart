// Grid arithmetic is only put to the test where a day can be 23 or 25 hours
// long; run this file in such a zone as well as the default one:
//
//   TZ=Europe/Brussels fvm flutter test test/calendar_heat_grid_test.dart

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

/// A Friday.
final _today = DateTime(2026, 6, 12);

Widget _host(
  Widget child, {
  double width = 600,
  TextDirection direction = TextDirection.ltr,
  ThemeData? theme,
}) => MaterialApp(
  theme: theme,
  home: Scaffold(
    body: Center(
      child: Directionality(
        textDirection: direction,
        child: SizedBox(width: width, child: child),
      ),
    ),
  ),
);

/// The days drawn, by their tips, first week first.
List<String> _days(WidgetTester tester) => [
  for (final tip in tester.widgetList<Tip>(find.byType(Tip))) tip.message,
];

/// The day whose tip is [message].
Finder _day(String message) =>
    find.byWidgetPredicate((w) => w is Tip && w.message == message);

/// The fill of the day whose tip is [message].
Color _fill(WidgetTester tester, String message) =>
    (tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: _day(message),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration)
        .color!;

/// The tip of the day holding keyboard focus.
String? _focused(WidgetTester tester) => tester
    .widgetList<Tip>(
      find.ancestor(
        of: find.byWidgetPredicate(
          (w) => w is Focus && (w.focusNode?.hasPrimaryFocus ?? false),
        ),
        matching: find.byType(Tip),
      ),
    )
    .firstOrNull
    ?.message;

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initializeDateFormatting);

  group('days', () {
    testWidgets('weeks ends on today’s week; the days after today are blank', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(CalendarHeatGrid(values: const {}, weeks: 2, today: _today)),
      );
      final days = _days(tester);
      // Sunday May 31 to Friday June 12: Saturday the 13th is not drawn.
      expect(days, hasLength(13));
      expect(days.first, 'Sun, May 31, 2026: 0');
      expect(days.last, 'Fri, Jun 12, 2026: 0');
    });

    testWidgets('a range shows its own days, up to today', (tester) async {
      await tester.pumpWidget(
        _host(
          CalendarHeatGrid.range(
            range: DateTimeRange(
              start: DateTime(2026, 6, 3),
              end: DateTime(2026, 8, 31),
            ),
            values: const {},
            today: _today,
          ),
        ),
      );
      final days = _days(tester);
      expect(days.first, 'Wed, Jun 3, 2026: 0');
      expect(days.last, 'Fri, Jun 12, 2026: 0');
      expect(days, hasLength(10));
    });

    testWidgets('a range before today shows every day of it', (tester) async {
      await tester.pumpWidget(
        _host(
          CalendarHeatGrid.range(
            range: DateTimeRange(
              start: DateTime(2026, 3, 1),
              end: DateTime(2026, 3, 31),
            ),
            values: const {},
            today: _today,
          ),
        ),
      );
      final days = _days(tester);
      expect(days, hasLength(31));
      expect(days.first, 'Sun, Mar 1, 2026: 0');
      expect(days.last, 'Tue, Mar 31, 2026: 0');
    });

    testWidgets('26 weeks across a clock change are 26 × 7 days, each once', (
      tester,
    ) async {
      final today = DateTime(2026, 11, 7); // a Saturday
      await tester.pumpWidget(
        _host(CalendarHeatGrid(values: const {}, today: today)),
      );
      final days = _days(tester);
      expect(days, hasLength(26 * 7));
      expect(days.toSet(), hasLength(26 * 7));
      expect(days.first, 'Sun, May 10, 2026: 0');
      expect(days.last, 'Sat, Nov 7, 2026: 0');
    });
  });

  group('week start', () {
    List<String> weekdays(WidgetTester tester) => [
      for (final text in tester.widgetList<Text>(
        find.descendant(
          of: find.byType(CalendarHeatGrid),
          matching: find.byType(Text),
        ),
      ))
        text.data!,
    ];

    for (final (locale, first, named) in [
      ('en_US', 'Sun, Jun 7', ['Mon', 'Wed', 'Fri']),
      ('fr', 'lun. 8 juin', ['mar.', 'jeu.', 'sam.']),
      ('ar', 'السبت', ['الأحد', 'الثلاثاء', 'الخميس']),
    ]) {
      testWidgets('$locale: its first day and its weekday names', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            CalendarHeatGrid(
              values: const {},
              weeks: 1,
              locale: locale,
              today: _today,
            ),
          ),
        );
        expect(_days(tester).first, startsWith(first));
        expect(weekdays(tester), containsAllInOrder(named));
      });
    }

    testWidgets('follows the app’s locale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: AdminLocalizations.localizationsDelegates,
          home: Scaffold(
            body: CalendarHeatGrid(values: const {}, weeks: 1, today: _today),
          ),
        ),
      );
      // French sets the colon off with a narrow space.
      expect(
        _days(tester).first,
        matches(RegExp(r'^lun\. 8 juin 2026\s:\s0$')),
      );
      expect(find.text('Moins'), findsOneWidget);
    });

    testWidgets('firstDayOfWeek overrides the locale', (tester) async {
      await tester.pumpWidget(
        _host(
          CalendarHeatGrid(
            values: const {},
            weeks: 1,
            locale: 'en_US',
            firstDayOfWeek: 1,
            today: _today,
          ),
        ),
      );
      expect(_days(tester).first, 'Mon, Jun 8, 2026: 0');
    });
  });

  group('values', () {
    const accent = Color(0xFF0050FF);

    testWidgets('a key’s time of day is ignored, and one day’s keys add up', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CalendarHeatGrid(
            values: {
              DateTime(2026, 6, 12, 9, 30): 1,
              DateTime.utc(2026, 6, 12, 23): 2,
              DateTime(2026, 6, 11): 1.5,
            },
            weeks: 1,
            today: _today,
          ),
        ),
      );
      expect(_day('Fri, Jun 12, 2026: 3'), findsOneWidget);
      expect(_day('Thu, Jun 11, 2026: 1.5'), findsOneWidget);
    });

    testWidgets('formatValue writes the value after the date', (tester) async {
      await tester.pumpWidget(
        _host(
          CalendarHeatGrid(
            values: {_today: 1},
            weeks: 1,
            today: _today,
            formatValue: (v) => v > 0 ? 'Used' : 'Not used',
          ),
        ),
      );
      expect(_day('Fri, Jun 12, 2026: Used'), findsOneWidget);
      expect(_day('Thu, Jun 11, 2026: Not used'), findsOneWidget);
    });

    testWidgets('a day takes the level of its share of max', (tester) async {
      await tester.pumpWidget(
        _host(
          CalendarHeatGrid(
            values: {
              DateTime(2026, 6, 7): 1, // 1/8: level 1
              DateTime(2026, 6, 8): 3, // 3/8: level 2
              DateTime(2026, 6, 9): 5, // 5/8: level 3
              DateTime(2026, 6, 10): 8, // level 4
              DateTime(2026, 6, 11): 20, // past max: level 4
              _today: -2, // none above zero: empty
            },
            weeks: 1,
            max: 8,
            color: accent,
            today: _today,
          ),
        ),
      );
      final levels = [
        _fill(tester, 'Sun, Jun 7, 2026: 1'),
        _fill(tester, 'Mon, Jun 8, 2026: 3'),
        _fill(tester, 'Tue, Jun 9, 2026: 5'),
        _fill(tester, 'Wed, Jun 10, 2026: 8'),
      ];
      expect(levels.toSet(), hasLength(4));
      expect(levels.last, accent);
      expect(_fill(tester, 'Thu, Jun 11, 2026: 20'), accent);
      // Each level a step further from the empty fill.
      final empty = _fill(tester, 'Fri, Jun 12, 2026: -2');
      final white = Colors.white;
      final steps = [
        for (final c in [empty, ...levels])
          contrastRatio(Color.alphaBlend(c, white), white),
      ];
      for (var i = 1; i < steps.length; i++) {
        expect(steps[i], greaterThan(steps[i - 1]));
      }
    });

    testWidgets('without max, the largest value shown fills fullest', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CalendarHeatGrid(
            values: {
              _today: 2,
              DateTime(2026, 6, 11): 1,
              // Before the grid: not counted.
              DateTime(2026, 1, 1): 100,
            },
            weeks: 1,
            color: accent,
            today: _today,
          ),
        ),
      );
      expect(_fill(tester, 'Fri, Jun 12, 2026: 2'), accent);
      expect(_fill(tester, 'Thu, Jun 11, 2026: 1'), isNot(accent));
    });

    testWidgets('levels: 1 fills every day used, and shows no legend', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CalendarHeatGrid(
            values: {_today: 1, DateTime(2026, 6, 11): 0.2},
            weeks: 1,
            levels: 1,
            color: accent,
            today: _today,
          ),
        ),
      );
      expect(_fill(tester, 'Fri, Jun 12, 2026: 1'), accent);
      expect(_fill(tester, 'Thu, Jun 11, 2026: 0.2'), accent);
      expect(find.text('Less'), findsNothing);
      expect(find.text('More'), findsNothing);
    });

    testWidgets('more levels show the legend, Less to More', (tester) async {
      await tester.pumpWidget(
        _host(CalendarHeatGrid(values: const {}, weeks: 1, today: _today)),
      );
      expect(find.text('Less'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Less')).dx,
        lessThan(tester.getTopLeft(find.text('More')).dx),
      );
    });
  });

  group('themes', () {
    for (final theme in adminThemes) {
      for (final dark in [false, true]) {
        final mode = dark ? 'dark' : 'light';
        testWidgets('${theme.name} $mode: an empty day shows on the surface '
            'and the page, and the lightest level apart from it', (
          tester,
        ) async {
          final tokens = dark ? theme.dark ?? theme.tokens : theme.tokens;
          final palette = tokens.palette;
          await tester.pumpWidget(
            _host(
              CalendarHeatGrid(
                values: {_today: 1, DateTime(2026, 6, 11): 4},
                weeks: 1,
                today: _today,
              ),
              theme: buildAppTheme(
                AdminTokens.from(palette: palette, radii: tokens.radii),
              ),
            ),
          );
          final empty = _fill(tester, 'Wed, Jun 10, 2026: 0');
          final lightest = _fill(tester, 'Fri, Jun 12, 2026: 1');
          for (final ground in [palette.surface, palette.background]) {
            final emptyOn = Color.alphaBlend(empty, ground);
            expect(contrastRatio(emptyOn, ground), greaterThan(1.1));
            expect(
              contrastRatio(Color.alphaBlend(lightest, ground), emptyOn),
              greaterThan(1.15),
            );
          }
          // The fullest level is the chart's first colour.
          expect(_fill(tester, 'Thu, Jun 11, 2026: 4'), palette.chart.first);
          // A square with the theme's small corner, at most a quarter of it.
          final radius =
              (tester
                          .widget<DecoratedBox>(
                            find
                                .descendant(
                                  of: _day('Wed, Jun 10, 2026: 0'),
                                  matching: find.byType(DecoratedBox),
                                )
                                .first,
                          )
                          .decoration
                      as BoxDecoration)
                  .borderRadius;
          final corner = tokens.radii.radiusSmall < 3
              ? tokens.radii.radiusSmall
              : 3.0;
          expect(radius, BorderRadius.circular(corner));
        });
      }
    }
  });

  group('reading a day', () {
    testWidgets('hovering a day opens its tip', (tester) async {
      await tester.pumpWidget(
        _host(CalendarHeatGrid(values: {_today: 2}, weeks: 2, today: _today)),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(
        location: tester.getCenter(_day('Fri, Jun 12, 2026: 2')),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Fri, Jun 12, 2026: 2'), findsOneWidget);
      await mouse.removePointer();
    });

    testWidgets('each day is announced by its date and value', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(CalendarHeatGrid(values: {_today: 2}, weeks: 1, today: _today)),
      );
      expect(find.bySemanticsLabel('Fri, Jun 12, 2026: 2'), findsOneWidget);
      expect(find.bySemanticsLabel('Sun, Jun 7, 2026: 0'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('one Tab stop, the latest day; the arrows, Home and End move '
        'it, and the focused day shows its tip', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              CalendarHeatGrid(values: const {}, weeks: 3, today: _today),
              TextButton(onPressed: () {}, child: const Text('After')),
            ],
          ),
        ),
      );
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focused(tester), 'Fri, Jun 12, 2026: 0');
      expect(find.text('Fri, Jun 12, 2026: 0'), findsOneWidget);

      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_focused(tester), 'Thu, Jun 11, 2026: 0');
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(_focused(tester), 'Thu, Jun 4, 2026: 0');
      await _key(tester, LogicalKeyboardKey.home);
      expect(_focused(tester), 'Sun, May 31, 2026: 0');
      await _key(tester, LogicalKeyboardKey.end);
      expect(_focused(tester), 'Sat, Jun 6, 2026: 0');
      await _key(tester, LogicalKeyboardKey.arrowRight);
      // Saturday the 13th is after today: as far as it goes.
      expect(_focused(tester), 'Fri, Jun 12, 2026: 0');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_focused(tester), 'Fri, Jun 12, 2026: 0');

      // Tab leaves the grid, and comes back to the day it left.
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focused(tester), isNull);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await _key(tester, LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      expect(_focused(tester), 'Fri, Jun 5, 2026: 0');
    });

    testWidgets('right to left, the arrows follow the weeks', (tester) async {
      await tester.pumpWidget(
        _host(
          CalendarHeatGrid(values: const {}, weeks: 3, today: _today),
          direction: TextDirection.rtl,
        ),
      );
      await _key(tester, LogicalKeyboardKey.tab);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_focused(tester), 'Fri, Jun 5, 2026: 0');
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(_focused(tester), 'Fri, Jun 12, 2026: 0');
    });
  });

  group('width', () {
    for (final direction in TextDirection.values) {
      testWidgets('${direction.name}: narrower than its weeks, it opens on the '
          'latest week and scrolls to the first', (tester) async {
        await tester.pumpWidget(
          _host(
            CalendarHeatGrid(values: const {}, today: _today),
            width: 240,
            direction: direction,
          ),
        );
        final view = tester.getRect(find.byType(Scrollable));
        final latest = tester.getRect(_day('Fri, Jun 12, 2026: 0'));
        final first = _day('Sun, Dec 14, 2025: 0');
        expect(view.contains(latest.center), isTrue);
        expect(view.contains(tester.getCenter(first)), isFalse);
        // Older weeks lie toward the start.
        final rtl = direction == TextDirection.rtl;
        expect(tester.getCenter(first).dx < latest.center.dx, !rtl);

        await tester.drag(
          find.byType(Scrollable),
          Offset(rtl ? -2000 : 2000, 0),
        );
        await tester.pumpAndSettle();
        expect(view.contains(tester.getCenter(first)), isTrue);
      });
    }

    testWidgets('wider than its weeks, it keeps to its start, the legend '
        'under its end', (tester) async {
      await tester.pumpWidget(
        _host(CalendarHeatGrid(values: const {}, weeks: 8, today: _today)),
      );
      final grid = tester.getRect(find.byType(CalendarHeatGrid));
      final latest = tester.getRect(_day('Fri, Jun 12, 2026: 0'));
      final more = tester.getRect(find.text('More'));
      expect(latest.right, lessThan(grid.left + 200));
      expect((more.right - latest.right).abs(), lessThan(8));
    });
  });
}
