import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// One line at 800px, two at 360.
const _short = 'Drafts are saved every thirty seconds.';

const _long =
    'Publishing is paused while the search index rebuilds. Drafts still '
    'save, and everything queued goes live once the rebuild finishes.';

Future<void> _pump(
  WidgetTester tester,
  Widget bar, {
  double width = 360,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(width, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      supportedLocales: AdminLocalizations.supportedLocales,
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Align(alignment: Alignment.topCenter, child: bar),
        ),
      ),
    ),
  );
}

RenderParagraph _paragraph(WidgetTester tester) => tester.renderObject(
  find.descendant(
    of: find.byType(AnnouncementBar),
    matching: find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains('Publishing'),
    ),
  ),
);

Rect _bar(WidgetTester tester) => tester.getRect(find.byType(AnnouncementBar));

Rect _text(WidgetTester tester, String contains) => tester.getRect(
  find.byWidgetPredicate(
    (w) => w is RichText && w.text.toPlainText().contains(contains),
  ),
);

Finder get _icon => find.descendant(
  of: find.byType(AnnouncementBar),
  matching: find.byType(Icon),
);

void main() {
  testWidgets('a long message wraps at 360px, with no ellipsis', (
    tester,
  ) async {
    await _pump(
      tester,
      const AnnouncementBar(_long, title: 'Publishing paused'),
    );
    final paragraph = _paragraph(tester);
    expect(paragraph.maxLines, isNull);
    expect(paragraph.overflow, isNot(TextOverflow.ellipsis));
    expect(paragraph.didExceedMaxLines, isFalse);
    // Three lines or more of 20px at this width.
    expect(_text(tester, 'Publishing').height, greaterThanOrEqualTo(60));
    expect(find.text('Show more'), findsNothing);
  });

  testWidgets('a single-line bar keeps 12px above and below its line, as '
      'tall with its controls as without', (tester) async {
    final heights = <double>[];
    for (final (action, dismiss) in [
      (false, false),
      (false, true),
      (true, false),
      (true, true),
    ]) {
      await _pump(
        tester,
        AnnouncementBar(
          'Saved.',
          action: action
              ? Button('Undo', size: ControlSize.small, onPressed: () {})
              : null,
          onDismiss: dismiss ? () {} : null,
        ),
        width: 800,
      );
      final bar = _bar(tester);
      final text = _text(tester, 'Saved.');
      final icon = tester.getRect(_icon.first);
      expect(text.height, 20, reason: 'one line of body text');
      // The line is the text's and the icon's, both 20px.
      expect(icon.top - bar.top, 12, reason: 'action $action, close $dismiss');
      expect(text.top - bar.top, 12, reason: 'action $action, close $dismiss');
      // Less the 1px rule along the bottom.
      expect(
        bar.bottom - 1 - text.bottom,
        12,
        reason: 'action $action, close $dismiss',
      );
      heights.add(bar.height);
    }
    expect(heights.toSet(), {12 + 20 + 12 + 1});
  });

  for (final direction in TextDirection.values) {
    testWidgets('${direction.name}: the icon, action and close centre on the '
        'first line of a wrapped message', (tester) async {
      await _pump(
        tester,
        AnnouncementBar(
          _long,
          title: 'Publishing paused',
          action: Button('Details', size: ControlSize.small, onPressed: () {}),
          onDismiss: () {},
        ),
        direction: direction,
      );
      final text = _text(tester, 'Publishing');
      expect(text.height, greaterThan(40), reason: 'wrapped');
      final line = text.top + 20 / 2;
      final icon = tester.getRect(_icon.first);
      final action = tester.getRect(find.byType(Button));
      final close = tester.getRect(find.byType(IconAction));
      expect(icon.center.dy, closeTo(line, 0.5));
      expect(action.center.dy, closeTo(line, 0.5));
      expect(close.center.dy, closeTo(line, 0.5));
      expect(text.top - _bar(tester).top, 12);

      final ltr = direction == TextDirection.ltr;
      expect(ltr ? icon.right < text.left : icon.left > text.right, isTrue);
      expect(
        ltr ? close.left > action.right : close.right < action.left,
        isTrue,
      );
    });
  }

  testWidgets('maxLines clips the text behind a Show more toggle on its '
      'first line, which expands and collapses it', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      const AnnouncementBar(_long, title: 'Publishing paused', maxLines: 1),
    );
    await tester.pump();

    var paragraph = _paragraph(tester);
    expect(paragraph.maxLines, 1);
    expect(paragraph.overflow, TextOverflow.ellipsis);
    expect(paragraph.didExceedMaxLines, isTrue);
    final more = find.text('Show more');
    expect(more.hitTestable(), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Show more')),
      isSemantics(
        label: 'Show more',
        isButton: true,
        hasExpandedState: true,
        isExpanded: false,
      ),
    );
    // One line tall, the toggle on it and after the text.
    final bar = _bar(tester);
    expect(bar.height, 12 + 20 + 12 + 1);
    final text = _text(tester, 'Publishing');
    final link = tester.getRect(find.bySemanticsLabel('Show more'));
    expect(link.center.dy, closeTo(text.top + 10, 0.5));
    expect(link.left, greaterThanOrEqualTo(text.right));
    expect(link.right, lessThanOrEqualTo(bar.right - 16));

    // The toggle is a Tab stop once the layout has shown it.
    final linkFocus = Focus.of(tester.element(find.text('Show more')));
    expect(linkFocus.canRequestFocus, isTrue);

    await tester.tap(more);
    await tester.pump();
    paragraph = _paragraph(tester);
    expect(paragraph.maxLines, isNull);
    expect(find.text('Show less'), findsOneWidget);
    expect(_bar(tester).height, greaterThan(12 + 40 + 12));

    await tester.tap(find.text('Show less'));
    await tester.pump();
    expect(_paragraph(tester).maxLines, 1);
    expect(_bar(tester).height, 12 + 20 + 12 + 1);
    handle.dispose();
  });

  testWidgets('a message within maxLines shows no toggle, to the eye, the '
      'pointer, assistive technology or the keyboard', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, const AnnouncementBar(_short, maxLines: 1), width: 800);
    await tester.pump();
    expect(find.text('Show more').hitTestable(), findsNothing);
    expect(find.bySemanticsLabel('Show more'), findsNothing);
    final exclude = tester.widget<ExcludeFocus>(
      find.ancestor(
        of: find.text('Show more'),
        matching: find.byType(ExcludeFocus),
      ),
    );
    expect(exclude.excluding, isTrue);
    final linkFocus = Focus.of(tester.element(find.text('Show more')));
    expect(linkFocus.canRequestFocus, isFalse);
    expect(_bar(tester).height, 12 + 20 + 12 + 1);

    // Narrowed until the message no longer fits, the toggle appears.
    await _pump(tester, const AnnouncementBar(_short, maxLines: 1), width: 360);
    await tester.pump();
    expect(find.text('Show more').hitTestable(), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the toggle reads at 4.5:1 on every severity, in every theme '
      'and brand', (tester) async {
    const brands = [
      null,
      Color(0xFFE11D48),
      Color(0xFF7C3AED),
      Color(0xFF0D9488),
      Color(0xFFD97706),
    ];
    for (final theme in adminThemes) {
      for (final palette in [
        for (final base in [theme.palette, ?theme.darkPalette])
          for (final brand in brands)
            brand == null ? base : base.branded(brand),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(AdminTokens.from(palette: palette)),
            localizationsDelegates: AdminLocalizations.localizationsDelegates,
            supportedLocales: AdminLocalizations.supportedLocales,
            home: Column(
              children: [
                for (final severity in Severity.values)
                  AnnouncementBar(_long, severity: severity, maxLines: 1),
              ],
            ),
          ),
        );
        for (final severity in Severity.values) {
          final bar = find.byWidgetPredicate(
            (widget) =>
                widget is AnnouncementBar && widget.severity == severity,
          );
          final toggle = tester.widget<Text>(
            find.descendant(of: bar, matching: find.text('Show more')),
          );
          final surface = severityStyleOf(
            tester.element(bar),
            severity,
          ).surface;
          expect(
            contrastRatio(toggle.style!.color!, surface),
            greaterThanOrEqualTo(4.5),
            reason: '${theme.name} ${palette.brightness.name} $severity',
          );
        }
      }
    }
  });
}
