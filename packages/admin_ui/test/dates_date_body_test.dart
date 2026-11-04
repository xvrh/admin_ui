import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 360, child: child),
    ),
  ),
);

/// The editor cell showing [token] (`DD`, `MM`, `YYYY`, `HH`) as its hint.
Finder _cell(String token) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == token,
);

String _text(WidgetTester tester, String token) =>
    tester.widget<TextField>(_cell(token)).controller!.text;

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.byType(DateBody));
  await tester.pumpAndSettle();
}

void main() {
  group('empty value', () {
    testWidgets('the editor shows placeholder cells, not a made-up date', (
      tester,
    ) async {
      await tester.pumpWidget(_host(DateBody(onChanged: (_) {})));
      expect(find.text('Select date…'), findsOneWidget);
      await _open(tester);
      for (final token in ['MM', 'DD', 'YYYY']) {
        expect(_cell(token), findsOneWidget, reason: token);
        expect(_text(tester, token), isEmpty, reason: token);
      }
    });

    testWidgets('a day alone takes the current month and year', (tester) async {
      DateTime? value;
      await tester.pumpWidget(_host(DateBody(onChanged: (v) => value = v)));
      await _open(tester);
      await tester.enterText(_cell('DD'), '7');
      await tester.pump();
      final now = DateTime.now();
      expect(value, DateTime(now.year, now.month, 7));
    });

    testWidgets('today, when given, is where the missing parts come from', (
      tester,
    ) async {
      DateTime? value;
      await tester.pumpWidget(
        _host(
          DateBody(
            today: DateTime(2026, 6, 12),
            granularity: DateGranularity.dateTime,
            defaultTime: const TimeOfDay(hour: 9, minute: 30),
            onChanged: (v) => value = v,
          ),
        ),
      );
      await _open(tester);
      await tester.enterText(_cell('DD'), '7');
      await tester.pump();
      expect(value, DateTime(2026, 6, 7, 9, 30));
    });

    testWidgets('a calendar pick on a date & time takes defaultTime', (
      tester,
    ) async {
      DateTime? value;
      await tester.pumpWidget(
        _host(
          DateBody(
            today: DateTime(2026, 6, 12),
            granularity: DateGranularity.dateTime,
            defaultTime: const TimeOfDay(hour: 9, minute: 30),
            onChanged: (v) => value = v,
          ),
        ),
      );
      await _open(tester);
      await tester.tap(find.text('18'));
      await tester.pump();
      expect(value, DateTime(2026, 6, 18, 9, 30));
    });

    testWidgets('without defaultTime a pick is midnight', (tester) async {
      DateTime? value;
      await tester.pumpWidget(
        _host(
          DateBody(
            today: DateTime(2026, 6, 12),
            granularity: DateGranularity.dateTime,
            onChanged: (v) => value = v,
          ),
        ),
      );
      await _open(tester);
      await tester.tap(find.text('18'));
      await tester.pump();
      expect(value, DateTime(2026, 6, 18));
    });
  });

  group('cells', () {
    testWidgets('are zero-padded to their width', (tester) async {
      await tester.pumpWidget(
        _host(
          DateBody(
            value: DateTime(2026, 6, 5, 9, 3),
            granularity: DateGranularity.dateTime,
            onChanged: (_) {},
          ),
        ),
      );
      await _open(tester);
      final month = tester
          .widgetList<TextField>(_cell('MM'))
          .first
          .controller!
          .text;
      expect(month, '06');
      expect(_text(tester, 'DD'), '05');
      expect(_text(tester, 'YYYY'), '2026');
      expect(_text(tester, 'HH'), '09');
      final minute = tester
          .widgetList<TextField>(_cell('MM'))
          .last
          .controller!
          .text;
      expect(minute, '03');
    });

    testWidgets('typing on past a full cell keeps the latest digits', (
      tester,
    ) async {
      DateTime? value = DateTime(2026, 6, 5);
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => DateBody(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await _open(tester);
      // "05" then 1: "51" is past the month, so the 1 starts over.
      await tester.enterText(_cell('DD'), '051');
      await tester.pump();
      expect(value, DateTime(2026, 6, 1));
      expect(_text(tester, 'DD'), '1');
      // Then 5: "15".
      await tester.enterText(_cell('DD'), '15');
      await tester.pump();
      expect(value, DateTime(2026, 6, 15));
    });
  });

  group('state', () {
    testWidgets('a null onChanged is read-only: full contrast, no chevron or '
        'clear, focusable, opens nothing', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(Column(children: [DateBody(value: DateTime(2026, 6, 18))])),
      );
      final context = tester.element(find.byType(DateBody));
      final text = tester.widget<Text>(find.text('Jun 18, 2026'));
      expect(text.style!.color, context.colors.foreground);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(
          find
              .ancestor(
                of: find.text('Jun 18, 2026'),
                matching: find.byType(Semantics),
              )
              .first,
        ),
        isSemantics(isReadOnly: true, isFocused: true, isFocusable: true),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(Calendar), findsNothing);
      await _open(tester);
      expect(find.byType(Calendar), findsNothing);
      semantics.dispose();
    });

    testWidgets('an empty read-only field shows a dash, not an instruction', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const DateBody()));
      expect(find.text('—'), findsOneWidget);
      expect(find.text('Select date…'), findsNothing);
    });

    testWidgets('a disabled scope dims the text and fills the box', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FieldStateScope(
            enabled: false,
            child: DateBody(value: DateTime(2026, 6, 18), onChanged: (_) {}),
          ),
        ),
      );
      final context = tester.element(find.byType(DateBody));
      expect(
        tester.widget<Text>(find.text('Jun 18, 2026')).style!.color,
        context.colors.foregroundSubtle,
      );
      final box =
          tester
                  .widget<Container>(
                    find
                        .descendant(
                          of: find.byType(FieldChrome),
                          matching: find.byType(Container),
                        )
                        .first,
                  )
                  .decoration!
              as BoxDecoration;
      expect(box.color, fieldFillColor(context.colors, {WidgetState.disabled}));
      await _open(tester);
      expect(find.byType(Calendar), findsNothing);
    });

    testWidgets('an invalid scope reddens the outline', (tester) async {
      await tester.pumpWidget(
        _host(
          FieldStateScope(
            invalid: true,
            child: DateBody(value: DateTime(2026, 6, 18), onChanged: (_) {}),
          ),
        ),
      );
      final context = tester.element(find.byType(DateBody));
      final box =
          tester
                  .widget<Container>(
                    find
                        .descendant(
                          of: find.byType(FieldChrome),
                          matching: find.byType(Container),
                        )
                        .first,
                  )
                  .decoration!
              as BoxDecoration;
      expect(
        (box.border! as Border).top,
        fieldBorderSide(context.colors, {
          WidgetState.error,
        }, stroke: const AdminStroke()),
      );
    });

    testWidgets('the trigger is the theme control height, the value at the '
        'leading-icon inset', (tester) async {
      await tester.pumpWidget(
        _host(DateBody(value: DateTime(2026, 6, 18), onChanged: (_) {})),
      );
      final context = tester.element(find.byType(DateBody));
      final chrome = tester.getRect(find.byType(FieldChrome));
      expect(chrome.height, context.sizes.medium);
      expect(
        tester.getTopLeft(find.text('Jun 18, 2026')).dx - chrome.left,
        context.sizes.fieldIconInset,
      );
      expect(find.byType(FieldChevron), findsOneWidget);
    });
  });

  group('keyboard', () {
    Widget host(Widget body) => _host(
      Column(
        children: [
          body,
          TextButton(onPressed: () {}, child: const Text('After')),
        ],
      ),
    );

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

    Future<void> key(WidgetTester tester, LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }

    testWidgets('a keyboard open lands on the calendar day', (tester) async {
      DateTime? value = DateTime(2026, 6, 18);
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => DateBody(
              value: value,
              today: DateTime(2026, 6, 12),
              clearable: false,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await key(tester, LogicalKeyboardKey.tab);
      await key(tester, LogicalKeyboardKey.enter);
      expect(focusedDay(tester), 'Thursday, June 18, 2026');
      await key(tester, LogicalKeyboardKey.arrowRight);
      await key(tester, LogicalKeyboardKey.enter);
      expect(value, DateTime(2026, 6, 19));
      expect(_text(tester, 'DD'), '19', reason: 'the cells follow the pick');
    });

    testWidgets('a time-only keyboard open lands on the first cell', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          DateBody(
            value: DateTime(2026, 6, 18, 7),
            granularity: DateGranularity.time,
            clearable: false,
            onChanged: (_) {},
          ),
        ),
      );
      await key(tester, LogicalKeyboardKey.tab);
      await key(tester, LogicalKeyboardKey.enter);
      final hour = tester.widget<TextField>(_cell('HH'));
      expect(hour.focusNode!.hasPrimaryFocus, isTrue);
    });

    testWidgets('focus leaving the popover closes it', (tester) async {
      await tester.pumpWidget(
        host(
          DateBody(
            value: DateTime(2026, 6, 18),
            clearable: false,
            onChanged: (_) {},
          ),
        ),
      );
      await key(tester, LogicalKeyboardKey.tab);
      await key(tester, LogicalKeyboardKey.enter);
      expect(find.byType(Calendar), findsOneWidget);
      await key(tester, LogicalKeyboardKey.tab);
      expect(find.byType(Calendar), findsNothing);
    });
  });

  group('masked, time only', () {
    testWidgets('a typed time keeps the value\'s date', (tester) async {
      DateTime? value;
      await tester.pumpWidget(
        _host(
          MaskedDateField(
            value: DateTime(2026, 3, 4, 7),
            granularity: DateGranularity.time,
            onChanged: (v) => value = v,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '1430');
      await tester.pump();
      expect(value, DateTime(2026, 3, 4, 14, 30));
    });

    testWidgets('an empty one puts the time on today', (tester) async {
      DateTime? value;
      await tester.pumpWidget(
        _host(
          MaskedDateField(
            granularity: DateGranularity.time,
            onChanged: (v) => value = v,
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '0915');
      await tester.pump();
      final now = DateTime.now();
      expect(value, DateTime(now.year, now.month, now.day, 9, 15));
    });
  });
}
