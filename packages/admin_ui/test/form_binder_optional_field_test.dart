import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<LocalScope> _pump(
  WidgetTester tester,
  List<Widget> Function(LocalScope) fields,
) async {
  final scope = LocalScope();
  addTearDown(scope.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(irisTheme.tokens),
      supportedLocales: AdminLocalizations.supportedLocales,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: fields(scope),
        ),
      ),
    ),
  );
  return scope;
}

Finder _input(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is FieldShell && w.label == label),
  matching: find.byType(TextField),
);

TextStyle _styleOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

void main() {
  testWidgets('counts the characters against maxLength, as Field does', (
    tester,
  ) async {
    final scope = await _pump(
      tester,
      (s) => [
        OptionalField(s.textOrNull('bio'), label: 'Bio', maxLength: 160),
        Field(s.text('title'), label: 'Title', maxLength: 80),
      ],
    );
    expect(find.text('0/160'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).first, 'Hello');
    await tester.pump();
    expect(scope.textOrNull('bio').value, 'Hello');
    expect(find.text('5/160'), findsOneWidget);
    expect(tester.widget<TextField>(_input('Bio')).maxLength, 160);

    expect(_styleOf(tester, '5/160'), _styleOf(tester, '0/80'));
  });

  testWidgets('shows its prefix and suffix, even while empty', (tester) async {
    await _pump(
      tester,
      (s) => [
        OptionalField(
          s.textOrNull('website'),
          label: 'Website',
          prefix: 'https://',
          hint: 'example.com',
        ),
        OptionalField(s.textOrNull('weight'), label: 'Weight', suffix: 'kg'),
        Field(s.text('url'), label: 'Url', prefix: 'ftp://', suffix: 'm'),
      ],
    );

    for (final text in ['https://', 'kg', 'ftp://', 'm']) {
      expect(find.text(text), findsOneWidget);
      expect(
        tester.renderObject<RenderParagraph>(find.text(text)).size.isEmpty,
        isFalse,
        reason: '$text is laid out',
      );
    }
    expect(_styleOf(tester, 'https://'), _styleOf(tester, 'ftp://'));
    expect(_styleOf(tester, 'kg'), _styleOf(tester, 'm'));
    expect(
      tester
          .widget<AnimatedOpacity>(
            find.ancestor(
              of: find.text('https://'),
              matching: find.byType(AnimatedOpacity),
            ),
          )
          .opacity,
      1,
      reason: 'the prefix shows before anything is typed',
    );
  });

  testWidgets('a text area takes a multi-line keyboard and its line bounds', (
    tester,
  ) async {
    await _pump(
      tester,
      (s) => [
        OptionalField(
          s.textOrNull('bio'),
          label: 'Bio',
          minLines: 3,
          maxLines: 6,
        ),
        OptionalField(s.textOrNull('note'), label: 'Note', maxLines: null),
        OptionalField(s.textOrNull('name'), label: 'Name'),
        OptionalField(
          s.textOrNull('email'),
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
      ],
    );

    final bio = tester.widget<TextField>(_input('Bio'));
    expect(bio.keyboardType, TextInputType.multiline);
    expect(bio.minLines, 3);
    expect(bio.maxLines, 6);
    expect(
      tester.widget<TextField>(_input('Note')).keyboardType,
      TextInputType.multiline,
    );
    final name = tester.widget<TextField>(_input('Name'));
    expect(name.keyboardType, TextInputType.text);
    expect(name.maxLines, 1);
    final email = tester.widget<TextField>(_input('Email'));
    expect(email.keyboardType, TextInputType.emailAddress);
    expect(email.autofillHints, [AutofillHints.email]);

    // Three lines tall before anything is typed.
    expect(
      tester.getSize(_input('Bio')).height,
      greaterThan(tester.getSize(_input('Name')).height * 1.8),
    );

    // Enter adds a line rather than submitting.
    await tester.showKeyboard(_input('Bio'));
    await tester.pump();
    expect(
      tester.testTextInput.setClientArgs?['inputType']?['name'],
      'TextInputType.multiline',
    );
    expect(
      tester.testTextInput.setClientArgs?['inputAction'],
      TextInputAction.newline.toString(),
    );
  });

  testWidgets('TextBody takes the same options', (tester) async {
    await _pump(
      tester,
      (s) => [
        FieldShell(
          label: 'Summary',
          child: TextBody(
            value: 'Short',
            onChanged: (_) {},
            minLines: 2,
            maxLines: 4,
            maxLength: 40,
            prefix: '#',
            suffix: 'ok',
          ),
        ),
      ],
    );
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.minLines, 2);
    expect(field.maxLines, 4);
    expect(field.keyboardType, TextInputType.multiline);
    expect(find.text('5/40'), findsOneWidget);
    expect(find.text('#'), findsOneWidget);
    expect(find.text('ok'), findsOneWidget);
  });

  testWidgets('an empty field keeps its prefix 4 from the hint', (
    tester,
  ) async {
    await _pump(
      tester,
      (s) => [
        OptionalField(
          s.textOrNull('site'),
          label: 'Site',
          prefix: 'https://',
          hint: 'example.com',
        ),
      ],
    );
    expect(
      tester.getTopLeft(find.text('example.com')).dx -
          tester.getTopRight(find.text('https://')).dx,
      AdminSpacing.xs,
    );
  });

  testWidgets('a disabled field dims its affixes and counter with its value', (
    tester,
  ) async {
    await _pump(
      tester,
      (s) => [
        OptionalField(
          s.textOrNull('site'),
          label: 'Site',
          prefix: 'https://',
          maxLength: 20,
          enabled: false,
        ),
        OptionalField(
          s.textOrNull('live'),
          label: 'Live',
          prefix: 'http://',
          maxLength: 30,
        ),
      ],
    );
    final colors = tester.element(find.text('https://')).colors;
    expect(_styleOf(tester, 'https://').color, colors.foregroundSubtle);
    expect(_styleOf(tester, '0/20').color, colors.foregroundSubtle);
    // A step above the hint's colour, so an empty field's prefix does not
    // read as more of the hint.
    expect(_styleOf(tester, 'http://').color, colors.foregroundSecondary);
    expect(_styleOf(tester, '0/30').color, colors.foregroundMuted);
  });
}
