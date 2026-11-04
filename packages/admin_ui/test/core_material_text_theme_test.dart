import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// [source] with its theme's ramp, weights and geometry, in the platform's
/// font: a Google font would be fetched on every `weighted` call.
AdminTokens _fontless(AdminTokens source) {
  final spec = source.typography.spec;
  return AdminTokens.from(
    palette: source.palette,
    radii: source.radii,
    type: AdminTypeSpec(
      ramp: spec.ramp,
      scale: spec.scale,
      heading: spec.heading,
      strong: spec.strong,
      body: spec.body,
      tracking: spec.tracking,
      uppercaseLabels: spec.uppercaseLabels,
    ),
    elevation: source.elevation,
    focus: source.focus,
    sizes: source.sizes,
    table: source.table,
    motion: source.motion,
    stroke: source.stroke,
    iconSizes: source.iconSizes,
  );
}

/// The line box a style lays a line of text in.
double _line(TextStyle style) => style.fontSize! * style.height!;

void main() {
  for (final theme in adminThemes) {
    for (final dark in [false, true]) {
      final name = '${theme.name} ${dark ? 'Dark' : 'Light'}';
      final tokens = _fontless(dark ? theme.dark! : theme.tokens);
      final type = tokens.typography;

      test('$name: the Material text theme is the ramp', () {
        final text = buildAppTheme(tokens).textTheme;
        for (final (role, material, kit) in [
          ('bodyLarge', text.bodyLarge!, type.fieldText),
          ('bodyMedium', text.bodyMedium!, type.body),
          ('bodySmall', text.bodySmall!, type.caption),
          ('labelLarge', text.labelLarge!, type.button),
          ('labelMedium', text.labelMedium!, type.sectionLabel),
          ('labelSmall', text.labelSmall!, type.micro),
          ('titleMedium', text.titleMedium!, type.heading),
          ('titleSmall', text.titleSmall!, type.bodyStrong),
        ]) {
          expect(material.fontSize, kit.fontSize, reason: role);
          expect(material.height, kit.height, reason: role);
          expect(material.letterSpacing, kit.letterSpacing, reason: role);
          expect(material.fontWeight, kit.fontWeight, reason: role);
          expect(
            material.leadingDistribution,
            TextLeadingDistribution.even,
            reason: role,
          );
        }
        final ramp = type.spec.ramp;
        for (final (role, material, step) in [
          ('displayLarge', text.displayLarge!, ramp.displayLarge),
          ('displayMedium', text.displayMedium!, ramp.displayMedium),
          ('displaySmall', text.displaySmall!, ramp.displaySmall),
          ('headlineMedium', text.headlineMedium!, ramp.headlineMedium),
          ('headlineSmall', text.headlineSmall!, ramp.headlineSmall),
          ('titleLarge', text.titleLarge!, ramp.titleLarge),
        ]) {
          expect(material.fontSize, step.size, reason: role);
          expect(_line(material), closeTo(step.line, 1e-9), reason: role);
        }
        expect(text.displayLarge!.fontSize, type.sizeDisplayLarge);
        expect(text.titleLarge!.fontSize, type.sizeTitleLarge);
      });

      testWidgets('$name: a stock TextField and TextFormField are as tall as '
          'a medium InputField', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(tokens),
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 240,
                  child: Column(
                    children: [
                      const InputField(key: Key('kit'), value: 'Title'),
                      TextField(
                        key: const Key('stock'),
                        controller: TextEditingController(text: 'Title'),
                      ),
                      TextFormField(
                        key: const Key('form'),
                        initialValue: 'Title',
                      ),
                      const TextField(
                        key: Key('hint'),
                        decoration: InputDecoration(hintText: 'Search'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        final medium = tokens.sizes.medium;
        for (final key in ['kit', 'stock', 'form', 'hint']) {
          expect(
            tester.getSize(find.byKey(Key(key))).height,
            moreOrLessEquals(medium),
            reason: key,
          );
        }
        final context = tester.element(find.byKey(const Key('stock')));
        final bodyMedium = Theme.of(context).textTheme.bodyMedium!;
        expect(bodyMedium.fontSize, type.body.fontSize);
        expect(DefaultTextStyle.of(context).style.fontSize, type.body.fontSize);
      });
    }
  }
}
