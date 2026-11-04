import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Reads `context.motion` under [tokens], with animations [disabled] or not.
Future<AdminMotion> _motion(
  WidgetTester tester,
  AdminTokens tokens, {
  required bool disabled,
}) async {
  late AdminMotion motion;
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(tokens),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: disabled),
        child: child!,
      ),
      home: Builder(
        builder: (context) {
          motion = context.motion;
          return const SizedBox();
        },
      ),
    ),
  );
  return motion;
}

const _ms = Duration(milliseconds: 1);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('context.motion', () {
    final tokens = AdminTokens.from(
      palette: irisPalette,
      motion: const AdminMotion(fast: Duration(milliseconds: 90)),
    );

    testWidgets('is the theme motion while animations run', (tester) async {
      final motion = await _motion(tester, tokens, disabled: false);
      expect(motion, tokens.motion);
      expect(motion.fast, _ms * 90);
    });

    testWidgets('zeroes every duration while animations are disabled', (
      tester,
    ) async {
      final motion = await _motion(tester, tokens, disabled: true);
      expect(motion, tokens.motion.reduced);
      for (final duration in [
        motion.fast,
        motion.medium,
        motion.slow,
        motion.pulse,
      ]) {
        expect(duration, Duration.zero);
      }
      expect(motion.standard, tokens.motion.standard);
      expect(motion.enter, tokens.motion.enter);
      expect(motion.exit, tokens.motion.exit);
      expect(motion.emphasized, tokens.motion.emphasized);
    });

    testWidgets('follows a change of the platform setting', (tester) async {
      expect(
        (await _motion(tester, tokens, disabled: true)).slow,
        Duration.zero,
      );
      expect((await _motion(tester, tokens, disabled: false)).slow, _ms * 240);
    });
  });

  test('each shipped theme takes its design system durations', () {
    const expected = {
      'Iris': (120, 180, 240),
      'Material': (100, 200, 300),
      'shadcn': (150, 200, 300),
      'Ant': (100, 200, 300),
      'Fluent': (100, 200, 250),
      'Carbon': (110, 150, 240),
    };
    for (final theme in adminThemes) {
      final light = theme.tokens.motion;
      final dark = theme.dark!.motion;
      expect(dark, light, reason: theme.name);
      expect(
        (
          light.fast.inMilliseconds,
          light.medium.inMilliseconds,
          light.slow.inMilliseconds,
        ),
        expected[theme.name],
        reason: theme.name,
      );
      expect(light.fast, lessThan(light.medium), reason: theme.name);
      expect(light.medium, lessThan(light.slow), reason: theme.name);
      expect(light.pulse, greaterThan(light.slow), reason: theme.name);
    }
  });

  test('the Material and Carbon curves are their references', () {
    final material = materialTheme.tokens.motion;
    expect(material.standard, const Cubic(0.2, 0, 0, 1));
    expect(material.enter, const Cubic(0.05, 0.7, 0.1, 1));
    expect(material.exit, const Cubic(0.3, 0, 0.8, 0.15));
    final carbon = carbonTheme.tokens.motion;
    expect(carbon.standard, const Cubic(0.2, 0, 0.38, 0.9));
    expect(carbon.emphasized, const Cubic(0.4, 0.14, 0.3, 1));
  });

  group('value semantics', () {
    const a = AdminMotion();
    const b = AdminMotion(
      fast: Duration(milliseconds: 200),
      medium: Duration(milliseconds: 300),
      slow: Duration(milliseconds: 400),
      pulse: Duration(milliseconds: 1100),
      standard: Curves.linear,
      enter: Curves.linear,
      exit: Curves.linear,
      emphasized: Curves.linear,
    );

    test('copyWith and ==', () {
      expect(a.copyWith(), a);
      expect(a.copyWith().hashCode, a.hashCode);
      expect(a, defaultMotion);
      expect(a.copyWith(fast: _ms * 121), isNot(a));
      expect(a.copyWith(enter: Curves.linear), isNot(a));
      expect(a.reduced, a.reduced);
      expect(a.reduced, isNot(a));
      expect(a.reduced.reduced, a.reduced);
    });

    test('lerp interpolates the durations and switches the curves', () {
      final mid = AdminMotion.lerp(a, b, 0.5);
      expect(mid.fast, _ms * 160);
      expect(mid.medium, _ms * 240);
      expect(mid.slow, _ms * 320);
      expect(mid.pulse, _ms * 1000);
      expect(mid.standard, Curves.linear);
      final early = AdminMotion.lerp(a, b, 0.25);
      expect(early.standard, a.standard);
      expect(early.fast, _ms * 140);
      expect(AdminMotion.lerp(a, b, 0), a);
      expect(AdminMotion.lerp(a, b, 1), b);
    });

    test('tokens carry it through copyWith, lerp and ==', () {
      final tokens = AdminTokens.from(palette: irisPalette);
      expect(tokens.motion, defaultMotion);
      final slower = tokens.copyWith(motion: b);
      expect(slower, isNot(tokens));
      expect(slower.motion, b);
      expect(slower.copyWith(), slower);
      expect(tokens.lerp(slower, 0.5).motion, AdminMotion.lerp(a, b, 0.5));
    });

    test('a theme hands it to both token sets', () {
      final theme = AdminTheme.from(
        name: 'Slow',
        palette: irisPalette,
        dark: irisDarkPalette,
        motion: b,
      );
      expect(theme.tokens.motion, b);
      expect(theme.dark!.motion, b);
      expect(
        theme.branded('Slow (brand)', const Color(0xFF0D9488)).tokens.motion,
        b,
      );
    });
  });
}
