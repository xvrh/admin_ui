import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// The type roles a theme weighs and inks apart from its headings: the large
// titles (a page's and a dialog's), a field's error line and a field's label.

/// What each shipped theme sets, from its reference: the page title and the
/// dialog title as size/line and weight, the weight of a heading, of a field
/// message, and the ink of a field label.
const _expected =
    <
      String,
      ({
        String pageTitle,
        String dialogTitle,
        FontWeight title,
        FontWeight heading,
        FontWeight message,
        LabelInk labelInk,
      })
    >{
      // the kit's own look: one bold weight for every heading
      'Iris': (
        pageTitle: '22/28',
        dialogTitle: '16/24',
        title: FontWeight.w700,
        heading: FontWeight.w700,
        message: FontWeight.w500,
        labelInk: LabelInk.secondary,
      ),
      // headlineSmall is Regular, for a page and for a dialog's headline;
      // titleMedium Medium; supporting text bodySmall; label onSurfaceVariant
      'Material': (
        pageTitle: '24/32',
        dialogTitle: '24/32',
        title: FontWeight.w400,
        heading: FontWeight.w500,
        message: FontWeight.w400,
        labelInk: LabelInk.secondary,
      ),
      // DialogTitle: text-lg font-semibold; FieldError: font-normal; Label
      // inherits the foreground
      'shadcn': (
        pageTitle: '24/32',
        dialogTitle: '18/28',
        title: FontWeight.w600,
        heading: FontWeight.w600,
        message: FontWeight.w400,
        labelInk: LabelInk.foreground,
      ),
      // a modal's title is heading 5 at fontWeightStrong; a form item's
      // label is colorTextHeading and its explain line regular
      'Ant': (
        pageTitle: '20/28',
        dialogTitle: '16/24',
        title: FontWeight.w600,
        heading: FontWeight.w600,
        message: FontWeight.w400,
        labelInk: LabelInk.foreground,
      ),
      // DialogTitle: subtitle1; a validation message: caption1; Label:
      // colorNeutralForeground1
      'Fluent': (
        pageTitle: '24/32',
        dialogTitle: '20/28',
        title: FontWeight.w600,
        heading: FontWeight.w600,
        message: FontWeight.w400,
        labelInk: LabelInk.foreground,
      ),
      // heading-04 and a modal's heading-03 are regular, the compact
      // headings semibold; a label is text-secondary
      'Carbon': (
        pageTitle: '28/36',
        dialogTitle: '20/28',
        title: FontWeight.w400,
        heading: FontWeight.w600,
        message: FontWeight.w400,
        labelInk: LabelInk.secondary,
      ),
    };

/// The client accents the catalog's Brand control offers.
const _brands = <String, Color?>{
  'Default': null,
  'Crimson': Color(0xFFE11D48),
  'Violet': Color(0xFF7C3AED),
  'Teal': Color(0xFF0D9488),
  'Amber': Color(0xFFD97706),
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
  group('AdminTypeSpec', () {
    test('by default weighs a title as a heading and a message medium', () {
      const spec = AdminTypeSpec();
      expect(spec.title, isNull);
      expect(spec.message, FontWeight.w500);
      expect(spec.labelInk, LabelInk.secondary);

      final type = AdminTypography.from(irisPalette, spec);
      expect(type.pageTitle.fontWeight, spec.heading);
      expect(type.dialogTitle.fontWeight, spec.heading);
      expect(type.fieldMessage.fontWeight, FontWeight.w500);
      expect(type.fieldLabel.color, irisPalette.foregroundSecondary);
    });

    test('a title weight reaches the page and the dialog, not a heading', () {
      const spec = AdminTypeSpec(
        heading: FontWeight.w600,
        title: FontWeight.w400,
      );
      final type = AdminTypography.from(irisPalette, spec);
      expect(type.pageTitle.fontWeight, FontWeight.w400);
      expect(type.dialogTitle.fontWeight, FontWeight.w400);
      expect(type.heading.fontWeight, FontWeight.w600);
      expect(type.sectionLabel.fontWeight, FontWeight.w600);
      // A label with no weight of its own still follows the headings.
      expect(type.fieldLabel.fontWeight, FontWeight.w600);
    });

    test('a message weight reaches the field message alone', () {
      final type = AdminTypography.from(
        irisPalette,
        const AdminTypeSpec(message: FontWeight.w400),
      );
      expect(type.fieldMessage.fontWeight, FontWeight.w400);
      expect(type.fieldMessage.color, isNull);
      expect(type.bodyStrong.fontWeight, FontWeight.w600);
    });

    test('a label ink picks the label colour', () {
      for (final palette in [irisPalette, irisDarkPalette]) {
        final quiet = AdminTypography.from(palette);
        final full = AdminTypography.from(
          palette,
          const AdminTypeSpec(labelInk: LabelInk.foreground),
        );
        expect(quiet.fieldLabel.color, palette.foregroundSecondary);
        expect(full.fieldLabel.color, palette.foreground);
        // Nothing else follows it.
        expect(full.sectionLabel.color, palette.foregroundSecondary);
        expect(full.fieldDescription.color, palette.foregroundMuted);
      }
    });

    test('copies and compares the three', () {
      const spec = AdminTypeSpec();
      expect(spec.copyWith(), spec);
      expect(spec.copyWith().hashCode, spec.hashCode);

      final titled = spec.copyWith(title: FontWeight.w400);
      expect(titled.title, FontWeight.w400);
      expect(titled, isNot(spec));
      expect(titled.copyWith(heading: FontWeight.w600).title, FontWeight.w400);

      final light = spec.copyWith(message: FontWeight.w400);
      expect(light.message, FontWeight.w400);
      expect(light, isNot(spec));

      final inked = spec.copyWith(labelInk: LabelInk.foreground);
      expect(inked.labelInk, LabelInk.foreground);
      expect(inked, isNot(spec));
      expect(inked.copyWith(message: FontWeight.w400).labelInk, inked.labelInk);

      expect(
        const AdminTypeSpec(
          title: FontWeight.w400,
          message: FontWeight.w400,
          labelInk: LabelInk.foreground,
        ),
        spec.copyWith(
          title: FontWeight.w400,
          message: FontWeight.w400,
          labelInk: LabelInk.foreground,
        ),
      );
      expect(
        titled.hashCode,
        const AdminTypeSpec(title: FontWeight.w400).hashCode,
      );
    });
  });

  group('the dialog title step', () {
    test('is the heading step where the ramp names none', () {
      expect(defaultTypeRamp.dialogTitle, isNull);
      expect(defaultTypeRamp.steps['dialogTitle'], defaultTypeRamp.heading);
      final type = AdminTypography.from(irisPalette);
      expect(type.dialogTitle, type.heading);
    });

    test('is the ramp\'s own where it names one', () {
      final ramp = defaultTypeRamp.copyWith(
        dialogTitle: const AdminTypeStep(20, 28),
      );
      expect(ramp.dialogTitle, const AdminTypeStep(20, 28));
      expect(ramp.steps['dialogTitle'], const AdminTypeStep(20, 28));
      // In declaration order, after the heading it stands in for.
      final names = ramp.steps.keys.toList();
      expect(names.indexOf('dialogTitle'), names.indexOf('heading') + 1);

      final type = AdminTypography.from(irisPalette, AdminTypeSpec(ramp: ramp));
      expect(_line(type.dialogTitle), '20/28');
      expect(_line(type.heading), '16/24');
      expect(type.dialogTitle.color, irisPalette.foreground);
      expect(
        type.dialogTitle.leadingDistribution,
        TextLeadingDistribution.even,
      );
      // The spec's scale reaches it as it does every other step.
      final scaled = AdminTypography.from(
        irisPalette,
        AdminTypeSpec(ramp: ramp, scale: 1.5),
      );
      expect(scaled.dialogTitle.fontSize, 30);
    });

    test('copies, compares and interpolates', () {
      final named = defaultTypeRamp.copyWith(
        dialogTitle: const AdminTypeStep(20, 28),
      );
      expect(named, isNot(defaultTypeRamp));
      expect(named.copyWith(), named);
      expect(named.copyWith().hashCode, named.hashCode);
      expect(
        named.copyWith(body: const AdminTypeStep(14, 20)).dialogTitle,
        const AdminTypeStep(20, 28),
      );
      // A ramp that names its heading's step draws what one naming none
      // draws.
      expect(
        defaultTypeRamp.copyWith(dialogTitle: defaultTypeRamp.heading),
        defaultTypeRamp,
      );

      expect(
        AdminTypeRamp.lerp(defaultTypeRamp, defaultTypeRamp, 0.5).dialogTitle,
        isNull,
      );
      // From a ramp naming none, the step starts at its heading.
      expect(
        AdminTypeRamp.lerp(defaultTypeRamp, named, 0.5).dialogTitle,
        const AdminTypeStep(18, 26),
      );
      expect(AdminTypeRamp.lerp(defaultTypeRamp, named, 1), named);
      expect(AdminTypeRamp.lerp(named, defaultTypeRamp, 1), defaultTypeRamp);
    });

    test('a typography built by hand titles a dialog as a heading', () {
      const body = TextStyle(fontSize: 14);
      const heading = TextStyle(fontSize: 18);
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
        heading: heading,
        sectionLabel: body,
        body: body,
        bodyStrong: body,
        bodyMuted: body,
        bodySmall: body,
        caption: body,
        micro: body,
        button: body,
        spec: AdminTypeSpec(),
      );
      expect(type.dialogTitle, heading);
    });

    test('a typography compares and interpolates it', () {
      final plain = AdminTypography.from(irisPalette);
      final named = AdminTypography.from(
        irisPalette,
        AdminTypeSpec(
          ramp: defaultTypeRamp.copyWith(
            dialogTitle: const AdminTypeStep(20, 28),
          ),
        ),
      );
      expect(named, isNot(plain));
      expect(named.hashCode, isNot(plain.hashCode));
      expect(AdminTypography.lerp(plain, named, 0).dialogTitle.fontSize, 16);
      expect(AdminTypography.lerp(plain, named, 0.5).dialogTitle.fontSize, 18);
      expect(AdminTypography.lerp(plain, named, 1).dialogTitle.fontSize, 20);
    });
  });

  group('each shipped theme', () {
    test('has an expectation', () {
      expect(_expected.keys.toSet(), {for (final t in adminThemes) t.name});
    });

    for (final theme in adminThemes) {
      for (final (mode, tokens) in [
        ('light', theme.tokens),
        ('dark', theme.dark!),
      ]) {
        test('${theme.name} $mode takes its reference type roles', () {
          final want = _expected[theme.name]!;
          final type = tokens.typography;
          final p = tokens.palette;

          expect(_line(type.pageTitle), want.pageTitle);
          expect(type.pageTitle.fontWeight, want.title);
          expect(_line(type.dialogTitle), want.dialogTitle);
          expect(type.dialogTitle.fontWeight, want.title);
          expect(type.heading.fontWeight, want.heading);
          expect(type.sectionLabel.fontWeight, want.heading);
          expect(type.fieldMessage.fontWeight, want.message);
          expect(type.spec.labelInk, want.labelInk);
          expect(type.fieldLabel.color, switch (want.labelInk) {
            LabelInk.secondary => p.foregroundSecondary,
            LabelInk.foreground => p.foreground,
          });
          expect(type.pageTitle.color, p.foreground);
          expect(type.dialogTitle.color, p.foreground);
        });
      }

      test('${theme.name}: a dialog is titled no smaller than a card', () {
        final type = theme.tokens.typography;
        expect(
          type.dialogTitle.fontSize,
          greaterThanOrEqualTo(type.heading.fontSize!),
        );
        expect(
          type.dialogTitle.fontSize,
          lessThanOrEqualTo(type.pageTitle.fontSize!),
        );
        // On a whole line, as every other role is.
        final line = type.dialogTitle.fontSize! * type.dialogTitle.height!;
        expect((line - line.roundToDouble()).abs(), lessThan(1e-9));
      });

      test('${theme.name}: a brand keeps the type roles', () {
        final branded = theme.branded('Test Teal', const Color(0xFF0D9488));
        final spec = theme.tokens.typography.spec;
        for (final tokens in [branded.tokens, branded.dark!]) {
          expect(tokens.typography.spec.title, spec.title);
          expect(tokens.typography.spec.message, spec.message);
          expect(tokens.typography.spec.labelInk, spec.labelInk);
          expect(
            tokens.typography.spec.ramp.dialogTitle,
            spec.ramp.dialogTitle,
          );
        }
      });
    }

    test('a field label reads at 4.5:1 in every theme, mode and brand', () {
      for (final theme in adminThemes) {
        for (final (mode, tokens) in [
          ('light', theme.tokens),
          ('dark', theme.dark!),
        ]) {
          for (final MapEntry(key: brand, value: seed) in _brands.entries) {
            final t = seed == null ? tokens : tokens.branded(seed);
            final p = t.palette;
            for (final (ground, on) in [
              ('surface', p.surface),
              ('background', p.background),
            ]) {
              expect(
                contrastRatio(t.typography.fieldLabel.color!, on),
                greaterThanOrEqualTo(4.5),
                reason: '${theme.name} $mode $brand: a label on the $ground',
              );
            }
          }
        }
      }
    });
  });

  group('widgets', () {
    for (final theme in adminThemes) {
      testWidgets('${theme.name}: a field\'s label and its error', (
        tester,
      ) async {
        for (final tokens in [theme.tokens, theme.dark!]) {
          await tester.pumpWidget(
            _host(
              tokens,
              const LabeledField(
                label: 'Price',
                errorText: 'Enter a price.',
                child: SizedBox(height: 36),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final want = _expected[theme.name]!;
          final p = tokens.palette;
          final label = _styleOf(
            tester,
            tokens.typography.fieldLabelText('Price'),
          );
          expect(label.color, switch (want.labelInk) {
            LabelInk.secondary => p.foregroundSecondary,
            LabelInk.foreground => p.foreground,
          });
          final error = _styleOf(tester, 'Enter a price.');
          expect(error.fontWeight, want.message);
          expect(error.color, p.dangerText);
        }
      });
    }

    for (final theme in adminThemes) {
      testWidgets('${theme.name}: a form field rests its label in the ink', (
        tester,
      ) async {
        for (final tokens in [theme.tokens, theme.dark!]) {
          await tester.pumpWidget(
            _host(
              tokens,
              const FieldShell(
                label: 'Title',
                fieldId: 'title',
                child: InputField(value: 'Hello'),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final p = tokens.palette;
          final color = _styleOf(
            tester,
            tokens.typography.fieldLabelText('Title'),
          ).color!;
          switch (_expected[theme.name]!.labelInk) {
            case LabelInk.foreground:
              expect(color, p.foreground);
            case LabelInk.secondary:
              // The quieter of the two that reads on the page and on a card.
              expect(color, anyOf(p.foregroundMuted, p.foregroundSecondary));
          }
          for (final ground in [p.surface, p.background]) {
            expect(contrastRatio(color, ground), greaterThanOrEqualTo(4.5));
          }
        }
      });
    }
  });
}
