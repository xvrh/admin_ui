// Grid arithmetic is only put to the test where a day can be 23 or 25 hours
// long; run this file in such a zone as well as the default one:
//
//   TZ=Europe/Brussels fvm flutter test test/dates_calendar_test.dart

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

final _today = DateTime(2026, 6, 12);

Widget _host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Directionality(
            textDirection: direction,
            child: SizedBox(width: 300, child: child),
          ),
        ),
      ),
    );

/// [DateRangePreset.defaults] under an English app.
Future<List<DateRangePreset>> _defaultPresets(WidgetTester tester) async {
  late List<DateRangePreset> presets;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          presets = DateRangePreset.defaults(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return presets;
}

/// The 42 day numbers of the grid, first row first.
List<int> _grid(WidgetTester tester) {
  final texts = tester
      .widgetList<Text>(
        find.descendant(of: find.byType(Calendar), matching: find.byType(Text)),
      )
      .map((t) => t.data!)
      .toList();
  return [for (final t in texts.sublist(texts.length - 42)) int.parse(t)];
}

/// The seven weekday initials, first column first.
List<String> _weekdays(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(of: find.byType(Calendar), matching: find.byType(Text)),
    )
    .skip(1)
    .take(7)
    .map((t) => t.data!)
    .toList();

/// The day whose spoken date is [label].
Finder _day(String label) =>
    find.byWidgetPredicate((w) => w is Tappable && w.semanticLabel == label);

/// The day holding keyboard focus, by its spoken date.
String? _focusedDay(WidgetTester tester) => tester
    .widgetList<Tappable>(
      find.descendant(
        of: find.byType(Calendar),
        matching: find.byType(Tappable),
      ),
    )
    .where((t) => t.focusNode?.hasPrimaryFocus ?? false)
    .firstOrNull
    ?.semanticLabel;

Future<void> _key(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initializeDateFormatting);

  group('calendar arithmetic', () {
    for (var month = 1; month <= 12; month++) {
      testWidgets('2026-$month: 42 consecutive days, each once', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            Calendar(
              today: _today,
              value: DateTime(2026, month, 15),
              onChanged: (_) {},
            ),
          ),
        );
        final days = _grid(tester);
        final first = days.indexOf(1);
        final last = DateUtils.getDaysInMonth(2026, month);
        expect(days.sublist(first, first + last), [
          for (var d = 1; d <= last; d++) d,
        ], reason: 'the month in order, no day twice');
        // The trailing days run on into the next month.
        expect(days.sublist(first + last), [
          for (var d = 1; d <= 42 - first - last; d++) d,
        ]);
        // The leading ones end on the previous month's last day.
        final previous = DateUtils.getDaysInMonth(
          2026,
          month - 1 < 1 ? 12 : month - 1,
        );
        expect(days.sublist(0, first), [
          for (var d = previous - first + 1; d <= previous; d++) d,
        ]);
      });
    }

    testWidgets('picks after a 25-hour day are midnight of the day tapped', (
      tester,
    ) async {
      final picks = <DateTime>[];
      await tester.pumpWidget(
        _host(
          Calendar(
            today: _today,
            value: DateTime(2026, 10, 15),
            onChanged: picks.add,
          ),
        ),
      );
      for (final day in [
        'Saturday, October 24, 2026',
        'Sunday, October 25, 2026',
        'Monday, October 26, 2026',
        'Tuesday, October 27, 2026',
      ]) {
        await tester.tap(_day(day));
      }
      expect(picks, [
        DateTime(2026, 10, 24),
        DateTime(2026, 10, 25),
        DateTime(2026, 10, 26),
        DateTime(2026, 10, 27),
      ]);
    });

    testWidgets('a range picked across the change is two midnights', (
      tester,
    ) async {
      DateTimeRange? range;
      await tester.pumpWidget(
        _host(
          Calendar(
            mode: CalendarMode.range,
            today: _today,
            range: DateTimeRange(
              start: DateTime(2026, 10, 20),
              end: DateTime(2026, 10, 21),
            ),
            onRangeChanged: (r) => range = r,
          ),
        ),
      );
      await tester.tap(_day('Friday, October 23, 2026'));
      await tester.pump();
      await tester.tap(_day('Wednesday, October 28, 2026'));
      await tester.pump();
      expect(range!.start, DateTime(2026, 10, 23));
      expect(range!.end, DateTime(2026, 10, 28));
    });

    testWidgets('presets are calendar spans of dates across a clock change', (
      tester,
    ) async {
      final presets = await _defaultPresets(tester);
      DateTimeRange build(String label, DateTime today) =>
          presets.firstWhere((p) => p.label == label).build(today);

      final afterFallBack = DateTime(2026, 11, 2);
      expect(
        build('Last 7 days', afterFallBack),
        DateTimeRange(start: DateTime(2026, 10, 27), end: afterFallBack),
      );
      expect(
        build('Last 30 days', afterFallBack),
        DateTimeRange(start: DateTime(2026, 10, 4), end: afterFallBack),
      );
      final afterSpringForward = DateTime(2026, 4, 2);
      expect(
        build('Last 7 days', afterSpringForward),
        DateTimeRange(start: DateTime(2026, 3, 27), end: afterSpringForward),
      );
      expect(
        build('Last month', afterFallBack),
        DateTimeRange(
          start: DateTime(2026, 10, 1),
          end: DateTime(2026, 10, 31),
        ),
      );
    });

    testWidgets('the default presets cannot be changed in place', (
      tester,
    ) async {
      final presets = await _defaultPresets(tester);
      expect(
        () => presets.add(
          DateRangePreset('x', (t) => DateTimeRange(start: t, end: t)),
        ),
        throwsUnsupportedError,
      );
    });
  });

  group('today', () {
    testWidgets('defaults to the current date', (tester) async {
      final semantics = tester.ensureSemantics();
      final now = DateTime.now();
      await tester.pumpWidget(_host(Calendar(onChanged: (_) {})));
      final strings = MaterialLocalizations.of(
        tester.element(find.byType(Calendar)),
      );
      expect(find.text(strings.formatMonthYear(now)), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          '${strings.formatFullDate(now)}, ${strings.currentDateLabel}',
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('the range picker anchors its presets on it, as dates', (
      tester,
    ) async {
      DateTimeRange? picked;
      await tester.pumpWidget(
        _host(DateRangePicker(onChanged: (r) => picked = r)),
      );
      await tester.tap(find.byType(DateRangePicker));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 7 days'));
      await tester.pumpAndSettle();
      final today = DateUtils.dateOnly(DateTime.now());
      expect(picked!.end, today);
      expect(picked!.start, DateTime(today.year, today.month, today.day - 6));
    });
  });

  group('locale', () {
    testWidgets('the ambient localizations: Sunday first, narrow names', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(Calendar(today: _today, value: _today, onChanged: (_) {})),
      );
      expect(_weekdays(tester), ['S', 'M', 'T', 'W', 'T', 'F', 'S']);
      expect(_grid(tester).first, 31, reason: 'Sunday May 31');
    });

    for (final (locale, first, weekdays) in [
      ('en_US', 31, ['S', 'M', 'T', 'W', 'T', 'F', 'S']),
      ('fr', 1, ['L', 'M', 'M', 'J', 'V', 'S', 'D']),
      ('ar', 30, ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج']),
      ('he', 31, ['א׳', 'ב׳', 'ג׳', 'ד׳', 'ה׳', 'ו׳', 'ש׳']),
    ]) {
      testWidgets('$locale: its week start and narrow weekday names', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            Calendar(
              locale: locale,
              today: _today,
              value: _today,
              onChanged: (_) {},
            ),
          ),
        );
        expect(_weekdays(tester), weekdays);
        expect(_grid(tester).first, first);
      });
    }

    testWidgets('ar and he headers are seven distinct names', (tester) async {
      for (final locale in ['ar', 'he']) {
        await tester.pumpWidget(
          _host(Calendar(locale: locale, today: _today, onChanged: (_) {})),
        );
        expect(_weekdays(tester).toSet(), hasLength(7), reason: locale);
      }
    });

    testWidgets('firstDayOfWeek overrides the locale', (tester) async {
      await tester.pumpWidget(
        _host(
          Calendar(
            locale: 'en_US',
            firstDayOfWeek: 1,
            today: _today,
            onChanged: (_) {},
          ),
        ),
      );
      expect(_weekdays(tester), ['M', 'T', 'W', 'T', 'F', 'S', 'S']);
      expect(_grid(tester).first, 1, reason: 'Monday June 1');
    });

    testWidgets('an explicit locale names the month and the days', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Calendar(
            locale: 'fr',
            today: _today,
            value: _today,
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('juin 2026'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('^jeudi 18 juin 2026')),
        findsOneWidget,
      );
      semantics.dispose();
    });
  });

  group('keyboard', () {
    Widget host(
      ValueChanged<DateTime> onPick, {
      DateTime? value,
      DateTime? min,
      DateTime? max,
      TextDirection direction = TextDirection.ltr,
    }) => MaterialApp(
      home: Scaffold(
        body: Directionality(
          textDirection: direction,
          child: Column(
            children: [
              TextButton(onPressed: () {}, child: const Text('Before')),
              SizedBox(
                width: 300,
                child: Calendar(
                  today: _today,
                  value: value,
                  min: min,
                  max: max,
                  onChanged: onPick,
                ),
              ),
              TextButton(onPressed: () {}, child: const Text('After')),
            ],
          ),
        ),
      ),
    );

    bool focusedText(WidgetTester tester, String text) =>
        Focus.of(tester.element(find.text(text))).hasPrimaryFocus;

    testWidgets('the grid is one Tab stop, on the selected day', (
      tester,
    ) async {
      await tester.pumpWidget(host((_) {}, value: DateTime(2026, 6, 18)));
      await _key(tester, LogicalKeyboardKey.tab); // Before
      await _key(tester, LogicalKeyboardKey.tab); // previous month
      await _key(tester, LogicalKeyboardKey.tab); // next month
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focusedDay(tester), 'Thursday, June 18, 2026');
      await _key(tester, LogicalKeyboardKey.tab);
      expect(focusedText(tester, 'After'), isTrue);
      await _key(tester, LogicalKeyboardKey.tab, shift: true);
      expect(_focusedDay(tester), 'Thursday, June 18, 2026');
    });

    testWidgets('with no selection the stop is today, else the first '
        'selectable day', (tester) async {
      await tester.pumpWidget(host((_) {}));
      for (var i = 0; i < 4; i++) {
        await _key(tester, LogicalKeyboardKey.tab);
      }
      expect(_focusedDay(tester), 'Friday, June 12, 2026, Today');

      await tester.pumpWidget(
        host((_) {}, min: DateTime(2026, 6, 15), max: DateTime(2026, 6, 20)),
      );
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        // Both month buttons are disabled: June is the only month.
        await _key(tester, LogicalKeyboardKey.tab);
      }
      expect(_focusedDay(tester), 'Monday, June 15, 2026');
    });

    testWidgets('arrows, Home, End and Page keys move the focus; the month '
        'follows; Enter picks', (tester) async {
      final picks = <DateTime>[];
      await tester.pumpWidget(host(picks.add, value: DateTime(2026, 6, 18)));
      for (var i = 0; i < 4; i++) {
        await _key(tester, LogicalKeyboardKey.tab);
      }
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_focusedDay(tester), 'Friday, June 19, 2026');
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(_focusedDay(tester), 'Friday, June 26, 2026');
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(_focusedDay(tester), 'Thursday, June 25, 2026');
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_focusedDay(tester), 'Thursday, June 18, 2026');
      await _key(tester, LogicalKeyboardKey.home);
      expect(_focusedDay(tester), 'Sunday, June 14, 2026');
      await _key(tester, LogicalKeyboardKey.end);
      expect(_focusedDay(tester), 'Saturday, June 20, 2026');

      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.arrowDown);
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_focusedDay(tester), 'Sunday, July 5, 2026');
      expect(find.text('July 2026'), findsOneWidget);

      await _key(tester, LogicalKeyboardKey.pageUp);
      expect(_focusedDay(tester), 'Friday, June 5, 2026');
      expect(find.text('June 2026'), findsOneWidget);
      await _key(tester, LogicalKeyboardKey.pageDown, shift: true);
      expect(_focusedDay(tester), 'Saturday, June 5, 2027');
      expect(find.text('June 2027'), findsOneWidget);

      await _key(tester, LogicalKeyboardKey.enter);
      expect(picks, [DateTime(2027, 6, 5)]);
      await _key(tester, LogicalKeyboardKey.space);
      expect(picks, [DateTime(2027, 6, 5), DateTime(2027, 6, 5)]);
    });

    testWidgets('Page Down keeps the day where the month has it', (
      tester,
    ) async {
      await tester.pumpWidget(host((_) {}, value: DateTime(2026, 1, 31)));
      for (var i = 0; i < 4; i++) {
        await _key(tester, LogicalKeyboardKey.tab);
      }
      await _key(tester, LogicalKeyboardKey.pageDown);
      expect(_focusedDay(tester), 'Saturday, February 28, 2026');
    });

    testWidgets('the focus stays within min and max', (tester) async {
      await tester.pumpWidget(
        host(
          (_) {},
          value: DateTime(2026, 6, 16),
          min: DateTime(2026, 6, 10),
          max: DateTime(2026, 6, 24),
        ),
      );
      for (var i = 0; i < 2; i++) {
        await _key(tester, LogicalKeyboardKey.tab);
      }
      expect(_focusedDay(tester), 'Tuesday, June 16, 2026');
      await _key(tester, LogicalKeyboardKey.arrowUp);
      expect(_focusedDay(tester), 'Wednesday, June 10, 2026');
      await _key(tester, LogicalKeyboardKey.pageDown);
      expect(_focusedDay(tester), 'Wednesday, June 24, 2026');
    });

    testWidgets('right to left, ← moves to the next day', (tester) async {
      await tester.pumpWidget(
        host(
          (_) {},
          value: DateTime(2026, 6, 18),
          direction: TextDirection.rtl,
        ),
      );
      for (var i = 0; i < 4; i++) {
        await _key(tester, LogicalKeyboardKey.tab);
      }
      expect(_focusedDay(tester), 'Thursday, June 18, 2026');
      await _key(tester, LogicalKeyboardKey.arrowLeft);
      expect(_focusedDay(tester), 'Friday, June 19, 2026');
    });

    testWidgets(
      'keyboard focus draws the focus ring around the day',
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
      (tester) async {
        await tester.pumpWidget(host((_) {}, value: DateTime(2026, 6, 18)));
        for (var i = 0; i < 4; i++) {
          await _key(tester, LogicalKeyboardKey.tab);
        }
        final ring = tester.widget<FocusRing>(
          find.ancestor(of: find.text('18'), matching: find.byType(FocusRing)),
        );
        expect(ring.focused, isTrue);
        expect(tester.getSize(find.byWidget(ring.child)), const Size(32, 32));
      },
    );

    testWidgets('autofocus puts focus on the stop', (tester) async {
      await tester.pumpWidget(
        _host(
          Calendar(
            today: _today,
            value: DateTime(2026, 6, 18),
            autofocus: true,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_focusedDay(tester), 'Thursday, June 18, 2026');
    });
  });

  group('semantics', () {
    testWidgets('each day is a button with its full date and state', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Calendar(
            today: _today,
            value: DateTime(2026, 6, 18),
            max: DateTime(2026, 6, 25),
            onChanged: (_) {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Thursday, June 18, 2026')),
        isSemantics(
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(
          find.bySemanticsLabel('Friday, June 12, 2026, Today'),
        ),
        isSemantics(
          isButton: true,
          hasSelectedState: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Monday, June 29, 2026')),
        isSemantics(
          isButton: true,
          hasSelectedState: true,
          isEnabled: false,
          hasEnabledState: true,
        ),
        reason: 'past max: disabled',
      );
      expect(find.bySemanticsLabel('Next month'), findsOneWidget);
      expect(find.bySemanticsLabel('Previous month'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a range names its start and end, and selects its days', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Calendar(
            mode: CalendarMode.range,
            today: _today,
            range: DateTimeRange(
              start: DateTime(2026, 6, 10),
              end: DateTime(2026, 6, 21),
            ),
            onRangeChanged: (_) {},
          ),
        ),
      );
      expect(
        tester.getSemantics(
          find.bySemanticsLabel('Start date Wednesday, June 10, 2026'),
        ),
        isSemantics(isButton: true, isSelected: true, hasSelectedState: true),
      );
      expect(
        tester.getSemantics(
          find.bySemanticsLabel('End date Sunday, June 21, 2026'),
        ),
        isSemantics(isButton: true, isSelected: true, hasSelectedState: true),
      );
      expect(
        tester.getSemantics(
          find.bySemanticsLabel('Friday, June 12, 2026, Today'),
        ),
        isSemantics(isButton: true, isSelected: true, hasSelectedState: true),
      );
      semantics.dispose();
    });
  });

  group('external range', () {
    Widget calendar(DateTimeRange range) => _host(
      Calendar(
        mode: CalendarMode.range,
        today: _today,
        range: range,
        onRangeChanged: (_) {},
      ),
    );

    testWidgets('moves to the month of its end when neither end is shown', (
      tester,
    ) async {
      await tester.pumpWidget(
        calendar(
          DateTimeRange(
            start: DateTime(2026, 6, 6),
            end: DateTime(2026, 6, 12),
          ),
        ),
      );
      expect(find.text('June 2026'), findsOneWidget);
      await tester.pumpWidget(
        calendar(
          DateTimeRange(
            start: DateTime(2026, 3, 1),
            end: DateTime(2026, 3, 31),
          ),
        ),
      );
      expect(find.text('March 2026'), findsOneWidget);
    });

    testWidgets('stays put while one end is shown', (tester) async {
      await tester.pumpWidget(
        calendar(
          DateTimeRange(
            start: DateTime(2026, 6, 6),
            end: DateTime(2026, 6, 12),
          ),
        ),
      );
      await tester.pumpWidget(
        calendar(
          DateTimeRange(
            start: DateTime(2026, 6, 20),
            end: DateTime(2026, 7, 4),
          ),
        ),
      );
      expect(find.text('June 2026'), findsOneWidget);
    });
  });

  group('theme shape', () {
    // The theme's palette and radii, without its font.
    AdminTokens tokensOf(AdminTheme theme) {
      final tokens = theme.tokens;
      return AdminTokens.from(palette: tokens.palette, radii: tokens.radii);
    }

    Widget themed(AdminTheme theme, Widget child) => MaterialApp(
      theme: buildAppTheme(tokensOf(theme)),
      home: Scaffold(
        body: Center(child: SizedBox(width: 300, child: child)),
      ),
    );

    BoxDecoration fill(WidgetTester tester, String day) =>
        tester
                .widget<Container>(
                  find
                      .ancestor(
                        of: find.text(day),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration!
            as BoxDecoration;

    for (final theme in adminThemes) {
      testWidgets('${theme.name}: the day fill follows radiusSmall', (
        tester,
      ) async {
        await tester.pumpWidget(
          themed(
            theme,
            Calendar(
              today: _today,
              value: DateTime(2026, 6, 18),
              onChanged: (_) {},
            ),
          ),
        );
        final tokens = tokensOf(theme);
        final small = tokens.radii.radiusSmall;
        final radius = small >= 16 ? 16.0 : small;
        expect(fill(tester, '18').borderRadius, BorderRadius.circular(radius));
        expect(fill(tester, '18').color, tokens.palette.controlAccent);
      });
    }

    testWidgets('Carbon days are square', (tester) async {
      final carbon = adminThemes.firstWhere((t) => t.name == 'Carbon');
      await tester.pumpWidget(
        themed(
          carbon,
          Calendar(
            today: _today,
            value: DateTime(2026, 6, 18),
            onChanged: (_) {},
          ),
        ),
      );
      expect(fill(tester, '18').borderRadius, BorderRadius.zero);
    });

    testWidgets(
      'the hover fill is the day shape, not a larger splash',
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
      (tester) async {
        await tester.pumpWidget(
          _host(Calendar(today: _today, value: _today, onChanged: (_) {})),
        );
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: tester.getCenter(find.text('16')));
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(Calendar));
        final box = tester.widget<Container>(
          find
              .ancestor(of: find.text('16'), matching: find.byType(Container))
              .first,
        );
        expect(
          (box.decoration! as BoxDecoration).color,
          context.colors.listHighlight,
        );
        expect(tester.getSize(find.byWidget(box)), const Size(32, 32));
        expect(find.byType(InkResponse), findsNothing);
        await gesture.removePointer();
      },
    );

    testWidgets('the weekday strip is micro type in foregroundMuted', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(Calendar(today: _today, onChanged: (_) {})),
      );
      final context = tester.element(find.byType(Calendar));
      final style = tester.widget<Text>(find.text('W')).style!;
      expect(style.fontSize, context.type.micro.fontSize);
      expect(style.fontWeight, context.type.micro.fontWeight);
      expect(style.color, context.colors.foregroundMuted);
    });
  });

  group('range picker presets', () {
    Widget picker(ValueChanged<DateTimeRange?> onChanged) => _host(
      DateRangePicker(
        today: _today,
        min: DateTime(2026, 6, 5),
        max: DateTime(2026, 6, 30),
        onChanged: onChanged,
      ),
    );

    testWidgets('clamp to min and max', (tester) async {
      DateTimeRange? picked;
      await tester.pumpWidget(picker((r) => picked = r));
      await tester.tap(find.byType(DateRangePicker));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 30 days'));
      await tester.pumpAndSettle();
      expect(
        picked,
        DateTimeRange(start: DateTime(2026, 6, 5), end: DateTime(2026, 6, 12)),
      );
    });

    testWidgets('one with no day left is disabled and skipped by the '
        'arrows', (tester) async {
      final semantics = tester.ensureSemantics();
      DateTimeRange? picked;
      await tester.pumpWidget(picker((r) => picked = r));
      await tester.tap(find.byType(DateRangePicker));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.text('Last month')),
        isSemantics(
          isButton: true,
          isEnabled: false,
          hasEnabledState: true,
          hasSelectedState: true,
        ),
      );
      final context = tester.element(find.text('Last month'));
      expect(
        tester.widget<Text>(find.text('Last month')).style!.color,
        context.colors.foregroundSubtle,
      );
      await tester.tap(find.text('Last month'));
      await tester.pumpAndSettle();
      expect(picked, isNull);

      Focus.of(tester.element(find.text('This month'))).requestFocus();
      await tester.pumpAndSettle();
      await _key(tester, LogicalKeyboardKey.arrowDown);
      expect(
        Focus.of(tester.element(find.text('Year to date'))).hasPrimaryFocus,
        isTrue,
      );
      semantics.dispose();
    });
  });
}
