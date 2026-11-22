// A form's text field in a right-to-left app: an email or a URL is typed
// and shown left to right, with its hint and its fixed prefix and suffix,
// while the label, the message and the counter stay where the page puts
// them. textDirection says so for any other field.

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// An 800×600 app in Arabic, so right to left, or in English with [ltr].
Future<LocalScope> _pump(
  WidgetTester tester,
  Widget Function(LocalScope) field, {
  bool ltr = false,
}) async {
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final scope = LocalScope();
  addTearDown(scope.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      locale: Locale(ltr ? 'en' : 'ar'),
      supportedLocales: AdminLocalizations.supportedLocales,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Center(child: SizedBox(width: 400, child: field(scope))),
      ),
    ),
  );
  return scope;
}

TextDirection _typed(WidgetTester tester) => tester
    .state<EditableTextState>(find.byType(EditableText))
    .renderEditable
    .textDirection;

Rect _input(WidgetTester tester) => tester.getRect(find.byType(TextField));

/// Where [text] is drawn: the box of its glyphs, not of the widget that
/// aligns them in its width.
Rect _text(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(
      // Whatever case the theme draws a label in.
      of: find.byWidgetPredicate(
        (w) => w is Text && w.data?.toLowerCase() == text.toLowerCase(),
      ),
      matching: find.byType(RichText),
    ),
  );
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );
  expect(boxes, isNotEmpty, reason: 'nothing drawn for "$text"');
  final ink = boxes
      .map((b) => b.toRect())
      .reduce((a, b) => a.expandToInclude(b));
  return MatrixUtils.transformRect(paragraph.getTransformTo(null), ink);
}

/// Whether [text] sits in the left half of the input.
bool _atLeft(WidgetTester tester, String text) =>
    _text(tester, text).center.dx < _input(tester).center.dx;

void main() {
  group('in a right-to-left app', () {
    for (final (name, type) in [
      ('an email', TextInputType.emailAddress),
      ('a URL', TextInputType.url),
    ]) {
      testWidgets('$name is typed left to right, from the left', (
        tester,
      ) async {
        await _pump(
          tester,
          (s) => Field(
            s.text('address'),
            label: 'العنوان',
            hint: 'name@example.com',
            keyboardType: type,
          ),
        );
        expect(_typed(tester), TextDirection.ltr);
        final input = _input(tester);
        final hint = _text(tester, 'name@example.com');
        expect(
          hint.left - input.left,
          lessThan(input.right - hint.right),
          reason: 'the hint starts where the address will',
        );

        await tester.enterText(find.byType(EditableText), 'a@b.co');
        await tester.pump();
        final caret = tester
            .state<EditableTextState>(find.byType(EditableText))
            .renderEditable
            .getLocalRectForCaret(const TextPosition(offset: 0));
        final editable = tester.getRect(find.byType(EditableText));
        expect(
          caret.left,
          lessThan(editable.width / 2),
          reason: 'the first letter is at the left',
        );
      });
    }

    testWidgets('the label, the message and the counter of an email field '
        'stay on the page\'s side', (tester) async {
      await _pump(
        tester,
        (s) => Field(
          s.text('email'),
          label: 'البريد',
          keyboardType: TextInputType.emailAddress,
          maxLength: 80,
          errorText: 'غير صالح',
        ),
      );
      expect(_typed(tester), TextDirection.ltr);
      final input = _input(tester);
      expect(_text(tester, 'البريد').center.dx, greaterThan(input.center.dx));
      expect(_text(tester, 'غير صالح').center.dx, greaterThan(input.center.dx));
      expect(_text(tester, '0/80').center.dx, lessThan(input.center.dx));
    });

    testWidgets('the prefix of a URL is at its left, the suffix at its '
        'right, each read left to right', (tester) async {
      await _pump(
        tester,
        (s) => Field(
          s.text('site'),
          label: 'الموقع',
          keyboardType: TextInputType.url,
          prefix: 'https://',
          suffix: '/shop',
        ),
      );
      await tester.enterText(find.byType(EditableText), 'example.com');
      await tester.pump();
      final value = tester.getRect(find.byType(EditableText));
      final prefix = _text(tester, 'https://');
      final suffix = _text(tester, '/shop');
      expect(prefix.right, lessThanOrEqualTo(value.left));
      expect(suffix.left, greaterThanOrEqualTo(value.right));
      // The gap is on the value's side of each.
      expect(value.left - prefix.right, AdminSpacing.xs);
      expect(suffix.left - value.right, AdminSpacing.xs);
      for (final affix in ['https://', '/shop']) {
        expect(
          tester.widget<Text>(find.text(affix)).textDirection,
          TextDirection.ltr,
          reason: affix,
        );
      }
    });

    testWidgets('any other field follows the page, its prefix at the '
        'right', (tester) async {
      await _pump(
        tester,
        (s) => Field(
          s.text('weight'),
          label: 'الوزن',
          hint: 'مثال',
          prefix: 'حوالي',
          suffix: 'كغ',
        ),
      );
      expect(_typed(tester), TextDirection.rtl);
      expect(_atLeft(tester, 'مثال'), isFalse);
      final value = tester.getRect(find.byType(EditableText));
      expect(_text(tester, 'حوالي').left, greaterThanOrEqualTo(value.right));
      expect(_text(tester, 'كغ').right, lessThanOrEqualTo(value.left));
      expect(tester.widget<Text>(find.text('حوالي')).textDirection, isNull);
    });

    testWidgets('textDirection makes any field left to right', (tester) async {
      await _pump(
        tester,
        (s) => Field(
          s.text('sku'),
          label: 'الرمز',
          hint: 'AB-1234',
          textDirection: TextDirection.ltr,
          prefix: 'SKU',
        ),
      );
      expect(_typed(tester), TextDirection.ltr);
      expect(_atLeft(tester, 'AB-1234'), isTrue);
      expect(_atLeft(tester, 'SKU'), isTrue);
    });

    testWidgets('textDirection outranks the keyboard', (tester) async {
      await _pump(
        tester,
        (s) => Field(
          s.text('email'),
          label: 'البريد',
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.rtl,
        ),
      );
      expect(_typed(tester), TextDirection.rtl);
    });

    testWidgets('an optional field and a bare text body do the same', (
      tester,
    ) async {
      await _pump(
        tester,
        (s) => OptionalField(
          s.textOrNull('email'),
          label: 'البريد',
          hint: 'name@example.com',
          keyboardType: TextInputType.emailAddress,
          prefix: 'mailto:',
        ),
      );
      expect(_typed(tester), TextDirection.ltr);
      expect(_atLeft(tester, 'name@example.com'), isTrue);
      expect(_atLeft(tester, 'mailto:'), isTrue);

      await _pump(
        tester,
        (s) => TextBody(
          value: '',
          onChanged: (_) {},
          hint: 'example.com',
          keyboardType: TextInputType.url,
          prefix: 'https://',
        ),
      );
      expect(_typed(tester), TextDirection.ltr);
      expect(_atLeft(tester, 'example.com'), isTrue);
      expect(_atLeft(tester, 'https://'), isTrue);

      await _pump(
        tester,
        (s) => OptionalField(
          s.textOrNull('sku'),
          label: 'الرمز',
          textDirection: TextDirection.ltr,
        ),
      );
      expect(_typed(tester), TextDirection.ltr);
    });
  });

  group('in a left-to-right app', () {
    testWidgets('an email field is as any other: nothing is swapped', (
      tester,
    ) async {
      await _pump(
        tester,
        ltr: true,
        (s) => Field(
          s.text('site'),
          label: 'Site',
          keyboardType: TextInputType.url,
          prefix: 'https://',
          suffix: '/shop',
        ),
      );
      expect(_typed(tester), TextDirection.ltr);
      final value = tester.getRect(find.byType(EditableText));
      expect(_text(tester, 'https://').right, lessThanOrEqualTo(value.left));
      expect(_text(tester, '/shop').left, greaterThanOrEqualTo(value.right));
    });

    testWidgets('a field with no direction passes none on', (tester) async {
      await _pump(
        tester,
        ltr: true,
        (s) => Field(s.text('name'), label: 'Name', prefix: 'Dr'),
      );
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.textDirection, isNull);
      expect(field.decoration!.hintTextDirection, isNull);
      expect(tester.widget<Text>(find.text('Dr')).textDirection, isNull);
    });

    testWidgets('a right-to-left field has its prefix at its right', (
      tester,
    ) async {
      await _pump(
        tester,
        ltr: true,
        (s) => Field(
          s.text('name'),
          label: 'Name',
          hint: 'الاسم',
          textDirection: TextDirection.rtl,
          prefix: 'السيد',
          maxLength: 40,
        ),
      );
      expect(_typed(tester), TextDirection.rtl);
      expect(_atLeft(tester, 'الاسم'), isFalse);
      final value = tester.getRect(find.byType(EditableText));
      expect(_text(tester, 'السيد').left, greaterThanOrEqualTo(value.right));
      // The label and the counter are the page's.
      final input = _input(tester);
      expect(_text(tester, 'Name').center.dx, lessThan(input.center.dx));
      expect(_text(tester, '0/40').center.dx, greaterThan(input.center.dx));
    });
  });

  testWidgets('a plain input field keeps the same rule', (tester) async {
    for (final (type, direction) in [
      (TextInputType.emailAddress, TextDirection.ltr),
      (TextInputType.url, TextDirection.ltr),
      (TextInputType.text, TextDirection.rtl),
      (null, TextDirection.rtl),
    ]) {
      await _pump(tester, (_) => InputField(keyboardType: type));
      expect(_typed(tester), direction, reason: '$type');
    }
    await _pump(
      tester,
      (_) => const InputField(
        keyboardType: TextInputType.emailAddress,
        textDirection: TextDirection.rtl,
      ),
    );
    expect(_typed(tester), TextDirection.rtl);
  });
}
