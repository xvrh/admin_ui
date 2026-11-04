import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _teal = Color(0xFF0D9488);

const _focused = {WidgetState.focused};
const _hovered = {WidgetState.hovered};
const _disabled = {WidgetState.disabled};
const _error = {WidgetState.error};
const _focusedError = {WidgetState.error, WidgetState.focused};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('value semantics', () {
    test('AdminFieldStyle', () {
      const style = AdminFieldStyle();
      const filled = AdminFieldStyle(
        variant: FieldVariant.filled,
        haloOpacity: 0.2,
      );
      expect(style.copyWith(), style);
      expect(style.copyWith().hashCode, style.hashCode);
      expect(style.copyWith(accentHover: true), isNot(style));
      expect(
        style.copyWith(variant: FieldVariant.filled, haloOpacity: 0.2),
        filled,
      );
      final mid = AdminFieldStyle.lerp(style, filled, 0.5);
      expect(mid.haloOpacity, closeTo(0.35, 1e-9));
      expect(mid.variant, FieldVariant.filled);
      expect(
        AdminFieldStyle.lerp(style, filled, 0.4).variant,
        FieldVariant.outlined,
      );
      expect('$filled', contains('filled'));
    });

    test('AdminButtonStyle and its padding', () {
      const style = AdminButtonStyle();
      const padding = AdminButtonPadding(
        small: AdminButtonInsets.symmetric(12),
        medium: AdminButtonInsets.symmetric(24, startWithIcon: 16),
        large: AdminButtonInsets(start: 16, end: 64),
      );
      const custom = AdminButtonStyle(
        padding: padding,
        minWidth: AdminButtonMinWidth(small: 64, medium: 96, large: 96),
        labelWeight: FontWeight.w500,
        disabled: ButtonDisabledStyle.faded,
      );
      expect(style.copyWith(), style);
      expect(custom.copyWith(), custom);
      expect(custom.copyWith().hashCode, custom.hashCode);
      expect(style.copyWith(strongOutline: true), isNot(style));
      expect(padding.copyWith(), padding);
      expect(
        padding.medium.startFor(leadingIcon: true),
        16,
        reason: 'the icon side',
      );
      expect(padding.medium.startFor(leadingIcon: false), 24);
      expect(padding.small.startFor(leadingIcon: true), 12);
      expect(padding.of(ControlSize.large).end, 64);

      // Unset, the kit's height / 2 - 4 either side and no minimum.
      for (final (size, height) in [
        (ControlSize.small, 28.0),
        (ControlSize.medium, 36.0),
        (ControlSize.large, 40.0),
      ]) {
        expect(
          style.paddingOf(size, height),
          AdminButtonInsets.symmetric(height / 2 - 4),
        );
        expect(style.minWidthOf(size), 0);
      }
      expect(custom.paddingOf(ControlSize.medium, 40), padding.medium);
      expect(custom.minWidthOf(ControlSize.small), 64);
      expect(custom.minWidthOf(ControlSize.large), 96);

      final mid = AdminButtonStyle.lerp(style, custom, 0.5);
      // medium: 14 either side (at 36) toward 24, 16 beside an icon
      expect(mid.paddingOf(ControlSize.medium, 36).end, 19);
      expect(mid.paddingOf(ControlSize.medium, 36).startWithIcon, 15);
      expect(mid.minWidthOf(ControlSize.medium), 48);
      expect(mid.disabled, ButtonDisabledStyle.faded);
      expect(AdminButtonStyle.lerp(style, style, 0.3), style);
      expect('$custom', contains('faded'));
    });

    test('AdminShellStyle', () {
      const style = AdminShellStyle();
      const carbon = AdminShellStyle(
        sidebarWidth: 256,
        itemRadius: 0,
        indicator: NavIndicator.edge,
        topBarPalette: carbonShellPalette,
      );
      expect(style.copyWith(), style);
      expect(carbon.copyWith(), carbon);
      expect(carbon.copyWith().hashCode, carbon.hashCode);
      expect(style.copyWith(itemGap: 0), isNot(style));
      expect(style.copyWith(itemMarginX: 12), isNot(style));
      expect(style.itemMarginX, isNull);
      expect(
        AdminShellStyle.lerp(
          style.copyWith(itemMarginX: 4),
          style.copyWith(itemMarginX: 12),
          0.5,
        ).itemMarginX,
        8,
      );
      expect(
        carbon,
        isNot(style.copyWith(sidebarWidth: 256, itemRadius: 0)),
        reason: 'the palette and the indicator differ',
      );
      final near = AdminShellStyle.lerp(style, carbon, 0.4);
      expect(near.sidebarWidth, closeTo(246.4, 1e-9));
      expect(near.topBarPalette, isNull);
      expect(near.itemRadius, isNull);
      final far = AdminShellStyle.lerp(style, carbon, 0.6);
      expect(far.topBarPalette, same(carbonShellPalette));
      expect(far.indicator, NavIndicator.edge);
      expect(far.itemRadius, 0);
    });

    test('AdminFocusSpec.innerWidth', () {
      const spec = AdminFocusSpec(width: 2, offset: 0, innerWidth: 1);
      expect(spec.copyWith(), spec);
      expect(spec, isNot(const AdminFocusSpec(width: 2, offset: 0)));
      expect(const AdminFocusSpec().innerWidth, 0);
      expect(
        AdminFocusSpec.lerp(const AdminFocusSpec(), spec, 0.5).innerWidth,
        0.5,
      );
    });
  });

  group('the kit defaults are the geometry it always drew', () {
    test('the shell', () {
      const shell = AdminShellStyle();
      expect(shell.sidebarWidth, Sidebar.expandedWidth);
      expect(shell.railWidth, Sidebar.collapsedWidth);
      expect(shell.topBarHeight, TopBar.height);
      expect(
        (shell.itemHeight, shell.itemGap, shell.itemPaddingX),
        (36, AdminSpacing.xs, AdminSpacing.md),
      );
      expect(shell.indicatorWidth, 3);
      expect(shell.itemRadiusOf(defaultRadii), defaultRadii.radiusSmall);
      expect(shell.itemIconSizeOf(const AdminIconSizes()), 16);
    });

    test('the selection mark follows the palette and the corner', () {
      const shell = AdminShellStyle();
      expect(shell.indicatorOf(irisPalette, defaultRadii), NavIndicator.bar);
      expect(
        shell.indicatorOf(irisPalette, defaultRadii.copyWith(radiusSmall: 0)),
        NavIndicator.edge,
      );
      expect(
        shell.indicatorOf(shadcnPalette, defaultRadii),
        NavIndicator.none,
        reason: 'shadcn draws a transparent navIndicator',
      );
      expect(
        shell.copyWith(itemRadius: 0).indicatorOf(irisPalette, defaultRadii),
        NavIndicator.edge,
      );
      expect(
        shell
            .copyWith(indicator: NavIndicator.none)
            .indicatorOf(irisPalette, defaultRadii),
        NavIndicator.none,
      );
    });

    test('radii: field and button roles derive from the scale', () {
      const r = AdminRadii(radiusSmall: 6, radius: 10, radiusLarge: 14);
      expect(r.radiusField, 10);
      expect(r.radiusButton, isNull);
      expect(r.button(ControlSize.small), 6);
      expect(r.button(ControlSize.medium), 10);
      expect(r.button(ControlSize.large), 10);
      final authored = r.copyWith(radiusField: 4, radiusButton: 999);
      expect(authored.radiusField, 4);
      for (final size in ControlSize.values) {
        expect(authored.button(size), 999);
      }
      expect(r.copyWith(radiusField: r.radiusField), isNot(r));
      expect(r.copyWith(radius: 12).radiusField, 12);
      final mid = AdminRadii.lerp(r, authored, 0.5);
      expect(mid.radiusField, 7);
      expect(mid.button(ControlSize.small), 504.5);
      expect(
        AdminRadii.lerp(r, r.copyWith(radius: 20), 0.5).radiusButton,
        isNull,
      );
      // The ends keep the derived per-size corner.
      expect(AdminRadii.lerp(authored, r, 1), r);
      expect(AdminRadii.lerp(authored, r, 1).button(ControlSize.small), 6);
      expect(AdminRadii.lerp(r, authored, 0), r);
    });

    test('palette: the new roles derive from the base', () {
      const p = irisPalette;
      expect(p.fieldFill, p.surface);
      expect(p.fieldFillHover, Color.alphaBlend(p.hoverOverlay, p.surface));
      expect(p.fieldRule, p.controlBorder, reason: 'already 3:1');
      expect(p.softFill, p.primarySubtle);
      expect(contrastRatio(p.onSoft, p.softFill), greaterThanOrEqualTo(4.5));
      expect(p.neutralFill, p.foregroundSecondary);
      expect(p.onNeutralFill, p.foregroundOn(p.foregroundSecondary));
      expect(
        p.neutralFillHover,
        Color.alphaBlend(
          p.surface.withValues(alpha: p.stateLayer.hover),
          p.neutralFill,
        ),
      );

      final authored = p.copyWith(
        fieldFill: const Color(0xFFF4F4F4),
        softFill: const Color(0xFFE8DEF8),
        neutralFill: const Color(0xFF393939),
      );
      expect(
        authored.fieldFillHover,
        Color.alphaBlend(p.hoverOverlay, const Color(0xFFF4F4F4)),
      );
      expect(authored.copyWith(), authored);
      final branded = authored.branded(_teal);
      expect(branded.fieldFill, authored.fieldFill, reason: 'kept');
      expect(branded.neutralFill, authored.neutralFill, reason: 'kept');
      expect(branded.softFill, branded.primarySubtle, reason: 'rebranded');
      final mid = AdminPalette.lerp(p, irisDarkPalette, 0.5);
      expect(mid.softFill, mid.primarySubtle, reason: 'still derived');
    });
  });

  group('tokens and themes carry the anatomy', () {
    const field = AdminFieldStyle(variant: FieldVariant.underlined);
    const button = AdminButtonStyle(accentGhost: true);
    const shell = AdminShellStyle(topBarHeight: 48);
    const darkShell = AdminShellStyle(topBarHeight: 64);
    const overlay = AdminOverlayStyle(tooltipArrow: true, arrowHeight: 8);

    test('AdminTokens.from, copyWith and lerp', () {
      final tokens = AdminTokens.from(
        palette: irisPalette,
        field: field,
        button: button,
        shell: shell,
        overlay: overlay,
      );
      expect(
        (tokens.field, tokens.button, tokens.shell, tokens.overlay),
        (field, button, shell, overlay),
      );
      final plain = AdminTokens.from(palette: irisPalette);
      expect(
        (plain.field, plain.button, plain.shell, plain.overlay),
        (
          const AdminFieldStyle(),
          const AdminButtonStyle(),
          const AdminShellStyle(),
          const AdminOverlayStyle(),
        ),
      );
      expect(
        plain.copyWith(
          field: field,
          button: button,
          shell: shell,
          overlay: overlay,
        ),
        tokens,
      );
      expect(tokens.lerp(plain, 0.5).shell.topBarHeight, 52);
      expect(tokens.lerp(plain, 0.5).overlay.arrowHeight, 7);
    });

    testWidgets('context getters read them', (tester) async {
      final tokens = AdminTokens.from(
        palette: irisPalette,
        field: field,
        button: button,
        shell: shell,
        overlay: overlay,
      );
      late (
        AdminFieldStyle,
        AdminButtonStyle,
        AdminShellStyle,
        AdminOverlayStyle,
      )
      read;
      await tester.pumpWidget(
        Theme(
          data: buildAppTheme(tokens),
          child: Builder(
            builder: (context) {
              read = (
                context.fieldStyle,
                context.buttonStyle,
                context.shellStyle,
                context.overlayStyle,
              );
              return const SizedBox();
            },
          ),
        ),
      );
      expect(read, (field, button, shell, overlay));
    });

    test('AdminTheme.from gives both modes the anatomy', () {
      final theme = AdminTheme.from(
        name: 'Test',
        palette: irisPalette,
        dark: irisDarkPalette,
        field: field,
        button: button,
        shell: shell,
        overlay: overlay,
      );
      for (final tokens in [theme.tokens, theme.dark!]) {
        expect(
          (tokens.field, tokens.button, tokens.shell, tokens.overlay),
          (field, button, shell, overlay),
        );
      }
      final split = AdminTheme.from(
        name: 'Test',
        palette: irisPalette,
        dark: irisDarkPalette,
        shell: shell,
        darkShell: darkShell,
      );
      expect(split.tokens.shell, shell);
      expect(split.dark!.shell, darkShell);
    });

    test('branding rebrands the shell palettes, lazily or not', () {
      final ant = antTheme.tokens;
      final branded = ant.branded(_teal);
      expect(branded.shell.sidebarPalette, antSiderPalette.branded(_teal));
      expect(branded.shell.sidebarWidth, ant.shell.sidebarWidth);
      expect(antTheme.branded('Ant Teal', _teal).tokens.shell, branded.shell);
      expect(
        carbonTheme.branded('Carbon Teal', _teal).dark!.shell.topBarPalette,
        carbonShellPalette.branded(_teal),
      );
      expect(irisTheme.tokens.branded(_teal).shell, const AdminShellStyle());
    });
  });

  group('the shipped presets', () {
    test('Iris and shadcn keep the kit defaults, bar the faded button', () {
      for (final theme in [irisTheme, shadcnTheme]) {
        for (final tokens in [theme.tokens, theme.dark!]) {
          expect(tokens.field, const AdminFieldStyle(), reason: theme.name);
          expect(tokens.shell, const AdminShellStyle(), reason: theme.name);
          expect(tokens.radii.radiusButton, isNull, reason: theme.name);
          expect(tokens.radii.radiusField, tokens.radii.radius);
          expect(tokens.focus.innerWidth, 0);
          expect(
            tokens.button,
            theme == shadcnTheme
                ? const AdminButtonStyle(disabled: ButtonDisabledStyle.faded)
                : const AdminButtonStyle(),
            reason: theme.name,
          );
        }
      }
    });

    // theme: (variant, focus indicator, accentFocus, accentHover)
    const fields = {
      'Iris': (
        FieldVariant.outlined,
        FieldFocusIndicator.outline,
        false,
        false,
      ),
      'Material': (
        FieldVariant.outlined,
        FieldFocusIndicator.outline,
        true,
        false,
      ),
      'shadcn': (
        FieldVariant.outlined,
        FieldFocusIndicator.outline,
        false,
        false,
      ),
      'Ant': (FieldVariant.outlined, FieldFocusIndicator.outline, true, true),
      'Fluent': (
        FieldVariant.underlined,
        FieldFocusIndicator.underline,
        true,
        false,
      ),
      'Carbon': (
        FieldVariant.filled,
        FieldFocusIndicator.outline,
        false,
        false,
      ),
    };
    // theme: (sidebar, rail, item, top bar, indicator)
    const shells = {
      'Iris': (240.0, 64.0, 36.0, 56.0, null),
      'Material': (360.0, 80.0, 56.0, 64.0, NavIndicator.none),
      'shadcn': (240.0, 64.0, 36.0, 56.0, null),
      'Ant': (200.0, 80.0, 40.0, 64.0, NavIndicator.none),
      'Fluent': (260.0, 48.0, 40.0, 48.0, NavIndicator.bar),
      'Carbon': (256.0, 48.0, 32.0, 48.0, NavIndicator.edge),
    };
    // theme: (label alignment, icon placement, weight, filled secondary)
    const buttons = {
      'Iris': (
        ButtonLabelAlignment.center,
        ButtonIconPlacement.leading,
        null,
        false,
      ),
      'Material': (
        ButtonLabelAlignment.center,
        ButtonIconPlacement.leading,
        FontWeight.w500,
        false,
      ),
      'shadcn': (
        ButtonLabelAlignment.center,
        ButtonIconPlacement.leading,
        null,
        false,
      ),
      'Ant': (
        ButtonLabelAlignment.center,
        ButtonIconPlacement.leading,
        FontWeight.w400,
        false,
      ),
      'Fluent': (
        ButtonLabelAlignment.center,
        ButtonIconPlacement.leading,
        FontWeight.w600,
        false,
      ),
      'Carbon': (
        ButtonLabelAlignment.start,
        ButtonIconPlacement.end,
        FontWeight.w400,
        true,
      ),
    };

    for (final theme in adminThemes) {
      test('${theme.name} draws its reference anatomy', () {
        final light = theme.tokens;
        final dark = theme.dark!;
        final f = light.field;
        expect((
          f.variant,
          f.focusIndicator,
          f.accentFocus,
          f.accentHover,
        ), fields[theme.name]);
        expect(dark.field, f);
        final s = light.shell;
        expect((
          s.sidebarWidth,
          s.railWidth,
          s.itemHeight,
          s.topBarHeight,
          s.indicator,
        ), shells[theme.name]);
        final b = light.button;
        expect((
          b.labelAlignment,
          b.iconPlacement,
          b.labelWeight,
          b.filledSecondary,
        ), buttons[theme.name]);
        expect(dark.button, b);
      });
    }

    test(
      'the chrome palettes: Carbon header in both modes, Ant sider light',
      () {
        final carbon = carbonTheme.tokens;
        final carbonDark = carbonTheme.dark!;
        expect(carbon.shell.topBarPalette, same(carbonShellPalette));
        expect(carbonDark.shell.topBarPalette, same(carbonShellPalette));
        expect(carbonShellPalette.surface, const Color(0xFF161616));
        expect(carbonShellPalette.focusRing, const Color(0xFFFFFFFF));
        expect(antTheme.tokens.shell.sidebarPalette, same(antSiderPalette));
        expect(antTheme.dark!.shell.sidebarPalette, isNull);
        expect(antSiderPalette.background, const Color(0xFF001529));
        expect(antSiderPalette.navSelectedFill, antPalette.primary);
      },
    );
  });

  group('resolveFieldChrome', () {
    const p = irisPalette;
    const stroke = AdminStroke(fieldFocus: 2, fieldError: 1);
    FieldChromeSpec chrome(AdminFieldStyle style, Set<WidgetState> states) =>
        FieldChromeSpec.of(p, states, stroke: stroke, style: style);
    BorderSide side(Color color, double width) =>
        BorderSide(color: color, width: width);
    final quiet = Color.lerp(p.border, p.controlBorder, 0.5)!;

    test('outlined draws fieldBorderSide, and no rule', () {
      for (final stroke in const [
        AdminStroke(),
        AdminStroke(fieldFocus: 1, fieldError: 1, fieldFocusHalo: 3),
        AdminStroke(fieldFocus: 2, fieldError: 2),
      ]) {
        for (final palette in [irisPalette, shadcnDarkPalette, carbonPalette]) {
          for (final states in [
            <WidgetState>{},
            _hovered,
            _focused,
            _disabled,
            _error,
            _focusedError,
          ]) {
            final spec = FieldChromeSpec.of(palette, states, stroke: stroke);
            expect(
              spec.outline,
              fieldBorderSide(palette, states, stroke: stroke),
            );
            expect(spec.rule, BorderSide.none);
            expect(spec.fill, fieldFillColor(palette, states));
            expect(spec.halo, fieldFocusHalo(palette, states, stroke: stroke));
          }
        }
      }
    });

    test('a state resolves once per palette, stroke and style', () {
      final tokens = antTheme.tokens;
      FieldChromeSpec hovered() => resolveFieldChrome(tokens, _hovered);
      expect(identical(hovered(), hovered()), isTrue);
      // A state the chrome does not read shares the entry.
      expect(
        identical(
          resolveFieldChrome(tokens, {..._hovered, WidgetState.pressed}),
          hovered(),
        ),
        isTrue,
      );
      expect(
        FieldChromeSpec.of(
          tokens.palette,
          _hovered,
          stroke: tokens.stroke,
          style: const AdminFieldStyle(),
        ),
        isNot(hovered()),
      );
      expect(FieldBorder.of(tokens), FieldBorder.of(tokens));
      expect(
        FieldBorder.of(tokens),
        isNot(FieldBorder.of(tokens.copyWith(palette: irisPalette))),
      );
    });

    test('the outlined helpers follow a style\'s accents', () {
      for (final theme in [antTheme, materialTheme]) {
        final tokens = theme.tokens;
        for (final states in [
          <WidgetState>{},
          _hovered,
          _focused,
          _disabled,
          _error,
          _focusedError,
        ]) {
          final spec = resolveFieldChrome(tokens, states);
          expect(
            fieldBorderSide(
              tokens.palette,
              states,
              stroke: tokens.stroke,
              style: tokens.field,
            ),
            spec.outline,
            reason: '${theme.name} $states',
          );
          expect(
            fieldFocusHalo(
              tokens.palette,
              states,
              stroke: tokens.stroke,
              style: tokens.field,
            ),
            spec.halo,
          );
        }
        const state = FieldState();
        expect(
          state.borderSide(
            tokens.palette,
            focused: true,
            stroke: tokens.stroke,
            style: tokens.field,
          ),
          resolveFieldChrome(tokens, _focused).outline,
        );
      }
    });

    test('filled: a bottom rule, a hover fill, an inset focus outline', () {
      const style = AdminFieldStyle(variant: FieldVariant.filled);
      final rest = chrome(style, {});
      expect(rest.outline, BorderSide.none);
      expect(rest.rule, side(p.fieldRule, 1));
      expect(rest.fill, p.fieldFill);
      expect(rest.border, const EdgeInsets.only(bottom: 1));

      final hover = chrome(style, _hovered);
      expect(hover.fill, p.fieldFillHover);
      expect(hover.outline, BorderSide.none);
      expect(
        contrastRatio(hover.rule.color, p.fieldFill),
        greaterThan(contrastRatio(rest.rule.color, p.fieldFill)),
      );

      final focus = chrome(style, _focused);
      expect(focus.outline, side(p.focusRing, 2));
      expect(focus.rule, BorderSide.none);
      expect(focus.border, const EdgeInsets.all(2));

      expect(chrome(style, _error).outline, side(p.danger, 1));
      expect(chrome(style, _focusedError).outline, side(p.danger, 2));
      final disabled = chrome(style, _disabled);
      expect(disabled.rule, side(quiet, 1));
      expect(disabled.outline, BorderSide.none);
      expect(disabled.fill, fieldFillColor(p, _disabled));
    });

    test('filled with an underline: M3 thickens the rule in the accent', () {
      const style = AdminFieldStyle(
        variant: FieldVariant.filled,
        focusIndicator: FieldFocusIndicator.underline,
        accentFocus: true,
      );
      final focus = chrome(style, _focused);
      expect(focus.outline, BorderSide.none);
      expect(focus.rule, side(p.controlAccent, 2));
      expect(chrome(style, _error).rule, side(p.danger, 1));
      expect(chrome(style, _error).outline, BorderSide.none);
      expect(chrome(style, _focusedError).rule, side(p.danger, 2));
    });

    test('underlined: Fluent keeps the frame and thickens the rule', () {
      const style = AdminFieldStyle(
        variant: FieldVariant.underlined,
        focusIndicator: FieldFocusIndicator.underline,
        accentFocus: true,
      );
      final rest = chrome(style, {});
      expect(rest.outline, side(p.border, 1));
      expect(rest.rule, side(p.fieldRule, 1));
      expect(rest.border, const EdgeInsets.all(1));

      final hover = chrome(style, _hovered);
      expect(hover.outline, rest.outline);
      expect(hover.fill, p.fieldFill);
      expect(hover.rule.color, isNot(rest.rule.color));

      final focus = chrome(style, _focused);
      expect(focus.outline, rest.outline);
      expect(focus.rule, side(p.controlAccent, 2));
      expect(focus.border, const EdgeInsets.fromLTRB(1, 1, 1, 2));

      final error = chrome(style, _error);
      expect(error.outline, side(p.danger, 1));
      expect(error.rule, side(p.danger, 1));
      expect(chrome(style, _focusedError).rule, side(p.danger, 2));

      final disabled = chrome(style, _disabled);
      expect(disabled.outline, side(quiet, 1));
      expect(disabled.rule, BorderSide.none);
    });

    test('accent hover eases the accent, never past the focused edge', () {
      for (final palette in [antPalette, antDarkPalette, irisPalette]) {
        const style = AdminFieldStyle(accentFocus: true, accentHover: true);
        final spec = FieldChromeSpec.of(
          palette,
          _hovered,
          stroke: const AdminStroke(fieldFocus: 1, fieldError: 1),
          style: style,
        );
        final fill = palette.fieldFill;
        final hover = contrastRatio(spec.outline.color, fill);
        expect(hover, greaterThanOrEqualTo(3));
        expect(
          hover,
          greaterThanOrEqualTo(contrastRatio(palette.controlBorder, fill)),
        );
        expect(
          hover,
          lessThanOrEqualTo(contrastRatio(palette.controlAccent, fill)),
        );
        expect(spec.outline.width, 1);
      }
    });

    test('the halo takes the accent at the style opacity', () {
      const style = AdminFieldStyle(accentFocus: true, haloOpacity: 0.2);
      const halo = AdminStroke(fieldFocus: 1, fieldError: 1, fieldFocusHalo: 2);
      final spec = FieldChromeSpec.of(
        antPalette,
        _focused,
        stroke: halo,
        style: style,
      );
      expect(spec.halo.width, 2);
      expect(spec.halo.color, antPalette.controlAccent.withValues(alpha: 0.2));
      expect(
        FieldChromeSpec.of(antPalette, {}, stroke: halo, style: style).halo,
        BorderSide.none,
      );
      expect(
        fieldFocusHalo(irisPalette, _focused, stroke: halo).color,
        irisPalette.focusRing.withValues(alpha: 0.5),
        reason: 'the default style keeps half',
      );
    });

    test('reads the tokens', () {
      final tokens = carbonTheme.tokens;
      expect(
        resolveFieldChrome(tokens, _focused),
        FieldChromeSpec.of(
          tokens.palette,
          _focused,
          stroke: tokens.stroke,
          style: tokens.field,
        ),
      );
      expect(resolveFieldChrome(tokens, {}).variant, FieldVariant.filled);
    });
  });

  group('FieldBorder', () {
    final iris = AdminTokens.from(palette: irisPalette);
    final carbon = carbonTheme.tokens;
    const states = <Set<WidgetState>>[
      {},
      _hovered,
      _focused,
      _disabled,
      _error,
      _focusedError,
    ];

    test('an outlined box resolves as FieldOutlineBorder does', () {
      for (final tokens in [
        iris,
        AdminTokens.from(
          palette: shadcnPalette,
          stroke: const AdminStroke(
            fieldFocus: 1,
            fieldError: 1,
            fieldFocusHalo: 3,
          ),
        ),
      ]) {
        final radius = BorderRadius.circular(tokens.radii.radiusField);
        final p = tokens.palette;
        final stroke = tokens.stroke;
        final outline = FieldOutlineBorder(
          side: (s) => fieldBorderSide(p, s, stroke: stroke),
          halo: stroke.fieldFocusHalo > 0
              ? (s) => fieldFocusHalo(p, s, stroke: stroke)
              : null,
          borderRadius: radius,
        );
        final border = FieldBorder.of(tokens);
        for (final s in states) {
          expect(border.resolve(s), outline.resolve(s), reason: '$s');
        }
        expect(border.borderSide, outline.borderSide);
        expect(border.gapPadding, 0);
      }
    });

    test('keeps its states through copyWith; a side pins the outline', () {
      final border = FieldBorder.of(carbon);
      final round = border.copyWith(borderRadius: BorderRadius.circular(6));
      expect(round.borderRadius, BorderRadius.circular(6));
      expect(round.chromeOf(_focused), border.chromeOf(_focused));
      expect(round, isNot(border));
      const pin = BorderSide(color: Color(0xFF0D9488), width: 3);
      final pinned = border.copyWith(borderSide: pin);
      for (final s in states) {
        expect((pinned.resolve(s) as OutlineInputBorder).borderSide, pin);
      }
      expect(pinned.copyWith(borderRadius: BorderRadius.zero).borderSide, pin);
    });

    test('equality follows the states, not the closures', () {
      Set<WidgetState> addError(Set<WidgetState> s) => {
        ...s,
        WidgetState.error,
      };
      expect(FieldBorder.of(carbon), FieldBorder.of(carbon));
      expect(FieldBorder.of(carbon).hashCode, FieldBorder.of(carbon).hashCode);
      expect(
        FieldBorder.of(carbon, mapStates: addError),
        FieldBorder.of(carbon, mapStates: (s) => {...s, WidgetState.error}),
      );
      expect(
        FieldBorder.of(carbon, mapStates: addError),
        isNot(FieldBorder.of(carbon)),
      );
      expect(
        FieldBorder.of(carbon, mapStates: addError).chromeOf({}),
        resolveFieldChrome(carbon, _error),
      );
    });

    test('a filled box: square-bottomed, laid out as an outline', () {
      final tokens = carbon.copyWith(
        radii: carbon.radii.copyWith(radiusField: 4),
      );
      final border = FieldBorder.of(tokens);
      final rest = border.resolve({}) as OutlineInputBorder;
      expect(rest.gapPadding, 0);
      expect(rest.isOutline, isTrue);
      expect(rest.dimensions, const EdgeInsets.only(bottom: 1));
      const rect = Rect.fromLTWH(0, 0, 100, 40);
      final path = rest.getOuterPath(rect);
      expect(path.contains(const Offset(0.2, 39.8)), isTrue, reason: 'square');
      expect(path.contains(const Offset(0.2, 0.2)), isFalse, reason: 'round');
      expect(border.getOuterPath(rect).getBounds(), rect);

      // Halfway to focus: the 2px outline fades in over the fading rule.
      final focus = border.resolve(_focused);
      final mid = ShapeBorder.lerp(rest, focus, 0.5)! as OutlineInputBorder;
      expect(mid.dimensions, const EdgeInsets.all(1));
      expect(mid, isNot(rest));
      expect(mid, isNot(focus));
    });

    testWidgets('paints its box in a TextField and a ShapeDecoration', (
      tester,
    ) async {
      final theme = buildAppTheme(carbon);
      expect(theme.inputDecorationTheme.border, isA<FieldBorder>());
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Material(
            child: Column(
              children: [
                const TextField(autofocus: true),
                Container(
                  width: 100,
                  height: 40,
                  decoration: fieldDecoration(
                    carbon,
                    _focused,
                    BorderRadius.zero,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final p = carbon.palette;
      // The fill in the box's shape, then the 2px $focus outline inside it.
      for (final target in [find.byType(TextField), find.byType(Container)]) {
        expect(
          target,
          paints
            ..rrect(color: p.fieldFill)
            ..rrect(color: p.focusRing, strokeWidth: 2),
        );
      }
    });
  });

  group('field decorations', () {
    final iris = AdminTokens.from(palette: irisPalette);
    final radius = BorderRadius.circular(9);

    test('an outline alone is the BoxDecoration FieldChrome draws', () {
      for (final s in [<WidgetState>{}, _hovered, _focused, _error]) {
        final side = fieldBorderSide(iris.palette, s, stroke: iris.stroke);
        expect(
          fieldDecoration(iris, s, radius),
          BoxDecoration(
            color: fieldFillColor(iris.palette, s),
            borderRadius: radius,
            border: Border.all(color: side.color, width: side.width),
          ),
        );
      }
      expect(fieldForegroundDecoration(iris, _focused, radius), isNull);
    });

    test('a rule makes a ShapeDecoration padded by the edges', () {
      final carbon = carbonTheme.tokens;
      for (final s in [<WidgetState>{}, _hovered, _focused, _error]) {
        final decoration = fieldDecoration(carbon, s, radius);
        expect(decoration, isA<ShapeDecoration>(), reason: '$s');
        expect(decoration.padding, resolveFieldChrome(carbon, s).border);
      }
      expect(
        (fieldDecoration(carbon, _hovered, radius) as ShapeDecoration).color,
        carbon.palette.fieldFillHover,
      );
    });

    test('a filled box leaves its halo to the foreground', () {
      final carbon = carbonTheme.tokens;
      final haloed = carbon.copyWith(
        stroke: carbon.stroke.copyWith(fieldFocusHalo: 2),
      );
      expect(resolveFieldChrome(haloed, _focused).halo.width, 2);
      expect(
        fieldDecoration(haloed, _focused, radius),
        fieldDecoration(carbon, _focused, radius),
        reason: 'the box paints no halo of its own',
      );
      expect(fieldForegroundDecoration(haloed, _focused, radius), isNotNull);
    });

    test('the halo, outside the box', () {
      final shadcn = shadcnTheme.tokens;
      expect(fieldForegroundDecoration(shadcn, {}, radius), isNull);
      final halo = fieldForegroundDecoration(shadcn, _focused, radius)!;
      expect(
        halo,
        BoxDecoration(
          borderRadius: radius,
          border: Border.fromBorderSide(
            fieldFocusHalo(shadcn.palette, _focused, stroke: shadcn.stroke),
          ),
        ),
      );
    });
  });

  group('FocusRing', () {
    /// The bands a focused [FocusRing] draws around a 40px box, as
    /// (rect, border width, colour), in keyboard highlight mode.
    Future<List<(Rect, double, Color)>> bands(
      WidgetTester tester,
      AdminFocusSpec spec,
    ) async {
      final tokens = AdminTokens.from(palette: fluentPalette, focus: spec);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Theme(
            data: buildAppTheme(tokens),
            child: const Center(
              child: FocusRing(
                focused: true,
                child: SizedBox(width: 40, height: 40),
              ),
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final boxes = find.descendant(
        of: find.byType(FocusRing),
        matching: find.byType(DecoratedBox),
      );
      return [
        for (final element in boxes.evaluate())
          if ((element.widget as DecoratedBox).decoration case BoxDecoration(
            border: final Border border,
          ))
            (
              tester.getRect(find.byWidget(element.widget)),
              border.top.width,
              border.top.color,
            ),
      ];
    }

    testWidgets("a flush ring lays Fluent's inner band inside", (tester) async {
      const p = fluentPalette;
      final flush = await bands(tester, const AdminFocusSpec(offset: 0));
      final box = tester.getRect(find.byType(SizedBox));
      expect(flush, [(box.inflate(2), 2.0, p.focusRing)]);
      expect(
        await bands(tester, const AdminFocusSpec(offset: 0, innerWidth: 1)),
        [(box, 1.0, p.surface), (box.inflate(2), 2.0, p.focusRing)],
      );
    });
  });
}
