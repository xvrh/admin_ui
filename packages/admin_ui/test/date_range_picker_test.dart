import 'package:admin_ui/src/common/ui/calendar.dart';
import 'package:admin_ui/src/common/ui/clear_button.dart';
import 'package:admin_ui/src/common/ui/date_range_picker.dart';
import 'package:admin_ui/src/common/ui/field_chrome.dart';
import 'package:admin_ui/src/common/ui/tappable.dart';
import 'package:admin_ui/src/theme/theme.dart';
import 'package:admin_ui/src/theme/themes/ant.dart';
import 'package:admin_ui/src/theme/tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 320, child: child)),
  ),
);

void main() {
  testWidgets('trigger shows the formatted span', (tester) async {
    await tester.pumpWidget(
      _host(
        DateRangePicker(
          value: DateTimeRange(
            start: DateTime(2026, 6, 8),
            end: DateTime(2026, 6, 14),
          ),
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('Jun 8 – Jun 14'), findsOneWidget);
  });

  testWidgets('placeholder when empty', (tester) async {
    await tester.pumpWidget(
      _host(DateRangePicker(onChanged: (_) {}, hint: 'Pick…')),
    );
    expect(find.text('Pick…'), findsOneWidget);
  });

  testWidgets('a preset selects a relative span and closes', (tester) async {
    DateTimeRange? picked;
    await tester.pumpWidget(
      _host(
        DateRangePicker(
          today: DateTime(2026, 6, 12),
          onChanged: (r) => picked = r,
        ),
      ),
    );

    await tester.tap(find.byType(DateRangePicker));
    await tester.pumpAndSettle();
    expect(find.text('Last 7 days'), findsOneWidget);

    await tester.tap(find.text('Last 7 days'));
    await tester.pumpAndSettle();

    expect(picked, isNotNull);
    expect(picked!.start, DateTime(2026, 6, 6));
    expect(picked!.end, DateTime(2026, 6, 12));
    // Popover dismissed.
    expect(find.text('Last 7 days'), findsNothing);
  });

  testWidgets('clear affordance resets to null', (tester) async {
    DateTimeRange? value = DateTimeRange(
      start: DateTime(2026, 6, 8),
      end: DateTime(2026, 6, 14),
    );
    bool? clearedToNull;
    await tester.pumpWidget(
      _host(
        DateRangePicker(
          value: value,
          onChanged: (r) => clearedToNull = r == null,
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.close_rounded));
    expect(clearedToNull, isTrue);
  });

  testWidgets('read-only (null onChanged) does not open', (tester) async {
    await tester.pumpWidget(
      _host(
        DateRangePicker(
          value: DateTimeRange(
            start: DateTime(2026, 6, 8),
            end: DateTime(2026, 6, 14),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(DateRangePicker));
    await tester.pumpAndSettle();
    expect(find.text('Last 7 days'), findsNothing);
  });

  testWidgets('selected preset and empty label use the text-safe roles', (
    tester,
  ) async {
    const palette = antPalette;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(AdminTokens.from(palette: palette)),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DateRangePicker(onChanged: (_) {}, hint: 'Pick…'),
                  DateRangePicker(
                    today: DateTime(2026, 6, 12),
                    value: DateTimeRange(
                      start: DateTime(2026, 6, 6),
                      end: DateTime(2026, 6, 12),
                    ),
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    Color color(String text) =>
        tester.widget<Text>(find.text(text)).style!.color!;
    expect(color('Pick…'), palette.placeholder);

    await tester.tap(find.text('Jun 6 – Jun 12'));
    await tester.pumpAndSettle();
    expect(color('Last 7 days'), palette.primaryText);
    final tile = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Last 7 days'),
            matching: find.byType(Container),
          )
          .first,
    );
    expect((tile.decoration! as BoxDecoration).color, palette.primarySubtle);
  });

  group('keyboard', () {
    final week = DateTimeRange(
      start: DateTime(2026, 6, 6),
      end: DateTime(2026, 6, 12),
    );

    Widget host(
      ValueChanged<DateTimeRange?> onChanged, {
      DateTimeRange? value,
    }) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(onPressed: () {}, child: const Text('Before')),
                DateRangePicker(
                  today: DateTime(2026, 6, 12),
                  value: value,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    bool focused(WidgetTester tester, String text) =>
        Focus.of(tester.element(find.text(text))).hasPrimaryFocus;

    Future<void> key(WidgetTester tester, LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }

    /// The calendar day holding keyboard focus, by its spoken date.
    String? focusedDay(WidgetTester tester) => tester
        .widgetList<Tappable>(
          find.descendant(
            of: find.byType(Calendar),
            matching: find.byType(Tappable),
          ),
        )
        .where((t) => t.focusNode?.hasPrimaryFocus ?? false)
        .firstOrNull
        ?.semanticLabel;

    testWidgets('Tab reaches the trigger; Enter opens it on the calendar, '
        'the preset still marked', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(host((_) {}, value: week));
      await key(tester, LogicalKeyboardKey.tab); // Before
      await key(tester, LogicalKeyboardKey.tab);
      final trigger = find
          .descendant(
            of: find.byType(DateRangePicker),
            matching: find.byType(GestureDetector),
          )
          .first;
      expect(
        tester.getSemantics(trigger),
        isSemantics(
          label: 'Date range\nJun 6 – Jun 12',
          isButton: true,
          isFocused: true,
          hasExpandedState: true,
          isExpanded: false,
        ),
      );

      await key(tester, LogicalKeyboardKey.enter);
      expect(find.text('Today'), findsOneWidget);
      expect(focusedDay(tester), 'Start date Saturday, June 6, 2026');
      expect(
        tester.getSemantics(find.text('Last 7 days')),
        isSemantics(isSelected: true, isButton: true),
      );
      semantics.dispose();
    });

    testWidgets('↓ opens it; Shift+Tab reaches the presets, where the '
        'arrows, Home and End walk them and Enter picks one', (tester) async {
      DateTimeRange? picked;
      await tester.pumpWidget(host((r) => picked = r));
      await key(tester, LogicalKeyboardKey.tab);
      await key(tester, LogicalKeyboardKey.tab);
      await key(tester, LogicalKeyboardKey.arrowDown);
      expect(focusedDay(tester), 'Friday, June 12, 2026, Today');

      // Back past the next- and previous-month buttons.
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await key(tester, LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      }
      expect(focused(tester, 'Today'), isTrue, reason: 'none selected');

      await key(tester, LogicalKeyboardKey.arrowDown);
      expect(focused(tester, 'Last 7 days'), isTrue);
      await key(tester, LogicalKeyboardKey.end);
      expect(focused(tester, 'Year to date'), isTrue);
      await key(tester, LogicalKeyboardKey.home);
      expect(focused(tester, 'Today'), isTrue);
      await key(tester, LogicalKeyboardKey.arrowDown);
      await key(tester, LogicalKeyboardKey.enter);

      expect(picked, week);
      expect(find.text('Today'), findsNothing);
      expect(
        focused(tester, 'Select range'),
        isTrue,
        reason: 'focus back on the trigger',
      );
    });

    testWidgets('a day picked from the keyboard closes it and returns focus', (
      tester,
    ) async {
      DateTimeRange? picked;
      await tester.pumpWidget(host((r) => picked = r));
      await key(tester, LogicalKeyboardKey.tab);
      await key(tester, LogicalKeyboardKey.tab);
      await key(tester, LogicalKeyboardKey.enter); // opens on today, the 12th
      await key(tester, LogicalKeyboardKey.enter); // start
      await key(tester, LogicalKeyboardKey.arrowRight);
      await key(tester, LogicalKeyboardKey.arrowRight);
      await key(tester, LogicalKeyboardKey.enter); // end

      expect(
        picked,
        DateTimeRange(start: DateTime(2026, 6, 12), end: DateTime(2026, 6, 14)),
      );
      expect(find.byType(Calendar), findsNothing);
      expect(focused(tester, 'Select range'), isTrue);
    });

    testWidgets('Tab past the calendar closes it', (tester) async {
      await tester.pumpWidget(host((_) {}, value: week));
      await key(tester, LogicalKeyboardKey.tab);
      await key(tester, LogicalKeyboardKey.tab);
      await key(tester, LogicalKeyboardKey.enter);
      expect(find.byType(Calendar), findsOneWidget);
      await key(tester, LogicalKeyboardKey.tab);
      expect(find.byType(Calendar), findsNothing);
    });

    testWidgets('Escape closes it after a tap and returns focus', (
      tester,
    ) async {
      await tester.pumpWidget(host((_) {}, value: week));
      await tester.tap(find.text('Jun 6 – Jun 12'));
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsOneWidget);

      await key(tester, LogicalKeyboardKey.escape);
      expect(find.text('Today'), findsNothing);
      expect(focused(tester, 'Jun 6 – Jun 12'), isTrue);
    });

    testWidgets('the clear is its own Tab stop and keeps the trigger height', (
      tester,
    ) async {
      await tester.pumpWidget(host((_) {}));
      final empty = tester.getSize(find.byType(FieldChrome)).height;

      DateTimeRange? cleared = week;
      await tester.pumpWidget(host((r) => cleared = r, value: week));
      expect(tester.getSize(find.byType(FieldChrome)).height, empty);

      await key(tester, LogicalKeyboardKey.tab); // Before
      await key(tester, LogicalKeyboardKey.tab); // the trigger
      await key(tester, LogicalKeyboardKey.tab); // the clear
      await key(tester, LogicalKeyboardKey.enter);
      expect(cleared, isNull);
      expect(
        find.text('Today'),
        findsNothing,
        reason: 'the popover stays shut',
      );
    });

    testWidgets('the clear control is a labelled 24px target', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(host((_) {}, value: week));
      final clear = find.descendant(
        of: find.byType(ClearButton),
        matching: find.byType(GestureDetector),
      );
      expect(tester.getSize(clear), const Size(24, 24));
      expect(
        tester.getSemantics(clear),
        isSemantics(label: 'Clear dates', isButton: true),
      );
      semantics.dispose();
    });
  });
}
