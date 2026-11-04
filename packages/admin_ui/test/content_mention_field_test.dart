import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _team = [
  MentionCandidate(id: 'u1', name: 'Alice Martin'),
  MentionCandidate(id: 'u2', name: 'Alan Reyes'),
  MentionCandidate(id: 'u3', name: 'Bea Stone'),
];

Widget _host(
  Widget child, {
  Locale locale = const Locale('en'),
  double width = 480,
}) => MaterialApp(
  theme: buildAppTheme(irisTheme.tokens),
  locale: locale,
  supportedLocales: AdminLocalizations.supportedLocales,
  localizationsDelegates: AdminLocalizations.localizationsDelegates,
  home: Scaffold(
    body: Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: SizedBox(width: width, child: child),
      ),
    ),
  ),
);

class _Harness {
  final WidgetTester tester;
  final TextEditingController controller;
  final FocusNode focus;
  final List<String> sent;

  _Harness(this.tester, this.controller, this.focus, this.sent);

  Finder get field => find.byType(TextField);

  /// Types [text] as a user would: the whole value, caret at its end.
  Future<void> type(String text) async {
    await tester.enterText(field, text);
    await tester.pumpAndSettle();
  }

  Future<void> key(LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await tester.pumpAndSettle();
  }

  bool get open => find.byType(PopoverMenuSurface).evaluate().isNotEmpty;

  List<String> get options => [
    for (final option in tester.widgetList<ListboxOption>(
      find.byType(ListboxOption),
    ))
      option.label,
  ];

  String? get highlighted {
    final options = tester
        .widgetList<ListboxOption>(find.byType(ListboxOption))
        .toList();
    final at = options.firstOrNull?.controller.highlighted;
    return at == null ? null : options[at].label;
  }
}

Future<_Harness> _pump(
  WidgetTester tester, {
  int? maxLines = 1,
  int? minLines,
  Locale locale = const Locale('en'),
  bool enabled = true,
  bool readOnly = false,
  String? label,
  String? errorText,
}) async {
  final controller = TextEditingController();
  final focus = FocusNode();
  final sent = <String>[];
  addTearDown(controller.dispose);
  addTearDown(focus.dispose);
  await tester.pumpWidget(
    _host(
      MentionField(
        controller: controller,
        focusNode: focus,
        candidates: _team,
        onSubmit: sent.add,
        maxLines: maxLines,
        minLines: minLines,
        enabled: enabled,
        readOnly: readOnly,
        label: label,
        errorText: errorText,
      ),
      locale: locale,
    ),
  );
  if (enabled) {
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
  }
  return _Harness(tester, controller, focus, sent);
}

void main() {
  group('suggestions', () {
    testWidgets('an @ offers every candidate, and typing narrows them', (
      tester,
    ) async {
      final h = await _pump(tester);
      await h.type('Ask @');
      expect(h.open, isTrue);
      expect(h.options, ['Alice Martin', 'Alan Reyes', 'Bea Stone']);
      expect(h.highlighted, 'Alice Martin');

      await h.type('Ask @al');
      expect(h.options, ['Alice Martin', 'Alan Reyes']);
      await h.type('Ask @ali');
      expect(h.options, ['Alice Martin']);
      expect(h.focus.hasFocus, isTrue, reason: 'the field keeps focus');
    });

    testWidgets('only at the start or after a space', (tester) async {
      final h = await _pump(tester);
      await h.type('mail me@al');
      expect(h.open, isFalse);
      await h.type('@al');
      expect(h.open, isTrue);

      final lines = await _pump(tester, maxLines: 3);
      await lines.type('line\n@be');
      expect(lines.options, ['Bea Stone'], reason: 'a line starts afresh');
    });

    testWidgets('no match shows the root "No matches"; text past it closes', (
      tester,
    ) async {
      final h = await _pump(tester);
      await h.type('Ask @zo');
      expect(h.open, isTrue);
      expect(find.text('No matches'), findsOneWidget);
      expect(find.byType(ListboxOption), findsNothing);

      await h.type('Ask @zo and');
      expect(h.open, isFalse, reason: 'the note goes on past a non-mention');
      await h.type('Ask @ ');
      expect(h.open, isFalse, reason: 'a space after the @ opens nothing');
    });

    testWidgets('the list closes as the field loses focus', (tester) async {
      final h = await _pump(tester);
      await h.type('@a');
      expect(h.open, isTrue);
      h.focus.unfocus();
      await tester.pumpAndSettle();
      expect(h.open, isFalse);
      h.focus.requestFocus();
      await tester.pumpAndSettle();
      expect(h.open, isTrue, reason: 'back in the field, at the same @');
    });

    testWidgets('a disabled or read-only field opens nothing', (tester) async {
      var h = await _pump(tester, enabled: false);
      h.controller.value = const TextEditingValue(
        text: '@a',
        selection: TextSelection.collapsed(offset: 2),
      );
      await tester.pumpAndSettle();
      expect(h.open, isFalse);

      h = await _pump(tester, readOnly: true);
      h.controller.value = const TextEditingValue(
        text: '@a',
        selection: TextSelection.collapsed(offset: 2),
      );
      await tester.pumpAndSettle();
      expect(h.open, isFalse);
    });
  });

  group('keyboard', () {
    testWidgets('ArrowDown and ArrowUp move the highlight and wrap', (
      tester,
    ) async {
      final h = await _pump(tester);
      await h.type('@');
      expect(h.highlighted, 'Alice Martin');
      await h.key(LogicalKeyboardKey.arrowDown);
      expect(h.highlighted, 'Alan Reyes');
      await h.key(LogicalKeyboardKey.arrowDown);
      await h.key(LogicalKeyboardKey.arrowDown);
      expect(h.highlighted, 'Alice Martin', reason: 'wraps past the last');
      await h.key(LogicalKeyboardKey.arrowUp);
      expect(h.highlighted, 'Bea Stone');
      expect(h.controller.selection.baseOffset, 1, reason: 'the caret stays');
      expect(h.focus.hasFocus, isTrue);
    });

    testWidgets('Enter accepts: the query becomes the name and a space', (
      tester,
    ) async {
      final h = await _pump(tester);
      await h.type('Ask @al');
      await h.key(LogicalKeyboardKey.arrowDown);
      await h.key(LogicalKeyboardKey.enter);
      expect(h.controller.text, 'Ask @Alan Reyes ');
      expect(h.controller.selection, const TextSelection.collapsed(offset: 16));
      expect(h.open, isFalse);
      expect(h.focus.hasFocus, isTrue);
      expect(h.sent, isEmpty, reason: 'Enter picked; it did not send');
    });

    testWidgets('Tab accepts; Shift+Tab does not', (tester) async {
      final h = await _pump(tester);
      await h.type('@be');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(h.controller.text, '@be');

      h.focus.requestFocus();
      await h.type('@be');
      await h.key(LogicalKeyboardKey.tab);
      expect(h.controller.text, '@Bea Stone ');
      expect(h.focus.hasFocus, isTrue, reason: 'Tab picked; focus stayed');
    });

    testWidgets('a mid-text mention keeps what follows', (tester) async {
      final h = await _pump(tester);
      h.controller.value = const TextEditingValue(
        text: 'cc @al please',
        selection: TextSelection.collapsed(offset: 6),
      );
      await tester.pumpAndSettle();
      await h.key(LogicalKeyboardKey.enter);
      expect(h.controller.text, 'cc @Alice Martin please');
      expect(
        h.controller.selection,
        const TextSelection.collapsed(offset: 17),
        reason: 'past the space already there',
      );
    });

    testWidgets('tapping a suggestion accepts it and keeps focus', (
      tester,
    ) async {
      final h = await _pump(tester);
      await h.type('Ask @');
      await tester.tap(find.widgetWithText(ListboxOption, 'Bea Stone'));
      await tester.pumpAndSettle();
      expect(h.controller.text, 'Ask @Bea Stone ');
      expect(h.focus.hasFocus, isTrue);
      expect(h.open, isFalse);
    });

    testWidgets('after a pick, typing on does not reopen the list', (
      tester,
    ) async {
      final h = await _pump(tester);
      await h.type('@al');
      await h.key(LogicalKeyboardKey.enter);
      await h.type('${h.controller.text}can you');
      expect(h.open, isFalse);
      await h.type('${h.controller.text} and @b');
      expect(h.options, ['Bea Stone'], reason: 'a new @ opens it again');
    });

    testWidgets('Escape closes this mention\'s list, keeping focus', (
      tester,
    ) async {
      final h = await _pump(tester);
      await h.type('Ask @a');
      await h.key(LogicalKeyboardKey.escape);
      expect(h.open, isFalse);
      expect(h.focus.hasFocus, isTrue);
      await h.type('Ask @al');
      expect(h.open, isFalse, reason: 'still the dismissed mention');
      await h.type('Ask @al @b');
      expect(h.open, isTrue);
    });

    testWidgets('the arrows move the caret while the list is closed', (
      tester,
    ) async {
      final h = await _pump(tester, maxLines: 4, minLines: 2);
      await h.type('one\ntwo');
      await h.key(LogicalKeyboardKey.arrowLeft);
      expect(h.controller.selection.baseOffset, 6);
      await h.key(LogicalKeyboardKey.arrowUp);
      expect(h.controller.selection.baseOffset, 2);
      await h.key(LogicalKeyboardKey.arrowRight);
      expect(h.controller.selection.baseOffset, 3);
      await h.key(LogicalKeyboardKey.arrowDown);
      expect(h.controller.selection.baseOffset, 7);
      expect(h.focus.hasFocus, isTrue);
    });
  });

  group('onSubmit', () {
    testWidgets('Ctrl+Enter in a multi-line field sends the body, tokenized', (
      tester,
    ) async {
      final h = await _pump(tester, maxLines: 4, minLines: 2);
      await h.type('Ask @al');
      await h.key(LogicalKeyboardKey.enter);
      await h.type('${h.controller.text}about it  ');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(h.sent, ['Ask <@u1> about it']);
      expect(h.controller.text, 'Ask @Alice Martin about it  ');
    });

    testWidgets('Meta+Enter sends too; a plain Enter is a new line', (
      tester,
    ) async {
      final h = await _pump(tester, maxLines: 4);
      await h.type('Hi @Bea Stone');
      await h.key(LogicalKeyboardKey.escape);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();
      expect(h.sent, ['Hi <@u3>']);
    });

    testWidgets('a one-line field sends on its action, not while picking', (
      tester,
    ) async {
      final h = await _pump(tester);
      await h.type('Ping @be');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
      expect(
        h.controller.text,
        'Ping @Bea Stone ',
        reason: 'the action picked',
      );
      expect(h.sent, isEmpty);

      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();
      expect(h.sent, ['Ping <@u3>']);
      expect(h.focus.hasFocus, isTrue, reason: 'ready for the next one');
    });

    testWidgets('a blank body is not sent', (tester) async {
      final h = await _pump(tester, maxLines: 3);
      await h.type('   ');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(h.sent, isEmpty);
    });
  });

  group('accessibility', () {
    testWidgets('a listbox of named options, the highlighted one focused', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final h = await _pump(tester, label: 'Note');
      expect(
        tester.getSemantics(h.field),
        isSemantics(
          isTextField: true,
          hasExpandedState: true,
          isExpanded: false,
        ),
      );
      await h.type('@al');
      expect(
        tester.getSemantics(h.field),
        isSemantics(hasExpandedState: true, isExpanded: true),
      );
      expect(find.bySemanticsLabel('People to mention'), findsOneWidget);
      expect(
        tester.getSemantics(find.widgetWithText(ListboxOption, 'Alice Martin')),
        isSemantics(label: 'Alice Martin', hint: '1 of 2', isFocused: true),
      );
      await h.key(LogicalKeyboardKey.arrowDown);
      expect(
        tester.getSemantics(find.widgetWithText(ListboxOption, 'Alan Reyes')),
        isSemantics(label: 'Alan Reyes', hint: '2 of 2', isFocused: true),
      );
      semantics.dispose();
    });

    testWidgets('the number of matches is announced as it changes', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final announced = <String>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, (
            message,
          ) async {
            final data = (message! as Map)['data'] as Map;
            announced.add(data['message'] as String);
            return null;
          });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(
              SystemChannels.accessibility,
              null,
            ),
      );
      final h = await _pump(tester);
      await h.type('@');
      await h.type('@a');
      await h.type('@al');
      await h.type('@ali');
      await h.type('@aliz');
      expect(announced, [
        '3 people to mention',
        '2 people to mention',
        '1 person to mention',
        'No matches',
      ]);
      semantics.dispose();
    });

    for (final (locale, empty, list) in const [
      ('fr', 'Aucune correspondance', 'Personnes à mentionner'),
      ('ar', 'لا توجد نتائج مطابقة', 'أشخاص للإشارة إليهم'),
    ]) {
      testWidgets('$locale: the list and its empty line are localized', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        final h = await _pump(tester, locale: Locale(locale));
        await h.type('@zz');
        expect(find.text(empty), findsOneWidget);
        await h.type('@a');
        expect(find.bySemanticsLabel(list), findsOneWidget);
        semantics.dispose();
      });
    }
  });

  group('placement', () {
    /// The '@' at [index] of the field's text, in global coordinates.
    Rect atSign(WidgetTester tester, int index) {
      final editable = tester
          .state<EditableTextState>(find.byType(EditableText))
          .renderEditable;
      final box = editable
          .getBoxesForSelection(
            TextSelection(baseOffset: index, extentOffset: index + 1),
          )
          .single
          .toRect();
      return box.shift(editable.localToGlobal(Offset.zero));
    }

    Rect avatar(WidgetTester tester) =>
        tester.getRect(find.byType(Avatar).first);

    testWidgets('an @ at the start opens the list flush with the field', (
      tester,
    ) async {
      final h = await _pump(tester);
      await h.type('@a');
      final field = tester.getRect(h.field);
      final menu = tester.getRect(find.byType(PopoverMenuSurface));
      expect(menu.left, field.left);
      expect(menu.top, greaterThan(field.bottom));
    });

    testWidgets('left to right, each avatar starts under the @', (
      tester,
    ) async {
      final h = await _pump(tester);
      await h.type('Please ask @a');
      expect(avatar(tester).left, closeTo(atSign(tester, 11).left, 1));
    });

    testWidgets('right to left, each avatar ends under the @', (tester) async {
      final h = await _pump(tester, locale: const Locale('ar'));
      await h.type('اسأل @a');
      final at = atSign(tester, 5);
      expect(avatar(tester).right, closeTo(at.right, 1));
      final field = tester.getRect(h.field);
      final menu = tester.getRect(find.byType(PopoverMenuSurface));
      expect(menu.right, lessThan(field.right), reason: 'moved in from start');

      await h.type('@a');
      expect(
        tester.getRect(find.byType(PopoverMenuSurface)).right,
        field.right,
        reason: 'an @ at the start: flush with the field',
      );
    });
  });

  group('chrome', () {
    testWidgets('a label, and an error under the field, as InputField', (
      tester,
    ) async {
      await _pump(tester, label: 'Note', errorText: 'Too long');
      final label = irisTheme.tokens.typography.fieldLabelText('Note');
      expect(find.text(label), findsOneWidget);
      expect(find.text('Too long'), findsOneWidget);
      expect(
        tester.getRect(find.text('Too long')).top,
        greaterThan(tester.getRect(find.byType(TextField)).bottom),
      );
    });

    testWidgets('bare, an error still shows and marks the field invalid', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester, errorText: 'Required');
      expect(find.text('Required'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(TextField)),
        isSemantics(validationResult: SemanticsValidationResult.invalid),
      );
      semantics.dispose();
    });
  });
}
