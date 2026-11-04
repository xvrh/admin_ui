import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
AdminTokens _tokens(AdminTheme theme, {bool dark = false, Color? brand}) {
  final source = dark ? theme.dark! : theme.tokens;
  return AdminTokens.from(
    palette: brand == null ? source.palette : source.palette.branded(brand),
    radii: source.radii,
    focus: source.focus,
    sizes: source.sizes,
    stroke: source.stroke,
    iconSizes: source.iconSizes,
    field: source.field,
  );
}

/// Every shipped theme in both modes, keyed `'<theme> <mode>'`.
final _themes = <String, AdminTokens>{
  for (final theme in adminThemes)
    for (final dark in [false, true])
      '${theme.name} ${dark ? 'Dark' : 'Light'}': _tokens(theme, dark: dark),
};

Widget _host(AdminTokens tokens, Widget child) => MaterialApp(
  theme: buildAppTheme(tokens),
  home: Scaffold(
    body: Center(child: SizedBox(width: 480, child: child)),
  ),
);

const _three = [
  SegmentOption('a', 'One'),
  SegmentOption('b', 'Two'),
  SegmentOption('c', 'Three'),
];

/// The fill behind the segment labelled [label].
Color _segmentFill(WidgetTester tester, String label) => tester
    .widget<ColoredBox>(
      find
          .ancestor(of: find.text(label), matching: find.byType(ColoredBox))
          .first,
    )
    .color;

Color _textColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!.color!;

/// The Segmented group's box: the container that draws its edge.
Container _group(WidgetTester tester) => tester
    .widgetList<Container>(
      find.descendant(
        of: find.byWidgetPredicate((w) => w is Segmented),
        matching: find.byType(Container),
      ),
    )
    .firstWhere((c) => c.foregroundDecoration is BoxDecoration);

/// The widget of type [T] that holds the primary focus, if any.
T? _focused<T extends Widget>() {
  final context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return null;
  if (context.widget is T) return context.widget as T;
  return context.findAncestorWidgetOfExactType<T>();
}

/// The label of the segment under the primary focus.
String? _focusedSegment(WidgetTester tester) {
  final node = FocusManager.instance.primaryFocus;
  if (node == null) return null;
  final texts = tester.widgetList<Text>(
    find.descendant(
      of: find.byWidgetPredicate(
        (w) => w is Tappable && identical(w.focusNode, node),
      ),
      matching: find.byType(Text),
    ),
  );
  return texts.map((t) => t.data).whereType<String>().firstOrNull;
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

SemanticsNode _nodeOf(WidgetTester tester, String label) =>
    tester.getSemantics(find.text(label));

/// What a selection control draws for its value, in one theme and state.
typedef _Look = ({Color mark, Color content, Color label});

void main() {
  group('Segmented readOnly', () {
    testWidgets('ignores taps, and the arrows move focus but never select', (
      tester,
    ) async {
      final picked = <String>[];
      await tester.pumpWidget(
        _host(
          defaultTokens,
          Segmented<String>(
            value: 'b',
            onChanged: picked.add,
            readOnly: true,
            segments: _three,
          ),
        ),
      );
      await tester.tap(find.text('One'));
      await tester.pump();
      expect(picked, isEmpty, reason: 'a tap');

      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focusedSegment(tester), 'Two', reason: 'Tab lands on the value');
      await _key(tester, LogicalKeyboardKey.arrowRight);
      expect(_focusedSegment(tester), 'Three');
      await _key(tester, LogicalKeyboardKey.home);
      expect(_focusedSegment(tester), 'One');
      await _key(tester, LogicalKeyboardKey.end);
      expect(_focusedSegment(tester), 'Three');
      await _key(tester, LogicalKeyboardKey.space);
      await _key(tester, LogicalKeyboardKey.enter);
      expect(picked, isEmpty, reason: 'the keyboard');
    });

    testWidgets('is one Tab stop, announced read-only', (tester) async {
      await tester.pumpWidget(
        _host(
          defaultTokens,
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Segmented<String>(
                value: 'b',
                readOnly: true,
                semanticLabel: 'Layout',
                segments: _three,
              ),
              Button('After', onPressed: _noop),
            ],
          ),
        ),
      );
      expect(
        _nodeOf(tester, 'Two'),
        isSemantics(
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
          hasEnabledState: true,
          isEnabled: true,
          isReadOnly: true,
          isFocusable: true,
        ),
      );
      var group = _nodeOf(tester, 'Two').parent;
      while (group != null &&
          group.getSemanticsData().role != SemanticsRole.radioGroup) {
        group = group.parent;
      }
      expect(group, isNotNull);
      expect(group!, isSemantics(label: 'Layout', isReadOnly: true));

      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focusedSegment(tester), 'Two');
      await _key(tester, LogicalKeyboardKey.tab);
      expect(_focused<Button>()?.label, 'After', reason: 'one stop only');
    });

    testWidgets('takes no hover or press tint, and no click cursor', (
      tester,
    ) async {
      final hovered = WidgetStatesController({WidgetState.hovered});
      final pressed = WidgetStatesController({WidgetState.pressed});
      addTearDown(hovered.dispose);
      addTearDown(pressed.dispose);
      await tester.pumpWidget(
        _host(
          defaultTokens,
          Segmented<String>(
            value: 'a',
            readOnly: true,
            segments: [
              const SegmentOption('a', 'One'),
              SegmentOption('b', 'Two', statesController: hovered),
              SegmentOption('c', 'Three', statesController: pressed),
            ],
          ),
        ),
      );
      final colors = defaultTokens.palette;
      for (final label in ['Two', 'Three']) {
        expect(_segmentFill(tester, label), colors.surface, reason: label);
        expect(_textColor(tester, label), colors.foregroundMuted);
      }
      final cursors = tester
          .widgetList<MouseRegion>(
            find.descendant(
              of: find.byType(Segmented<String>),
              matching: find.byType(MouseRegion),
            ),
          )
          .map((r) => r.cursor);
      expect(cursors, isNot(contains(SystemMouseCursors.click)));
    });

    group('keeps the enabled look, its selection at 4.5:1 or more', () {
      for (final theme in adminThemes) {
        for (final dark in [false, true]) {
          for (final MapEntry(key: brand, value: seed) in _brands.entries) {
            final name = '${theme.name} ${dark ? 'Dark' : 'Light'} $brand';
            testWidgets(name, (tester) async {
              final tokens = _tokens(theme, dark: dark, brand: seed);
              Future<List<Color>> look({required bool readOnly}) async {
                await tester.pumpWidget(
                  _host(
                    tokens,
                    Segmented<String>(
                      key: ValueKey(readOnly),
                      value: 'a',
                      onChanged: readOnly ? null : (_) {},
                      readOnly: readOnly,
                      segments: _three,
                    ),
                  ),
                );
                return [
                  for (final label in ['One', 'Two']) ...[
                    _segmentFill(tester, label),
                    _textColor(tester, label),
                  ],
                  (_group(tester).foregroundDecoration! as BoxDecoration)
                      .border!
                      .top
                      .color,
                ];
              }

              final readOnly = await look(readOnly: true);
              expect(readOnly, await look(readOnly: false));
              final ratio = contrastRatio(readOnly[1], readOnly[0]);
              expect(
                ratio,
                greaterThanOrEqualTo(4.5),
                reason: 'the selected label on its fill',
              );
            });
          }
        }
      }
    });
  });

  testWidgets('a disabled Segmented leaves the Tab order', (tester) async {
    await tester.pumpWidget(
      _host(
        defaultTokens,
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Button('Before', onPressed: _noop),
            Segmented<String>(value: 'b', segments: _three),
            Button('After', onPressed: _noop),
          ],
        ),
      ),
    );
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_focused<Button>()?.label, 'Before');
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_focused<Button>()?.label, 'After');
    for (final label in ['One', 'Two', 'Three']) {
      expect(
        _nodeOf(tester, label),
        isSemantics(isEnabled: false, isFocusable: false, isReadOnly: false),
        reason: label,
      );
    }
  });

  group('the Segmented group takes the button corner and the field edge', () {
    for (final MapEntry(key: name, value: tokens) in _themes.entries) {
      testWidgets(name, (tester) async {
        for (final size in ControlSize.values) {
          for (final enabled in [true, false]) {
            await tester.pumpWidget(
              _host(
                tokens,
                Segmented<String>(
                  key: ValueKey((size, enabled)),
                  value: 'a',
                  onChanged: enabled ? (_) {} : null,
                  size: size,
                  segments: _three,
                ),
              ),
            );
            final corner = BorderRadius.circular(tokens.radii.button(size));
            final group = _group(tester);
            final edge = group.foregroundDecoration! as BoxDecoration;
            expect(edge.borderRadius, corner, reason: '$size');
            expect(
              (group.decoration! as BoxDecoration).borderRadius,
              corner,
              reason: '$size clip',
            );
            final ring = tester.widget<FocusRing>(
              find
                  .ancestor(
                    of: find.text('One'),
                    matching: find.byType(FocusRing),
                  )
                  .last,
            );
            expect(ring.radius, tokens.radii.button(size), reason: '$size');

            final states = {if (!enabled) WidgetState.disabled};
            final chrome = resolveFieldChrome(tokens, states);
            final expected = chrome.variant == FieldVariant.filled
                ? chrome.rule
                : fieldBorderSide(
                    tokens.palette,
                    states,
                    stroke: tokens.stroke,
                  );
            final side = (edge.border! as Border).top;
            expect(
              (side.color, side.width),
              (expected.color, expected.width),
              reason: '$size ${enabled ? 'enabled' : 'disabled'} edge',
            );
          }
        }
      });
    }
    test('a stadium in Material, square in Carbon', () {
      expect(_themes['Material Light']!.radii.button(ControlSize.medium), 999);
      expect(_themes['Carbon Light']!.radii.button(ControlSize.small), 0);
    });
  });

  // One read-only rule (the enabled look, at full contrast) and one disabled
  // rule (a grey label, and the value's mark dimmed from the control's own
  // selected look: a solid mark in the disabled grey under the page colour
  // for the three that fill it, Segmented's soft tint in a neutral tone)
  // across the four selection controls.
  group('read-only and disabled look alike across Toggle, Check, Choice and '
      'Segmented', () {
    for (final MapEntry(key: name, value: tokens) in _themes.entries) {
      testWidgets(name, (tester) async {
        final colors = tokens.palette;

        Future<Map<String, _Look>> looks(String mode) async {
          final ValueChanged<bool>? onBool = mode == 'enabled' ? (_) {} : null;
          final ValueChanged<String>? onString = mode == 'enabled'
              ? (_) {}
              : null;
          final readOnly = mode == 'readOnly';
          await tester.pumpWidget(
            _host(
              tokens,
              Column(
                key: ValueKey(mode),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Check(
                    value: true,
                    onChanged: onBool,
                    readOnly: readOnly,
                    label: 'Check',
                  ),
                  Toggle(
                    value: true,
                    onChanged: onBool,
                    readOnly: readOnly,
                    label: 'Toggle',
                  ),
                  Choice<String>(
                    value: 'a',
                    onChanged: onString,
                    readOnly: readOnly,
                    options: const [ChoiceOption('a', 'Choice')],
                  ),
                  Segmented<String>(
                    value: 'a',
                    onChanged: onString,
                    readOnly: readOnly,
                    segments: const [
                      SegmentOption('a', 'Picked'),
                      SegmentOption('b', 'Other'),
                    ],
                  ),
                ],
              ),
            ),
          );
          final box = tester.widget<Container>(
            find.descendant(
              of: find.byType(Check),
              matching: find.byWidgetPredicate(
                (w) => w is Container && w.constraints?.maxWidth == 18,
              ),
            ),
          );
          final track = tester.widget<AnimatedContainer>(
            find.descendant(
              of: find.byType(Toggle),
              matching: find.byType(AnimatedContainer),
            ),
          );
          final knob = tester.widget<Container>(
            find.descendant(
              of: find.byType(AnimatedAlign),
              matching: find.byType(Container),
            ),
          );
          final ring = tester.widget<Container>(
            find.descendant(
              of: find.byType(Choice<String>),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is Container &&
                    (w.decoration as BoxDecoration?)?.shape == BoxShape.circle,
              ),
            ),
          );
          final ringDecoration = ring.decoration! as BoxDecoration;
          return {
            'Check': (
              mark: (box.decoration! as BoxDecoration).color!,
              content: tester
                  .widget<Icon>(
                    find.descendant(
                      of: find.byType(Check),
                      matching: find.byType(Icon),
                    ),
                  )
                  .color!,
              label: _textColor(tester, 'Check'),
            ),
            'Toggle': (
              mark: (track.decoration! as BoxDecoration).color!,
              content: (knob.decoration! as BoxDecoration).color!,
              label: _textColor(tester, 'Toggle'),
            ),
            'Choice': (
              mark: (ringDecoration.border! as Border).top.color,
              content: ringDecoration.color!,
              label: _textColor(tester, 'Choice'),
            ),
            'Segmented': (
              mark: _segmentFill(tester, 'Picked'),
              content: _textColor(tester, 'Picked'),
              label: _textColor(tester, 'Other'),
            ),
          };
        }

        final enabled = await looks('enabled');
        final readOnly = await looks('readOnly');
        final disabled = await looks('disabled');

        expect(readOnly, enabled, reason: 'read-only is the enabled look');
        for (final control in ['Check', 'Toggle', 'Choice']) {
          expect(enabled[control]!.mark, colors.controlAccent);
          expect(enabled[control]!.label, colors.foreground);
        }

        for (final control in ['Check', 'Toggle', 'Choice']) {
          expect(disabled[control], (
            mark: colors.foregroundSubtle,
            content: colors.surface,
            label: colors.foregroundSubtle,
          ), reason: '$control disabled');
        }
        expect(disabled['Segmented'], (
          mark: Color.alphaBlend(colors.pressedOverlay, colors.surface),
          content: colors.foregroundSubtle,
          label: colors.foregroundSubtle,
        ), reason: 'Segmented disabled');
        expect(
          _segmentFill(tester, 'Other'),
          isNot(disabled['Segmented']!.mark),
          reason: 'the disabled selection stands apart',
        );
      });
    }
  });
}

void _noop() {}
