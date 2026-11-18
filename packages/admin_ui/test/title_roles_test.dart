import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// The large titles as the widgets draw them: a Modal's on the theme's dialog
// title, a PageHeader's and a StatCard's value on its page title, both at
// the theme's title weight. `core_type_roles_test.dart` holds the tokens.

/// Each shipped theme's page title and dialog title, as size/line, and the
/// weight of both, from its reference.
const _expected =
    <String, ({String pageTitle, String dialogTitle, FontWeight title})>{
      'Iris': (
        pageTitle: '22/28',
        dialogTitle: '16/24',
        title: FontWeight.w700,
      ),
      // headlineSmall, for a page and for a dialog's headline: Regular
      'Material': (
        pageTitle: '24/32',
        dialogTitle: '24/32',
        title: FontWeight.w400,
      ),
      // DialogTitle: text-lg font-semibold
      'shadcn': (
        pageTitle: '24/32',
        dialogTitle: '18/28',
        title: FontWeight.w600,
      ),
      // a modal's title: heading 5 at fontWeightStrong
      'Ant': (pageTitle: '20/28', dialogTitle: '16/24', title: FontWeight.w600),
      // title3; DialogTitle: subtitle1
      'Fluent': (
        pageTitle: '24/32',
        dialogTitle: '20/28',
        title: FontWeight.w600,
      ),
      // heading-04; a modal's heading-03: both regular
      'Carbon': (
        pageTitle: '28/36',
        dialogTitle: '20/28',
        title: FontWeight.w400,
      ),
    };

String _line(TextStyle style) =>
    '${style.fontSize!.round()}/${(style.fontSize! * style.height!).round()}';

Widget _host(AdminTokens tokens, Widget child) => MaterialApp(
  theme: buildAppTheme(tokens),
  supportedLocales: AdminLocalizations.supportedLocales,
  localizationsDelegates: AdminLocalizations.localizationsDelegates,
  home: Scaffold(
    body: Center(child: SizedBox(width: 480, child: child)),
  ),
);

/// The style [text] is drawn in.
TextStyle _styleOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

void main() {
  test('each shipped theme has an expectation', () {
    expect(_expected.keys.toSet(), {for (final t in adminThemes) t.name});
  });

  for (final theme in adminThemes) {
    testWidgets('${theme.name}: a modal is titled in the dialog title', (
      tester,
    ) async {
      final tokens = theme.tokens;
      await tester.pumpWidget(
        _host(
          tokens,
          Modal(
            title: 'Delete page?',
            message: 'It cannot be restored.',
            onDismiss: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final want = _expected[theme.name]!;
      final style = _styleOf(tester, 'Delete page?');
      expect(style, tokens.typography.dialogTitle);
      expect(_line(style), want.dialogTitle);
      expect(style.fontWeight, want.title);

      // The title is one line of that height, and the close button is
      // centred on it.
      final title = tester.getRect(find.text('Delete page?'));
      expect(title.height, style.fontSize! * style.height!);
      final close = tester.getRect(find.byType(IconAction));
      expect(close.center.dy, closeTo(title.center.dy, 0.5));
    });

    testWidgets('${theme.name}: a page is titled in the title weight', (
      tester,
    ) async {
      final tokens = theme.tokens;
      await tester.pumpWidget(_host(tokens, const PageHeader('Orders')));
      await tester.pumpAndSettle();
      final style = _styleOf(tester, 'Orders');
      expect(style.fontWeight, _expected[theme.name]!.title);
      expect(_line(style), _expected[theme.name]!.pageTitle);
    });
  }

  testWidgets('a modal gives a title with no line of its own a fixed one', (
    tester,
  ) async {
    const bare = TextStyle(fontSize: 20, fontWeight: FontWeight.w600);
    final tokens = defaultTokens.copyWith(
      typography: AdminTypography(
        sizeDisplayLarge: 36,
        sizeDisplayMedium: 28,
        sizeDisplaySmall: 24,
        sizeHeadlineMedium: 20,
        sizeHeadlineSmall: 18,
        sizeTitleLarge: 18,
        fieldLabel: defaultTokens.typography.fieldLabel,
        fieldText: defaultTokens.typography.fieldText,
        fieldMessage: defaultTokens.typography.fieldMessage,
        pageTitle: defaultTokens.typography.pageTitle,
        heading: bare,
        sectionLabel: defaultTokens.typography.sectionLabel,
        body: defaultTokens.typography.body,
        bodyStrong: defaultTokens.typography.bodyStrong,
        bodyMuted: defaultTokens.typography.bodyMuted,
        bodySmall: defaultTokens.typography.bodySmall,
        caption: defaultTokens.typography.caption,
        micro: defaultTokens.typography.micro,
        button: defaultTokens.typography.button,
        spec: const AdminTypeSpec(),
      ),
    );
    await tester.pumpWidget(
      _host(tokens, Modal(title: 'Delete page?', onDismiss: () {})),
    );
    await tester.pumpAndSettle();

    final style = _styleOf(tester, 'Delete page?');
    expect(style.fontSize, 20);
    expect(style.height, 1.5);
    expect(style.leadingDistribution, TextLeadingDistribution.even);
    final title = tester.getRect(find.text('Delete page?'));
    expect(title.height, 30);
    final close = tester.getRect(find.byType(IconAction));
    expect(close.center.dy, closeTo(title.center.dy, 0.5));
  });

  testWidgets('a modal\'s title line grows with the text scale', (
    tester,
  ) async {
    final tokens = fluentTheme.tokens;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(800, 600),
          textScaler: TextScaler.linear(2),
        ),
        // Short enough for one line at twice the size.
        child: _host(tokens, Modal(title: 'Delete?', onDismiss: () {})),
      ),
    );
    await tester.pumpAndSettle();
    final title = tester.getRect(find.text('Delete?'));
    expect(title.height, 56);
    final close = tester.getRect(find.byType(IconAction));
    expect(close.center.dy, closeTo(title.center.dy, 0.5));
  });

  testWidgets('a stat card\'s value follows the page title', (tester) async {
    for (final theme in [irisTheme, materialTheme, carbonTheme]) {
      await tester.pumpWidget(
        _host(theme.tokens, const StatCard(label: 'Revenue', value: '1,204')),
      );
      await tester.pumpAndSettle();
      expect(
        _styleOf(tester, '1,204').fontWeight,
        _expected[theme.name]!.title,
        reason: theme.name,
      );
    }
  });
}
