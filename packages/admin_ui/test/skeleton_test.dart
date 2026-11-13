import 'package:admin_ui/src/common/ui/skeleton.dart';
import 'package:admin_ui/src/theme/motion.dart';
import 'package:admin_ui/src/theme/theme.dart';
import 'package:admin_ui/src/theme/themes/iris.dart';
import 'package:admin_ui/src/theme/tokens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

Color _colorOf(WidgetTester tester, Finder skeleton) {
  final container = tester.widget<Container>(
    find.descendant(of: skeleton, matching: find.byType(Container)),
  );
  return (container.decoration as BoxDecoration).color!;
}

void main() {
  testWidgets('renders a box and pulses (color changes between frames)', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const Skeleton(width: 100)));
    await tester.pump();

    expect(find.byType(Skeleton), findsOneWidget);
    final first = _colorOf(tester, find.byType(Skeleton));

    await tester.pump(const Duration(milliseconds: 450));
    final later = _colorOf(tester, find.byType(Skeleton));

    expect(later, isNot(first));
  });

  testWidgets('Skeleton.circle paints a round box', (tester) async {
    await tester.pumpWidget(_host(const Skeleton.circle(size: 40)));
    await tester.pump();

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(Skeleton),
        matching: find.byType(Container),
      ),
    );
    expect((container.decoration as BoxDecoration).shape, BoxShape.circle);
  });

  testWidgets('SkeletonGroup drives all descendants in sync', (tester) async {
    await tester.pumpWidget(
      _host(
        const SkeletonGroup(
          child: Column(
            children: [
              Skeleton(key: Key('a'), width: 100),
              Skeleton(key: Key('b'), width: 100),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      _colorOf(tester, find.byKey(const Key('a'))),
      _colorOf(tester, find.byKey(const Key('b'))),
    );
  });

  testWidgets('is hidden from semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(const Skeleton(width: 100)));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(Skeleton),
        matching: find.byType(ExcludeSemantics),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('holds still when animations are disabled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Center(
              child: SkeletonGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Skeleton(key: Key('grouped'), width: 100),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Skeleton(key: Key('alone'), width: 100),
                  SkeletonGroup(
                    child: Skeleton(key: Key('grouped'), width: 100),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final alone = _colorOf(tester, find.byKey(const Key('alone')));
    final grouped = _colorOf(tester, find.byKey(const Key('grouped')));
    await tester.pump(const Duration(milliseconds: 450));
    expect(_colorOf(tester, find.byKey(const Key('alone'))), alone);
    expect(_colorOf(tester, find.byKey(const Key('grouped'))), grouped);
    expect(tester.hasRunningAnimations, isFalse);
  });

  for (final grouped in [false, true]) {
    testWidgets('pulses over the theme\'s motion.pulse'
        '${grouped ? ' in a group' : ''}', (tester) async {
      for (final pulse in const [
        Duration(milliseconds: 600),
        Duration(milliseconds: 1500),
      ]) {
        final tokens = AdminTokens.from(
          palette: irisPalette,
          motion: AdminMotion(pulse: pulse),
        );
        const skeleton = Skeleton(key: Key('s'), width: 100);
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(pulse),
            theme: buildAppTheme(tokens),
            home: Scaffold(
              body: Center(
                child: grouped
                    ? const SkeletonGroup(child: skeleton)
                    : skeleton,
              ),
            ),
          ),
        );
        await tester.pump();
        // Half a cycle in, the pulse is at its darkest.
        await tester.pump(pulse);
        expect(
          _colorOf(tester, find.byKey(const Key('s'))),
          Color.lerp(
            tokens.palette.borderSubtle,
            tokens.palette.border,
            0.4 + 0.45,
          ),
          reason: '$pulse',
        );
      }
    });
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('SkeletonText is one line of its style tall, text x$scale', (
      tester,
    ) async {
      const style = TextStyle(fontSize: 24, height: 1.3);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery.withClampedTextScaling(
            minScaleFactor: scale,
            maxScaleFactor: scale,
            child: const Scaffold(
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Revenue', key: Key('text'), style: style),
                  SizedBox(
                    width: 200,
                    child: SkeletonText(
                      key: Key('line'),
                      style: style,
                      widthFactor: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSize(find.byKey(const Key('line'))).height,
        tester.getSize(find.byKey(const Key('text'))).height,
      );
      expect(tester.getSize(find.byType(Skeleton)).width, 100);
    });
  }
}
