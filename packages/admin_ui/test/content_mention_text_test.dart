import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _names = {'u1': 'Alice Martin', 'u2': 'Bea Stone'};

String _nameOf(String id) => _names[id] ?? 'Someone';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(irisTheme.tokens),
  home: Scaffold(body: Center(child: child)),
);

/// The spans of the one [MentionText] on screen, as (text, style) pairs.
List<(String, TextStyle?)> _spans(WidgetTester tester) {
  final text = tester.widget<Text>(
    find.descendant(of: find.byType(MentionText), matching: find.byType(Text)),
  );
  final root = text.textSpan! as TextSpan;
  return [
    for (final span in root.children!.cast<TextSpan>())
      (span.text!, span.style),
  ];
}

void main() {
  testWidgets('draws each mention as @Name in the link colour, strong', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const MentionText('Ask <@u1> and <@u2> about <@u9>.', nameOf: _nameOf),
      ),
    );
    final tokens = irisTheme.tokens;
    final spans = _spans(tester);
    expect(
      [for (final (text, _) in spans) text],
      [
        'Ask ',
        '@Alice Martin',
        ' and ',
        '@Bea Stone',
        ' about ',
        '@Someone',
        '.',
      ],
    );
    for (final (text, style) in spans) {
      if (text.startsWith('@')) {
        expect(style?.color, tokens.palette.primaryText, reason: text);
        expect(
          style?.fontWeight,
          tokens.typography
              .weighted(tokens.typography.body, tokens.typography.spec.strong)
              .fontWeight,
          reason: text,
        );
      } else {
        expect(style, isNull, reason: 'plain text takes the base style');
      }
    }
    expect(
      find.text('Ask @Alice Martin and @Bea Stone about @Someone.'),
      findsOneWidget,
    );
  });

  testWidgets('a body with no mention is one plain run', (tester) async {
    await tester.pumpWidget(
      _host(const MentionText('Nothing to see', nameOf: _nameOf)),
    );
    expect(_spans(tester), [('Nothing to see', null)]);
  });

  testWidgets('the given style is the base, mentions keep their colour', (
    tester,
  ) async {
    const base = TextStyle(fontSize: 11, color: Color(0xFF123456));
    await tester.pumpWidget(
      _host(const MentionText('Hi <@u2>', nameOf: _nameOf, style: base)),
    );
    final text = tester.widget<Text>(
      find.descendant(
        of: find.byType(MentionText),
        matching: find.byType(Text),
      ),
    );
    expect(text.textSpan!.style, base);
    final (_, mention) = _spans(tester).last;
    expect(mention?.fontSize, 11);
    expect(mention?.color, irisTheme.tokens.palette.primaryText);
  });

  group('a mention stands apart from the text around it', () {
    Future<void> pump(WidgetTester tester, AdminTokens tokens) =>
        tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(tokens),
            themeAnimationDuration: Duration.zero,
            home: const Scaffold(
              body: Center(
                child: MentionText('Ask <@u1> now', nameOf: _nameOf),
              ),
            ),
          ),
        );

    testWidgets('on a chip, a wash of the link colour, where that colour '
        'reads as the text\'s', (tester) async {
      for (final tokens in [
        shadcnTheme.tokens,
        shadcnTheme.dark!,
        materialTheme.dark!,
      ]) {
        await pump(tester, tokens);
        final p = tokens.palette;
        expect(
          find.byType(MentionText),
          paints..rrect(
            color: p.primaryText.withValues(alpha: p.stateLayer.selected),
          ),
        );
      }
    });

    testWidgets('in the link colour alone where it reads apart', (
      tester,
    ) async {
      for (final tokens in [
        irisTheme.tokens,
        shadcnTheme.tokens.branded(const Color(0xFFE11D48)),
      ]) {
        await pump(tester, tokens);
        expect(find.byType(MentionText), isNot(paints..rrect()));
      }
    });
  });

  group('selection', () {
    testWidgets('selectable on its own', (tester) async {
      await tester.pumpWidget(
        _host(const MentionText('Hi <@u1>', nameOf: _nameOf)),
      );
      expect(
        find.ancestor(
          of: find.byType(Text),
          matching: find.byType(SelectionArea),
        ),
        findsOneWidget,
      );
    });

    testWidgets('joins an enclosing SelectionArea rather than nest one', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SelectionArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MentionText('One <@u1>', nameOf: _nameOf),
                MentionText('Two <@u2>', nameOf: _nameOf),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(SelectionArea), findsOneWidget);
    });

    testWidgets('selectable: false leaves plain text, for a tappable row', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          GestureDetector(
            onTap: () => taps++,
            child: const MentionText(
              'Hi <@u1>',
              nameOf: _nameOf,
              selectable: false,
            ),
          ),
        ),
      );
      expect(find.byType(SelectionArea), findsNothing);
      await tester.tap(find.byType(MentionText));
      expect(taps, 1);
    });
  });

  testWidgets('reads as the text, mentions by name', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(const MentionText('Ask <@u1>', nameOf: _nameOf, selectable: false)),
    );
    expect(find.bySemanticsLabel('Ask @Alice Martin'), findsOneWidget);
    semantics.dispose();
  });
}
