import 'package:admin_ui/admin_ui.dart' show Button, defaultTokens;
import 'package:admin_ui/src/fields/ui/code_body.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

TextEditingValue _v(String text, int offset) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: offset),
);

TextEditingValue _sel(String text, int base, int extent) => TextEditingValue(
  text: text,
  selection: TextSelection(baseOffset: base, extentOffset: extent),
);

/// The token kind covering character [at] in [src], or null if outside any token
/// (tokens are contiguous, so a hit is always found for in-range indices).
JsonTokenKind? _kindAt(String src, int at) {
  for (final t in tokenizeJson(src)) {
    if (at >= t.start && at < t.end) return t.kind;
  }
  return null;
}

void main() {
  group('tokenizeJson', () {
    test('covers every character contiguously', () {
      const src = '{ "a": [1, true] }';
      final tokens = tokenizeJson(src);
      expect(tokens.first.start, 0);
      expect(tokens.last.end, src.length);
      for (var i = 1; i < tokens.length; i++) {
        expect(tokens[i].start, tokens[i - 1].end, reason: 'no gaps/overlaps');
      }
    });

    test('a string before a colon is a key, otherwise a string', () {
      const src = '{"name": "Ada"}';
      expect(_kindAt(src, src.indexOf('name')), JsonTokenKind.key);
      expect(_kindAt(src, src.indexOf('Ada')), JsonTokenKind.string);
    });

    test('whitespace between a key and its colon still reads as a key', () {
      const src = '{"name"  : 1}';
      expect(_kindAt(src, src.indexOf('name')), JsonTokenKind.key);
    });

    test('escaped quote does not end the string early', () {
      const src = r'"a\"b": 1';
      // The whole quoted run (incl. the escaped quote) is one key token.
      final keyTokens = tokenizeJson(src)
          .where((t) => t.kind == JsonTokenKind.key)
          .toList();
      expect(keyTokens, hasLength(1));
      expect(
        src.substring(keyTokens.first.start, keyTokens.first.end),
        r'"a\"b"',
      );
    });

    test('numbers, literals and punctuation classify', () {
      const src = '[-1.5e3, false, null]';
      expect(_kindAt(src, src.indexOf('-1.5e3')), JsonTokenKind.number);
      expect(_kindAt(src, src.indexOf('false')), JsonTokenKind.literal);
      expect(_kindAt(src, src.indexOf('null')), JsonTokenKind.literal);
      expect(_kindAt(src, 0), JsonTokenKind.punctuation);
    });

    test('lexes partial input without throwing', () {
      expect(() => tokenizeJson('{"a": '), returnsNormally);
      expect(() => tokenizeJson('"unterminated'), returnsNormally);
    });
  });

  group('validateJson', () {
    test('blank and valid documents return null', () {
      expect(validateJson(''), isNull);
      expect(validateJson('   \n '), isNull);
      expect(validateJson('{"a": [1, 2, 3]}'), isNull);
    });

    test('pins the error to a 1-based line and column', () {
      // Trailing comma on line 3.
      const bad = '{\n  "a": 1,\n}';
      final err = validateJson(bad);
      expect(err, isNotNull);
      expect(err!.line, 3);
      expect(err.column, greaterThanOrEqualTo(1));
      expect(err.message, isNotEmpty);
    });

    test('strips the trailing "(at ...)" location noise from the message', () {
      final err = validateJson('{"a" 1}');
      expect(err, isNotNull);
      expect(err!.message, isNot(contains('(at ')));
    });
  });

  group('autoEditOnChange — pairing', () {
    test('typing an opener inserts the closer and keeps the caret between', () {
      final r = autoEditOnChange(_v('', 0), _v('{', 1));
      expect(r, isNotNull);
      expect(r!.text, '{}');
      expect(r.selection.baseOffset, 1);
    });

    test('typing a closer over an existing one steps past it', () {
      // Caret between `{}`, user types `}` → field made `{}}`, we step over.
      final r = autoEditOnChange(_v('{}', 1), _v('{}}', 2));
      expect(r, isNotNull);
      expect(r!.text, '{}');
      expect(r.selection.baseOffset, 2);
    });

    test('backspacing an opener removes its adjacent closer', () {
      // Caret between `{}`, backspace deletes `{` → field made `}`, we drop `}`.
      final r = autoEditOnChange(_v('{}', 1), _v('}', 0));
      expect(r, isNotNull);
      expect(r!.text, '');
      expect(r.selection.baseOffset, 0);
    });

    test('autoClose:false suppresses pairing but keeps indent', () {
      expect(autoEditOnChange(_v('', 0), _v('{', 1), autoClose: false), isNull);
      final r = autoEditOnChange(
        _v('  a', 3),
        _v('  a\n', 4),
        autoClose: false,
      );
      expect(r, isNotNull);
      expect(r!.text, '  a\n  ');
    });

    test('a multi-character paste passes through untouched', () {
      expect(autoEditOnChange(_v('', 0), _v('abc', 3)), isNull);
    });
  });

  group('autoEditOnChange — newline indent', () {
    test('carries the previous line indentation', () {
      final r = autoEditOnChange(_v('  ab', 4), _v('  ab\n', 5));
      expect(r, isNotNull);
      expect(r!.text, '  ab\n  ');
      expect(r.selection.baseOffset, 7);
    });

    test('splitting an empty bracket pair opens an indented block', () {
      // `{|}` then Enter → field made `{\n}`, we expand to a 3-line block.
      final r = autoEditOnChange(_v('{}', 1), _v('{\n}', 2));
      expect(r, isNotNull);
      expect(r!.text, '{\n  \n}');
      expect(r.selection.baseOffset, 4);
    });

    test('top-level newline with no indentation is left alone', () {
      expect(autoEditOnChange(_v('ab', 2), _v('ab\n', 3)), isNull);
    });
  });

  group('codeIndent', () {
    test('a collapsed caret inserts one indent unit', () {
      final r = codeIndent(_v('ab', 2), outdent: false);
      expect(r.text, 'ab  ');
      expect(r.selection.baseOffset, 4);
    });

    test('indents every line a selection touches', () {
      final r = codeIndent(_sel('a\nb', 0, 3), outdent: false);
      expect(r.text, '  a\n  b');
      expect(r.selection.baseOffset, 2);
      expect(r.selection.extentOffset, 7);
    });

    test('outdent strips up to one indent unit of leading spaces', () {
      final r = codeIndent(_v('    a', 5), outdent: true);
      expect(r.text, '  a');
    });

    test('outdent is a no-op on an already flush line', () {
      final r = codeIndent(_v('a', 1), outdent: true);
      expect(r.text, 'a');
    });
  });

  group('CodeBody widget', () {
    testWidgets('renders, edits, and reports validity without re-entry crash', (
      tester,
    ) async {
      String? emitted;
      bool? valid;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeBody(
              value: '{"a": 1}',
              onChanged: (v) => emitted = v,
              onValidChanged: (v) => valid = v,
            ),
          ),
        ),
      );
      expect(find.text('Valid JSON'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), '{ bad');
      await tester.pump();
      expect(emitted, '{ bad');
      expect(valid, isFalse);
      expect(find.textContaining('Line 1'), findsOneWidget);
    });

    testWidgets('the editor and its gutter set the theme\'s mono roles', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CodeBody(value: '{}', onChanged: (_) {}),
          ),
        ),
      );
      final type = defaultTokens.typography;
      final style = tester
          .widget<EditableText>(find.byType(EditableText))
          .style;
      expect(style.fontSize, type.mono.fontSize);
      expect(style.height, type.mono.height);
      expect(style.fontFamily, type.mono.fontFamily);
      // Format is the kit's small ghost button.
      expect(
        tester.getSize(find.widgetWithText(Button, 'Format')).height,
        defaultTokens.sizes.small,
      );
    });
  });
}
