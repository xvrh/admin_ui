import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// An Alert and a toast drawn from the theme's AdminFeedbackStyle: what they
// are filled with, the status bar on their leading edge, an alert's corner
// and a toast's outline.

/// Each shipped theme's alert and toast, from its reference.
const _expected = {
  // a tinted alert; an outlined toast behind a 4px bar
  'Iris': AdminFeedbackStyle(),
  // no inline alert in M3. A snackbar: no bar, no outline, in the inverse
  // scheme (see [_toastPalettes])
  'Material': AdminFeedbackStyle(toastBar: 0, toastOutline: false),
  // Alert: a rounded-lg card. Sonner: outlined, no bar
  'shadcn': AdminFeedbackStyle(
    alertFill: FeedbackFill.surface,
    alertRadius: 10,
    toastBar: 0,
  ),
  // Alert: borderRadiusLG. Notification: no border, no bar
  'Ant': AdminFeedbackStyle(alertRadius: 8, toastBar: 0, toastOutline: false),
  // MessageBar: tinted. Toast: a transparent border, no bar
  'Fluent': AdminFeedbackStyle(toastBar: 0, toastOutline: false),
  // inline, the low-contrast notification: tinted behind a 3px bar. A
  // toast, the high-contrast one: a card behind the bar, in the inverse
  // scheme (see [_toastPalettes])
  'Carbon': AdminFeedbackStyle(alertBar: 3, toastBar: 3, toastOutline: false),
};

/// A toast tinted with its status behind a 3px bar, as Carbon's inline
/// notification is. No shipped theme draws its toast so; the anatomy still
/// can.
const _tinted = AdminFeedbackStyle(
  alertBar: 3,
  toastFill: FeedbackFill.tint,
  toastBar: 3,
);

/// The palette each theme draws a toast in where it is not the page's, on
/// its light page then on its dark one.
final _toastPalettes = <String, (AdminPalette, AdminPalette)>{
  // the opposite scheme on inverseSurface, under inverseOnSurface
  'Material': (
    materialDarkPalette.copyWith(
      surface: const Color(0xFF322F35),
      foreground: const Color(0xFFF5EFF7),
    ),
    materialPalette.copyWith(
      surface: const Color(0xFFE6E0E9),
      foreground: const Color(0xFF322F35),
      // its warning text deepened to read there
      warningText: const Color(0xFF7D5C00),
    ),
  ),
  // the opposite theme on $background-inverse, under $text-inverse, with
  // $support-error-inverse on the light page
  'Carbon': (
    carbonDarkPalette.copyWith(
      surface: const Color(0xFF393939),
      foreground: const Color(0xFFFFFFFF),
      danger: const Color(0xFFFA4D56),
    ),
    carbonPalette.copyWith(surface: const Color(0xFFF4F4F4)),
  ),
};

/// [theme]'s expected feedback anatomy, on its light page then its dark one.
(AdminFeedbackStyle, AdminFeedbackStyle) _expectedOf(AdminTheme theme) {
  final style = _expected[theme.name]!;
  final palettes = _toastPalettes[theme.name];
  if (palettes == null) return (style, style);
  return (
    style.copyWith(toastPalette: palettes.$1),
    style.copyWith(toastPalette: palettes.$2),
  );
}

/// The client accents the catalog's Brand control offers.
const _brands = <String, Color?>{
  'Default': null,
  'Crimson': Color(0xFFE11D48),
  'Violet': Color(0xFF7C3AED),
  'Teal': Color(0xFF0D9488),
  'Amber': Color(0xFFD97706),
};

Widget _host(AdminTokens tokens, Widget child) => MaterialApp(
  theme: buildAppTheme(tokens),
  supportedLocales: AdminLocalizations.supportedLocales,
  localizationsDelegates: AdminLocalizations.localizationsDelegates,
  builder: (context, navigator) => ToastScope(child: navigator!),
  home: Scaffold(
    body: Center(child: SizedBox(width: 420, child: child)),
  ),
);

AdminTokens _tokens(AdminFeedbackStyle style, {AdminPalette? palette}) =>
    AdminTokens.from(palette: palette ?? irisPalette, feedback: style);

/// The alert's box: the container that paints its fill and edge.
Finder _alertBox() => find.descendant(
  of: find.byType(Alert),
  matching: find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration! as BoxDecoration).border != null,
  ),
);

BoxDecoration _alertLook(WidgetTester tester) =>
    tester.widget<Container>(_alertBox()).decoration! as BoxDecoration;

/// The status bar over an alert's leading edge, where it has one.
Finder _alertBar() => find.descendant(
  of: find.byType(Alert),
  matching: find.byWidgetPredicate(
    (w) => w is PositionedDirectional && w.child is ColoredBox,
  ),
);

/// The card of the toast that says [text].
Finder _toastCard(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(Material)).first;

/// The status bar at the card's leading edge, where it has one: the one
/// fixed-width box beside the content.
Finder _toastBar(String text) => find.descendant(
  of: _toastCard(text),
  matching: find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.constraints?.hasTightWidth == true &&
        w.color != null,
  ),
);

Future<void> _showToast(
  WidgetTester tester,
  AdminTokens tokens, {
  Severity severity = Severity.success,
}) async {
  await tester.pumpWidget(_host(tokens, const SizedBox()));
  tester
      .state<ToastScopeState>(find.byType(ToastScope))
      .show(Toast('Page published.', severity: severity, duration: null));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("the defaults are the kit's own", () {
    const style = AdminFeedbackStyle();
    expect(style.alertFill, FeedbackFill.tint);
    expect((style.alertBar, style.alertRadius), (0, null));
    expect(style.toastFill, FeedbackFill.surface);
    expect((style.toastBar, style.toastOutline), (4, true));
  });

  test('a negative bar or corner is refused', () {
    expect(() => AdminFeedbackStyle(alertBar: -1), throwsAssertionError);
    expect(() => AdminFeedbackStyle(toastBar: -1), throwsAssertionError);
    expect(() => AdminFeedbackStyle(alertRadius: -1), throwsAssertionError);
  });

  test('copyWith, lerp, == and toString', () {
    const style = AdminFeedbackStyle();
    final shadcn = _expected['shadcn']!;
    final carbon = _tinted;
    expect(style.copyWith(), style);
    expect(style.copyWith().hashCode, style.hashCode);
    expect(
      style.copyWith(
        alertFill: FeedbackFill.surface,
        alertRadius: 10,
        toastBar: 0,
      ),
      shadcn,
    );
    expect(
      style.copyWith(alertBar: 3, toastFill: FeedbackFill.tint, toastBar: 3),
      carbon,
    );
    expect(style.copyWith(toastOutline: false), isNot(style));
    expect(shadcn, isNot(style));
    expect(shadcn.hashCode, isNot(style.hashCode));

    expect(AdminFeedbackStyle.lerp(style, carbon, 0), style);
    expect(AdminFeedbackStyle.lerp(style, carbon, 1), carbon);
    final mid = AdminFeedbackStyle.lerp(style, carbon, 0.5);
    expect((mid.alertBar, mid.toastBar), (1.5, 3.5));
    expect(mid.toastFill, FeedbackFill.tint);
    expect(
      AdminFeedbackStyle.lerp(style, carbon, 0.4).toastFill,
      style.toastFill,
    );
    // one side derives its corner: the nearer side's, not a blend
    expect(AdminFeedbackStyle.lerp(style, shadcn, 0.5).alertRadius, 10);
    expect(AdminFeedbackStyle.lerp(style, shadcn, 0.4).alertRadius, isNull);
    expect(
      AdminFeedbackStyle.lerp(
        shadcn,
        shadcn.copyWith(alertRadius: 6),
        0.5,
      ).alertRadius,
      8,
    );

    expect(
      '$style',
      allOf(contains("the theme's radius"), contains('outlined')),
    );
    expect(
      '$shadcn',
      allOf(contains('alert surface'), contains('radius 10.0')),
    );
    expect('$carbon', contains('toast tint, bar 3.0'));
  });

  test('AdminTokens carry it through from, copyWith, lerp and ==', () {
    final carbon = _tinted;
    final plain = AdminTokens.from(palette: irisPalette);
    final tokens = AdminTokens.from(palette: irisPalette, feedback: carbon);
    expect(plain.feedback, const AdminFeedbackStyle());
    expect(tokens.feedback, carbon);
    expect(plain.copyWith(feedback: carbon), tokens);
    expect(tokens, isNot(plain));
    expect(tokens.hashCode, plain.copyWith(feedback: carbon).hashCode);
    expect(tokens.branded(const Color(0xFF0D9488)).feedback, carbon);
    expect(plain.lerp(tokens, 0.5).feedback.alertBar, 1.5);
  });

  test('AdminTheme.from gives both modes the feedback anatomy', () {
    final style = _expected['shadcn']!;
    final theme = AdminTheme.from(
      name: 'Test',
      palette: irisPalette,
      dark: irisDarkPalette,
      feedback: style,
    );
    expect(theme.tokens.feedback, style);
    expect(theme.dark!.feedback, style);
    expect(
      theme.branded('Test Teal', const Color(0xFF0D9488)).dark!.feedback,
      style,
    );
  });

  group('each theme', () {
    for (final theme in adminThemes) {
      test('${theme.name}: its reference system', () {
        expect(
          _expected[theme.name],
          isNotNull,
          reason: 'a theme with no expectation',
        );
        final (light, dark) = _expectedOf(theme);
        expect(theme.tokens.feedback, light);
        expect(theme.dark!.feedback, dark);
        // A toast in a scheme of its own is in the opposite one.
        for (final tokens in [theme.tokens, theme.dark!]) {
          final own = tokens.feedback.toastPalette;
          if (own != null) {
            expect(own.brightness, isNot(tokens.palette.brightness));
          }
        }
      });
    }
  });

  testWidgets('context.feedbackStyle reads the active theme’s', (tester) async {
    const style = AdminFeedbackStyle(alertBar: 2);
    late AdminFeedbackStyle read;
    await tester.pumpWidget(
      Theme(
        data: buildAppTheme(_tokens(style)),
        child: Builder(
          builder: (context) {
            read = context.feedbackStyle;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(read, style);
  });

  group('an Alert', () {
    const alert = Alert(
      'Check the price before publishing.',
      title: 'Could not publish',
      severity: Severity.danger,
    );

    testWidgets('tinted: the status’s fill inside its border, at the theme’s '
        'radius', (tester) async {
      final p = irisPalette;
      await tester.pumpWidget(
        _host(_tokens(const AdminFeedbackStyle()), alert),
      );
      final look = _alertLook(tester);
      expect(look.color, p.statusFill(p.danger));
      expect((look.border! as Border).top.color, p.statusBorder(p.danger));
      expect(
        look.borderRadius,
        BorderRadius.circular(defaultTokens.radii.radius),
      );
      expect(_alertBar(), findsNothing);
    });

    testWidgets('surface: a card in the surface colour inside the border, '
        'its icon still in the status’s colour', (tester) async {
      final p = irisPalette;
      await tester.pumpWidget(
        _host(
          _tokens(const AdminFeedbackStyle(alertFill: FeedbackFill.surface)),
          alert,
        ),
      );
      final look = _alertLook(tester);
      expect(look.color, p.surface);
      expect((look.border! as Border).top.color, p.border);
      final icon = tester.widget<Icon>(
        find.descendant(of: find.byType(Alert), matching: find.byType(Icon)),
      );
      expect(icon.color, p.dangerText);
      expect(contrastRatio(icon.color!, p.surface), greaterThanOrEqualTo(4.5));
    });

    testWidgets('a corner of its own', (tester) async {
      await tester.pumpWidget(
        _host(_tokens(const AdminFeedbackStyle(alertRadius: 10)), alert),
      );
      expect(_alertLook(tester).borderRadius, BorderRadius.circular(10));
    });

    testWidgets('a status bar lies over its leading edge, and its content '
        'moves in by as much', (tester) async {
      final p = irisPalette;
      await tester.pumpWidget(
        _host(_tokens(const AdminFeedbackStyle()), alert),
      );
      final plain = tester.getRect(find.byType(Alert));
      final iconAt = tester.getTopLeft(
        find.descendant(of: find.byType(Alert), matching: find.byType(Icon)),
      );

      await tester.pumpWidget(
        _host(_tokens(const AdminFeedbackStyle(alertBar: 3)), alert),
      );
      await tester.pumpAndSettle();
      final bar = tester.getRect(_alertBar());
      final box = tester.getRect(find.byType(Alert));
      expect(bar.width, 3);
      expect(bar.left, box.left);
      expect((bar.top, bar.bottom), (box.top, box.bottom));
      expect(
        (tester.widget<PositionedDirectional>(_alertBar()).child as ColoredBox)
            .color,
        p.danger,
      );
      // as tall and as wide as without it
      expect(box.size, plain.size);
      expect(
        tester
            .getTopLeft(
              find.descendant(
                of: find.byType(Alert),
                matching: find.byType(Icon),
              ),
            )
            .dx,
        iconAt.dx + 3,
      );
    });

    testWidgets('the bar is on the right, right to left', (tester) async {
      await tester.pumpWidget(
        _host(
          _tokens(const AdminFeedbackStyle(alertBar: 3)),
          const Directionality(textDirection: TextDirection.rtl, child: alert),
        ),
      );
      expect(
        tester.getRect(_alertBar()).right,
        tester.getRect(find.byType(Alert)).right,
      );
    });
  });

  group('a toast', () {
    testWidgets('the default: outlined in the surface colour behind a 4px '
        'bar', (tester) async {
      final p = irisPalette;
      await _showToast(tester, _tokens(const AdminFeedbackStyle()));
      final card = tester.widget<Material>(_toastCard('Page published.'));
      expect(card.color, p.surface);
      expect((card.shape! as RoundedRectangleBorder).side.color, p.border);
      final bar = tester.widget<Container>(_toastBar('Page published.'));
      expect(bar.constraints!.maxWidth, 4);
      expect(bar.color, p.success);
    });

    testWidgets('no bar, and no outline on a light page', (tester) async {
      await _showToast(
        tester,
        _tokens(const AdminFeedbackStyle(toastBar: 0, toastOutline: false)),
      );
      final card = tester.widget<Material>(_toastCard('Page published.'));
      expect((card.shape! as RoundedRectangleBorder).side, BorderSide.none);
      expect(_toastBar('Page published.'), findsNothing);
    });

    testWidgets('a dark page always rings it, where a shadow does not read', (
      tester,
    ) async {
      final p = irisDarkPalette;
      await _showToast(
        tester,
        _tokens(
          const AdminFeedbackStyle(toastBar: 0, toastOutline: false),
          palette: p,
        ),
      );
      final card = tester.widget<Material>(_toastCard('Page published.'));
      expect((card.shape! as RoundedRectangleBorder).side.color, p.border);
    });

    testWidgets('tinted: the status’s fill inside its border, behind its bar', (
      tester,
    ) async {
      final p = carbonPalette;
      await _showToast(tester, _tokens(_tinted, palette: p));
      final card = tester.widget<Material>(_toastCard('Page published.'));
      expect(card.color, p.statusFill(p.success));
      expect(
        (card.shape! as RoundedRectangleBorder).side.color,
        p.statusBorder(p.success),
      );
      final bar = tester.widget<Container>(_toastBar('Page published.'));
      expect(bar.constraints!.maxWidth, 3);
      expect(bar.color, p.success);
    });
  });

  group('each theme’s alert and toast read at 4.5:1', () {
    for (final theme in adminThemes) {
      for (final (mode, tokens) in [
        ('Light', theme.tokens),
        ('Dark', theme.dark!),
      ]) {
        for (final MapEntry(key: brand, value: seed) in _brands.entries) {
          test('${theme.name} $mode $brand', () {
            final t = seed == null ? tokens : tokens.branded(seed);
            final style = t.feedback;
            // An alert is in the page's palette; a toast in its own where
            // the theme gives it one.
            for (final (what, fill, p) in [
              ('alert', style.alertFill, t.palette),
              ('toast', style.toastFill, style.toastPalette ?? t.palette),
            ]) {
              for (final (name, accent, ink) in [
                ('info', p.info, p.infoText),
                ('success', p.success, p.successText),
                ('warning', p.warning, p.warningText),
                ('danger', p.danger, p.dangerText),
              ]) {
                final ground = switch (fill) {
                  FeedbackFill.tint => p.statusFill(accent),
                  FeedbackFill.surface => p.surface,
                };
                for (final (part, color) in [
                  ('title', p.foreground),
                  ('message', p.foregroundSecondary),
                  ('icon', ink),
                ]) {
                  expect(
                    contrastRatio(color, ground),
                    greaterThanOrEqualTo(4.5),
                    reason: 'the $name $what’s $part',
                  );
                }
              }
            }
          });
        }
      }
    }
  });

  group('every shipped theme', () {
    for (final theme in adminThemes) {
      for (final (mode, tokens) in [
        ('Light', theme.tokens),
        ('Dark', theme.dark!),
      ]) {
        testWidgets('${theme.name} $mode draws its alert and its toast', (
          tester,
        ) async {
          final style = tokens.feedback;
          final p = tokens.palette;
          await tester.pumpWidget(
            _host(
              tokens,
              const Alert(
                'Check the price before publishing.',
                severity: Severity.warning,
              ),
            ),
          );
          tester
              .state<ToastScopeState>(find.byType(ToastScope))
              .show(
                const Toast(
                  'Page published.',
                  severity: Severity.success,
                  duration: null,
                ),
              );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          final alert = _alertLook(tester);
          expect(
            alert.color,
            style.alertFill == FeedbackFill.tint
                ? p.statusFill(p.warning)
                : p.surface,
          );
          expect(
            alert.borderRadius,
            BorderRadius.circular(style.alertRadius ?? tokens.radii.radius),
          );
          expect(
            _alertBar(),
            style.alertBar > 0 ? findsOneWidget : findsNothing,
          );

          // In its own palette where the theme gives it one, and
          // otherwise in the page's as what stands on a popover reads it.
          final tp = style.toastPalette ?? p.withSurface(p.popoverSurface);
          final card = tester.widget<Material>(_toastCard('Page published.'));
          expect(
            card.color,
            style.toastFill == FeedbackFill.tint
                ? tp.statusFill(tp.success)
                : tp.surface,
          );
          // Ringed where the theme outlines it, and always where it is a
          // dark card on a dark page.
          expect(
            (card.shape! as RoundedRectangleBorder).side == BorderSide.none,
            !(style.toastOutline ||
                (p.brightness == Brightness.dark &&
                    tp.brightness == Brightness.dark)),
          );
          expect(
            _toastBar('Page published.'),
            style.toastBar > 0 ? findsOneWidget : findsNothing,
          );
        });
      }
    }
  });

  group('a toast in a palette of its own', () {
    // A dark card for a light page: Iris's dark palette on another surface.
    final own = irisDarkPalette.copyWith(surface: const Color(0xFF2A2D35));
    const bare = AdminFeedbackStyle(toastOutline: false);
    final style = bare.copyWith(toastPalette: own);

    test('the style carries it', () {
      expect(const AdminFeedbackStyle().toastPalette, isNull);
      expect(style.toastPalette, own);
      expect(style, isNot(bare));
      expect(style.hashCode, isNot(bare.hashCode));
      expect(style.copyWith(), style);
      expect(style.copyWith().hashCode, style.hashCode);
      expect(style.copyWith(toastBar: 0).toastPalette, own);
      expect(style, bare.copyWith(toastPalette: own.copyWith()));
      expect(bare.copyWith(toastPalette: irisPalette), isNot(style));

      // From the nearer side, as the fills are.
      expect(AdminFeedbackStyle.lerp(bare, style, 0.4).toastPalette, isNull);
      expect(AdminFeedbackStyle.lerp(bare, style, 0.6).toastPalette, own);

      expect('$style', contains('own palette'));
      expect('$bare', isNot(contains('palette')));
    });

    test('a brand reaches it, and leaves a style with none alone', () {
      const seed = Color(0xFF0D9488);
      expect(bare.branded(seed), same(bare));
      final branded = style.branded(seed);
      expect(branded.toastPalette, own.branded(seed));
      expect(branded.toastPalette, isNot(own));
      // Its surface and its text are untouched.
      expect(branded.toastPalette!.surface, own.surface);
      expect(branded.toastPalette!.foreground, own.foreground);
      expect(branded.toastBar, style.toastBar);

      final tokens = AdminTokens.from(palette: irisPalette, feedback: style);
      expect(tokens.branded(seed).feedback.toastPalette, own.branded(seed));
      expect(tokens.branded(seed).palette, irisPalette.branded(seed));
    });

    test('AdminTheme.from gives each mode its own', () {
      final light = style;
      final dark = bare.copyWith(toastPalette: irisPalette);
      final theme = AdminTheme.from(
        name: 'Test',
        palette: irisPalette,
        dark: irisDarkPalette,
        feedback: light,
        darkFeedback: dark,
      );
      expect(theme.tokens.feedback, light);
      expect(theme.dark!.feedback, dark);

      // Left out, the dark set takes the light one.
      final shared = AdminTheme.from(
        name: 'Test',
        palette: irisPalette,
        dark: irisDarkPalette,
        feedback: light,
      );
      expect(shared.dark!.feedback, light);

      const seed = Color(0xFF0D9488);
      final branded = theme.branded('Test Teal', seed);
      expect(branded.tokens.feedback.toastPalette, own.branded(seed));
      expect(branded.dark!.feedback.toastPalette, irisPalette.branded(seed));
    });

    Future<void> show(
      WidgetTester tester,
      AdminTokens tokens, {
      Severity severity = Severity.success,
    }) async {
      await tester.pumpWidget(_host(tokens, const SizedBox()));
      tester
          .state<ToastScopeState>(find.byType(ToastScope))
          .show(
            Toast(
              'It could not be restored.',
              title: 'Page deleted',
              severity: severity,
              duration: null,
              actionLabel: 'Undo',
              onAction: () {},
            ),
          );
      await tester.pumpAndSettle();
    }

    Color inkOf(WidgetTester tester, String text) =>
        tester.widget<Text>(find.text(text)).style!.color!;

    testWidgets('its fill, text, icon, bar, action and close are that '
        'palette’s', (tester) async {
      final tokens = _tokens(style);
      await show(tester, tokens, severity: Severity.danger);
      expect(tester.takeException(), isNull);

      final card = tester.widget<Material>(_toastCard('Page deleted'));
      expect(card.color, own.surface);
      expect(card.color, isNot(irisPalette.surface));
      // No ring: it stands out from the light page by its fill.
      expect((card.shape! as RoundedRectangleBorder).side, BorderSide.none);

      expect(inkOf(tester, 'Page deleted'), own.foreground);
      expect(
        inkOf(tester, 'It could not be restored.'),
        own.foregroundSecondary,
      );
      final icon = tester.widget<Icon>(
        find.descendant(
          of: _toastCard('Page deleted'),
          matching: find.byIcon(Icons.error_outline_rounded),
        ),
      );
      expect(icon.color, own.dangerText);
      final bar = tester.widget<Container>(_toastBar('Page deleted'));
      expect(bar.color, own.danger);

      // The action and the close button are drawn for that surface too.
      expect(
        contrastRatio(inkOf(tester, 'Undo'), own.surface),
        greaterThanOrEqualTo(4.5),
      );
      final close = tester.widget<Icon>(
        find.descendant(
          of: find.descendant(
            of: _toastCard('Page deleted'),
            matching: find.byType(IconAction),
          ),
          matching: find.byType(Icon),
        ),
      );
      expect(contrastRatio(close.color!, own.surface), greaterThanOrEqualTo(3));
      for (final text in ['Page deleted', 'It could not be restored.']) {
        expect(
          contrastRatio(inkOf(tester, text), own.surface),
          greaterThanOrEqualTo(4.5),
        );
      }
    });

    testWidgets('the page under it keeps its own palette', (tester) async {
      final tokens = _tokens(style);
      await tester.pumpWidget(
        _host(tokens, const Alert('Check the price before publishing.')),
      );
      tester
          .state<ToastScopeState>(find.byType(ToastScope))
          .show(const Toast('Page published.', duration: null));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Material>(_toastCard('Page published.')).color,
        own.surface,
      );
      expect(
        _alertLook(tester).color,
        irisPalette.statusFill(irisPalette.info),
      );
    });

    testWidgets('on a dark page, a dark card is ringed and a light one is '
        'not', (tester) async {
      // Dark on dark: the shadow does not read, so the ring comes back.
      await show(tester, _tokens(style, palette: irisDarkPalette));
      var card = tester.widget<Material>(_toastCard('Page deleted'));
      expect((card.shape! as RoundedRectangleBorder).side.color, own.border);

      // Light on dark: the fill is the edge.
      final light = bare.copyWith(toastPalette: irisPalette);
      await show(tester, _tokens(light, palette: irisDarkPalette));
      card = tester.widget<Material>(_toastCard('Page deleted'));
      expect(card.color, irisPalette.surface);
      expect((card.shape! as RoundedRectangleBorder).side, BorderSide.none);

      // And a style that outlines its toast rings it in that palette's edge.
      await show(
        tester,
        _tokens(light.copyWith(toastOutline: true), palette: irisDarkPalette),
      );
      card = tester.widget<Material>(_toastCard('Page deleted'));
      expect(
        (card.shape! as RoundedRectangleBorder).side.color,
        irisPalette.border,
      );
    });

    testWidgets('a tinted toast is tinted in that palette', (tester) async {
      await show(
        tester,
        _tokens(style.copyWith(toastFill: FeedbackFill.tint)),
        severity: Severity.warning,
      );
      final card = tester.widget<Material>(_toastCard('Page deleted'));
      expect(card.color, own.statusFill(own.warning));
    });
  });
}
