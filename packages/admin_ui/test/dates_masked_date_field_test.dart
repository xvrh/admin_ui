import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

Object? _captured = #unset;

Widget _host({
  String locale = 'en_US',
  DateGranularity granularity = DateGranularity.date,
  DateTime? initial,
}) {
  _captured = #unset;
  return MaterialApp(
    locale: Locale(locale.split('_').first),
    supportedLocales: [Locale(locale.split('_').first)],
    home: Scaffold(
      body: MaskedDateField(
        value: initial,
        granularity: granularity,
        locale: locale,
        onChanged: (v) => _captured = v,
      ),
    ),
  );
}

// A single enterText replaces the whole value — i.e. behaves like a paste.
Future<void> _type(WidgetTester tester, String s) async {
  await tester.enterText(find.byType(TextField), s);
  await tester.pump();
}

// Append one character at a time onto the current text, so the formatter sees
// each keystroke as a +1 edit (real typing, which triggers per-segment clamp).
Future<void> _typeEach(WidgetTester tester, String chars) async {
  for (final ch in chars.split('')) {
    final cur = tester
        .widget<TextField>(find.byType(TextField))
        .controller!
        .text;
    await tester.enterText(find.byType(TextField), cur + ch);
    await tester.pump();
  }
}

void main() {
  setUpAll(initializeDateFormatting);

  testWidgets('US order parses typed digits as M/D/Y', (tester) async {
    await tester.pumpWidget(_host(locale: 'en_US'));
    await _type(tester, '06182026');
    expect(_captured, DateTime(2026, 6, 18));
  });

  testWidgets('UK order: an unambiguous date stays D/M/Y', (tester) async {
    await tester.pumpWidget(_host(locale: 'en_GB'));
    await _type(tester, '01022026'); // 01 Feb 2026
    expect(_captured, DateTime(2026, 2, 1));
  });

  testWidgets('US order: the same digits read as M/D/Y', (tester) async {
    await tester.pumpWidget(_host(locale: 'en_US'));
    await _type(tester, '01022026'); // Jan 2 2026
    expect(_captured, DateTime(2026, 1, 2));
  });

  testWidgets('an ISO paste into a US field still lands correctly', (
    tester,
  ) async {
    await tester.pumpWidget(_host(locale: 'en_US'));
    await _type(tester, '2026-06-18'); // separators stripped → 20260618
    expect(_captured, DateTime(2026, 6, 18));
  });

  testWidgets('a partial value never emits a date', (tester) async {
    await tester.pumpWidget(_host(locale: 'en_US'));
    await _type(tester, '0618'); // incomplete
    expect(_captured, anyOf(equals(#unset), isNull)); // never a half-baked date
  });

  testWidgets('emptying the field emits null', (tester) async {
    await tester.pumpWidget(
      _host(locale: 'en_US', initial: DateTime(2026, 1, 1)),
    );
    await _type(tester, '');
    expect(_captured, isNull);
  });

  testWidgets('Feb 30 clamps to a real date', (tester) async {
    await tester.pumpWidget(_host(locale: 'en_US'));
    await _type(tester, '02302026');
    expect(_captured, DateTime(2026, 2, 28));
  });

  testWidgets('date & time parses both halves', (tester) async {
    await tester.pumpWidget(
      _host(locale: 'en_US', granularity: DateGranularity.dateTime),
    );
    await _type(tester, '061820261430');
    expect(_captured, DateTime(2026, 6, 18, 14, 30));
  });

  testWidgets('typing an over-max month clamps live (99 → 12)', (tester) async {
    await tester.pumpWidget(_host(locale: 'en_US'));
    await _typeEach(tester, '99');
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, startsWith('12'));
  });

  testWidgets('typing an over-max day clamps live (US: 99 → 31)', (
    tester,
  ) async {
    await tester.pumpWidget(_host(locale: 'en_US'));
    await _typeEach(tester, '0699'); // month 06, day 99 → 31
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, startsWith('06/31'));
  });

  testWidgets('single-digit parts: "1/1/2000" enters Jan 1 (separator pads)', (
    tester,
  ) async {
    await tester.pumpWidget(_host(locale: 'en_US'));
    await _typeEach(tester, '1/1/2000');
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '01/01/2000');
    expect(_captured, DateTime(2000, 1, 1));
  });

  testWidgets('a paste is not clamped, so cross-format detection still works', (
    tester,
  ) async {
    await tester.pumpWidget(_host(locale: 'en_US'));
    // 20 as a first segment would clamp to 12 if treated as typing; as a paste
    // it must survive so ISO order is detected.
    await _type(tester, '20260618');
    expect(_captured, DateTime(2026, 6, 18));
  });

  testWidgets('the masked text reseeds from an external value', (tester) async {
    await tester.pumpWidget(
      _host(locale: 'en_US', initial: DateTime(2026, 6, 18)),
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '06/18/2026');
  });

  testWidgets('DateBody masked editor: the popover hosts a typeable field', (
    tester,
  ) async {
    DateTime? value = DateTime(2026, 6, 18);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: Center(
            child: DateBody(
              value: value,
              locale: 'en_US',
              editor: DateEditorStyle.masked,
              onChanged: (v) => value = v,
            ),
          ),
        ),
      ),
    );
    // No editor until the popover opens.
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byType(DateBody));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), '12252026');
    await tester.pump();
    expect(value, DateTime(2026, 12, 25));
  });

  testWidgets('DateBody inline editor: field is typeable without a popover', (
    tester,
  ) async {
    DateTime? value;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: Center(
            child: DateBody(
              value: value,
              locale: 'en_US',
              editor: DateEditorStyle.inline,
              onChanged: (v) => value = v,
            ),
          ),
        ),
      ),
    );
    // The field is present immediately — no trigger to tap.
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), '07042026');
    await tester.pump();
    expect(value, DateTime(2026, 7, 4));
  });
}
