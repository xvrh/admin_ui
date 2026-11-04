// Every field box in a theme draws one anatomy (`context.fieldStyle`): an
// input and a select trigger take the same corner and the same edges state
// for state, their content holds still as an edge thickens, and each preset
// draws its reference system's field — Carbon's filled box, Fluent's brand
// underline, M3's 4dp outline — while Iris and shadcn draw what they did.

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// [source] in the platform's font, everything else as the theme has it: a
/// Google font would be fetched.
AdminTokens _fontless(AdminTokens source) {
  final spec = source.typography.spec;
  return source.copyWith(
    typography: AdminTypography.from(
      source.palette,
      AdminTypeSpec(
        ramp: spec.ramp,
        scale: spec.scale,
        heading: spec.heading,
        strong: spec.strong,
        body: spec.body,
        tracking: spec.tracking,
        uppercaseLabels: spec.uppercaseLabels,
      ),
    ),
  );
}

AdminTokens _tokens(AdminTheme theme, {required bool dark}) =>
    _fontless(dark ? theme.dark! : theme.tokens);

Widget _host(AdminTokens tokens, Widget child) => MaterialApp(
  theme: buildAppTheme(tokens),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.xxl),
        child: SizedBox(width: 320, child: child),
      ),
    ),
  ),
);

/// An input above a select trigger, both holding 'Value'.
Widget _pair({bool invalid = false}) => FieldStateScope(
  invalid: invalid,
  child: Column(
    children: [
      const InputField(value: 'Value'),
      const Gap(AdminSpacing.xl),
      Popover(
        anchor: (context, controller) => FieldTrigger(
          controller: controller,
          chevron: true,
          child: Text('Value', style: fieldTextStyle(context)),
        ),
        content: (context, controller) => const SizedBox.shrink(),
      ),
    ],
  ),
);

final _input = find.byType(InputDecorator);
final _trigger = find.byType(FieldChrome);
final _inputText = find.byType(EditableText);
final _triggerText = find.descendant(
  of: _trigger,
  matching: find.text('Value'),
);

/// The states the input's decorator resolves its border in.
Set<WidgetState> _inputStates(WidgetTester tester) {
  final decorator = tester.widget<InputDecorator>(_input);
  return {
    if (decorator.isFocused) WidgetState.focused,
    if (decorator.isHovering) WidgetState.hovered,
    if (!decorator.decoration.enabled) WidgetState.disabled,
  };
}

FieldBorder _inputBorder(WidgetTester tester) =>
    tester.widget<InputDecorator>(_input).decoration.border! as FieldBorder;

/// The chrome the input draws: its border resolved in its states, which
/// fold in the scope's through `mapStates`.
FieldChromeSpec _inputChrome(WidgetTester tester) =>
    _inputBorder(tester).chromeOf(_inputStates(tester));

/// The states the trigger's chrome draws in.
Set<WidgetState> _triggerStates(WidgetTester tester) {
  final chrome = tester.widget<FieldChrome>(_trigger);
  final state = FieldStateScope.of(tester.element(_trigger)).merge(
    enabled: chrome.enabled,
    readOnly: chrome.readOnly,
    invalid: chrome.invalid,
  );
  return state.states(hovered: chrome.hovered, focused: chrome.active);
}

/// The focus rings lit around the trigger: none, as around an input, since
/// the chrome's own edge shows its focus.
Iterable<FocusRing> _triggerRings(WidgetTester tester) => tester
    .widgetList<FocusRing>(
      find.ancestor(of: _trigger, matching: find.byType(FocusRing)),
    )
    .where((ring) => ring.focused);

Container _triggerBox(WidgetTester tester) => tester.widget<Container>(
  find.descendant(of: _trigger, matching: find.byType(Container)).first,
);

/// The input and the trigger draw the same chrome at the same corner, and
/// the trigger draws exactly `fieldDecoration` of it.
void _expectSameChrome(
  WidgetTester tester,
  AdminTokens tokens, {
  required Set<WidgetState> inputStates,
  required String reason,
}) {
  final corners = BorderRadius.circular(tokens.radii.radiusField);
  final triggerStates = _triggerStates(tester);
  expect(
    resolveFieldChrome(tokens, triggerStates),
    _inputBorder(tester).chromeOf(inputStates),
    reason: reason,
  );
  expect(_inputBorder(tester).borderRadius, corners, reason: reason);
  final box = _triggerBox(tester);
  expect(
    box.decoration,
    fieldDecoration(tokens, triggerStates, corners),
    reason: reason,
  );
  expect(
    box.foregroundDecoration,
    fieldForegroundDecoration(tokens, triggerStates, corners),
    reason: reason,
  );
}

void main() {
  for (final theme in adminThemes) {
    for (final dark in [false, true]) {
      final name = '${theme.name} ${dark ? 'Dark' : 'Light'}';
      final tokens = _tokens(theme, dark: dark);

      testWidgets('$name: an input and a trigger draw one box in every state', (
        tester,
      ) async {
        await tester.pumpWidget(_host(tokens, _pair()));
        final height = tester.getSize(_input).height;
        expect(height, tokens.sizes.medium);
        expect(tester.getSize(_trigger).height, height);
        expect(_inputStates(tester), isEmpty);
        expect(_triggerStates(tester), isEmpty);
        _expectSameChrome(tester, tokens, inputStates: {}, reason: 'rest');

        // The text starts as far in on both.
        double inset(Finder text, Finder box) =>
            tester.getRect(text).left - tester.getRect(box).left;
        expect(
          inset(_triggerText, _trigger),
          inset(_inputText, _input),
          reason: 'text inset',
        );
        final inputText = tester.getRect(_inputText);
        final triggerText = tester.getRect(_triggerText);

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(tester.getCenter(_input));
        await tester.pump();
        final hoveredInput = _inputStates(tester);
        expect(hoveredInput, {WidgetState.hovered});
        await mouse.moveTo(tester.getCenter(_trigger));
        await tester.pump();
        expect(_triggerStates(tester), {WidgetState.hovered});
        _expectSameChrome(
          tester,
          tokens,
          inputStates: hoveredInput,
          reason: 'hovered',
        );
        expect(tester.getRect(_triggerText), triggerText, reason: 'hovered');
        await mouse.moveTo(Offset.zero);
        await tester.pump();

        await tester.tap(find.byType(TextField));
        await tester.pump();
        final focusedInput = _inputStates(tester);
        expect(focusedInput, {WidgetState.focused});
        expect(tester.getRect(_inputText), inputText, reason: 'focused');
        // Tab moves focus on to the trigger, with the keyboard highlight.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_triggerStates(tester), {WidgetState.focused});
        _expectSameChrome(
          tester,
          tokens,
          inputStates: focusedInput,
          reason: 'focused',
        );
        expect(_triggerRings(tester), isEmpty, reason: 'focused');
        expect(tester.getRect(_triggerText), triggerText, reason: 'focused');
      });

      testWidgets('$name: invalid, at rest and focused', (tester) async {
        await tester.pumpWidget(_host(tokens, _pair(invalid: true)));
        _expectSameChrome(tester, tokens, inputStates: {}, reason: 'invalid');
        expect(
          _inputChrome(tester),
          resolveFieldChrome(tokens, {WidgetState.error}),
        );
        final triggerText = tester.getRect(_triggerText);
        final inputText = tester.getRect(_inputText);

        await tester.tap(find.byType(TextField));
        await tester.pump();
        final focusedInput = _inputStates(tester);
        expect(
          _inputChrome(tester),
          resolveFieldChrome(tokens, {WidgetState.error, WidgetState.focused}),
        );
        expect(tester.getRect(_inputText), inputText);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        _expectSameChrome(
          tester,
          tokens,
          inputStates: focusedInput,
          reason: 'invalid and focused',
        );
        expect(_triggerRings(tester), isEmpty, reason: 'invalid and focused');
        expect(tester.getRect(_triggerText), triggerText);
      });
    }
  }

  group('the content holds still in every anatomy', () {
    for (final (variant, indicator) in [
      (FieldVariant.outlined, FieldFocusIndicator.outline),
      (FieldVariant.filled, FieldFocusIndicator.outline),
      (FieldVariant.filled, FieldFocusIndicator.underline),
      (FieldVariant.underlined, FieldFocusIndicator.underline),
      (FieldVariant.underlined, FieldFocusIndicator.outline),
    ]) {
      testWidgets('${variant.name}, focus on the ${indicator.name}', (
        tester,
      ) async {
        final tokens = defaultTokens.copyWith(
          // Every edge a different width, so any leak would show.
          stroke: const AdminStroke(fieldFocus: 2, fieldError: 3),
          field: AdminFieldStyle(variant: variant, focusIndicator: indicator),
        );
        final rects = <String, Rect>{};
        final boxes = <String, Size>{};
        for (final (label, chrome) in [
          ('rest', const FieldChrome(child: Text('Value'))),
          ('hovered', const FieldChrome(hovered: true, child: Text('Value'))),
          ('focused', const FieldChrome(active: true, child: Text('Value'))),
          ('invalid', const FieldChrome(invalid: true, child: Text('Value'))),
          (
            'invalid and focused',
            const FieldChrome(
              active: true,
              invalid: true,
              child: Text('Value'),
            ),
          ),
          ('disabled', const FieldChrome(enabled: false, child: Text('Value'))),
        ]) {
          await tester.pumpWidget(_host(tokens, chrome));
          rects[label] = tester.getRect(find.text('Value'));
          boxes[label] = tester.getSize(find.byType(FieldChrome));
        }
        expect(rects.values.toSet(), hasLength(1), reason: '$rects');
        expect(boxes.values.toSet(), hasLength(1), reason: '$boxes');
        // Where an input's text starts.
        expect(
          rects['rest']!.left - tester.getRect(find.byType(FieldChrome)).left,
          tokens.sizes.fieldPaddingX,
        );
      });
    }
  });

  group('Carbon: a filled box over a bottom rule', () {
    for (final dark in [false, true]) {
      testWidgets(dark ? 'dark' : 'light', (tester) async {
        final tokens = _tokens(carbonTheme, dark: dark);
        final rest = resolveFieldChrome(tokens, {});
        expect(rest.variant, FieldVariant.filled);
        expect(rest.outline, BorderSide.none);
        expect(rest.border, const EdgeInsets.only(bottom: 1));
        expect(
          contrastRatio(rest.rule.color, rest.fill),
          greaterThanOrEqualTo(3),
        );
        // Square: Carbon's corners are 0.
        expect(tokens.radii.radiusField, 0);

        await tester.pumpWidget(_host(tokens, _pair()));
        expect(_inputChrome(tester), rest);
        final box = _triggerBox(tester).decoration! as ShapeDecoration;
        expect(box.color, rest.fill);
        expect(box.padding, const EdgeInsets.only(bottom: 1));

        // Focused: the 2px $focus outline inset over the whole edge.
        final focused = resolveFieldChrome(tokens, {WidgetState.focused});
        expect(
          focused.outline,
          BorderSide(color: tokens.palette.focusRing, width: 2),
        );
        // Hovered: $field-hover.
        expect(
          resolveFieldChrome(tokens, {WidgetState.hovered}).fill,
          tokens.palette.fieldFillHover,
        );
      });
    }
  });

  group('Fluent: the brand underline on focus', () {
    for (final (label, theme) in [
      ('default', fluentTheme),
      ('crimson', fluentTheme.branded('Crimson', const Color(0xFFDC2626))),
    ]) {
      for (final dark in [false, true]) {
        testWidgets('$label ${dark ? 'dark' : 'light'}', (tester) async {
          final tokens = _tokens(theme, dark: dark);
          await tester.pumpWidget(_host(tokens, _pair()));
          final rest = _inputChrome(tester);
          await tester.tap(find.byType(TextField));
          await tester.pump();
          final focused = _inputChrome(tester);
          expect(
            focused.rule,
            BorderSide(color: tokens.palette.controlAccent, width: 2),
          );
          // The hairline frame stays as it was.
          expect(focused.outline, rest.outline);
          expect(focused.outline.width, 1);
          expect(focused.border, const EdgeInsets.fromLTRB(1, 1, 1, 2));
        });
      }
    }

    test('the underline follows the brand', () {
      final plain = _tokens(fluentTheme, dark: false);
      final crimson = _tokens(
        fluentTheme.branded('Crimson', const Color(0xFFDC2626)),
        dark: false,
      );
      Color underline(AdminTokens tokens) =>
          resolveFieldChrome(tokens, {WidgetState.focused}).rule.color;
      expect(underline(crimson), isNot(underline(plain)));
      expect(underline(crimson), crimson.palette.controlAccent);
    });
  });

  group('Material: the 4dp outlined field', () {
    for (final dark in [false, true]) {
      testWidgets(dark ? 'dark' : 'light', (tester) async {
        final tokens = _tokens(materialTheme, dark: dark);
        await tester.pumpWidget(_host(tokens, _pair()));
        expect(_inputBorder(tester).borderRadius, BorderRadius.circular(4));
        final box = _triggerBox(tester).decoration! as BoxDecoration;
        expect(box.borderRadius, BorderRadius.circular(4));
        await tester.tap(find.byType(TextField));
        await tester.pump();
        // 2dp of primary on focus.
        expect(
          _inputChrome(tester).outline,
          BorderSide(color: tokens.palette.controlAccent, width: 2),
        );
      });
    }
  });

  group('Iris and shadcn draw what they drew', () {
    const states = <Set<WidgetState>>[
      {},
      {WidgetState.hovered},
      {WidgetState.focused},
      {WidgetState.disabled},
      {WidgetState.error},
      {WidgetState.error, WidgetState.focused},
    ];
    for (final theme in [irisTheme, shadcnTheme]) {
      for (final dark in [false, true]) {
        final tokens = _tokens(theme, dark: dark);
        final p = tokens.palette;
        final stroke = tokens.stroke;
        final corners = BorderRadius.circular(tokens.radii.radius);

        test('${theme.name} ${dark ? 'dark' : 'light'}: the input', () {
          expect(tokens.radii.radiusField, tokens.radii.radius);
          final before = FieldOutlineBorder(
            side: (s) => fieldBorderSide(p, s, stroke: stroke),
            halo: stroke.fieldFocusHalo > 0
                ? (s) => fieldFocusHalo(p, s, stroke: stroke)
                : null,
            borderRadius: corners,
          );
          final now = FieldBorder.of(tokens);
          for (final s in states) {
            expect(now.resolve(s), before.resolve(s), reason: '$s');
            expect(now.chromeOf(s).fill, fieldFillColor(p, s), reason: '$s');
          }
        });

        testWidgets('${theme.name} ${dark ? 'dark' : 'light'}: FieldChrome', (
          tester,
        ) async {
          const pad = EdgeInsets.all(10);
          for (final (enabled, active, hovered, invalid) in [
            (true, false, false, false),
            (true, false, true, false),
            (true, true, false, false),
            (true, false, false, true),
            (true, true, false, true),
            (false, false, false, false),
          ]) {
            await tester.pumpWidget(
              _host(
                tokens,
                FieldChrome(
                  enabled: enabled,
                  active: active,
                  hovered: hovered,
                  invalid: invalid,
                  padding: pad,
                  child: const Text('Value'),
                ),
              ),
            );
            final state = FieldState(enabled: enabled, invalid: invalid);
            final side = state.borderSide(
              p,
              hovered: hovered,
              focused: active,
              stroke: stroke,
            );
            final halo = state.focusHalo(p, focused: active, stroke: stroke);
            final box = _triggerBox(tester);
            final reason = '$state, active $active, hovered $hovered';
            expect(
              box.decoration,
              BoxDecoration(
                color: state.fillColor(p),
                borderRadius: corners,
                border: Border.all(color: side.color, width: side.width),
              ),
              reason: reason,
            );
            expect(
              box.foregroundDecoration,
              halo.width > 0
                  ? BoxDecoration(
                      borderRadius: corners,
                      border: Border.fromBorderSide(halo),
                    )
                  : null,
              reason: reason,
            );
            expect(
              box.padding,
              pad - EdgeInsets.all(side.width - stroke.control),
              reason: reason,
            );
          }
        });
      }
    }
  });
}
