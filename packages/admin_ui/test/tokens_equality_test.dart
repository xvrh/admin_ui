// AdminTokens compare by value, copyWith(palette:) re-derives what derives
// from the palette, and adminThemes cannot be edited.

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _teal = Color(0xFF0D9488);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tokenSets = {
    for (final theme in adminThemes) ...{
      '${theme.name} Light': theme.tokens,
      '${theme.name} Dark': theme.dark!,
    },
  };

  group('value equality', () {
    for (final MapEntry(key: name, value: tokens) in tokenSets.entries) {
      test('$name: a copy equals its original', () {
        final copy = tokens.copyWith();
        expect(copy, isNot(same(tokens)));
        expect(copy, tokens);
        expect(copy.hashCode, tokens.hashCode);

        final palette = tokens.palette;
        expect(palette.copyWith(), palette);
        expect(palette.copyWith().hashCode, palette.hashCode);

        final radii = tokens.radii;
        expect(radii.copyWith(), radii);
        expect(radii.copyWith().hashCode, radii.hashCode);

        final type = tokens.typography;
        final rebuilt = AdminTypography.from(palette, type.spec);
        expect(rebuilt, type);
        expect(rebuilt.hashCode, type.hashCode);

        final elevation = AdminElevation.lerp(
          tokens.elevation,
          tokens.elevation,
          0,
        );
        expect(elevation, tokens.elevation);
        expect(elevation.hashCode, tokens.elevation.hashCode);

        final spec = type.spec;
        expect(spec.copyWith(), spec);
        expect(spec.copyWith().hashCode, spec.hashCode);
        expect(spec.ramp.copyWith(), spec.ramp);

        for (final (copy, original) in <(Object, Object)>[
          (tokens.motion.copyWith(), tokens.motion),
          (tokens.stroke.copyWith(), tokens.stroke),
          (tokens.iconSizes.copyWith(), tokens.iconSizes),
          (palette.stateLayer.copyWith(), palette.stateLayer),
          (tokens.field.copyWith(), tokens.field),
          (tokens.button.copyWith(), tokens.button),
          (tokens.shell.copyWith(), tokens.shell),
          (tokens.focus.copyWith(), tokens.focus),
        ]) {
          expect(copy, original);
          expect(copy.hashCode, original.hashCode);
        }
      });
    }

    test('a changed member breaks equality', () {
      final tokens = tokenSets['Iris Light']!;
      final palette = tokens.palette;
      expect(palette.copyWith(primary: _teal), isNot(palette));
      expect(
        palette.copyWith(chart: [...palette.chart, _teal]),
        isNot(palette),
      );
      // An optional role authored at the value it would derive to is still
      // a different palette: it no longer follows the base.
      expect(palette.copyWith(onPrimary: palette.onPrimary), isNot(palette));
      expect(
        palette.copyWith(controlAccent: palette.controlAccent),
        isNot(palette),
      );
      expect(
        palette.copyWith(controlAccent: _teal).hashCode,
        isNot(palette.hashCode),
      );
      expect(
        tokens.radii.copyWith(radiusMenu: tokens.radii.radiusMenu),
        isNot(tokens.radii),
      );
      expect(
        tokens.copyWith(radii: defaultRadii.copyWith(radius: 3)),
        isNot(tokens),
      );
      expect(
        const AdminTypeSpec(fontFamily: 'Inter'),
        isNot(const AdminTypeSpec(fontFamily: 'Roboto')),
      );
      expect(const AdminTypeSpec(scale: 1.1), const AdminTypeSpec(scale: 1.1));
      expect(defaultElevation, isNot(defaultDarkElevation));
      expect(
        tokens.copyWith(motion: defaultMotion.copyWith(fast: Duration.zero)),
        isNot(tokens),
      );
      expect(
        tokens.copyWith(stroke: const AdminStroke(fieldFocus: 3)),
        isNot(tokens),
      );
      expect(
        tokens.copyWith(iconSizes: const AdminIconSizes(md: 18)),
        isNot(tokens),
      );
      expect(
        tokens.copyWith(
          field: const AdminFieldStyle(variant: FieldVariant.filled),
        ),
        isNot(tokens),
      );
      expect(
        tokens.copyWith(button: const AdminButtonStyle(accentGhost: true)),
        isNot(tokens),
      );
      expect(
        tokens.copyWith(shell: const AdminShellStyle(topBarHeight: 48)),
        isNot(tokens),
      );
      expect(
        palette.copyWith(fieldFill: palette.fieldFill),
        isNot(palette),
        reason: 'an authored role no longer follows the base',
      );
      expect(
        palette.copyWith(stateLayer: const AdminStateLayer(hover: 0.08)),
        isNot(palette),
      );
      expect(
        const AdminTypeSpec(),
        isNot(
          AdminTypeSpec(
            ramp: defaultTypeRamp.copyWith(body: const AdminTypeStep(14, 20)),
          ),
        ),
      );
    });

    test('branding with one seed twice gives equal tokens', () {
      for (final tokens in tokenSets.values) {
        final a = tokens.branded(_teal);
        final b = tokens.branded(_teal);
        expect(a, isNot(same(b)));
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      }
    });

    test('themes stay equal by name', () {
      final theme = adminThemes.first;
      expect(theme.branded(theme.name, _teal), theme);
      expect(theme.branded('Other', _teal), isNot(theme));
    });
  });

  group('copyWith(palette:)', () {
    final tokens = tokenSets['Iris Light']!;
    final other = adminThemes[1].palette;

    test('re-derives a derived typography from the new palette', () {
      final copy = tokens.copyWith(palette: other);
      expect(copy.palette, same(other));
      expect(copy.typography.spec, same(tokens.typography.spec));
      expect(copy.typography.body.color, other.foreground);
      expect(copy.typography.fieldLabel.color, other.foregroundSecondary);
      expect(copy.typography.caption.color, other.foregroundMuted);
      expect(
        copy.typography,
        AdminTypography.from(other, tokens.typography.spec),
      );
    });

    test('keeps a typography built by hand', () {
      final custom = AdminTypography.from(
        tokens.palette.copyWith(foreground: _teal),
        tokens.typography.spec,
      );
      final handBuilt = tokens.copyWith(typography: custom);
      final copy = handBuilt.copyWith(palette: other);
      expect(copy.typography, same(custom));
      expect(copy.typography.body.color, _teal);
    });

    test('takes an explicit typography over the derived one', () {
      final custom = AdminTypography.from(
        other,
        const AdminTypeSpec(scale: 1.2),
      );
      final copy = tokens.copyWith(palette: other, typography: custom);
      expect(copy.typography, same(custom));
    });

    test('branded keeps the typography colours', () {
      final branded = tokens.branded(_teal);
      expect(branded.typography, tokens.typography);
    });
  });

  test('adminThemes is unmodifiable', () {
    expect(
      () => adminThemes.add(AdminTheme(name: 'Extra', tokens: defaultTokens)),
      throwsUnsupportedError,
    );
    expect(() => adminThemes.removeLast(), throwsUnsupportedError);
    expect(adminThemes.map((t) => t.name), [
      'Iris',
      'Material',
      'shadcn',
      'Ant',
      'Fluent',
      'Carbon',
    ]);
  });
}
