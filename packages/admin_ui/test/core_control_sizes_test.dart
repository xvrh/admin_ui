import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Each shipped theme's ramp, from its design system.
const _ramps = {
  'Iris': (28.0, 36.0, 40.0),
  'Material': (32.0, 40.0, 48.0),
  'shadcn': (32.0, 36.0, 40.0),
  'Ant': (24.0, 32.0, 40.0),
  'Fluent': (24.0, 32.0, 40.0),
  'Carbon': (32.0, 40.0, 48.0),
};

Widget _host(AdminTokens tokens, Widget child, {double textScale = 1}) =>
    MaterialApp(
      theme: buildAppTheme(tokens),
      home: MediaQuery.withClampedTextScaling(
        minScaleFactor: textScale,
        maxScaleFactor: textScale,
        child: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 240, child: child),
          ),
        ),
      ),
    );

/// A [TextField] on [fieldInputDecoration], keyed by [key].
Widget _input(
  Key key, {
  ControlSize size = ControlSize.medium,
  IconData? leadingIcon,
  Widget? suffix,
  String text = '',
}) => Builder(
  builder: (context) => TextField(
    key: key,
    controller: TextEditingController(text: text),
    style: fieldTextStyle(context),
    decoration: fieldInputDecoration(
      context,
      size: size,
      leadingIcon: leadingIcon,
      suffix: suffix,
    ),
  ),
);

void main() {
  group('each shipped theme', () {
    for (final theme in adminThemes) {
      test('${theme.name} ramps its controls as its design system', () {
        final (small, medium, large) = _ramps[theme.name]!;
        final light = theme.tokens.sizes;
        final dark = theme.dark!.sizes;
        expect(
          [light.small, light.medium, light.large],
          [small, medium, large],
        );
        expect(dark, light);
        // One inset for every theme: the leading text starts at 36.
        expect(light.fieldPaddingX, 12);
        expect(light.fieldIconInset, 36);
      });
    }
  });

  for (final theme in adminThemes) {
    for (final dark in [false, true]) {
      final mode = dark ? 'Dark' : 'Light';
      // The theme's palette, radii and sizes, without its font.
      final source = dark ? theme.dark! : theme.tokens;
      final tokens = AdminTokens.from(
        palette: source.palette,
        radii: source.radii,
        focus: source.focus,
        sizes: source.sizes,
      );

      for (final size in ControlSize.values) {
        final height = tokens.sizes.height(size);
        testWidgets(
          '${theme.name} $mode ${size.name}: every control is $height tall',
          (tester) async {
            await tester.pumpWidget(
              _host(
                tokens,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Button(
                      'Button',
                      key: const Key('button'),
                      size: size,
                      onPressed: () {},
                    ),
                    Button.icon(
                      Icons.tune_rounded,
                      key: const Key('icon'),
                      semanticLabel: 'Filters',
                      size: size,
                      onPressed: () {},
                    ),
                    _input(const Key('plain'), size: size),
                    _input(
                      const Key('leading'),
                      size: size,
                      leadingIcon: Icons.search,
                    ),
                    _input(
                      const Key('clear'),
                      size: size,
                      text: 'Value',
                      suffix: ClearButton(onPressed: () {}),
                    ),
                    _input(
                      const Key('chevron'),
                      size: size,
                      suffix: const FieldChevron(),
                    ),
                    FieldChrome(
                      key: const Key('chrome'),
                      size: size,
                      child: const Text('Chrome'),
                    ),
                    Popover(
                      anchor: (context, controller) => FieldTrigger(
                        key: const Key('trigger'),
                        controller: controller,
                        size: size,
                        chevron: true,
                        trailing: ClearButton(onPressed: () {}),
                        child: const Text('Trigger'),
                      ),
                      content: (context, controller) => const SizedBox(),
                    ),
                  ],
                ),
              ),
            );
            for (final key in [
              'button',
              'icon',
              'plain',
              'leading',
              'clear',
              'chevron',
              'chrome',
              'trigger',
            ]) {
              expect(
                tester.getSize(find.byKey(Key(key))).height,
                height,
                reason: key,
              );
            }
            expect(tester.getSize(find.byKey(const Key('icon'))).width, height);
          },
        );
      }
    }
  }

  group('field insets', () {
    final tokens = AdminTokens.from(palette: irisPalette);
    Rect text(WidgetTester tester, String key) => tester.getRect(
      find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(EditableText),
      ),
    );

    testWidgets('text starts at 12, or at 36 after a leading glyph at 12', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          tokens,
          Column(
            children: [
              _input(const Key('plain')),
              _input(const Key('leading'), leadingIcon: Icons.search),
            ],
          ),
        ),
      );
      final plain = tester.getRect(find.byKey(const Key('plain')));
      final leading = tester.getRect(find.byKey(const Key('leading')));
      expect(text(tester, 'plain').left - plain.left, 12);
      expect(text(tester, 'leading').left - leading.left, 36);
      final glyph = tester.getRect(find.byIcon(Icons.search));
      expect(glyph.left - leading.left, 12);
      expect(glyph.width, 16);
      expect(glyph.center.dy, leading.center.dy);
    });

    testWidgets('a suffix glyph lines up with the padding; text ends at 36', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          tokens,
          _input(
            const Key('clear'),
            text: 'Value',
            suffix: ClearButton(onPressed: () {}),
          ),
        ),
      );
      final field = tester.getRect(find.byKey(const Key('clear')));
      final slot = tester.getRect(find.byType(IconAction));
      expect(slot.size, const Size.square(24));
      expect(field.right - slot.right, 8);
      final glyph = tester.getRect(find.byIcon(Icons.close_rounded));
      expect(field.right - glyph.right, 12);
      expect(slot.center.dy, field.center.dy);
      expect(field.right - text(tester, 'clear').right, 36);
    });

    testWidgets('a trigger lines its glyphs up the same way', (tester) async {
      await tester.pumpWidget(
        _host(
          tokens,
          Popover(
            anchor: (context, controller) => FieldTrigger(
              key: const Key('trigger'),
              controller: controller,
              chevron: true,
              trailing: ClearButton(onPressed: () {}),
              child: const SizedBox(key: Key('value'), height: 20),
            ),
            content: (context, controller) => const SizedBox(),
          ),
        ),
      );
      final box = tester.getRect(find.byKey(const Key('trigger')));
      final chevron = tester.getRect(
        find.byIcon(Icons.keyboard_arrow_down_rounded),
      );
      final clear = tester.getRect(find.byIcon(Icons.close_rounded));
      expect(box.right - chevron.right, 12);
      expect(chevron.left - clear.right, 8);
      final value = tester.getRect(find.byKey(const Key('value')));
      expect(value.left - box.left, 12);
      expect(clear.left - value.right, 8);
    });

    testWidgets('an oversized suffix never grows the field', (tester) async {
      await tester.pumpWidget(
        _host(
          tokens,
          _input(
            const Key('field'),
            suffix: const SizedBox(key: Key('big'), width: 60, height: 60),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(const Key('field'))).height, 36);
      expect(
        tester.getSize(find.byKey(const Key('big'))),
        const Size.square(24),
      );
    });

    testWidgets('a larger text scale grows the field instead of clipping', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(tokens, _input(const Key('field')), textScale: 2.5),
      );
      final field = tester.getSize(find.byKey(const Key('field'))).height;
      final line = tester
          .getSize(
            find.descendant(
              of: find.byKey(const Key('field')),
              matching: find.byType(EditableText),
            ),
          )
          .height;
      expect(field, greaterThan(36));
      expect(field, greaterThanOrEqualTo(line));
    });
  });

  group('tokens', () {
    const custom = AdminControlSizes(
      small: 20,
      medium: 30,
      large: 50,
      fieldPaddingX: 10,
      fieldIcon: 14,
      fieldIconGap: 6,
    );

    test('height() picks the size; fieldIconInset sums the leading slot', () {
      expect(custom.height(ControlSize.small), 20);
      expect(custom.height(ControlSize.medium), 30);
      expect(custom.height(ControlSize.large), 50);
      expect(custom.fieldIconInset, 30);
      expect(defaultControlSizes.fieldIconInset, 36);
    });

    test('copyWith, ==, hashCode and lerp', () {
      expect(custom.copyWith(), custom);
      expect(custom.copyWith().hashCode, custom.hashCode);
      expect(custom.copyWith(medium: 31), isNot(custom));
      final mid = AdminControlSizes.lerp(defaultControlSizes, custom, 0.5);
      expect(mid.small, 24);
      expect(mid.medium, 33);
      expect(mid.large, 45);
      expect(mid.fieldPaddingX, 11);
      expect(AdminControlSizes.lerp(defaultControlSizes, custom, 1), custom);
    });

    test('ride on AdminTokens: from, copyWith and lerp', () {
      final base = AdminTokens.from(palette: irisPalette);
      expect(base.sizes, defaultControlSizes);
      final sized = AdminTokens.from(palette: irisPalette, sizes: custom);
      expect(sized.sizes, custom);
      expect(sized.copyWith().sizes, custom);
      expect(base.copyWith(sizes: custom).sizes, custom);
      expect(base.lerp(sized, 1).sizes, custom);
      expect(sized.branded(const Color(0xFF0D9488)).sizes, custom);
    });

    test('AdminTheme.from threads sizes to both modes and its brands', () {
      final theme = AdminTheme.from(
        name: 'Sized',
        palette: irisPalette,
        dark: irisDarkPalette,
        sizes: custom,
      );
      expect(theme.tokens.sizes, custom);
      expect(theme.dark!.sizes, custom);
      final branded = theme.branded('Sized Teal', const Color(0xFF0D9488));
      expect(branded.tokens.sizes, custom);
      expect(branded.dark!.sizes, custom);
    });

    testWidgets('context.sizes, IconAction medium and ElevatedButton follow', (
      tester,
    ) async {
      final tokens = AdminTokens.from(palette: irisPalette, sizes: custom);
      late AdminControlSizes read;
      await tester.pumpWidget(
        _host(
          tokens,
          Builder(
            builder: (context) {
              read = context.sizes;
              return Column(
                children: [
                  IconAction(Icons.edit, label: 'Edit', onPressed: () {}),
                  ElevatedButton(onPressed: () {}, child: const Text('Go')),
                ],
              );
            },
          ),
        ),
      );
      expect(read, custom);
      expect(tester.getSize(find.byType(IconAction)), const Size.square(30));
      expect(tester.getSize(find.byType(ElevatedButton)).height, 30);
    });
  });
}
