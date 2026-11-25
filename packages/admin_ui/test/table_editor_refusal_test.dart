import 'dart:ui' show SemanticsValidationResult;

import 'package:admin_ui/l10n.dart';
import 'package:admin_ui/src/collection/ui/collection_table.dart';
import 'package:admin_ui/src/collection/ui/table_edit_session.dart';
import 'package:admin_ui/src/common/ui/labeled_field.dart';
import 'package:admin_ui/src/common/ui/popover_menu.dart';
import 'package:admin_ui/src/theme/tokens.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _kitLanguages = AdminLanguages([adminEn, adminFr, adminAr]);

// A draft a cell's editor refuses: it stays open, marked invalid, and says
// why on a card beside the cell.

typedef _Editor = Widget Function(EditSession session);

/// A table whose "Value" column edits with [editor], and whose "Other" column
/// edits with [other] when given. [valueLast] puts "Value" after a wide
/// read-only column, by the window's far edge.
class _Sheet extends StatelessWidget {
  final _Editor editor;
  final _Editor? other;
  final bool numeric;
  final int rows;
  final bool valueLast;

  const _Sheet(
    this.editor, {
    this.other,
    this.numeric = true,
    this.rows = 4,
    this.valueLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final value = TableColumn<int>(
      id: 'value',
      label: 'Value',
      fixed: 160,
      numeric: numeric,
      cell: (r) => Text('cell $r'),
      editBuilder: (_, session) => editor(session),
    );
    final id = TableColumn<int>(
      id: 'id',
      label: 'ID',
      fixed: 240,
      cell: (r) => Text('#$r'),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(onPressed: () {}, child: const Text('Outside')),
        Expanded(
          child: CollectionTable<int>(
            rows: [for (var i = 0; i < rows; i++) i],
            rowKey: (r) => r,
            columns: [
              if (valueLast) id,
              value,
              if (other case final other?)
                TableColumn(
                  id: 'other',
                  label: 'Other',
                  fixed: 160,
                  cell: (r) => Text('other $r'),
                  editBuilder: (_, session) => other(session),
                ),
              if (!valueLast) id,
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(1000, 600),
  String locale = 'en',
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      supportedLocales: _kitLanguages.locales,
      localizationsDelegates: _kitLanguages.delegates,
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
  await tester.pump();
}

/// Opens the editor of the cell that reads [cell].
Future<void> _edit(WidgetTester tester, [String cell = 'cell 0']) async {
  await tester.tap(find.text(cell));
  // Past the double-tap window: this is one tap.
  await tester.pump(kDoubleTapTimeout);
  await _key(tester, LogicalKeyboardKey.f2);
}

/// Types [text] over the draft and commits it with Enter.
Future<void> _commit(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await _key(tester, LogicalKeyboardKey.enter);
}

final _field = find.byType(TextField);
final _card = find.byType(PopoverMenuSurface);

String get _said =>
    (find.byType(FieldMessage).evaluate().single.widget as FieldMessage).error!;

/// The colour of the editor's edge, as it is drawn at rest.
Color _edge(WidgetTester tester) => WidgetStateProperty.resolveAs<InputBorder>(
  tester.widget<TextField>(_field).decoration!.border!,
  const {},
).borderSide.color;

SemanticsValidationResult _validity(WidgetTester tester) =>
    tester.getSemantics(_field).getSemanticsData().validationResult;

void main() {
  group('a number', () {
    testWidgets('that is none is refused, and the cell says so', (
      tester,
    ) async {
      final saved = <num>[];
      await _pump(
        tester,
        _Sheet(
          (s) => TableTextEditor.number(
            session: s,
            value: 20,
            onCommit: saved.add,
          ),
        ),
      );
      await _edit(tester);
      expect(_card, findsNothing, reason: 'nothing is refused yet');

      await _commit(tester, 'twenty');
      expect(_field, findsOneWidget);
      expect(_said, 'Enter a number like 1,234.5');
      expect(saved, isEmpty);
    });

    testWidgets('that passes is saved, with no message', (tester) async {
      final saved = <num>[];
      await _pump(
        tester,
        _Sheet(
          (s) => TableTextEditor.number(
            session: s,
            value: 20,
            onCommit: saved.add,
          ),
        ),
      );
      await _edit(tester);
      await _commit(tester, '-25.5');
      expect(_field, findsNothing);
      expect(_card, findsNothing);
      expect(saved, [-25.5]);
    });

    testWidgets('told to be whole refuses a fraction', (tester) async {
      final saved = <num>[];
      await _pump(
        tester,
        _Sheet(
          (s) => TableTextEditor.number(
            session: s,
            value: 20,
            integer: true,
            onCommit: saved.add,
          ),
        ),
      );
      await _edit(tester);
      await _commit(tester, '2.5');
      expect(_field, findsOneWidget);
      expect(_said, 'Enter a number like 1,234');
      expect(saved, isEmpty);
    });

    testWidgets('told to be whole is handed over as an int', (tester) async {
      final saved = <num>[];
      final asked = <num>[];
      await _pump(
        tester,
        _Sheet(
          (s) => TableTextEditor.number(
            session: s,
            value: 20,
            integer: true,
            validate: (v) {
              asked.add(v);
              return null;
            },
            onCommit: saved.add,
          ),
        ),
      );
      await _edit(tester);
      await _commit(tester, '7.0');
      expect(_field, findsNothing);
      expect(saved.single, isA<int>());
      expect(saved.single, 7);
      expect(asked.single, isA<int>());
    });

    testWidgets('too long to be one is refused, not thrown on', (tester) async {
      final saved = <num>[];
      await _pump(
        tester,
        _Sheet(
          (s) => TableTextEditor.number(
            session: s,
            value: 20,
            integer: true,
            onCommit: saved.add,
          ),
        ),
      );
      await _edit(tester);
      await _commit(tester, '9' * 400);
      expect(tester.takeException(), isNull);
      expect(_field, findsOneWidget);
      expect(_said, 'Enter a number like 1,234');
      expect(saved, isEmpty);
    });

    testWidgets('below its minimum is refused, and the minimum is not', (
      tester,
    ) async {
      final saved = <num>[];
      await _pump(
        tester,
        _Sheet(
          (s) => TableTextEditor.number(
            session: s,
            value: 20,
            min: 0,
            onCommit: saved.add,
          ),
        ),
      );
      await _edit(tester);
      await _commit(tester, '-3');
      expect(_field, findsOneWidget);
      expect(_said, 'Enter 0 or more');
      expect(saved, isEmpty);

      await _commit(tester, '0');
      expect(_field, findsNothing);
      expect(saved, [0]);
    });

    testWidgets('above its maximum is refused, and the maximum is not', (
      tester,
    ) async {
      final saved = <num>[];
      await _pump(
        tester,
        _Sheet(
          (s) => TableTextEditor.number(
            session: s,
            value: 20,
            max: 100,
            onCommit: saved.add,
          ),
        ),
      );
      await _edit(tester);
      await _commit(tester, '100.5');
      expect(_said, 'Enter 100 or less');
      expect(saved, isEmpty);

      await _commit(tester, '100');
      expect(saved, [100]);
    });

    testWidgets('outside both bounds is told both, written as the cell '
        'writes a number', (tester) async {
      final saved = <num>[];
      await _pump(
        tester,
        _Sheet(
          (s) => TableTextEditor.number(
            session: s,
            value: 20,
            fractionDigits: 2,
            min: 0.5,
            max: 1500,
            onCommit: saved.add,
          ),
        ),
      );
      await _edit(tester);
      await _commit(tester, '0.25');
      expect(_said, 'Enter a number from 0.50 to 1,500.00');
      await _commit(tester, '1500.01');
      expect(_said, 'Enter a number from 0.50 to 1,500.00');
      expect(saved, isEmpty);

      await _commit(tester, '0.5');
      expect(saved, [0.5]);
    });

    testWidgets("is put to the app's own rule last, and only once the "
        'others let it through', (tester) async {
      final saved = <num>[];
      final asked = <num>[];
      await _pump(
        tester,
        _Sheet(
          (s) => TableTextEditor.number(
            session: s,
            value: 20,
            integer: true,
            min: 0,
            validate: (v) {
              asked.add(v);
              return v > 999 ? 'No more than 999 fit on the shelf' : null;
            },
            onCommit: saved.add,
          ),
        ),
      );
      await _edit(tester);
      await _commit(tester, 'many');
      await _commit(tester, '2.5');
      await _commit(tester, '-3');
      expect(asked, isEmpty);

      await _commit(tester, '1000');
      expect(asked, [1000]);
      expect(_field, findsOneWidget);
      expect(_said, 'No more than 999 fit on the shelf');
      expect(saved, isEmpty);

      await _commit(tester, '999');
      expect(asked, [1000, 999]);
      expect(_field, findsNothing);
      expect(saved, [999]);
    });

    testWidgets('speaks the app\'s language and notation', (tester) async {
      await _pump(
        tester,
        locale: 'fr',
        _Sheet(
          (s) => TableTextEditor.number(
            session: s,
            value: 20,
            min: 0.5,
            onCommit: (_) {},
          ),
        ),
      );
      await _edit(tester);
      await _commit(tester, '0,25');
      expect(_said, 'Saisissez 0,5 ou plus');
      await _commit(tester, 'vingt');
      expect(_said, 'Saisissez un nombre comme 1 234,5');
    });

    testWidgets('has the keyboard its rules leave it', (tester) async {
      TextInputType? keyboard() =>
          tester.widget<TextField>(_field).keyboardType;

      await _pump(
        tester,
        _Sheet(
          (s) => TableTextEditor.number(session: s, value: 1, onCommit: (_) {}),
        ),
      );
      await _edit(tester);
      expect(
        keyboard(),
        const TextInputType.numberWithOptions(decimal: true, signed: true),
        reason: 'as it was',
      );
      await _key(tester, LogicalKeyboardKey.escape);

      await _pump(
        tester,
        _Sheet(
          (s) => TableTextEditor.number(
            session: s,
            value: 1,
            integer: true,
            min: 0,
            onCommit: (_) {},
          ),
        ),
      );
      await _edit(tester);
      expect(
        keyboard(),
        const TextInputType.numberWithOptions(decimal: false, signed: false),
      );
      await _key(tester, LogicalKeyboardKey.escape);

      await _pump(
        tester,
        _Sheet(
          (s) => TableTextEditor.number(
            session: s,
            value: 1,
            min: -5,
            onCommit: (_) {},
          ),
        ),
      );
      await _edit(tester);
      expect(
        keyboard(),
        const TextInputType.numberWithOptions(decimal: true, signed: true),
      );
    });

    test('told to be whole has no decimals to show, and no empty range', () {
      final session = EditSession(label: 'Value', onEnd: (_) {});
      expect(
        () => TableTextEditor.number(
          session: session,
          value: 1,
          integer: true,
          fractionDigits: 2,
          onCommit: (_) {},
        ),
        throwsAssertionError,
      );
      expect(
        () => TableTextEditor.number(
          session: session,
          value: 1,
          min: 10,
          max: 5,
          onCommit: (_) {},
        ),
        throwsAssertionError,
      );
      // A whole number shown with none is said twice, not wrongly.
      TableTextEditor.number(
        session: session,
        value: 1,
        integer: true,
        fractionDigits: 0,
        onCommit: (_) {},
      );
    });
  });

  group('a text', () {
    testWidgets("is put to the app's rule", (tester) async {
      final saved = <String>[];
      await _pump(
        tester,
        _Sheet(
          numeric: false,
          (s) => TableTextEditor(
            session: s,
            value: 'Fern',
            validate: (v) => v.trim().isEmpty ? 'A name is required' : null,
            onCommit: saved.add,
          ),
        ),
      );
      await _edit(tester);
      await _commit(tester, '  ');
      expect(_field, findsOneWidget);
      expect(_said, 'A name is required');
      expect(saved, isEmpty);

      await _commit(tester, 'Moss');
      expect(_field, findsNothing);
      expect(saved, ['Moss']);
    });

    testWidgets('with no rule saves whatever is typed, as it did', (
      tester,
    ) async {
      final saved = <String>[];
      await _pump(
        tester,
        _Sheet(
          numeric: false,
          (s) =>
              TableTextEditor(session: s, value: 'Fern', onCommit: saved.add),
        ),
      );
      await _edit(tester);
      await _commit(tester, '');
      expect(_field, findsNothing);
      expect(_card, findsNothing);
      expect(saved, ['']);
    });
  });

  group('a draft refused', () {
    _Editor stock(List<num> saved) =>
        (s) => TableTextEditor.number(
          session: s,
          value: 20,
          integer: true,
          min: 0,
          onCommit: saved.add,
        );

    testWidgets('marks the editor invalid, with why as its hint', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _Sheet(stock([])));
      await _edit(tester);
      expect(_validity(tester), SemanticsValidationResult.none);

      await _commit(tester, '-3');
      final data = tester.getSemantics(_field).getSemanticsData();
      expect(data.validationResult, SemanticsValidationResult.invalid);
      expect(data.label, 'Value');
      expect(data.hint, 'Enter 0 or more');
      expect(
        tester.getSemantics(find.text('Enter 0 or more')),
        matchesSemantics(label: 'Enter 0 or more', isLiveRegion: true),
        reason: 'the card is announced as it appears',
      );
      handle.dispose();
    });

    testWidgets("draws the editor with an invalid field's edge, until it is "
        'edited', (tester) async {
      await _pump(tester, _Sheet(stock([])));
      await _edit(tester);
      final atRest = _edge(tester);

      await _commit(tester, '-3');
      final refused = _edge(tester);
      expect(refused, isNot(atRest));
      expect(refused, defaultTokens.palette.danger);

      await tester.enterText(_field, '3');
      await tester.pump();
      expect(_edge(tester), atRest);
    });

    testWidgets('with an empty message is refused, and shows no card', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final saved = <num>[];
      await _pump(
        tester,
        _Sheet(
          (s) => TableTextEditor.number(
            session: s,
            value: 20,
            validate: (v) => v > 9 ? 'One figure only' : '',
            onCommit: saved.add,
          ),
        ),
      );
      await _edit(tester);
      await _commit(tester, '5');
      expect(_field, findsOneWidget);
      expect(saved, isEmpty);
      expect(_card, findsNothing);
      final data = tester.getSemantics(_field).getSemanticsData();
      expect(data.validationResult, SemanticsValidationResult.invalid);
      expect(data.hint, isEmpty);

      // After a refusal that said why, too.
      await _commit(tester, '50');
      expect(_said, 'One figure only');
      await _commit(tester, '6');
      expect(_card, findsNothing);
      expect(_validity(tester), SemanticsValidationResult.invalid);
      handle.dispose();
    });

    testWidgets('edited loses its message and its mark, and stays open', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _Sheet(stock([])));
      await _edit(tester);
      await _commit(tester, '-3');
      expect(_card, findsOneWidget);

      await tester.enterText(_field, '-');
      await tester.pump();
      expect(_card, findsNothing);
      expect(_validity(tester), SemanticsValidationResult.none);
      expect(_field, findsOneWidget);
      handle.dispose();
    });

    testWidgets('committed again is refused again', (tester) async {
      final saved = <num>[];
      await _pump(tester, _Sheet(stock(saved)));
      await _edit(tester);
      await _commit(tester, '-3');
      await _key(tester, LogicalKeyboardKey.enter);
      expect(_card, findsOneWidget, reason: 'Enter again, the same draft');

      await tester.enterText(_field, '-');
      await tester.pump();
      await _commit(tester, '-3');
      expect(_said, 'Enter 0 or more');
      expect(saved, isEmpty);
    });

    testWidgets('says the latest reason', (tester) async {
      await _pump(tester, _Sheet(stock([])));
      await _edit(tester);
      await _commit(tester, '-3');
      expect(_said, 'Enter 0 or more');
      await _commit(tester, '2.5');
      expect(_card, findsOneWidget);
      expect(_said, 'Enter a number like 1,234');
    });

    testWidgets('says the latest reason for a draft left as it was', (
      tester,
    ) async {
      var asked = 0;
      await _pump(
        tester,
        _Sheet(
          (s) => TableTextEditor.number(
            session: s,
            value: 20,
            validate: (_) => ++asked == 1 ? 'Not yet' : 'Still not',
            onCommit: (_) {},
          ),
        ),
      );
      await _edit(tester);
      await _commit(tester, '5');
      expect(_said, 'Not yet');
      await _key(tester, LogicalKeyboardKey.enter);
      expect(_card, findsOneWidget);
      expect(_said, 'Still not');
    });

    testWidgets('keeps Tab in its cell', (tester) async {
      final saved = <num>[];
      await _pump(
        tester,
        _Sheet(
          stock(saved),
          other: (s) =>
              TableTextEditor(session: s, value: 'other', onCommit: (_) {}),
        ),
      );
      await _edit(tester);
      await tester.enterText(_field, '-3');
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_field, findsOneWidget);
      expect(tester.widget<TextField>(_field).controller!.text, '-3');
      expect(_said, 'Enter 0 or more');

      await tester.enterText(_field, '3');
      await _key(tester, LogicalKeyboardKey.tab);
      expect(saved, [3]);
      expect(tester.widget<TextField>(_field).controller!.text, 'other');
      expect(_card, findsNothing);
    });

    testWidgets('stays open on a tap outside', (tester) async {
      final saved = <num>[];
      await _pump(tester, _Sheet(stock(saved)));
      await _edit(tester);
      await tester.enterText(_field, '-3');
      await tester.tap(find.text('Outside'));
      await tester.pump();
      expect(_field, findsOneWidget);
      expect(_said, 'Enter 0 or more');
      expect(saved, isEmpty);
    });

    testWidgets('is dropped by Escape, with its message', (tester) async {
      final saved = <num>[];
      await _pump(tester, _Sheet(stock(saved)));
      await _edit(tester);
      await _commit(tester, '-3');
      await _key(tester, LogicalKeyboardKey.escape);
      expect(_field, findsNothing);
      expect(_card, findsNothing);
      expect(saved, isEmpty);
    });

    testWidgets('takes its message with it when the table goes', (
      tester,
    ) async {
      await _pump(tester, _Sheet(stock([])));
      await _edit(tester);
      await _commit(tester, '-3');
      expect(_card, findsOneWidget);
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(_card, findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('the message', () {
    Widget stock(EditSession s) => TableTextEditor.number(
      session: s,
      value: 20,
      integer: true,
      min: 0,
      onCommit: (_) {},
    );
    Widget name(EditSession s) => TableTextEditor(
      session: s,
      value: 'Fern',
      validate: (v) => v.isEmpty ? 'A name is required' : null,
      onCommit: (_) {},
    );

    testWidgets("stands under a number, on the cell's far edge", (
      tester,
    ) async {
      await _pump(tester, _Sheet(stock, valueLast: true));
      await _edit(tester, 'cell 1');
      await _commit(tester, '-3');
      final field = tester.getRect(_field);
      final card = tester.getRect(_card);
      expect(card.top, field.bottom + 4);
      expect(card.right, field.right);
      expect(card.width, lessThan(280), reason: 'as wide as what it says');
    });

    testWidgets("stands under a text, on the cell's near edge", (tester) async {
      await _pump(tester, _Sheet(name, numeric: false, valueLast: true));
      await _edit(tester, 'cell 1');
      await _commit(tester, '');
      final field = tester.getRect(_field);
      final card = tester.getRect(_card);
      expect(card.top, field.bottom + 4);
      expect(card.left, field.left);
    });

    testWidgets('mirrors right to left', (tester) async {
      await _pump(
        tester,
        Directionality(
          textDirection: TextDirection.rtl,
          child: _Sheet(stock, valueLast: true),
        ),
      );
      await _edit(tester, 'cell 1');
      await _commit(tester, '-3');
      expect(tester.getRect(_card).left, tester.getRect(_field).left);
      await _key(tester, LogicalKeyboardKey.escape);

      await _pump(
        tester,
        Directionality(
          textDirection: TextDirection.rtl,
          child: _Sheet(name, numeric: false, valueLast: true),
        ),
      );
      await _edit(tester, 'cell 1');
      await _commit(tester, '');
      expect(tester.getRect(_card).right, tester.getRect(_field).right);
    });

    testWidgets('stands over the cell where it does not fit below', (
      tester,
    ) async {
      const window = Size(1000, 300);
      await _pump(
        tester,
        size: window,
        _Sheet(stock, rows: 12, valueLast: true),
      );
      // The last row that shows whole.
      final last = [
        for (var i = 0; i < 12; i++)
          if (find.text('cell $i').evaluate().isNotEmpty &&
              tester.getRect(find.text('cell $i')).bottom < window.height - 8)
            i,
      ].last;
      await _edit(tester, 'cell $last');
      await _commit(tester, '-3');
      final field = tester.getRect(_field);
      final card = tester.getRect(_card);
      expect(
        window.height - field.bottom,
        lessThan(card.height + 4 + 8),
        reason: 'no room for the card and its margin',
      );
      expect(card.bottom, field.top - 4);
      expect(card.right, field.right);
    });

    testWidgets('is kept inside the window, off its edge', (tester) async {
      // A number in the first column: the card would end on the cell's far
      // edge and start before the window does.
      await _pump(tester, _Sheet(stock));
      await _edit(tester, 'cell 1');
      await _commit(tester, '-3');
      final field = tester.getRect(_field);
      final card = tester.getRect(_card);
      expect(field.right - card.width, lessThan(8), reason: 'no room');
      expect(card.left, 8);
      expect(card.top, field.bottom + 4);
    });

    testWidgets('wraps a long message, and is kept inside the window', (
      tester,
    ) async {
      const window = Size(420, 600);
      const long =
          'A name is required, and it is what the shop shows on every '
          'page a customer sees';
      await _pump(
        tester,
        size: window,
        _Sheet(
          numeric: false,
          valueLast: true,
          (s) => TableTextEditor(
            session: s,
            value: 'Fern',
            validate: (_) => long,
            onCommit: (_) {},
          ),
        ),
      );
      await _edit(tester, 'cell 1');
      await _commit(tester, 'Moss');
      final field = tester.getRect(_field);
      final card = tester.getRect(_card);
      expect(card.width, 280);
      expect(card.height, greaterThan(50), reason: 'the message wraps');
      expect(
        field.left + 280,
        greaterThan(window.width - 8),
        reason: 'no room',
      );
      expect(card.right, window.width - 8);
    });

    testWidgets('is no wider than the window leaves it', (tester) async {
      const window = Size(200, 600);
      await _pump(
        tester,
        size: window,
        _Sheet(
          numeric: false,
          (s) => TableTextEditor(
            session: s,
            value: 'Fern',
            validate: (_) => 'A name is required, whatever else is not',
            onCommit: (_) {},
          ),
        ),
      );
      await _edit(tester, 'cell 1');
      await _commit(tester, 'Moss');
      final card = tester.getRect(_card);
      expect(card.width, window.width - 16);
      expect(card.left, 8);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is kept inside a window made narrower', (tester) async {
      await _pump(tester, _Sheet(name, numeric: false, valueLast: true));
      await _edit(tester, 'cell 1');
      await _commit(tester, '');
      final width = tester.getRect(_card).width;
      expect(tester.getRect(_card).left, tester.getRect(_field).left);

      tester.view.physicalSize = const Size(380, 600);
      await tester.pump();
      final field = tester.getRect(_field);
      final card = tester.getRect(_card);
      expect(field.left + width, greaterThan(380 - 8), reason: 'no room');
      expect(card.right, 380 - 8);
      expect(card.width, width);
      expect(card.top, field.bottom + 4);
    });

    testWidgets('follows its cell as the table scrolls', (tester) async {
      await _pump(
        tester,
        size: const Size(1000, 400),
        _Sheet(stock, rows: 40, valueLast: true),
      );
      await _edit(tester, 'cell 2');
      await _commit(tester, '-3');
      final before = tester.getRect(_field);
      expect(tester.getRect(_card).top, before.bottom + 4);

      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(
        pointer.hover(tester.getCenter(find.text('#4'))),
      );
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 30)));
      await tester.pump();
      await tester.pump();
      final after = tester.getRect(_field);
      expect(after.top, before.top - 30, reason: 'the table scrolled');
      expect(tester.getRect(_card).top, after.bottom + 4);
      expect(tester.getRect(_card).right, after.right);
    });

    testWidgets('takes no pointer: a tap on it lands under it', (tester) async {
      await _pump(tester, _Sheet(stock));
      await _edit(tester, 'cell 0');
      await _commit(tester, '-3');
      expect(_card, findsOneWidget);
      expect(_card.hitTestable(), findsNothing);
      expect(find.byType(FieldMessage).hitTestable(), findsNothing);
    });

    testWidgets('leaves the focus in the editor', (tester) async {
      await _pump(tester, _Sheet(stock));
      await _edit(tester);
      await _commit(tester, '-3');
      expect(_card, findsOneWidget);
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasPrimaryFocus, isTrue);
    });
  });
}
