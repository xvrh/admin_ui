import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('AdminBreakpoint.forWidth', () {
    test('splits at 600 and 1200 by default', () {
      expect(
        {
          for (final width in <double>[0, 599, 599.9, 600, 1199, 1199.9, 1200])
            width: AdminBreakpoint.forWidth(width),
        },
        <double, AdminBreakpoint>{
          0: AdminBreakpoint.compact,
          599: AdminBreakpoint.compact,
          599.9: AdminBreakpoint.compact,
          600: AdminBreakpoint.medium,
          1199: AdminBreakpoint.medium,
          1199.9: AdminBreakpoint.medium,
          1200: AdminBreakpoint.expanded,
        },
      );
    });

    test('splits where the breakpoints say', () {
      expect(AdminBreakpoint.forWidth(479, _narrow), AdminBreakpoint.compact);
      expect(AdminBreakpoint.forWidth(480, _narrow), AdminBreakpoint.medium);
      expect(AdminBreakpoint.forWidth(959, _narrow), AdminBreakpoint.medium);
      expect(AdminBreakpoint.forWidth(960, _narrow), AdminBreakpoint.expanded);
    });

    test('names each class once', () {
      expect(
        [
          for (final b in AdminBreakpoint.values)
            (b.isCompact, b.isMedium, b.isExpanded),
        ],
        [(true, false, false), (false, true, false), (false, false, true)],
      );
    });
  });

  group('AdminBreakpoints', () {
    test('is a value', () {
      const breakpoints = AdminBreakpoints();
      expect((breakpoints.medium, breakpoints.expanded), (600, 1200));
      expect(breakpoints.copyWith(), breakpoints);
      expect(breakpoints.copyWith().hashCode, breakpoints.hashCode);
      expect(
        breakpoints.copyWith(expanded: 1440),
        const AdminBreakpoints(expanded: 1440),
      );
      expect(breakpoints.copyWith(medium: 480), isNot(breakpoints));
    });

    test('snaps when lerped: a layout switches at one width or the other', () {
      const a = AdminBreakpoints();
      expect(AdminBreakpoints.lerp(a, _narrow, 0.49), a);
      expect(AdminBreakpoints.lerp(a, _narrow, 0.5), _narrow);
    });
  });

  group('the tokens carry the breakpoints', () {
    test('the default set and Iris split at 600 and 1200', () {
      expect(defaultTokens.breakpoints, const AdminBreakpoints());
      expect(irisTheme.tokens.breakpoints, const AdminBreakpoints());
      expect(irisTheme.dark!.breakpoints, const AdminBreakpoints());
    });

    test('from, copyWith, equality and lerp', () {
      final tokens = AdminTokens.from(
        palette: irisPalette,
        breakpoints: _narrow,
      );
      expect(tokens.breakpoints, _narrow);
      expect(tokens.copyWith().breakpoints, _narrow);
      expect(tokens.copyWith(radii: defaultRadii), tokens);
      expect(defaultTokens.copyWith(breakpoints: _narrow), tokens);
      expect(tokens, isNot(defaultTokens));
      expect(tokens.copyWith().hashCode, tokens.hashCode);
      expect(tokens.lerp(defaultTokens, 0.25).breakpoints, _narrow);
      expect(tokens.lerp(defaultTokens, 0.75).breakpoints, isNot(_narrow));
    });

    test('a theme sets them for both modes, and branding keeps them', () {
      final theme = AdminTheme.from(
        name: 'Narrow',
        palette: irisPalette,
        dark: irisDarkPalette,
        breakpoints: _narrow,
      );
      expect(theme.tokens.breakpoints, _narrow);
      expect(theme.dark!.breakpoints, _narrow);
      final branded = theme.branded('Narrow (teal)', const Color(0xFF0D9488));
      expect(branded.tokens.breakpoints, _narrow);
      expect(branded.dark!.breakpoints, _narrow);
      expect(
        defaultTokens
            .copyWith(breakpoints: _narrow)
            .branded(const Color(0xFF0D9488))
            .breakpoints,
        _narrow,
      );
    });
  });

  group('AdminBreakpoint.of', () {
    Future<(AdminBreakpoint, AdminBreakpoints)> classify(
      WidgetTester tester,
      double width,
      AdminTokens tokens,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.reset);
      late AdminBreakpoint breakpoint;
      late AdminBreakpoints breakpoints;
      // A new app, not the last one rethemed: that would animate the theme.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(tokens),
          home: Builder(
            builder: (context) {
              breakpoint = AdminBreakpoint.of(context);
              breakpoints = context.breakpoints;
              return const SizedBox();
            },
          ),
        ),
      );
      return (breakpoint, breakpoints);
    }

    testWidgets('classifies the window by the theme\'s widths', (tester) async {
      final narrow = defaultTokens.copyWith(breakpoints: _narrow);
      expect(await classify(tester, 1000, defaultTokens), (
        AdminBreakpoint.medium,
        const AdminBreakpoints(),
      ));
      expect(await classify(tester, 1000, narrow), (
        AdminBreakpoint.expanded,
        _narrow,
      ));
      expect((await classify(tester, 500, narrow)).$1, AdminBreakpoint.medium);
      expect(
        (await classify(tester, 500, defaultTokens)).$1,
        AdminBreakpoint.compact,
      );
    });

    testWidgets('follows the window as it resizes', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 800);
      addTearDown(tester.view.reset);
      final seen = <AdminBreakpoint>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(defaultTokens),
          home: Builder(
            builder: (context) {
              seen.add(AdminBreakpoint.of(context));
              return const SizedBox();
            },
          ),
        ),
      );
      tester.view.physicalSize = const Size(700, 800);
      await tester.pump();
      tester.view.physicalSize = const Size(390, 800);
      await tester.pump();
      expect(seen, [
        AdminBreakpoint.expanded,
        AdminBreakpoint.medium,
        AdminBreakpoint.compact,
      ]);
    });
  });
}

const _narrow = AdminBreakpoints(medium: 480, expanded: 960);
