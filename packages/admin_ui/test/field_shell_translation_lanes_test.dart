import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _tokens = defaultTokens;
final _p = _tokens.palette;

Widget _host(Widget child, {double width = 640}) => MaterialApp(
  theme: buildAppTheme(_tokens),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: width,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: child,
        ),
      ),
    ),
  ),
);

const _de = LocaleInfo(
  code: 'de',
  native: 'Deutsch',
  status: LocaleStatus.outdated,
);

Widget _lane(
  LocaleInfo lane, {
  Widget? trailing,
  VoidCallback? Function(LocaleInfo lane)? retranslate,
}) => FieldShell(
  label: 'Title',
  mergeSemantics: false,
  child: LaneStack(
    lanes: [lane],
    laneBuilder: (l) => TextBody(value: 'Sommer', onChanged: (_) {}),
    laneTrailing: trailing == null ? null : (_) => trailing,
    retranslate: retranslate,
  ),
);

/// The colour of the text [text] is drawn in.
Color? _colorOf(WidgetTester tester, String text) => tester
    .widget<RichText>(
      find.descendant(of: find.text(text), matching: find.byType(RichText)),
    )
    .text
    .style
    ?.color;

void main() {
  setUp(() {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
  });
  tearDown(() {
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });

  group('LaneStack', () {
    testWidgets('a lone lane keeps its trailing and its outdated banner, and '
        'drops only the box and gutter', (tester) async {
      await tester.pumpWidget(
        _host(_lane(_de, trailing: const Text('actions'))),
      );
      expect(find.text('actions'), findsOneWidget);
      expect(
        find.text('Source changed since this was translated'),
        findsOneWidget,
      );
      expect(find.text('DE'), findsNothing);
      // The trailing sits beside the body, centred on its control row.
      final body = tester.getRect(find.byType(TextField));
      final trailing = tester.getRect(find.text('actions'));
      expect(trailing.left, greaterThan(body.right));
      expect(trailing.center.dy, closeTo(body.center.dy, 0.5));
    });

    testWidgets('a lone lane keeps its focus as it turns outdated', (
      tester,
    ) async {
      const fresh = LocaleInfo(
        code: 'de',
        native: 'Deutsch',
        status: LocaleStatus.translated,
      );
      await tester.pumpWidget(_host(_lane(fresh)));
      await tester.tap(find.byType(TextField));
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus;
      expect(focused, isNotNull);

      await tester.pumpWidget(_host(_lane(_de, trailing: const Text('a'))));
      expect(FocusManager.instance.primaryFocus, same(focused));
    });

    testWidgets('Re-translate calls back with the lane, from the pointer and '
        'the keyboard', (tester) async {
      final calls = <LocaleInfo>[];
      await tester.pumpWidget(
        _host(
          _lane(
            _de,
            retranslate: (lane) =>
                () => calls.add(lane),
          ),
        ),
      );
      await tester.tap(find.text('Re-translate'));
      expect(calls, [_de]);

      // A Tab stop after the lane's input.
      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(calls, [_de, _de]);
    });

    testWidgets('without a callback the banner is a plain warning', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(_lane(_de)));
      expect(
        find.text('Source changed since this was translated'),
        findsOneWidget,
      );
      expect(find.text('Re-translate'), findsNothing);
      handle.dispose();
    });

    testWidgets('the banner wears the outdated colour of its pill', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_lane(_de, retranslate: (_) => () {})));
      expect(
        _colorOf(tester, 'Source changed since this was translated'),
        _p.dangerText,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.sync_problem_rounded)).color,
        _p.dangerText,
      );
    });

    testWidgets('lanes are named by the field and their language', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          FieldShell(
            label: 'Title',
            mergeSemantics: false,
            child: LaneStack(
              lanes: const [
                LocaleInfo(
                  code: 'en',
                  native: 'English',
                  status: LocaleStatus.source,
                ),
                _de,
              ],
              laneBuilder: (l) => TextBody(value: l.code, onChanged: (_) {}),
            ),
          ),
        ),
      );
      final labels = [
        for (final e in find.byType(EditableText).evaluate())
          tester.getSemantics(find.byWidget(e.widget)).label,
      ];
      expect(labels, [
        startsWith('Title, English'),
        startsWith('Title, German'),
      ]);
      handle.dispose();
    });
  });

  group('Status', () {
    testWidgets('needs review is never warning, outdated always danger', (
      tester,
    ) async {
      late BuildContext context;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      final meta = localeStatusMeta(context);
      final review = meta[LocaleStatus.review]!;
      final outdated = meta[LocaleStatus.outdated]!;
      expect(review.color, isNot(_p.warning));
      expect(review.color, _p.info);
      expect(outdated.color, _p.danger);
      expect(outdated.text, _p.dangerText);
    });

    test('LocaleInfo compares by value', () {
      const a = LocaleInfo(
        code: 'fr',
        native: 'Français',
        status: LocaleStatus.missing,
      );
      const b = LocaleInfo(
        code: 'fr',
        native: 'Français',
        status: LocaleStatus.missing,
      );
      const c = LocaleInfo(
        code: 'fr',
        native: 'Français',
        status: LocaleStatus.outdated,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('bind', () {
    const locales = [
      LocaleInfo(code: 'en', native: 'English', status: LocaleStatus.source),
      LocaleInfo(
        code: 'fr',
        native: 'Français',
        status: LocaleStatus.translated,
      ),
    ];

    testWidgets('LangScope rebuilds the lanes when only a status changes', (
      tester,
    ) async {
      var builds = 0;
      // One child instance throughout, so only a notification rebuilds it.
      final child = Builder(
        builder: (context) {
          LangScope.of(context);
          builds++;
          return const SizedBox();
        },
      );
      Widget scope(List<LocaleInfo> locales, {String source = 'en'}) => _host(
        LangScope(
          locales: locales,
          visibleLocales: {'en', 'fr'},
          sourceLocale: source,
          activeLocale: 'fr',
          onVisibleLocalesChanged: (_) {},
          child: child,
        ),
      );
      await tester.pumpWidget(scope([...locales]));
      expect(builds, 1);
      // Equal content, new instances: nothing to redraw.
      await tester.pumpWidget(scope([...locales]));
      expect(builds, 1);
      await tester.pumpWidget(
        scope([
          locales.first,
          const LocaleInfo(
            code: 'fr',
            native: 'Français',
            status: LocaleStatus.outdated,
          ),
        ]),
      );
      expect(builds, 2);
      await tester.pumpWidget(scope([...locales], source: 'fr'));
      expect(builds, 3);
    });
  });
}
