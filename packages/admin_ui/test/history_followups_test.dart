import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The theme called [name], with its label casing but not its font.
AdminTokens _tokens(String name) {
  final theme = adminThemes.firstWhere((t) => t.name == name);
  final source = theme.tokens;
  return AdminTokens.from(
    palette: source.palette,
    radii: source.radii,
    focus: source.focus,
    type: AdminTypeSpec(
      uppercaseLabels: source.typography.spec.uppercaseLabels,
    ),
  );
}

Widget _host(Widget child, {String admin = 'en', AdminTokens? tokens}) =>
    MaterialApp(
      theme: buildAppTheme(tokens ?? defaultTokens),
      locale: Locale(admin),
      supportedLocales: AdminLocalizations.supportedLocales,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Align(alignment: Alignment.topCenter, child: child),
      ),
    );

const _base = VersionRef(
  id: 'v1',
  label: 'Trimmed intro',
  author: 'Ada Park',
  initials: 'AP',
  timestamp: '2 hours ago',
  status: VersionStatus.published,
);
const _draft = VersionRef(
  id: 'draft',
  label: 'Working draft',
  author: 'You',
  initials: 'YO',
  timestamp: 'just now',
  status: VersionStatus.draft,
);

const _english = LocaleDiff(
  locale: 'en',
  op: DiffOp.changed,
  before: 'Ship fast.',
  after: 'Ship faster.',
);
const _arabic = LocaleDiff(
  locale: 'ar',
  op: DiffOp.changed,
  before: 'أهلا',
  after: 'أهلا بكم.',
);

VersionDiff _diff(
  List<LocaleDiff> lanes, {
  bool translatable = true,
  DiffFieldKind kind = DiffFieldKind.text,
}) => VersionDiff(
  base: _base,
  compare: _draft,
  locales: [for (final l in lanes) l.locale],
  fields: [
    FieldDiff(
      label: 'Summary',
      fieldKey: 'summary',
      kind: kind,
      translatable: translatable,
      locales: lanes,
    ),
  ],
);

Future<void> _pumpDiff(
  WidgetTester tester,
  VersionDiff diff, {
  required String admin,
  DiffLayout layout = DiffLayout.unified,
}) async {
  tester.view.physicalSize = const Size(1000, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _host(
      SizedBox(
        width: 900,
        height: 700,
        child: DiffView(diff: diff, initialLayout: layout),
      ),
      admin: admin,
    ),
  );
  await tester.pumpAndSettle();
}

/// The paragraph whose visible text (not what a screen reader hears)
/// contains [text].
Finder _text(String text) => find.byWidgetPredicate(
  (w) =>
      w is RichText &&
      w.text.toPlainText(includeSemanticsLabels: false).contains(text),
);

RenderParagraph _paragraph(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(_text(text));

String _visible(RenderParagraph paragraph) =>
    paragraph.text.toPlainText(includeSemanticsLabels: false);

/// The global box of the character at [index] of [paragraph]'s text.
Rect _glyph(RenderParagraph paragraph, int index) {
  final box = paragraph
      .getBoxesForSelection(
        TextSelection(baseOffset: index, extentOffset: index + 1),
      )
      .single
      .toRect();
  return box.shift(paragraph.localToGlobal(Offset.zero));
}

/// The first and last characters of [paragraph]'s text, laid out.
(Rect, Rect) _ends(RenderParagraph paragraph) {
  final length = _visible(paragraph).length;
  return (_glyph(paragraph, 0), _glyph(paragraph, length - 1));
}

void main() {
  group('diff lanes keep their language direction', () {
    testWidgets('an English lane in an Arabic admin runs left to right, its '
        'period at the end', (tester) async {
      await _pumpDiff(tester, _diff([_english]), admin: 'ar');

      final paragraph = _paragraph(tester, 'Ship');
      expect(paragraph.textDirection, TextDirection.ltr);
      final (first, last) = _ends(paragraph);
      expect(_visible(paragraph), endsWith('.'));
      expect(last.left, greaterThan(first.right));
      // The content starts at its own (left) edge, while its locale tag, the
      // lane's chrome, keeps the admin's start (right).
      final tag = tester.getRect(find.text('EN'));
      expect(first.left, lessThan(tag.left));
      expect(first.left, lessThan(450));
      expect(
        tester.renderObject<RenderParagraph>(find.text('EN')).textDirection,
        TextDirection.rtl,
      );
      expect(
        Localizations.localeOf(tester.element(_text('Ship'))).languageCode,
        'en',
      );
    });

    testWidgets('an Arabic lane in an English admin runs right to left', (
      tester,
    ) async {
      await _pumpDiff(tester, _diff([_arabic]), admin: 'en');

      final paragraph = _paragraph(tester, 'أهلا');
      expect(paragraph.textDirection, TextDirection.rtl);
      final (first, last) = _ends(paragraph);
      // The logical end — the period — is drawn leftmost.
      expect(last.right, lessThan(first.left));
      final tag = tester.getRect(find.text('AR'));
      expect(first.right, greaterThan(tag.right));
      expect(first.right, greaterThan(450));
    });

    testWidgets('a value that is not per language keeps the admin direction', (
      tester,
    ) async {
      await _pumpDiff(
        tester,
        _diff([
          const LocaleDiff(
            locale: '',
            op: DiffOp.changed,
            before: 'Ship fast.',
            after: 'Ship faster.',
          ),
        ], translatable: false),
        admin: 'ar',
      );
      expect(_paragraph(tester, 'Ship').textDirection, TextDirection.rtl);
    });

    testWidgets('split, the before column keeps the admin start while each '
        'side reads in its language', (tester) async {
      await _pumpDiff(
        tester,
        _diff([_english]),
        admin: 'ar',
        layout: DiffLayout.split,
      );
      final before = _paragraph(tester, 'Ship fast.');
      final after = _paragraph(tester, 'faster.');
      expect(before.textDirection, TextDirection.ltr);
      expect(after.textDirection, TextDirection.ltr);
      final beforeLeft = before.localToGlobal(Offset.zero).dx;
      final afterLeft = after.localToGlobal(Offset.zero).dx;
      expect(beforeLeft, greaterThan(afterLeft));
    });

    testWidgets('a rich lane lays out its block text in the language, its '
        'marker and labels in the admin direction', (tester) async {
      await _pumpDiff(
        tester,
        _diff([
          const LocaleDiff(
            locale: 'en',
            op: DiffOp.changed,
            blocks: [
              BlockChange(
                id: 'p1',
                type: 'paragraph',
                op: DiffOp.added,
                after: 'No card needed.',
              ),
              BlockChange(
                id: 'p2',
                type: 'paragraph',
                op: DiffOp.changed,
                before: 'Plans for teams.',
                after: 'Plans for every team.',
              ),
            ],
          ),
        ], kind: DiffFieldKind.richText),
        admin: 'ar',
      );

      final added = _paragraph(tester, 'No card needed.');
      expect(added.textDirection, TextDirection.ltr);
      final (first, last) = _ends(added);
      expect(last.left, greaterThan(first.right));
      expect(first.left, lessThan(450));

      final changed = _paragraph(tester, 'Plans for');
      expect(changed.textDirection, TextDirection.ltr);
      expect(_ends(changed).$2.left, greaterThan(_ends(changed).$1.right));

      for (final label in _text('Paragraph').evaluate()) {
        final paragraph = label.renderObject! as RenderParagraph;
        expect(paragraph.textDirection, TextDirection.rtl);
      }
    });

    testWidgets('the quick diff lays out a lane in its language', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 360,
            child: FieldQuickDiff(
              FieldDiff(
                label: 'Summary',
                fieldKey: 'summary',
                kind: DiffFieldKind.text,
                translatable: true,
                locales: [_english, _arabic],
              ),
            ),
          ),
          admin: 'ar',
        ),
      );
      await tester.pumpAndSettle();

      final english = _paragraph(tester, 'Ship');
      expect(english.textDirection, TextDirection.ltr);
      final (first, last) = _ends(english);
      expect(last.left, greaterThan(first.right));
      expect(_paragraph(tester, 'أهلا').textDirection, TextDirection.rtl);
    });

    testWidgets('a block quick diff takes its language', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 360,
            child: QuickDiffSurface(
              child: BlockQuickDiff(
                BlockChange(
                  id: 'p1',
                  type: 'paragraph',
                  op: DiffOp.changed,
                  before: 'Plans for teams.',
                  after: 'Plans for every team.',
                ),
                language: 'en',
              ),
            ),
          ),
          admin: 'ar',
        ),
      );
      await tester.pumpAndSettle();
      expect(_paragraph(tester, 'Plans for').textDirection, TextDirection.ltr);
    });
  });

  group('muted text on a tinted row', () {
    const rail = [
      _draft,
      VersionRef(
        id: 'v2',
        label: 'Reordered sections',
        author: 'You',
        initials: 'YO',
        timestamp: 'yesterday',
        status: VersionStatus.published,
      ),
      _base,
      VersionRef(
        id: 'v0',
        label: 'Initial publish',
        author: 'Ada Park',
        initials: 'AP',
        timestamp: 'last week',
        status: VersionStatus.published,
      ),
    ];

    for (final theme in ['Iris', 'shadcn', 'Ant']) {
      testWidgets('$theme Light: the timeline caption reads on an endpoint '
          'and under the pointer', (tester) async {
        final tokens = _tokens(theme);
        final p = tokens.palette;
        await tester.pumpWidget(
          _host(
            SizedBox(
              width: 320,
              height: 420,
              child: VersionTimeline(
                versions: rail,
                baseId: _base.id,
                compareId: _draft.id,
                onTap: (_) {},
              ),
            ),
            tokens: tokens,
          ),
        );
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(tester.getCenter(find.text('Initial publish')));
        await tester.pumpAndSettle();

        // The caption's worst contrast on its row's fill, over either page
        // colour.
        double worst(String label, String caption) {
          final row = tester
              .widgetList<Container>(
                find.ancestor(
                  of: find.text(label),
                  matching: find.byType(Container),
                ),
              )
              .firstWhere((c) => c.color != null);
          final ink = tester.widget<Text>(find.text(caption)).style!.color!;
          return [p.surface, p.background]
              .map(
                (page) =>
                    contrastRatio(ink, Color.alphaBlend(row.color!, page)),
              )
              .reduce((a, b) => a < b ? a : b);
        }

        expect(
          worst('Working draft', 'You · just now'),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          worst('Trimmed intro', 'Ada Park · 2 hours ago'),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          worst('Initial publish', 'Ada Park · last week'),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });

  group('capability popover headings follow the theme casing', () {
    const versions = [
      FieldVersion(
        label: 'Published v3',
        author: 'Ada Park',
        initials: 'AP',
        color: Color(0xFF9333A8),
        time: 'Yesterday',
      ),
    ];
    const messages = [
      CommentEntry(
        author: 'Lena',
        initials: 'LF',
        color: Color(0xFFD97706),
        time: '14m',
        body: 'Love this headline.',
      ),
      CommentEntry(
        author: 'Diego',
        initials: 'DR',
        color: Color(0xFF0F9D8F),
        time: '6m',
        body: 'Agreed.',
      ),
    ];

    for (final (theme, capitals) in [('Fluent', false), ('Iris', true)]) {
      String cased(String text) => capitals ? text.toUpperCase() : text;

      testWidgets('$theme: version history', (tester) async {
        await tester.pumpWidget(
          _host(
            const HistoryButton(
              draft: 'new draft',
              baseline: 'old published',
              versions: versions,
              onRevert: _noop,
            ),
            tokens: _tokens(theme),
          ),
        );
        await tester.tap(find.byType(HistoryButton));
        await tester.pumpAndSettle();

        expect(find.text(cased('Version history')), findsOneWidget);
        expect(find.text(cased('Pending edit')), findsOneWidget);
        // Capitals are for the eye: a screen reader gets the words as written.
        expect(
          tester
              .widget<Text>(find.text(cased('Version history')))
              .semanticsLabel,
          'Version history',
        );
      });

      testWidgets('$theme: comments', (tester) async {
        await tester.pumpWidget(
          _host(
            const CommentsButton(
              count: 2,
              messages: messages,
              onResolve: _noop,
            ),
            tokens: _tokens(theme),
          ),
        );
        await tester.tap(find.byType(CommentsButton));
        await tester.pumpAndSettle();

        expect(find.text(cased('Comments · 2')), findsOneWidget);
      });

      testWidgets('$theme: quick diff title', (tester) async {
        await tester.pumpWidget(
          _host(
            const QuickDiffSurface(title: 'Summary', child: SizedBox()),
            tokens: _tokens(theme),
          ),
        );
        expect(find.text(cased('Summary')), findsOneWidget);
      });
    }

    testWidgets('both headings share one style and inset', (tester) async {
      Future<(TextStyle, Offset)> heading(Widget button, String text) async {
        await tester.pumpWidget(_host(button, tokens: _tokens('Fluent')));
        await tester.tap(find.byWidget(button));
        await tester.pumpAndSettle();
        final style = tester.widget<Text>(find.text(text)).style!;
        final inset =
            tester.getTopLeft(find.text(text)) -
            tester.getTopLeft(find.byType(PopoverMenuSurface));
        return (style, inset);
      }

      const history = HistoryButton(
        draft: 'new draft',
        baseline: 'old published',
        versions: versions,
      );
      const comments = CommentsButton(
        count: 2,
        messages: messages,
        onResolve: _noop,
      );
      final (historyStyle, historyInset) = await heading(
        history,
        'Version history',
      );
      final (commentsStyle, commentsInset) = await heading(
        comments,
        'Comments · 2',
      );
      expect(commentsStyle, historyStyle);
      expect(commentsInset, historyInset);
    });
  });
}

void _noop() {}
