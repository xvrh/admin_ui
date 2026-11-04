import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The client accents the catalog's Brand control offers.
const _brands = <String, Color?>{
  'Default': null,
  'Crimson': Color(0xFFE11D48),
  'Violet': Color(0xFF7C3AED),
  'Teal': Color(0xFF0D9488),
  'Amber': Color(0xFFD97706),
};

/// [theme]'s light or dark tokens in the default type, so no font loads.
AdminTokens _tokens(
  AdminTheme theme, {
  bool dark = false,
  Color? brand,
  AdminButtonStyle? button,
}) {
  final source = dark ? theme.dark! : theme.tokens;
  return AdminTokens.from(
    palette: brand == null ? source.palette : source.palette.branded(brand),
    radii: source.radii,
    focus: source.focus,
    sizes: source.sizes,
    stroke: source.stroke,
    iconSizes: source.iconSizes,
    button: button ?? source.button,
  );
}

AdminTheme _theme(String name) =>
    adminThemes.firstWhere((theme) => theme.name == name);

Widget _host(
  AdminTokens tokens,
  Widget child, {
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  theme: buildAppTheme(tokens),
  home: Directionality(
    textDirection: direction,
    child: Scaffold(body: Center(child: child)),
  ),
);

/// The [Material] a button paints its fill and border with.
Material _surface(WidgetTester tester, Finder button) =>
    tester.widget<Material>(
      find.descendant(of: button, matching: find.byType(Material)).first,
    );

BorderRadius _corners(WidgetTester tester, Finder button) =>
    (_surface(tester, button).shape! as RoundedRectangleBorder).borderRadius
        .resolve(TextDirection.ltr);

BorderSide _side(WidgetTester tester, Finder button) =>
    (_surface(tester, button).shape! as RoundedRectangleBorder).side;

TextStyle _label(WidgetTester tester, Finder button) => tester
    .widget<Text>(find.descendant(of: button, matching: find.byType(Text)))
    .style!;

/// The opacity [button] is drawn at: its outermost [Opacity].
double _opacityOf(WidgetTester tester, Finder button) => tester
    .widget<Opacity>(
      find.descendant(of: button, matching: find.byType(Opacity)).first,
    )
    .opacity;

/// A button's label colour, and its fill as it lands on the page.
(Color, Color) _ink(WidgetTester tester, Finder button, Color page) => (
  _label(tester, button).color!,
  Color.alphaBlend(_surface(tester, button).color!, page),
);

const _variants = [
  ButtonVariant.primary,
  ButtonVariant.secondary,
  ButtonVariant.soft,
  ButtonVariant.ghost,
  ButtonVariant.link,
];

const _states = [
  <WidgetState>{},
  {WidgetState.hovered},
  {WidgetState.pressed},
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('geometry follows the theme\'s button style', _geometry);
  group('Carbon', _carbon);
  group('contrast', _contrast);
  group('disabled', _disabled);
  group('the style override', _override);
  group('Iris and shadcn are unchanged', _unchanged);
  group('link and soft', _linkAndSoft);
  group('SplitButton and IconAction', _splitAndIconAction);
}

void _geometry() {
  for (final theme in adminThemes) {
    testWidgets('${theme.name}: height, corner and padding at every size', (
      tester,
    ) async {
      final tokens = _tokens(theme);
      final style = tokens.button;
      for (final size in ControlSize.values) {
        final height = tokens.sizes.height(size);
        final insets = style.paddingOf(size, height);
        // Wider than any minimum width, so the padding alone sets the box.
        await tester.pumpWidget(
          _host(
            tokens,
            Button('Publish the page', size: size, onPressed: () {}),
          ),
        );
        final button = find.byType(Button);
        final box = tester.getRect(button);
        final label = tester.getRect(find.text('Publish the page'));
        expect(box.height, height, reason: '$size');
        expect(label.left - box.left, insets.start, reason: '$size');
        expect(box.right - label.right, insets.end, reason: '$size');
        expect(
          _corners(tester, button).topLeft.x,
          tokens.radii.button(size),
          reason: '$size',
        );
        final weight = style.labelWeight;
        if (weight != null) {
          expect(_label(tester, button).fontWeight, weight, reason: '$size');
        }

        await tester.pumpWidget(
          _host(
            tokens,
            Button(
              'Publish the page',
              icon: Icons.send_rounded,
              size: size,
              onPressed: () {},
            ),
          ),
        );
        final glyph = tester.getRect(find.byIcon(Icons.send_rounded));
        final withIcon = tester.getRect(find.byType(Button));
        if (style.iconPlacement == ButtonIconPlacement.leading) {
          expect(
            glyph.left - withIcon.left,
            insets.startFor(leadingIcon: true),
            reason: '$size',
          );
        } else {
          expect(withIcon.right - glyph.right, insets.start, reason: '$size');
        }
      }
    });
  }

  testWidgets('a minimum width holds a short label, centred', (tester) async {
    final tokens = _tokens(_theme('Fluent'));
    await tester.pumpWidget(_host(tokens, Button('OK', onPressed: () {})));
    final box = tester.getRect(find.byType(Button));
    expect(box.width, tokens.button.minWidthOf(ControlSize.medium));
    expect(box.width, 96);
    expect(tester.getCenter(find.text('OK')).dx, box.center.dx);
  });

  testWidgets('Material: a stadium, however tall', (tester) async {
    final tokens = _tokens(_theme('Material'));
    for (final size in ControlSize.values) {
      await tester.pumpWidget(
        _host(tokens, Button('Save', size: size, onPressed: () {})),
      );
      final button = find.byType(Button);
      expect(
        _corners(tester, button).topLeft.x,
        greaterThanOrEqualTo(tester.getSize(button).height / 2),
      );
    }
    await tester.pumpWidget(
      _host(
        tokens,
        Button.icon(
          Icons.tune_rounded,
          semanticLabel: 'Filters',
          onPressed: () {},
        ),
      ),
    );
    final icon = find.byType(Button);
    expect(
      _corners(tester, icon).topLeft.x,
      greaterThanOrEqualTo(tester.getSize(icon).height / 2),
      reason: 'an icon button is a circle',
    );
  });

  testWidgets('Material: the outlined button in controlBorder, the text '
      'button in the primary', (tester) async {
    final tokens = _tokens(_theme('Material'));
    final colors = tokens.palette;
    await tester.pumpWidget(
      _host(
        tokens,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Button('Outlined', onPressed: () {}),
            Button.ghost('Text', onPressed: () {}),
          ],
        ),
      ),
    );
    final outlined = find.widgetWithText(Button, 'Outlined');
    expect(_side(tester, outlined).color, colors.controlBorder);
    expect(
      _label(tester, find.widgetWithText(Button, 'Text')).color,
      colors.primaryText,
    );
  });
}

void _carbon() {
  final tokens = _tokens(_theme('Carbon'));
  final colors = tokens.palette;

  testWidgets('the label at the start, the glyph at the end edge', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        tokens,
        Button('Filter', icon: Icons.tune_rounded, onPressed: () {}),
      ),
    );
    final box = tester.getRect(find.byType(Button));
    final label = tester.getRect(find.text('Filter'));
    final glyph = tester.getRect(find.byIcon(Icons.tune_rounded));
    expect(label.left - box.left, 16);
    expect(box.right - glyph.right, 16);
    expect(glyph.left, greaterThan(label.right));
    // 16 before the label, 64 after it, the glyph inside those 64.
    expect(box.width, 16 + label.width + 64);
    expect(_corners(tester, find.byType(Button)), BorderRadius.zero);
  });

  testWidgets('stretched, the label stays at the start and the glyph at the '
      'end', (tester) async {
    await tester.pumpWidget(
      _host(
        tokens,
        SizedBox(
          width: 400,
          child: Button(
            'Publish',
            icon: Icons.send_rounded,
            expand: true,
            onPressed: () {},
          ),
        ),
      ),
    );
    final box = tester.getRect(find.byType(Button));
    expect(box.width, 400);
    expect(tester.getRect(find.text('Publish')).left - box.left, 16);
    expect(
      box.right - tester.getRect(find.byIcon(Icons.send_rounded)).right,
      16,
    );
  });

  testWidgets('right to left, the glyph takes the left edge', (tester) async {
    await tester.pumpWidget(
      _host(
        tokens,
        Button('Filter', icon: Icons.tune_rounded, onPressed: () {}),
        direction: TextDirection.rtl,
      ),
    );
    final box = tester.getRect(find.byType(Button));
    expect(box.right - tester.getRect(find.text('Filter')).right, 16);
    expect(tester.getRect(find.byIcon(Icons.tune_rounded)).left - box.left, 16);
  });

  testWidgets('loading holds the width, the spinner centred on the button', (
    tester,
  ) async {
    Widget save({bool loading = false}) =>
        _host(tokens, Button('Save', loading: loading, onPressed: () {}));
    await tester.pumpWidget(save());
    final resting = tester.getRect(find.byType(Button));
    await tester.pumpWidget(save(loading: true));
    expect(tester.getRect(find.byType(Button)), resting);
    expect(tester.getCenter(find.byType(Spinner)), resting.center);
  });

  testWidgets('a menu trigger\'s chevron takes the end edge', (tester) async {
    await tester.pumpWidget(
      _host(
        tokens,
        Button(
          'Options',
          trailingIcon: Icons.keyboard_arrow_down_rounded,
          onPressed: () {},
        ),
      ),
    );
    final box = tester.getRect(find.byType(Button));
    final chevron = tester.getRect(
      find.byIcon(Icons.keyboard_arrow_down_rounded),
    );
    expect(box.right - chevron.right, 16);
  });

  testWidgets('a filled Gray 80 secondary and a link-primary ghost', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        tokens,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Button('Secondary', onPressed: () {}),
            Button.ghost('Ghost', onPressed: () {}),
          ],
        ),
      ),
    );
    final secondary = find.widgetWithText(Button, 'Secondary');
    expect(_surface(tester, secondary).color, colors.neutralFill);
    expect(_label(tester, secondary).color, colors.onNeutralFill);
    expect(_side(tester, secondary), BorderSide.none);
    expect(
      _label(tester, find.widgetWithText(Button, 'Ghost')).color,
      colors.primaryText,
    );
  });

  testWidgets('a ghost or a link sets its glyph after the label, and pads '
      'its end as its start', (tester) async {
    for (final button in [
      Button.ghost('Add row', icon: Icons.add_rounded, onPressed: () {}),
      Button.link('Add row', icon: Icons.add_rounded, onPressed: () {}),
    ]) {
      await tester.pumpWidget(_host(tokens, button));
      final box = tester.getRect(find.byType(Button));
      final label = tester.getRect(find.text('Add row'));
      final glyph = tester.getRect(find.byIcon(Icons.add_rounded));
      expect(label.left - box.left, 16, reason: '${button.variant}');
      expect(glyph.left - label.right, AdminSpacing.md);
      expect(box.right - glyph.right, 16);
    }
  });

  testWidgets('an icon-only ghost keeps the neutral glyph; a split ghost\'s '
      'caret takes its action\'s', (tester) async {
    await tester.pumpWidget(
      _host(
        tokens,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Button.icon(
              Icons.tune_rounded,
              semanticLabel: 'Filters',
              variant: ButtonVariant.ghost,
              onPressed: () {},
            ),
            SplitButton(
              label: 'Export',
              variant: ButtonVariant.ghost,
              onPressed: () {},
              entries: [MenuItem('CSV', onSelect: () {})],
              menuSemanticLabel: 'More export options',
            ),
          ],
        ),
      ),
    );
    Color glyph(IconData icon) => tester.widget<Icon>(find.byIcon(icon)).color!;
    expect(glyph(Icons.tune_rounded), colors.foregroundSecondary);
    expect(glyph(Icons.keyboard_arrow_down_rounded), colors.primaryText);
    expect(
      _label(tester, find.widgetWithText(Button, 'Export')).color,
      colors.primaryText,
    );
  });

  testWidgets('a flush ghost still lines its label up with the edge', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        tokens,
        SizedBox(
          width: 300,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Button.ghost('Add row', flush: true, onPressed: () {}),
          ),
        ),
      ),
    );
    final slot = tester.getRect(find.byType(SizedBox).first);
    expect(tester.getRect(find.text('Add row')).left, slot.left);
  });
}

void _contrast() {
  for (final theme in adminThemes) {
    for (final dark in [false, true]) {
      for (final MapEntry(key: brand, value: seed) in _brands.entries) {
        final why = '${theme.name} ${dark ? 'Dark' : 'Light'}, brand $brand';
        testWidgets('$why: every label reads at 4.5:1 on its fill, in either '
            'tone, at rest, hovered and pressed', (tester) async {
          final tokens = _tokens(theme, dark: dark, brand: seed);
          final colors = tokens.palette;
          final controllers = <WidgetStatesController>[];
          addTearDown(() {
            for (final c in controllers) {
              c.dispose();
            }
          });
          final cases = <(Key, String)>[];
          final buttons = <Widget>[];
          for (final variant in _variants) {
            for (final danger in [false, true]) {
              for (final states in _states) {
                final key = ValueKey((variant, danger, states));
                final controller = WidgetStatesController({...states});
                controllers.add(controller);
                cases.add((key, '$variant${danger ? ' danger' : ''} $states'));
                buttons.add(
                  Button(
                    'Delete',
                    key: key,
                    variant: variant,
                    danger: danger,
                    statesController: controller,
                    onPressed: () {},
                  ),
                );
              }
            }
          }
          await tester.pumpWidget(_host(tokens, Wrap(children: buttons)));
          for (final (key, name) in cases) {
            for (final page in [colors.background, colors.surface]) {
              final (label, fill) = _ink(tester, find.byKey(key), page);
              expect(
                contrastRatio(label, fill),
                greaterThanOrEqualTo(4.5),
                reason: '$name on $page',
              );
            }
          }
        });
      }
    }
  }
}

void _disabled() {
  testWidgets('faded keeps the variant and its tone at the faded opacity', (
    tester,
  ) async {
    final tokens = _tokens(_theme('shadcn'));
    final colors = tokens.palette;
    final style = tokens.button;
    expect(style.disabled, ButtonDisabledStyle.faded);
    await tester.pumpWidget(
      _host(
        tokens,
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Button.danger('Delete'),
            Button('Remove', danger: true),
            Button.link('Unlink', danger: true),
          ],
        ),
      ),
    );
    final delete = find.widgetWithText(Button, 'Delete');
    expect(_surface(tester, delete).color, colors.danger);
    expect(_label(tester, delete).color, colors.onDanger);
    final remove = find.widgetWithText(Button, 'Remove');
    expect(_side(tester, remove).color, colors.danger);
    expect(_label(tester, remove).color, colors.dangerText);
    expect(
      _label(tester, find.widgetWithText(Button, 'Unlink')).color,
      colors.dangerText,
    );
    for (final label in ['Delete', 'Remove', 'Unlink']) {
      expect(
        _opacityOf(tester, find.widgetWithText(Button, label)),
        style.fadedOpacity,
        reason: label,
      );
      expect(style.fadedOpacity, 0.5);
    }
  });

  testWidgets('neutral draws every filled variant in one grey, whatever its '
      'tone', (tester) async {
    final tokens = _tokens(_theme('Ant'));
    await tester.pumpWidget(
      _host(
        tokens,
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Button.primary('Primary'),
            Button.danger('Delete'),
            Button.soft('Soft'),
          ],
        ),
      ),
    );
    final fills = {
      for (final label in ['Primary', 'Delete', 'Soft'])
        _surface(tester, find.widgetWithText(Button, label)).color,
    };
    expect(fills, hasLength(1));
    expect(find.byType(Opacity), findsNothing);
  });

  for (final theme in adminThemes) {
    for (final dark in [false, true]) {
      for (final MapEntry(key: brand, value: seed) in _brands.entries) {
        final why = '${theme.name} ${dark ? 'Dark' : 'Light'}, brand $brand';
        testWidgets('$why: a neutral disabled label keeps 2.5:1', (
          tester,
        ) async {
          final source = _tokens(theme, dark: dark, brand: seed);
          final tokens = _tokens(
            theme,
            dark: dark,
            brand: seed,
            button: source.button.copyWith(
              disabled: ButtonDisabledStyle.neutral,
            ),
          );
          final colors = tokens.palette;
          await tester.pumpWidget(
            _host(
              tokens,
              Wrap(
                children: [
                  for (final variant in _variants)
                    for (final danger in [false, true])
                      Button(
                        'Off',
                        key: ValueKey((variant, danger)),
                        variant: variant,
                        danger: danger,
                      ),
                ],
              ),
            ),
          );
          for (final variant in _variants) {
            for (final danger in [false, true]) {
              for (final page in [colors.background, colors.surface]) {
                final (label, fill) = _ink(
                  tester,
                  find.byKey(ValueKey((variant, danger))),
                  page,
                );
                expect(
                  contrastRatio(label, fill),
                  greaterThanOrEqualTo(2.5),
                  reason: '$variant${danger ? ' danger' : ''} on $page',
                );
              }
            }
          }
        });
      }
    }
  }
}

void _override() {
  testWidgets('its members win over the theme\'s', (tester) async {
    final tokens = _tokens(_theme('Iris'));
    await tester.pumpWidget(
      _host(
        tokens,
        SizedBox(
          width: 400,
          child: Button(
            'Publish',
            expand: true,
            style: const AdminButtonStyle(
              labelAlignment: ButtonLabelAlignment.start,
              padding: AdminButtonPadding.all(
                AdminButtonInsets(start: 20, end: 30),
              ),
              labelWeight: FontWeight.w300,
              minWidth: AdminButtonMinWidth(),
            ),
            onPressed: () {},
          ),
        ),
      ),
    );
    final box = tester.getRect(find.byType(Button));
    expect(tester.getRect(find.text('Publish')).left - box.left, 20);
    expect(_label(tester, find.byType(Button)).fontWeight, FontWeight.w300);
  });

  testWidgets('its unset padding, minimum width and weight are the '
      'theme\'s', (tester) async {
    final tokens = _tokens(_theme('Fluent'));
    await tester.pumpWidget(
      _host(
        tokens,
        Button(
          'OK',
          style: const AdminButtonStyle(disabled: ButtonDisabledStyle.faded),
          onPressed: () {},
        ),
      ),
    );
    expect(tester.getSize(find.byType(Button)).width, 96);
    expect(
      _label(tester, find.byType(Button)).fontWeight,
      tokens.button.labelWeight,
    );
  });

  testWidgets('a faded disabled look for one button in a neutral theme', (
    tester,
  ) async {
    final tokens = _tokens(_theme('Iris'));
    await tester.pumpWidget(
      _host(
        tokens,
        Button.danger(
          'Delete',
          style: tokens.button.copyWith(disabled: ButtonDisabledStyle.faded),
        ),
      ),
    );
    expect(_surface(tester, find.byType(Button)).color, tokens.palette.danger);
    expect(_opacityOf(tester, find.byType(Button)), 0.5);
  });

  testWidgets('a SplitButton hands it to both segments', (tester) async {
    final tokens = _tokens(_theme('Iris'));
    await tester.pumpWidget(
      _host(
        tokens,
        SplitButton(
          label: 'Publish',
          onPressed: () {},
          entries: [MenuItem('Schedule…', onSelect: () {})],
          menuSemanticLabel: 'More publish options',
          style: const AdminButtonStyle(
            padding: AdminButtonPadding.all(AdminButtonInsets.symmetric(24)),
          ),
        ),
      ),
    );
    final action = find.ancestor(
      of: find.text('Publish'),
      matching: find.byType(Button),
    );
    expect(
      tester.getRect(find.text('Publish')).left - tester.getRect(action).left,
      24,
    );
  });
}

void _unchanged() {
  for (final name in ['Iris', 'shadcn']) {
    for (final dark in [false, true]) {
      testWidgets('$name ${dark ? 'Dark' : 'Light'}: rects and colours at '
          'rest, hovered and pressed', (tester) async {
        final tokens = _tokens(_theme(name), dark: dark);
        final colors = tokens.palette;
        final radii = tokens.radii;
        final sizes = tokens.sizes;
        expect(tokens.button.padding, isNull);
        expect(tokens.button.minWidth, isNull);
        expect(tokens.button.labelWeight, isNull);

        for (final size in ControlSize.values) {
          await tester.pumpWidget(
            _host(tokens, Button.primary('Save', size: size, onPressed: () {})),
          );
          final button = find.byType(Button);
          final height = sizes.height(size);
          final box = tester.getRect(button);
          final label = tester.getRect(find.text('Save'));
          expect(box.height, height);
          expect(label.left - box.left, height / 2 - 4);
          expect(box.width, label.width + height - 8);
          expect(
            _corners(tester, button).topLeft.x,
            size == ControlSize.small ? radii.radiusSmall : radii.radius,
          );
          expect(
            _label(tester, button).fontWeight,
            (size == ControlSize.small
                    ? tokens.typography.buttonSmall
                    : tokens.typography.button)
                .fontWeight,
          );
        }

        final hover = WidgetStatesController({WidgetState.hovered});
        final pressed = WidgetStatesController({WidgetState.pressed});
        addTearDown(hover.dispose);
        addTearDown(pressed.dispose);
        for (final (variant, fill, hoverFill, pressedFill, fg, border) in [
          (
            ButtonVariant.primary,
            colors.primary,
            colors.primaryHover,
            colors.primaryActive,
            colors.onPrimary,
            null,
          ),
          (
            ButtonVariant.secondary,
            colors.surface,
            Color.alphaBlend(colors.hoverOverlay, colors.surface),
            Color.alphaBlend(colors.pressedOverlay, colors.surface),
            colors.foreground,
            colors.border,
          ),
          (
            ButtonVariant.ghost,
            Colors.transparent,
            Color.alphaBlend(colors.hoverOverlay, Colors.transparent),
            Color.alphaBlend(colors.pressedOverlay, Colors.transparent),
            colors.foregroundSecondary,
            null,
          ),
        ]) {
          for (final (states, expected) in [
            (null, fill),
            (hover, hoverFill),
            (pressed, pressedFill),
          ]) {
            await tester.pumpWidget(
              _host(
                tokens,
                Button(
                  'Save',
                  // A fresh state each time: a controller swapped out carries
                  // its live states into the next one.
                  key: ValueKey((variant, states)),
                  variant: variant,
                  statesController: states,
                  onPressed: () {},
                ),
              ),
            );
            final button = find.byType(Button);
            expect(
              _surface(tester, button).color,
              expected,
              reason: '$variant',
            );
            expect(_label(tester, button).color, fg, reason: '$variant');
            expect(
              _side(tester, button),
              border == null ? BorderSide.none : BorderSide(color: border),
              reason: '$variant',
            );
            expect(_label(tester, button).decoration, isNull);
          }
        }
      });
    }
  }
}

void _linkAndSoft() {
  final tokens = _tokens(_theme('Iris'));
  final colors = tokens.palette;

  testWidgets('a link: the primary text, underlined under the pointer, laid '
      'out as a ghost', (tester) async {
    await tester.pumpWidget(
      _host(
        tokens,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Button.link('History', onPressed: () {}),
            Button.ghost('History', onPressed: () {}),
          ],
        ),
      ),
    );
    final link = find.byType(Button).first;
    final ghost = find.byType(Button).last;
    expect(tester.getSize(link), tester.getSize(ghost));
    expect(_surface(tester, link).color, Colors.transparent);
    expect(_side(tester, link), BorderSide.none);
    expect(_label(tester, link).color, colors.primaryText);
    expect(_label(tester, link).decoration, isNull);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(link));
    await tester.pump();
    expect(_label(tester, link).decoration, TextDecoration.underline);
    expect(_surface(tester, link).color, Colors.transparent);
  });

  testWidgets('a link sets no minimum width, where a button does', (
    tester,
  ) async {
    final fluent = _tokens(_theme('Fluent'));
    await tester.pumpWidget(
      _host(
        fluent,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Button.link('Go', onPressed: () {}),
            Button.ghost('Go', onPressed: () {}),
          ],
        ),
      ),
    );
    final label = tester.getSize(find.text('Go').first).width;
    final padding = fluent.button.paddingOf(
      ControlSize.medium,
      fluent.sizes.medium,
    );
    expect(
      tester.getSize(find.byType(Button).first).width,
      padding.start + label + padding.end,
    );
    expect(
      tester.getSize(find.byType(Button).last).width,
      fluent.button.minWidthOf(ControlSize.medium),
    );
  });

  testWidgets('a link with danger reads in the danger text colour', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(tokens, Button.link('Remove', danger: true, onPressed: () {})),
    );
    expect(_label(tester, find.byType(Button)).color, colors.dangerText);
  });

  testWidgets('soft: softFill and onSoft, overlaid under the pointer', (
    tester,
  ) async {
    final hover = WidgetStatesController({WidgetState.hovered});
    addTearDown(hover.dispose);
    await tester.pumpWidget(
      _host(
        tokens,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Button.soft('Rest', onPressed: () {}),
            Button.soft('Hover', statesController: hover, onPressed: () {}),
          ],
        ),
      ),
    );
    final rest = find.widgetWithText(Button, 'Rest');
    expect(_surface(tester, rest).color, colors.softFill);
    expect(_label(tester, rest).color, colors.onSoft);
    expect(
      _surface(tester, find.widgetWithText(Button, 'Hover')).color,
      Color.alphaBlend(colors.hoverOverlay, colors.softFill),
    );
  });

  testWidgets('soft with danger takes the danger tint', (tester) async {
    await tester.pumpWidget(
      _host(tokens, Button.soft('Delete', danger: true, onPressed: () {})),
    );
    expect(
      _surface(tester, find.byType(Button)).color,
      colors.statusFill(colors.danger),
    );
  });

  testWidgets('primary with danger is exactly the danger variant', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        tokens,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Button.primary('A', danger: true, onPressed: () {}),
            Button.danger('B', onPressed: () {}),
          ],
        ),
      ),
    );
    final a = find.widgetWithText(Button, 'A');
    final b = find.widgetWithText(Button, 'B');
    expect(_surface(tester, a).color, _surface(tester, b).color);
    expect(_label(tester, a).color, _label(tester, b).color);
    expect(tester.getSize(a).height, tester.getSize(b).height);
  });

  testWidgets('Ant: the secondary\'s outline and label turn primaryHover '
      'under the pointer', (tester) async {
    final ant = _tokens(_theme('Ant'));
    final hover = WidgetStatesController({WidgetState.hovered});
    addTearDown(hover.dispose);
    await tester.pumpWidget(
      _host(ant, Button('Save', statesController: hover, onPressed: () {})),
    );
    final button = find.byType(Button);
    expect(_side(tester, button).color, ant.palette.primaryHover);
    expect(
      _label(tester, button).color,
      ant.palette.readableOn(ant.palette.primaryHover),
    );
    expect(_surface(tester, button).color, ant.palette.surface);
  });
}

void _splitAndIconAction() {
  testWidgets('Material: a stadium outside, square inner corners', (
    tester,
  ) async {
    final tokens = _tokens(_theme('Material'));
    await tester.pumpWidget(
      _host(
        tokens,
        SplitButton(
          label: 'Publish',
          onPressed: () {},
          entries: [MenuItem('Schedule…', onSelect: () {})],
          menuSemanticLabel: 'More publish options',
        ),
      ),
    );
    final action = find.ancestor(
      of: find.text('Publish'),
      matching: find.byType(Button),
    );
    final caret = find.ancestor(
      of: find.byIcon(Icons.keyboard_arrow_down_rounded),
      matching: find.byType(Button),
    );
    final height = tester.getSize(action).height;
    final start = _corners(tester, action);
    final end = _corners(tester, caret);
    expect(start.topLeft.x, greaterThanOrEqualTo(height / 2));
    expect(start.topRight, Radius.zero);
    expect(end.topLeft, Radius.zero);
    expect(end.topRight.x, greaterThanOrEqualTo(height / 2));
    final group = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(SplitButton),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(
      (group.decoration as BoxDecoration).borderRadius,
      BorderRadius.circular(tokens.radii.button(ControlSize.medium)),
    );
  });

  testWidgets('Carbon: the caret at the end, the action\'s label at its '
      'start', (tester) async {
    final tokens = _tokens(_theme('Carbon'));
    await tester.pumpWidget(
      _host(
        tokens,
        SplitButton(
          label: 'Publish',
          icon: Icons.send_rounded,
          onPressed: () {},
          entries: [MenuItem('Schedule…', onSelect: () {})],
          menuSemanticLabel: 'More publish options',
        ),
      ),
    );
    final split = tester.getRect(find.byType(SplitButton));
    final caret = tester.getRect(
      find.ancestor(
        of: find.byIcon(Icons.keyboard_arrow_down_rounded),
        matching: find.byType(Button),
      ),
    );
    expect(caret.right, split.right);
    expect(tester.getRect(find.text('Publish')).left - split.left, 16);
    expect(
      tester.getRect(find.byIcon(Icons.send_rounded)).right,
      caret.left - 1 - 16,
    );
  });

  testWidgets('a disabled faded split fades its divider and outline too', (
    tester,
  ) async {
    final tokens = _tokens(_theme('shadcn'));
    await tester.pumpWidget(
      _host(
        tokens,
        const SplitButton(
          label: 'Save',
          variant: ButtonVariant.secondary,
          onPressed: null,
          entries: [MenuItem('Schedule…')],
          menuSemanticLabel: 'More save options',
        ),
      ),
    );
    final group = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(SplitButton),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final border = (group.decoration as BoxDecoration).border! as Border;
    expect(border.top.color.a, closeTo(tokens.palette.border.a * 0.5, 1e-3));
  });

  for (final (theme, radius) in [
    ('Material', 999.0),
    ('Carbon', 0.0),
    ('Iris', _tokens(_theme('Iris')).radii.radiusSmall),
    ('shadcn', _tokens(_theme('shadcn')).radii.radiusSmall),
  ]) {
    testWidgets('$theme: IconAction hovers in the small button\'s corner', (
      tester,
    ) async {
      final tokens = _tokens(_theme(theme));
      await tester.pumpWidget(
        _host(
          tokens,
          IconAction(Icons.close_rounded, label: 'Close', onPressed: () {}),
        ),
      );
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(IconAction),
              matching: find.byType(DecoratedBox),
            )
            .last,
      );
      expect(
        (box.decoration as BoxDecoration).borderRadius,
        BorderRadius.circular(radius),
      );
      expect(
        tester.getSize(find.byType(IconAction)).height,
        tokens.sizes.medium,
      );
    });
  }
}
