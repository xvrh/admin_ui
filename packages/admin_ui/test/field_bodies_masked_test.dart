import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Drive a formatter the way a TextField would: from [before] to [after] with
/// the caret at [cursor] in the [after] string. Returns the reformatted result.
TextEditingValue _edit(
  MaskFormatter f,
  String before,
  String after,
  int cursor,
) {
  return f.formatEditUpdate(
    TextEditingValue(
      text: before,
      selection: TextSelection.collapsed(offset: before.length),
    ),
    TextEditingValue(
      text: after,
      selection: TextSelection.collapsed(offset: cursor),
    ),
  );
}

void main() {
  group('apply / unmask', () {
    test('formats a raw payload through the mask', () {
      expect(
        MaskFormatter.apply(Masks.phoneUS, '5551234567'),
        '(555) 123-4567',
      );
      expect(MaskFormatter.apply(Masks.date, '12312024'), '12/31/2024');
      expect(
        MaskFormatter.apply(Masks.creditCard, '4242424242424242'),
        '4242 4242 4242 4242',
      );
    });

    test('drops characters that overflow the mask', () {
      expect(MaskFormatter.apply(Masks.time, '12345'), '12:34');
    });

    test('drops characters that do not fit the next slot', () {
      // Letters can't fill digit slots.
      expect(
        MaskFormatter.apply(Masks.phoneUS, '55ab5512345'),
        '(555) 512-345',
      );
    });

    test('honours literals via backslash escape', () {
      expect(MaskFormatter.apply(Masks.hexColor, 'ff8800'), '#ff8800');
      // A typed '#' is a literal that gets re-inserted, not a payload char.
      expect(MaskFormatter.apply(Masks.hexColor, '#ff8800'), '#ff8800');
    });

    test('mixed letter/digit mask', () {
      expect(MaskFormatter.apply('AAA-####', 'xyz1234'), 'xyz-1234');
    });

    test('unmask recovers the raw payload', () {
      expect(
        MaskFormatter.unmask(Masks.phoneUS, '(555) 123-4567'),
        '5551234567',
      );
      expect(MaskFormatter.unmask(Masks.hexColor, '#ff8800'), 'ff8800');
    });

    test('template renders tokens as fill characters', () {
      expect(MaskFormatter(Masks.phoneUS).template(), '(___) ___-____');
      expect(MaskFormatter(Masks.hexColor).template(), '#______');
    });
  });

  group('live editing', () {
    final phone = MaskFormatter(Masks.phoneUS);

    test('typing the first digit inserts the leading literal', () {
      final r = _edit(phone, '', '5', 1);
      expect(r.text, '(5');
      expect(r.selection.baseOffset, 2);
    });

    test('separator appears only once the next digit arrives', () {
      // Three digits: no dangling ") " yet.
      var r = _edit(phone, '(55', '(555', 4);
      expect(r.text, '(555');
      expect(r.selection.baseOffset, 4);
      // The fourth digit pulls in the ") " between the groups.
      r = _edit(phone, '(555', '(5556', 5);
      expect(r.text, '(555) 6');
      expect(r.selection.baseOffset, 7);
    });

    test('pasting a raw number reflows and lands the caret at the end', () {
      final r = _edit(phone, '', '5551234567', 10);
      expect(r.text, '(555) 123-4567');
      expect(r.selection.baseOffset, 14);
    });

    test(
      'inserting in the middle keeps the caret after the inserted digit',
      () {
        // "(555) 123-4567" with a 9 typed after the "(5" → caret was at 3.
        final r = _edit(phone, '(555) 123-4567', '(5955) 123-4567', 3);
        expect(r.text, '(595) 512-3456'); // 7 leftmost digits kept, rest reflow
        expect(r.selection.baseOffset, 3);
      },
    );

    test('deleting the last digit drops the now-trailing separator', () {
      // "12/3" → delete the 3 → "12" with the slash peeled off (not sticky).
      final date = MaskFormatter(Masks.date);
      final r = _edit(date, '12/3', '12/', 3);
      expect(r.text, '12');
      expect(r.selection.baseOffset, 2);
    });

    test('clearing to empty stays empty (no literals resurface)', () {
      final r = _edit(phone, '(5', '(', 1);
      expect(r.text, '');
      expect(r.selection.baseOffset, 0);
    });
  });

  group('eager separators', () {
    final time = MaskFormatter(Masks.time, eager: true);

    test(
      'completing a group reveals the separator with the caret after it',
      () {
        final r = _edit(time, '1', '15', 2);
        expect(r.text, '15:');
        expect(r.selection.baseOffset, 3);
      },
    );

    test('apply eagerly trails the separator at a group boundary', () {
      expect(MaskFormatter.apply(Masks.time, '15', eager: true), '15:');
      expect(MaskFormatter.apply(Masks.phoneUS, '555', eager: true), '(555) ');
    });

    test('a mid-group value gets no trailing separator', () {
      final r = _edit(time, '1', '1', 1);
      expect(r.text, '1');
    });

    test('backspacing the eager separator deletes the digit before it', () {
      // "15:" → backspace → "1": the auto colon isn't independently deletable,
      // so it eats the "5" rather than just dropping the colon (which would
      // leave "15" looking unchanged) or trapping the caret on the colon.
      final r = _edit(time, '15:', '15', 2);
      expect(r.text, '1');
      expect(r.selection.baseOffset, 1);
    });

    test('backspacing a separator mid-string deletes the digit before it', () {
      // Caret just after the colon → the "5" is eaten (rest reflows), rather
      // than the colon getting re-inserted and the caret trapped on it.
      final r = _edit(time, '15:30', '1530', 2);
      expect(r.text, '13:0');
      expect(r.selection.baseOffset, 1);
    });

    test('typing past the separator fills the next group', () {
      final r = _edit(time, '15:', '15:3', 4);
      expect(r.text, '15:3');
      expect(r.selection.baseOffset, 4);
    });
  });

  group('ghost mask overlay', () {
    String? ghostOf(WidgetTester tester) {
      for (final rt in tester.widgetList<RichText>(find.byType(RichText))) {
        final s = rt.text.toPlainText();
        if (s.contains('_')) return s;
      }
      return null;
    }

    testWidgets('shows the full template when empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MaskedBody(mask: Masks.date, ghostMask: true)),
        ),
      );
      expect(ghostOf(tester), '__/__/____');
    });

    testWidgets('keeps the field its own rounded, filled chrome', (
      tester,
    ) async {
      // Regression: the chrome must come from the TextField itself (rounded
      // OutlineInputBorder + fill), not a square wrapper that clips the corners.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MaskedBody(mask: Masks.date, ghostMask: true)),
        ),
      );
      final deco = tester.widget<TextField>(find.byType(TextField)).decoration!;
      expect(deco.filled, isTrue);
      expect(deco.border, isA<OutlineInputBorder>());
    });

    testWidgets('renders typed value plus the remaining ghost suffix', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MaskedBody(mask: Masks.date, value: '12', ghostMask: true),
          ),
        ),
      );
      // Typed "12" then the grey "/__/____" tail — same paragraph, aligned.
      expect(ghostOf(tester), '12/__/____');
    });
  });
}
