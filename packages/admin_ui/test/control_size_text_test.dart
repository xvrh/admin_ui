import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// The text a control holds at each ControlSize: a field's value and hint and
// a button's label follow the size where the theme's design system sizes
// them, and the box pads the text it holds.

/// What each shipped theme sets, from its reference: a field's text and a
/// button's label at small, medium and large as size/line, and the button's
/// weight at each.
const _expected =
    <
      String,
      ({List<String> field, List<String> button, List<FontWeight> buttonWeight})
    >{
      // the kit's own: one field step, and a smaller label on a small button
      'Iris': (
        field: ['13/20', '13/20', '13/20'],
        button: ['12/16', '13/20', '13/20'],
        buttonWeight: [FontWeight.w600, FontWeight.w600, FontWeight.w600],
      ),
      // one text field size (bodyLarge) and one button size (labelLarge)
      'Material': (
        field: ['16/24', '16/24', '16/24'],
        button: ['14/20', '14/20', '14/20'],
        buttonWeight: [FontWeight.w500, FontWeight.w500, FontWeight.w500],
      ),
      // text-sm at every size
      'shadcn': (
        field: ['14/20', '14/20', '14/20'],
        button: ['14/20', '14/20', '14/20'],
        buttonWeight: [FontWeight.w500, FontWeight.w500, FontWeight.w500],
      ),
      // fontSize in the small and middle sizes, fontSizeLG on lineHeightLG
      // in the large one
      'Ant': (
        field: ['14/22', '14/22', '16/24'],
        button: ['14/22', '14/22', '16/24'],
        buttonWeight: [FontWeight.w400, FontWeight.w400, FontWeight.w400],
      ),
      // Input: body1, and body2 when large. Button: Base200 regular, Base300
      // semibold, Base400 semibold
      'Fluent': (
        field: ['14/20', '14/20', '16/22'],
        button: ['12/16', '14/20', '16/22'],
        buttonWeight: [FontWeight.w400, FontWeight.w600, FontWeight.w600],
      ),
      // body-compact-01 at every size
      'Carbon': (
        field: ['14/18', '14/18', '14/18'],
        button: ['14/18', '14/18', '14/18'],
        buttonWeight: [FontWeight.w400, FontWeight.w400, FontWeight.w400],
      ),
    };

String _line(TextStyle style) =>
    '${style.fontSize!.round()}/${(style.fontSize! * style.height!).round()}';

Widget _host(AdminTokens tokens, Widget child) => MaterialApp(
  theme: buildAppTheme(tokens),
  supportedLocales: AdminLocalizations.supportedLocales,
  localizationsDelegates: AdminLocalizations.localizationsDelegates,
  home: Scaffold(
    body: Center(child: SizedBox(width: 360, child: child)),
  ),
);

/// The box a text input draws.
Rect _box(WidgetTester tester) => tester.getRect(find.byType(InputDecorator));

/// The style [text] is drawn in.
TextStyle _styleOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

void main() {
  group('the ramp', () {
    test('names no large step by default', () {
      expect(defaultTypeRamp.fieldTextLarge, isNull);
      expect(defaultTypeRamp.buttonLarge, isNull);
      expect(
        defaultTypeRamp.steps['fieldTextLarge'],
        defaultTypeRamp.fieldText,
      );
      expect(defaultTypeRamp.steps['buttonLarge'], defaultTypeRamp.button);

      final type = AdminTypography.from(irisPalette);
      expect(type.fieldTextLarge, type.fieldText);
      expect(type.buttonLarge, type.button);
    });

    test('a large step reaches the large styles alone', () {
      final ramp = defaultTypeRamp.copyWith(
        fieldTextLarge: const AdminTypeStep(16, 24),
        buttonLarge: const AdminTypeStep(16, 22),
      );
      expect(ramp.steps['fieldTextLarge'], const AdminTypeStep(16, 24));
      expect(ramp.steps['buttonLarge'], const AdminTypeStep(16, 22));
      // Each after the step it stands in for, in declaration order.
      final names = ramp.steps.keys.toList();
      expect(names.indexOf('fieldTextLarge'), names.indexOf('fieldText') + 1);
      expect(names.indexOf('buttonLarge'), names.indexOf('buttonSmall') + 1);

      const spec = AdminTypeSpec();
      final type = AdminTypography.from(irisPalette, spec.copyWith(ramp: ramp));
      expect(_line(type.fieldTextLarge), '16/24');
      expect(_line(type.fieldText), '13/20');
      expect(type.fieldTextLarge.color, type.fieldText.color);
      expect(type.fieldTextLarge.fontWeight, spec.body);
      expect(
        type.fieldTextLarge.leadingDistribution,
        TextLeadingDistribution.even,
      );
      expect(_line(type.buttonLarge), '16/22');
      expect(_line(type.button), '13/20');
      expect(type.buttonLarge.fontWeight, spec.strong);
      expect(type.buttonLarge.color, isNull);
      // The spec's scale reaches them as it does every other step.
      final scaled = AdminTypography.from(
        irisPalette,
        AdminTypeSpec(ramp: ramp, scale: 1.5),
      );
      expect(scaled.fieldTextLarge.fontSize, 24);
      expect(scaled.buttonLarge.fontSize, 24);
    });

    test('copies, compares and interpolates', () {
      final large = defaultTypeRamp.copyWith(
        fieldTextLarge: const AdminTypeStep(17, 24),
        buttonLarge: const AdminTypeStep(15, 22),
      );
      expect(large, isNot(defaultTypeRamp));
      expect(large.copyWith(), large);
      expect(large.copyWith().hashCode, large.hashCode);
      expect(
        large.copyWith(body: const AdminTypeStep(14, 20)).fieldTextLarge,
        const AdminTypeStep(17, 24),
      );
      // A ramp that names the step it would fall back to draws the same.
      expect(
        defaultTypeRamp.copyWith(
          fieldTextLarge: defaultTypeRamp.fieldText,
          buttonLarge: defaultTypeRamp.button,
        ),
        defaultTypeRamp,
      );

      final none = AdminTypeRamp.lerp(defaultTypeRamp, defaultTypeRamp, 0.5);
      expect(none.fieldTextLarge, isNull);
      expect(none.buttonLarge, isNull);
      // From a ramp naming none, a step starts at the one drawn in its place.
      final half = AdminTypeRamp.lerp(defaultTypeRamp, large, 0.5);
      expect(half.fieldTextLarge, const AdminTypeStep(15, 22));
      expect(half.buttonLarge, const AdminTypeStep(14, 21));
      expect(AdminTypeRamp.lerp(defaultTypeRamp, large, 1), large);
      expect(AdminTypeRamp.lerp(large, defaultTypeRamp, 1), defaultTypeRamp);
    });
  });

  group('AdminTypography', () {
    test('gives a control its text by size', () {
      final type = AdminTypography.from(
        irisPalette,
        AdminTypeSpec(
          ramp: defaultTypeRamp.copyWith(
            fieldTextLarge: const AdminTypeStep(16, 24),
            buttonLarge: const AdminTypeStep(16, 22),
          ),
        ),
      );
      expect(type.fieldTextOf(ControlSize.small), type.fieldText);
      expect(type.fieldTextOf(ControlSize.medium), type.fieldText);
      expect(type.fieldTextOf(ControlSize.large), type.fieldTextLarge);
      expect(type.buttonOf(ControlSize.small), type.buttonSmall);
      expect(type.buttonOf(ControlSize.medium), type.button);
      expect(type.buttonOf(ControlSize.large), type.buttonLarge);
    });

    test('built by hand, sizes a large control as a medium one', () {
      const body = TextStyle(fontSize: 14);
      const button = TextStyle(fontSize: 13);
      const field = TextStyle(fontSize: 15);
      const type = AdminTypography(
        sizeDisplayLarge: 36,
        sizeDisplayMedium: 28,
        sizeDisplaySmall: 24,
        sizeHeadlineMedium: 20,
        sizeHeadlineSmall: 18,
        sizeTitleLarge: 18,
        fieldLabel: body,
        fieldText: field,
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
      expect(type.fieldTextLarge, field);
      expect(type.buttonLarge, button);
      for (final size in ControlSize.values) {
        expect(type.fieldTextOf(size), field);
        expect(type.buttonOf(size), button);
      }
    });

    test('compares and interpolates the large styles', () {
      final plain = AdminTypography.from(irisPalette);
      final large = AdminTypography.from(
        irisPalette,
        AdminTypeSpec(
          ramp: defaultTypeRamp.copyWith(
            fieldTextLarge: const AdminTypeStep(17, 24),
            buttonLarge: const AdminTypeStep(15, 22),
          ),
        ),
      );
      expect(large, isNot(plain));
      expect(large.hashCode, isNot(plain.hashCode));
      final half = AdminTypography.lerp(plain, large, 0.5);
      expect(half.fieldTextLarge.fontSize, 15);
      expect(half.buttonLarge.fontSize, 14);
      expect(half.fieldText.fontSize, 13);
      expect(AdminTypography.lerp(plain, large, 1).fieldTextLarge.fontSize, 17);
    });

    test('pads a field from the line of the text its size holds', () {
      final type = AdminTypography.from(
        irisPalette,
        AdminTypeSpec(
          ramp: defaultTypeRamp.copyWith(
            fieldTextLarge: const AdminTypeStep(16, 24),
          ),
        ),
      );
      // 13/20 in 36, and by default whatever the height.
      expect(fieldPaddingY(type, 36), 8);
      expect(fieldPaddingY(type, 44), 12);
      expect(fieldPaddingY(type, 36, size: ControlSize.small), 8);
      // 16/24 in 44.
      expect(fieldPaddingY(type, 44, size: ControlSize.large), 10);
      // Never negative, in a box shorter than the line.
      expect(fieldPaddingY(type, 20, size: ControlSize.large), 0);
    });
  });

  group('AdminButtonStyle', () {
    test('weighs a small label as the others by default', () {
      const style = AdminButtonStyle();
      expect(style.smallLabelWeight, isNull);
      for (final size in ControlSize.values) {
        expect(style.labelWeightOf(size), isNull);
      }
      const medium = AdminButtonStyle(labelWeight: FontWeight.w500);
      for (final size in ControlSize.values) {
        expect(medium.labelWeightOf(size), FontWeight.w500);
      }
    });

    test('a small weight reaches the small button alone', () {
      const style = AdminButtonStyle(
        labelWeight: FontWeight.w600,
        smallLabelWeight: FontWeight.w400,
      );
      expect(style.labelWeightOf(ControlSize.small), FontWeight.w400);
      expect(style.labelWeightOf(ControlSize.medium), FontWeight.w600);
      expect(style.labelWeightOf(ControlSize.large), FontWeight.w600);
      // Without a weight for the others, they keep the type role's.
      const smallOnly = AdminButtonStyle(smallLabelWeight: FontWeight.w400);
      expect(smallOnly.labelWeightOf(ControlSize.small), FontWeight.w400);
      expect(smallOnly.labelWeightOf(ControlSize.medium), isNull);
    });

    test('copies, compares, interpolates and describes it', () {
      const style = AdminButtonStyle(labelWeight: FontWeight.w600);
      final small = style.copyWith(smallLabelWeight: FontWeight.w400);
      expect(small.smallLabelWeight, FontWeight.w400);
      expect(small.labelWeight, FontWeight.w600);
      expect(small, isNot(style));
      expect(small.copyWith(), small);
      expect(small.copyWith().hashCode, small.hashCode);
      expect(
        small,
        const AdminButtonStyle(
          labelWeight: FontWeight.w600,
          smallLabelWeight: FontWeight.w400,
        ),
      );
      expect(
        small.copyWith(fadedOpacity: 0.4).smallLabelWeight,
        FontWeight.w400,
      );

      // From the nearer side, as the other choices are.
      expect(AdminButtonStyle.lerp(style, small, 0.4).smallLabelWeight, isNull);
      expect(
        AdminButtonStyle.lerp(style, small, 0.6).smallLabelWeight,
        FontWeight.w400,
      );

      expect(small.toString(), contains('FontWeight.w400 small'));
      expect(style.toString(), isNot(contains('small')));
    });

    test('a theme carries it through AdminTokens and a brand', () {
      const style = AdminButtonStyle(smallLabelWeight: FontWeight.w400);
      final tokens = AdminTokens.from(palette: irisPalette, button: style);
      expect(tokens.button.smallLabelWeight, FontWeight.w400);
      expect(
        tokens.branded(const Color(0xFF0D9488)).button.smallLabelWeight,
        FontWeight.w400,
      );
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
        test('${theme.name} $mode sizes its control text as its reference', () {
          final want = _expected[theme.name]!;
          final type = tokens.typography;
          for (final size in ControlSize.values) {
            expect(
              _line(type.fieldTextOf(size)),
              want.field[size.index],
              reason: 'a ${size.name} field',
            );
            expect(
              _line(type.buttonOf(size)),
              want.button[size.index],
              reason: 'a ${size.name} button',
            );
            expect(
              tokens.button.labelWeightOf(size) ??
                  type.buttonOf(size).fontWeight,
              want.buttonWeight[size.index],
              reason: 'a ${size.name} button',
            );
            // One ink and one weight for a field's text at every size.
            expect(type.fieldTextOf(size).color, tokens.palette.foreground);
            expect(type.fieldTextOf(size).fontWeight, type.spec.body);
          }
        });
      }

      test('${theme.name}: each size\'s text fits its control', () {
        final tokens = theme.tokens;
        final type = tokens.typography;
        for (final size in ControlSize.values) {
          final height = tokens.sizes.height(size);
          for (final (role, style) in [
            ('field', type.fieldTextOf(size)),
            ('button', type.buttonOf(size)),
          ]) {
            final line = style.fontSize! * style.height!;
            // On a whole line, inside the box's outline.
            expect((line - line.roundToDouble()).abs(), lessThan(1e-9));
            expect(
              line,
              lessThanOrEqualTo(height - 2),
              reason: 'a ${size.name} $role in $height',
            );
          }
          expect(
            fieldPaddingY(type, height, size: size),
            greaterThanOrEqualTo(0),
          );
        }
        // Text never shrinks as the control grows.
        expect(
          type.fieldTextLarge.fontSize,
          greaterThanOrEqualTo(type.fieldText.fontSize!),
        );
        expect(
          type.buttonLarge.fontSize,
          greaterThanOrEqualTo(type.button.fontSize!),
        );
        expect(
          type.button.fontSize,
          greaterThanOrEqualTo(type.buttonSmall.fontSize!),
        );
      });

      test('${theme.name}: a brand keeps the sizes', () {
        final branded = theme.branded('Test Teal', const Color(0xFF0D9488));
        for (final (tokens, source) in [
          (branded.tokens, theme.tokens),
          (branded.dark!, theme.dark!),
        ]) {
          expect(
            tokens.typography.spec.ramp.fieldTextLarge,
            source.typography.spec.ramp.fieldTextLarge,
          );
          expect(
            tokens.typography.spec.ramp.buttonLarge,
            source.typography.spec.ramp.buttonLarge,
          );
          expect(
            tokens.button.smallLabelWeight,
            source.button.smallLabelWeight,
          );
        }
      });
    }
  });

  group('widgets', () {
    for (final theme in adminThemes) {
      final tokens = theme.tokens;
      final type = tokens.typography;

      testWidgets('${theme.name}: a text input holds its size\'s text', (
        tester,
      ) async {
        for (final size in ControlSize.values) {
          final height = tokens.sizes.height(size);
          final want = type.fieldTextOf(size);
          final inputs = <String, Widget>{
            'InputField': InputField(value: 'Value', size: size),
            'InputField, labelled': InputField(
              value: 'Value',
              label: 'Label',
              size: size,
            ),
            'SearchField': SearchField(value: 'Value', size: size),
            'PasswordField': PasswordField(value: 'Value', size: size),
            'Combobox': Combobox<String>(
              value: 'a',
              onChanged: (_) {},
              options: const [ComboboxOption('a', 'Value')],
              size: size,
            ),
            'MentionField': MentionField(candidates: const [], size: size),
          };
          for (final MapEntry(key: name, value: input) in inputs.entries) {
            await tester.pumpWidget(_host(tokens, input));
            await tester.pumpAndSettle();
            final reason = '$name, ${size.name}';
            expect(_box(tester).height, height, reason: reason);
            final text = tester.widget<EditableText>(find.byType(EditableText));
            expect(text.style.fontSize, want.fontSize, reason: reason);
            expect(text.style.height, want.height, reason: reason);
          }

          // The hint is the size of the value it stands in for.
          await tester.pumpWidget(
            _host(tokens, InputField(value: '', hint: 'Search', size: size)),
          );
          await tester.pumpAndSettle();
          expect(_box(tester).height, height, reason: 'a hint, ${size.name}');
          final hint = _styleOf(tester, 'Search');
          expect(hint.fontSize, want.fontSize);
          expect(hint.height, want.height);
          expect(hint.color, tokens.palette.placeholder);
        }
      });

      testWidgets(
        '${theme.name}: a date range trigger holds its size\'s text',
        (tester) async {
          for (final size in ControlSize.values) {
            await tester.pumpWidget(
              _host(tokens, DateRangePicker(hint: 'Any date', size: size)),
            );
            await tester.pumpAndSettle();
            expect(
              tester.getSize(find.byType(FieldTrigger)).height,
              tokens.sizes.height(size),
              reason: size.name,
            );
            final hint = _styleOf(tester, 'Any date');
            expect(hint.fontSize, type.fieldTextOf(size).fontSize);
            expect(hint.height, type.fieldTextOf(size).height);
          }
        },
      );

      testWidgets('${theme.name}: a button is labelled in its size\'s role', (
        tester,
      ) async {
        final want = _expected[theme.name]!;
        for (final size in ControlSize.values) {
          await tester.pumpWidget(
            _host(
              tokens,
              Center(
                child: Button('Publish', size: size, onPressed: () {}),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final label = _styleOf(tester, 'Publish');
          expect(_line(label), want.button[size.index], reason: size.name);
          expect(
            label.fontWeight,
            want.buttonWeight[size.index],
            reason: size.name,
          );
          expect(
            tester.getSize(find.byType(Button)).height,
            tokens.sizes.height(size),
            reason: size.name,
          );
        }
      });
    }

    testWidgets('a weight a button names is its weight at every size', (
      tester,
    ) async {
      // Fluent sets its small button in regular.
      final tokens = fluentTheme.tokens;
      expect(tokens.button.smallLabelWeight, FontWeight.w400);
      for (final size in ControlSize.values) {
        await tester.pumpWidget(
          _host(
            tokens,
            Center(
              child: Button(
                'Publish',
                size: size,
                style: const AdminButtonStyle(labelWeight: FontWeight.w700),
                onPressed: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          _styleOf(tester, 'Publish').fontWeight,
          FontWeight.w700,
          reason: size.name,
        );
      }
      // A small weight of its own, over the theme's.
      await tester.pumpWidget(
        _host(
          tokens,
          Center(
            child: Button(
              'Publish',
              size: ControlSize.small,
              style: const AdminButtonStyle(
                labelWeight: FontWeight.w700,
                smallLabelWeight: FontWeight.w500,
              ),
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_styleOf(tester, 'Publish').fontWeight, FontWeight.w500);
      // And one that changes something else keeps the theme's weights.
      await tester.pumpWidget(
        _host(
          tokens,
          Center(
            child: Button(
              'Publish',
              size: ControlSize.small,
              style: const AdminButtonStyle(fadedOpacity: 0.4),
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_styleOf(tester, 'Publish').fontWeight, FontWeight.w400);
    });

    testWidgets('a large field grows with the text scale, and holds its text', (
      tester,
    ) async {
      for (final theme in [antTheme, fluentTheme]) {
        final tokens = theme.tokens;
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 600),
              textScaler: TextScaler.linear(2),
            ),
            child: _host(
              tokens,
              const InputField(value: 'Value', size: ControlSize.large),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: theme.name);
        final line =
            2 *
            tokens.typography.fieldTextLarge.fontSize! *
            tokens.typography.fieldTextLarge.height!;
        expect(
          _box(tester).height,
          greaterThanOrEqualTo(line),
          reason: theme.name,
        );
      }
    });
  });
}
