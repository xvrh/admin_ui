import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  AdminTokens? tokens,
  double textScale = 1,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: tokens == null ? null : buildAppTheme(tokens),
      locale: locale,
      supportedLocales: AdminLocalizations.supportedLocales,
      localizationsDelegates: AdminLocalizations.localizationsDelegates,
      home: MediaQuery.withClampedTextScaling(
        minScaleFactor: textScale,
        maxScaleFactor: textScale,
        child: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: 720, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// A loaded card with every row, beside the same card loading.
Widget _pair({String loadingLabel = 'Revenue', IconData? icon}) => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(
      child: StatCard(
        key: const ValueKey('loaded'),
        label: 'Revenue',
        value: r'$48.2k',
        icon: icon,
        delta: const StatDelta('12%'),
        caption: 'vs last month',
      ),
    ),
    const SizedBox(width: 16),
    Expanded(
      child: StatCard(
        key: const ValueKey('loading'),
        label: loadingLabel,
        icon: icon,
        loading: true,
      ),
    ),
  ],
);

double _height(WidgetTester tester, String key) =>
    tester.getSize(find.byKey(ValueKey(key))).height;

void main() {
  test('only a loading card may leave out its label and value', () {
    final revenue = 'Revenue', figure = r'$48.2k';
    expect(() => StatCard(label: revenue), throwsAssertionError);
    expect(() => StatCard(value: figure), throwsAssertionError);
    expect(StatCard(label: revenue, loading: true).value, isEmpty);
  });

  group('StatCard(loading: true)', () {
    final themes = {
      for (final theme in adminThemes) ...{
        '${theme.name} Light': theme.tokens,
        '${theme.name} Dark': theme.dark!,
      },
      'default tokens': defaultTokens,
    };
    for (final MapEntry(key: name, value: tokens) in themes.entries) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'is exactly as tall as a loaded card: $name, text x$scale',
          (tester) async {
            for (final (label, icon) in [
              ('Revenue', Icons.payments_rounded),
              ('Revenue', null),
              ('', Icons.payments_rounded),
              ('', null),
            ]) {
              await _pump(
                tester,
                _pair(loadingLabel: label, icon: icon),
                tokens: tokens,
                textScale: scale,
              );
              expect(
                _height(tester, 'loading'),
                _height(tester, 'loaded'),
                reason: 'label "$label", icon $icon',
              );
            }
          },
        );
      }
    }

    testWidgets('shows its label and icon, and a bar for everything else', (
      tester,
    ) async {
      await _pump(
        tester,
        const StatCard(
          label: 'Revenue',
          value: r'$48.2k',
          icon: Icons.payments_rounded,
          delta: StatDelta('12%'),
          caption: 'vs last month',
          loading: true,
        ),
      );
      expect(find.text('Revenue'), findsOneWidget);
      expect(find.byIcon(Icons.payments_rounded), findsOneWidget);
      expect(find.text(r'$48.2k'), findsNothing);
      expect(find.text('12%'), findsNothing);
      expect(find.text('vs last month'), findsNothing);
      expect(find.byType(Skeleton), findsNWidgets(3));

      await _pump(tester, const StatCard(loading: true));
      expect(find.byType(Skeleton), findsNWidgets(4), reason: 'the label too');
    });

    testWidgets('the delta bar is the chip: its height and its pill', (
      tester,
    ) async {
      await _pump(
        tester,
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StatCard(
                label: 'Revenue',
                value: '1',
                delta: StatDelta('12%'),
              ),
            ),
            Expanded(child: StatCard(label: 'Revenue', loading: true)),
          ],
        ),
        tokens: irisTheme.tokens,
      );
      final chip = find.ancestor(
        of: find.text('12%'),
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.decoration is BoxDecoration,
        ),
      );
      final pill = tester
          .widgetList<Skeleton>(find.byType(Skeleton))
          .firstWhere((s) => s.borderRadius != null);
      expect(pill.height, tester.getSize(chip.first).height);
      expect(
        pill.borderRadius,
        BorderRadius.circular(irisTheme.tokens.radii.radiusPill),
      );
    });

    testWidgets('reads as its label and "Loading…", in every language', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      for (final (locale, labelled, bare) in const [
        ('en', 'Revenue, Loading…', 'Loading…'),
        ('fr', 'Revenue, Chargement…', 'Chargement…'),
        ('ar', 'Revenue، جارٍ التحميل…', 'جارٍ التحميل…'),
      ]) {
        await _pump(
          tester,
          const Column(
            children: [
              StatCard(label: 'Revenue', loading: true),
              StatCard(loading: true),
            ],
          ),
          locale: Locale(locale),
        );
        expect(find.bySemanticsLabel(labelled), findsOneWidget);
        expect(find.bySemanticsLabel(bare), findsOneWidget);
      }
      semantics.dispose();
    });

    testWidgets('takes no taps while loading', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        StatCard(label: 'Revenue', loading: true, onTap: () => taps++),
      );
      await tester.tap(find.text('Revenue'));
      expect(taps, 0);
      expect(find.byType(Tappable), findsNothing);
    });
  });

  group('StatGrid', () {
    testWidgets('loading cards pulse from one clock', (tester) async {
      await _pump(
        tester,
        const StatGrid(
          children: [
            StatCard(label: 'Revenue', loading: true),
            StatCard(loading: true),
          ],
        ),
      );
      expect(find.byType(SkeletonGroup), findsOneWidget);

      await _pump(
        tester,
        const StatGrid(
          children: [
            StatCard(label: 'Revenue', value: '1'),
            StatCard(label: 'Orders', value: '2'),
          ],
        ),
      );
      expect(find.byType(SkeletonGroup), findsNothing);
    });

    testWidgets('a loading row is as tall as the loaded row it becomes', (
      tester,
    ) async {
      Widget grid({required bool loading}) => StatGrid(
        minTileWidth: 160,
        children: [
          for (final label in ['Revenue', 'Orders', 'Customers'])
            StatCard(
              label: label,
              value: '1',
              icon: Icons.payments_rounded,
              delta: const StatDelta('4%'),
              loading: loading,
            ),
        ],
      );
      await _pump(tester, grid(loading: false), tokens: irisTheme.tokens);
      final loaded = tester.getSize(find.byType(StatGrid)).height;
      await _pump(tester, grid(loading: true), tokens: irisTheme.tokens);
      expect(tester.getSize(find.byType(StatGrid)).height, loaded);
    });
  });
}
