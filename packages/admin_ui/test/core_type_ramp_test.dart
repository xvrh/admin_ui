import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Every style of [type], by name.
Map<String, TextStyle> _styles(AdminTypography type) => {
  'fieldLabel': type.fieldLabel,
  'fieldText': type.fieldText,
  'fieldDescription': type.fieldDescription,
  'fieldMessage': type.fieldMessage,
  'pageTitle': type.pageTitle,
  'heading': type.heading,
  'sectionLabel': type.sectionLabel,
  'body': type.body,
  'bodyStrong': type.bodyStrong,
  'bodyMuted': type.bodyMuted,
  'bodySmall': type.bodySmall,
  'caption': type.caption,
  'micro': type.micro,
  'button': type.button,
  'buttonSmall': type.buttonSmall,
  'mono': type.mono,
  'monoSmall': type.monoSmall,
};

bool _whole(double value) => (value - value.roundToDouble()).abs() < 1e-9;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final tokenSets = {
    for (final theme in adminThemes) ...{
      '${theme.name} Light': theme.tokens,
      '${theme.name} Dark': theme.dark!,
    },
  };

  group('each shipped theme', () {
    for (final MapEntry(key: name, value: tokens) in tokenSets.entries) {
      final type = tokens.typography;

      test('$name: every step is whole pixels, 10 or more', () {
        for (final MapEntry(key: role, value: step)
            in type.spec.ramp.steps.entries) {
          expect(_whole(step.size), isTrue, reason: '$role size ${step.size}');
          expect(_whole(step.line), isTrue, reason: '$role line ${step.line}');
          expect(step.size, greaterThanOrEqualTo(10), reason: role);
          expect(step.line, greaterThanOrEqualTo(step.size), reason: role);
        }
      });

      test('$name: every style has a whole size on a fixed line', () {
        for (final MapEntry(key: role, value: style) in _styles(type).entries) {
          final size = style.fontSize!;
          expect(_whole(size), isTrue, reason: '$role size $size');
          expect(style.height, isNotNull, reason: '$role has no line height');
          expect(
            _whole(size * style.height!),
            isTrue,
            reason: '$role line ${size * style.height!}',
          );
          expect(
            style.leadingDistribution,
            TextLeadingDistribution.even,
            reason: role,
          );
        }
      });

      test('$name: control text fits the smallest control', () {
        final sizes = tokens.sizes;
        expect(fieldPaddingY(type, sizes.small), greaterThanOrEqualTo(0));
        for (final (role, style) in [
          ('fieldText', type.fieldText),
          ('button', type.button),
          ('buttonSmall', type.buttonSmall),
        ]) {
          expect(
            style.fontSize! * style.height!,
            lessThanOrEqualTo(sizes.small - 2),
            reason: '$role in a ${sizes.small} control with its border',
          );
        }
      });

      test('$name: a field label, its description and its error', () {
        expect(type.fieldLabel.color, tokens.palette.foregroundSecondary);
        expect(
          type.fieldLabel.fontWeight,
          type.spec.label ?? type.spec.heading,
        );
        expect(type.caption.color, tokens.palette.foregroundMuted);
        expect(type.fieldDescription.color, tokens.palette.foregroundMuted);
        expect(type.fieldDescription.fontWeight, type.spec.body);
        expect(type.fieldMessage.fontWeight, FontWeight.w500);
        // A description and the error that replaces it are one size.
        final ramp = type.spec.ramp;
        expect(
          (ramp.fieldDescription.size, ramp.fieldDescription.line),
          (ramp.fieldMessage.size, ramp.fieldMessage.line),
        );
        expect(
          type.fieldLabel.fontSize,
          greaterThanOrEqualTo(type.caption.fontSize!),
        );
      });
    }
  });

  test('each theme takes its reference sizes', () {
    // (body, fieldText, caption, fieldLabel, fieldDescription) as size/line.
    const expected = {
      'Iris': ('13/20', '13/20', '12/16', '12/16', '12/16'),
      'Material': ('14/20', '16/24', '12/16', '12/16', '12/16'),
      'shadcn': ('14/20', '14/20', '12/16', '14/20', '14/20'),
      'Ant': ('14/22', '14/22', '12/20', '14/22', '14/22'),
      'Fluent': ('14/20', '14/20', '12/16', '14/20', '12/16'),
      'Carbon': ('14/20', '14/18', '12/16', '12/16', '12/16'),
    };
    String of(AdminTypeStep step) =>
        '${step.size.toInt()}/${step.line.toInt()}';
    for (final theme in adminThemes) {
      final ramp = theme.tokens.typography.spec.ramp;
      expect(
        (
          of(ramp.body),
          of(ramp.fieldText),
          of(ramp.caption),
          of(ramp.fieldLabel),
          of(ramp.fieldDescription),
        ),
        expected[theme.name],
        reason: theme.name,
      );
    }
  });

  test("each theme's field label takes its reference weight", () {
    const expected = {
      'Iris': FontWeight.w700,
      'Material': FontWeight.w400,
      'shadcn': FontWeight.w500,
      'Ant': FontWeight.w400,
      'Fluent': FontWeight.w400,
      'Carbon': FontWeight.w400,
    };
    for (final theme in adminThemes) {
      final type = theme.tokens.typography;
      expect(
        type.fieldLabel.fontWeight,
        expected[theme.name],
        reason: theme.name,
      );
    }
  });

  test('shadcn tracks its headings tight and nothing smaller', () {
    final ramp = shadcnTheme.tokens.typography.spec.ramp;
    expect(ramp.pageTitle.letterSpacing, lessThan(0));
    expect(ramp.heading.letterSpacing, lessThan(0));
    final type = shadcnTheme.tokens.typography;
    for (final (role, style) in [
      ('caption', type.caption),
      ('micro', type.micro),
      ('body', type.body),
      ('fieldText', type.fieldText),
      ('fieldLabel', type.fieldLabel),
    ]) {
      expect(style.letterSpacing, greaterThanOrEqualTo(0), reason: role);
    }
  });

  test('the spec tracking is still added to every style', () {
    const spec = AdminTypeSpec(tracking: 0.5);
    final type = AdminTypography.from(irisPalette, spec);
    final plain = AdminTypography.from(irisPalette);
    expect(type.body.letterSpacing, plain.body.letterSpacing! + 0.5);
    expect(type.micro.letterSpacing, plain.micro.letterSpacing! + 0.5);
  });

  test('scale multiplies sizes and lines', () {
    final type = AdminTypography.from(
      irisPalette,
      const AdminTypeSpec(scale: 1.5),
    );
    expect(type.body.fontSize, 13 * 1.5);
    expect(type.body.fontSize! * type.body.height!, closeTo(30, 1e-9));
    expect(type.sizeDisplayLarge, defaultTypeRamp.displayLarge.size * 1.5);
  });

  group('mono', () {
    test('is the platform monospace family, with its fallbacks', () {
      final type = AdminTypography.from(irisPalette);
      expect(type.mono.fontFamily, 'monospace');
      expect(type.mono.fontFamilyFallback, contains('Menlo'));
      expect(type.monoSmall.fontSize, 12);
      expect(type.body.fontFamily, isNot('monospace'));
    });

    test('weighted keeps the monospace family', () {
      final type = AdminTypography.from(
        irisPalette,
        const AdminTypeSpec(fontFamily: 'Inter'),
      );
      final bold = type.weighted(type.mono, FontWeight.w700);
      expect(bold.fontFamily, 'monospace');
      expect(bold.fontWeight, FontWeight.w700);
      expect(bold.fontSize, type.mono.fontSize);
      final body = type.weighted(type.body, FontWeight.w700);
      expect(body.fontFamily, 'Inter');
    });

    test('weighted keeps a monospace font of the theme\'s own', () {
      const spec = AdminTypeSpec(
        fontFamily: 'Inter',
        monoFontFamily: 'Roboto Mono',
      );
      final type = AdminTypography.from(irisPalette, spec);
      expect(type.mono.fontFamily, 'Roboto Mono');
      final bold = type.weighted(type.mono, FontWeight.w700);
      expect(bold.fontFamily, 'Roboto Mono');
      final again = type.weighted(bold, FontWeight.w400);
      expect(again.fontFamily, 'Roboto Mono');
    });
  });

  test('a typography built by hand falls back for the new roles', () {
    const button = TextStyle(fontSize: 13);
    const body = TextStyle(fontSize: 14);
    const type = AdminTypography(
      sizeDisplayLarge: 36,
      sizeDisplayMedium: 28,
      sizeDisplaySmall: 24,
      sizeHeadlineMedium: 20,
      sizeHeadlineSmall: 18,
      sizeTitleLarge: 18,
      fieldLabel: body,
      fieldText: body,
      fieldMessage: body,
      pageTitle: body,
      heading: body,
      sectionLabel: body,
      body: body,
      bodyStrong: body,
      bodyMuted: body,
      bodySmall: body,
      caption: body,
      micro: body,
      button: button,
      spec: AdminTypeSpec(),
    );
    expect(type.buttonSmall, button);
    expect(type.mono, body);
    expect(type.monoSmall, body);
  });

  group('value semantics', () {
    test('steps and ramps', () {
      const step = AdminTypeStep(14, 20, letterSpacing: 0.1);
      expect(step.copyWith(), step);
      expect(step.copyWith().hashCode, step.hashCode);
      expect(step.copyWith(line: 22), isNot(step));
      expect(
        AdminTypeStep.lerp(
          const AdminTypeStep(12, 16),
          const AdminTypeStep(14, 20),
          0.5,
        ),
        const AdminTypeStep(13, 18),
      );

      expect(defaultTypeRamp.copyWith(), defaultTypeRamp);
      expect(defaultTypeRamp.copyWith().hashCode, defaultTypeRamp.hashCode);
      final bigger = defaultTypeRamp.copyWith(
        body: const AdminTypeStep(14, 20),
      );
      expect(bigger, isNot(defaultTypeRamp));
      expect(AdminTypeRamp.lerp(defaultTypeRamp, bigger, 0), defaultTypeRamp);
      expect(AdminTypeRamp.lerp(defaultTypeRamp, bigger, 1), bigger);
      expect(
        AdminTypeRamp.lerp(defaultTypeRamp, bigger, 0.5).body,
        const AdminTypeStep(13.5, 20),
      );
    });

    test('the spec compares its ramp and mono knobs', () {
      const spec = AdminTypeSpec();
      expect(spec.copyWith(), spec);
      expect(spec.copyWith().hashCode, spec.hashCode);
      expect(
        spec.copyWith(
          ramp: defaultTypeRamp.copyWith(micro: defaultTypeRamp.caption),
        ),
        isNot(spec),
      );
      expect(spec.copyWith(monoFontFamily: 'Courier'), isNot(spec));
      expect(spec.copyWith(monoFontFamily: 'Roboto Mono'), isNot(spec));
      expect(
        spec.copyWith(monoFontFamilyFallback: const ['Menlo']),
        isNot(spec),
      );
    });

    test('a typography compares its new roles', () {
      final a = AdminTypography.from(irisPalette);
      final b = AdminTypography.from(irisPalette);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      final lerped = AdminTypography.lerp(a, b, 0.5);
      expect(lerped.buttonSmall, a.buttonSmall);
      expect(lerped.mono, a.mono);
      expect(lerped.monoSmall, a.monoSmall);
    });
  });
}
