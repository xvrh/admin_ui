import 'dart:ui' show SemanticsValidationResult;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _p = irisPalette;
final _tokens = AdminTokens.from(palette: _p);

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(_tokens),
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(40),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 280, child: child),
      ),
    ),
  ),
);

/// The decoration a [FieldChrome] draws.
BoxDecoration _chrome(WidgetTester tester, [Finder? of]) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: of ?? find.byType(FieldChrome),
          matching: find.byType(Container),
        )
        .first,
  );
  return container.decoration! as BoxDecoration;
}

BorderSide _side(WidgetTester tester, [Finder? of]) =>
    (_chrome(tester, of).border! as Border).top;

Color _hover(AdminPalette p) =>
    Color.alphaBlend(p.foreground.withValues(alpha: 0.3), p.controlBorder);

/// The disabled outline: halfway from `controlBorder` to `border`.
Color _disabled(AdminPalette p) => Color.lerp(p.border, p.controlBorder, 0.5)!;

/// Builds [child] and hands back what [read] saw in its context.
Future<T> _read<T>(
  WidgetTester tester,
  T Function(BuildContext) read, {
  Widget Function(Widget child)? wrap,
}) async {
  late T value;
  final probe = Builder(
    builder: (context) {
      value = read(context);
      return const SizedBox();
    },
  );
  await tester.pumpWidget(_host(wrap?.call(probe) ?? probe));
  return value;
}

void main() {
  group('FieldStateScope', () {
    testWidgets('outside any scope: enabled, editable and valid', (
      tester,
    ) async {
      expect(await _read(tester, FieldStateScope.of), const FieldState());
    });

    testWidgets('nests: enabled while both, read-only while either, '
        'invalid its own', (tester) async {
      expect(
        await _read(
          tester,
          FieldStateScope.of,
          wrap: (child) => FieldStateScope(
            enabled: false,
            invalid: true,
            child: FieldStateScope(readOnly: true, child: child),
          ),
        ),
        const FieldState(enabled: false, readOnly: true),
      );
      expect(
        await _read(
          tester,
          FieldStateScope.of,
          wrap: (child) => FieldStateScope(
            readOnly: true,
            child: FieldStateScope(invalid: true, child: child),
          ),
        ),
        const FieldState(readOnly: true, invalid: true),
      );
    });

    test('merge folds a widget\'s own flags in', () {
      const state = FieldState(invalid: true);
      expect(state.merge(), state);
      expect(
        state.merge(enabled: false, readOnly: true),
        const FieldState(enabled: false, readOnly: true, invalid: true),
      );
      expect(const FieldState().merge(invalid: true), state);
    });

    test('a disabled field neither hovers nor focuses; read-only never '
        'hovers', () {
      const disabled = FieldState(enabled: false);
      expect(disabled.states(hovered: true, focused: true), {
        WidgetState.disabled,
      });
      const readOnly = FieldState(readOnly: true);
      expect(readOnly.states(hovered: true, focused: true), {
        WidgetState.focused,
      });
      expect(const FieldState(invalid: true).states(hovered: true), {
        WidgetState.error,
        WidgetState.hovered,
      });
    });

    test('resolves the one colour set every body uses', () {
      const rest = FieldState();
      const disabled = FieldState(enabled: false);
      const readOnly = FieldState(readOnly: true);
      expect(rest.textColor(_p), _p.foreground);
      expect(readOnly.textColor(_p), _p.foreground);
      expect(disabled.textColor(_p), _p.foregroundSubtle);
      expect(rest.iconColor(_p), _p.foregroundMuted);
      expect(disabled.iconColor(_p), _p.foregroundSubtle);
      expect(rest.fillColor(_p), _p.surface);
      expect(readOnly.fillColor(_p), _p.surface);
      expect(
        disabled.fillColor(_p),
        Color.alphaBlend(_p.foreground.withValues(alpha: 0.04), _p.surface),
      );
      expect(
        rest.borderColor(_p, stroke: const AdminStroke()),
        _p.controlBorder,
      );
      expect(
        rest.borderColor(_p, hovered: true, stroke: const AdminStroke()),
        _hover(_p),
      );
      expect(
        readOnly.borderColor(_p, hovered: true, stroke: const AdminStroke()),
        _p.controlBorder,
      );
      expect(
        rest.borderColor(_p, focused: true, stroke: const AdminStroke()),
        _p.focusRing,
      );
      expect(
        disabled.borderColor(_p, focused: true, stroke: const AdminStroke()),
        _disabled(_p),
      );
      expect(
        const FieldState(invalid: true)
            .borderSide(_p, focused: true, stroke: const AdminStroke()),
        BorderSide(color: _p.danger, width: 1.5),
      );
    });
  });

  group('fieldInputDecoration', () {
    BorderSide resolve(InputDecoration d, Set<WidgetState> states) =>
        WidgetStateProperty.resolveAs(d.border, states)!.borderSide;

    testWidgets('reads invalid, disabled and read-only from the scope', (
      tester,
    ) async {
      final plain = await _read(tester, fieldInputDecoration);
      expect(resolve(plain, {}).color, _p.controlBorder);
      expect(resolve(plain, {WidgetState.hovered}).color, _hover(_p));
      expect(plain.enabled, isTrue);

      final invalid = await _read(
        tester,
        fieldInputDecoration,
        wrap: (child) => FieldStateScope(invalid: true, child: child),
      );
      expect(resolve(invalid, {}), BorderSide(color: _p.danger, width: 1.5));

      final disabled = await _read(
        tester,
        fieldInputDecoration,
        wrap: (child) => FieldStateScope(enabled: false, child: child),
      );
      expect(disabled.enabled, isFalse);
      expect(resolve(disabled, {}).color, _disabled(_p));
      expect(
        WidgetStateProperty.resolveAs(disabled.fillColor, {}),
        fieldFillColor(_p, {WidgetState.disabled}),
      );

      final readOnly = await _read(
        tester,
        fieldInputDecoration,
        wrap: (child) => FieldStateScope(readOnly: true, child: child),
      );
      expect(resolve(readOnly, {WidgetState.hovered}).color, _p.controlBorder);
      expect(resolve(readOnly, {WidgetState.focused}).color, _p.focusRing);
    });

    testWidgets('its own flags add to the scope', (tester) async {
      final d = await _read(
        tester,
        (context) =>
            fieldInputDecoration(context, invalid: true, readOnly: true),
      );
      expect(resolve(d, {WidgetState.hovered}).color, _p.danger);
      final pinned = await _read(
        tester,
        (context) => fieldInputDecoration(context, hovered: true),
      );
      expect(resolve(pinned, {}).color, _hover(_p));
    });

    testWidgets('a TextField that leaves enabled unset follows the scope', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          FieldStateScope(
            enabled: false,
            child: Builder(
              builder: (context) => TextField(
                decoration: fieldInputDecoration(context, hint: 'Title'),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(EditableText)),
        isSemantics(isTextField: true, isEnabled: false),
      );
      handle.dispose();
    });

    testWidgets('fieldTextStyle is the field line in the state\'s colour', (
      tester,
    ) async {
      final style = await _read(tester, fieldTextStyle);
      expect(style.fontSize, _tokens.typography.fieldText.fontSize);
      expect(style.fontSize! * style.height!, 20);
      expect(style.color, _p.foreground);
      final disabled = await _read(
        tester,
        fieldTextStyle,
        wrap: (child) => FieldStateScope(enabled: false, child: child),
      );
      expect(disabled.color, _p.foregroundSubtle);
      final own = await _read(
        tester,
        (context) => fieldTextStyle(context, enabled: false),
      );
      expect(own.color, _p.foregroundSubtle);
    });

    testWidgets('chromeless stays bare but keeps the hint style', (
      tester,
    ) async {
      final d = await _read(
        tester,
        fieldInputDecoration,
        wrap: (child) => ChromelessFieldScope(child: child),
      );
      expect(d.border, InputBorder.none);
      expect(d.filled, isFalse);
      expect(d.contentPadding, EdgeInsets.zero);
      expect(d.hintStyle!.fontSize, _tokens.typography.fieldText.fontSize);
      expect(d.hintStyle!.color, _p.placeholder);

      await tester.pumpWidget(
        _host(
          ChromelessFieldScope(
            child: Builder(
              builder: (context) => TextField(
                decoration: fieldInputDecoration(
                  context,
                  leadingIcon: Icons.search,
                  suffix: ClearButton(onPressed: () {}),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byType(ClearButton), findsOneWidget);
      expect(tester.getSize(find.byType(IconAction)), const Size.square(24));
    });
  });

  group('FieldChrome', () {
    testWidgets('takes invalid, disabled and read-only from the scope', (
      tester,
    ) async {
      Future<void> pump(Widget Function(Widget) wrap) => tester.pumpWidget(
        _host(wrap(const FieldChrome(hovered: true, child: Text('Value')))),
      );

      await pump((child) => child);
      expect(_side(tester).color, _hover(_p));

      await pump((child) => FieldStateScope(invalid: true, child: child));
      expect(_side(tester), BorderSide(color: _p.danger, width: 1.5));

      await pump((child) => FieldStateScope(enabled: false, child: child));
      expect(_side(tester).color, _disabled(_p));
      expect(_chrome(tester).color, fieldFillColor(_p, {WidgetState.disabled}));

      await pump((child) => FieldStateScope(readOnly: true, child: child));
      expect(_side(tester).color, _p.controlBorder);
      expect(_chrome(tester).color, _p.surface);
    });

    testWidgets('is the control height, its content centred', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FieldChrome(child: SizedBox(key: Key('medium'), height: 10)),
              FieldChrome(
                size: ControlSize.large,
                child: SizedBox(key: Key('large'), height: 10),
              ),
            ],
          ),
        ),
      );
      final medium = tester.getRect(find.byType(FieldChrome).first);
      final large = tester.getRect(find.byType(FieldChrome).last);
      expect(medium.height, 36);
      expect(large.height, 40);
      expect(
        tester.getCenter(find.byKey(const Key('medium'))).dy,
        medium.center.dy,
      );
      expect(tester.getTopLeft(find.byKey(const Key('medium'))).dx, 52);
    });

    testWidgets('builds its content under its own state', (tester) async {
      await tester.pumpWidget(
        _host(const FieldChrome(enabled: false, child: FieldChevron())),
      );
      expect(
        tester
            .widget<Icon>(find.byIcon(Icons.keyboard_arrow_down_rounded))
            .color,
        _p.foregroundSubtle,
      );
    });
  });

  group('FieldTrigger', () {
    Widget trigger({bool readOnly = false, bool enabled = true}) => Column(
      children: [
        Popover(
          anchor: (context, controller) => FieldTrigger(
            controller: controller,
            readOnly: readOnly,
            enabled: enabled,
            chevron: true,
            semanticLabel: 'Status',
            trailing: ClearButton(onPressed: () {}),
            child: const Text('Published'),
          ),
          content: (context, controller) => const Text('Options'),
        ),
      ],
    );

    testWidgets('the pointer draws the hover outline', (tester) async {
      await tester.pumpWidget(_host(trigger()));
      expect(_side(tester).color, _p.controlBorder);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Published')));
      await tester.pump();
      expect(_side(tester).color, _hover(_p));
    });

    testWidgets('read-only: a Tab stop that announces its value, opens '
        'nothing, and drops the chevron and clear', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(trigger(readOnly: true)));
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      expect(
        tester.getSemantics(find.text('Published')),
        isSemantics(
          label: 'Status\nPublished',
          isReadOnly: true,
          isFocusable: true,
          isButton: false,
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'FieldTrigger');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('Options'), findsNothing);
      // The full-contrast box, with the keyboard focus drawn on it.
      expect(_side(tester).color, _p.focusRing);
      expect(_chrome(tester).color, _p.surface);

      await tester.tap(find.text('Published'));
      await tester.pumpAndSettle();
      expect(find.text('Options'), findsNothing);
      handle.dispose();
    });

    testWidgets('a read-only scope makes it read-only', (tester) async {
      await tester.pumpWidget(
        _host(FieldStateScope(readOnly: true, child: trigger())),
      );
      await tester.tap(find.text('Published'));
      await tester.pumpAndSettle();
      expect(find.text('Options'), findsNothing);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
    });

    testWidgets('disabled: out of the Tab order, the chevron muted', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(FieldStateScope(enabled: false, child: trigger())),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        isNot('FieldTrigger'),
      );
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      expect(
        tester
            .widget<Icon>(find.byIcon(Icons.keyboard_arrow_down_rounded))
            .color,
        _p.foregroundSubtle,
      );
      await tester.tap(find.text('Published'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Options'), findsNothing);
    });

    testWidgets('editable: opens, with the chevron in foregroundMuted', (
      tester,
    ) async {
      await tester.pumpWidget(_host(trigger()));
      expect(
        tester
            .widget<Icon>(find.byIcon(Icons.keyboard_arrow_down_rounded))
            .color,
        _p.foregroundMuted,
      );
      await tester.tap(find.text('Published'));
      await tester.pumpAndSettle();
      expect(find.text('Options'), findsOneWidget);
    });
  });

  group('FieldChevron and ClearButton', () {
    testWidgets('the chevron: 16 in a 24 slot, nothing when read-only', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const Row(children: [FieldChevron()])));
      expect(tester.getSize(find.byType(FieldChevron)), const Size.square(24));
      expect(
        tester.getSize(find.byIcon(Icons.keyboard_arrow_down_rounded)),
        const Size.square(16),
      );
      await tester.pumpWidget(
        _host(const Row(children: [FieldChevron(readOnly: true)])),
      );
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('the clear hides under a read-only or disabled scope', (
      tester,
    ) async {
      for (final (scope, shown) in [
        (const FieldState(), true),
        (const FieldState(readOnly: true), false),
        (const FieldState(enabled: false), false),
        (const FieldState(invalid: true), true),
      ]) {
        await tester.pumpWidget(
          _host(
            FieldStateScope(
              enabled: scope.enabled,
              readOnly: scope.readOnly,
              invalid: scope.invalid,
              child: Row(children: [ClearButton(onPressed: () {})]),
            ),
          ),
        );
        expect(
          find.byIcon(Icons.close_rounded),
          shown ? findsOneWidget : findsNothing,
          reason: '$scope',
        );
      }
    });

    testWidgets('a suffix action a scroll view clips away leaves the tree', (
      tester,
    ) async {
      // The field straddles the edge of the list's cache extent (500 + 250):
      // part of the field is kept, the action's tooltip-wrapped node is not.
      final handle = tester.ensureSemantics();
      tester.view.physicalSize = const Size(600, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (var top = 740.0; top < 752; top += 0.5) {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(_tokens),
            home: Scaffold(
              body: ListView(
                children: [
                  SizedBox(height: top),
                  Builder(
                    builder: (context) => TextField(
                      decoration: fieldInputDecoration(
                        context,
                        suffix: ClearButton(onPressed: () {}),
                      ),
                    ),
                  ),
                  const SizedBox(height: 600),
                ],
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: 'field at $top');
      }
      handle.dispose();
    });
  });

  group('LabeledField', () {
    Widget field({
      String? error,
      String? description,
      bool required = false,
      bool enabled = true,
      bool readOnly = false,
      Widget? trailing,
    }) => LabeledField(
      label: 'Title',
      errorText: error,
      description: description,
      required: required,
      enabled: enabled,
      readOnly: readOnly,
      trailing: trailing,
      child: Builder(
        builder: (context) => TextField(
          readOnly: FieldStateScope.of(context).readOnly,
          decoration: fieldInputDecoration(context, hint: 'h'),
        ),
      ),
    );

    testWidgets('names its control, with the error as its hint and a failed '
        'validation', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(field(error: 'Title is required', required: true)),
      );
      expect(
        tester.getSemantics(find.byType(EditableText)),
        isSemantics(
          label: 'Title\nh',
          hint: 'Title is required',
          isTextField: true,
          isRequired: true,
          validationResult: SemanticsValidationResult.invalid,
        ),
      );
      // The visible label and the star are not read on their own.
      expect(find.bySemanticsLabel('Title'), findsNothing);
      expect(find.bySemanticsLabel('*'), findsNothing);
      // The message is announced as it appears.
      expect(
        tester.getSemantics(find.text('Title is required')),
        isSemantics(label: 'Title is required', isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('without an error the description is the hint', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(field(description: 'Shown in lists')));
      expect(
        tester.getSemantics(find.byType(EditableText)),
        isSemantics(
          hint: 'Shown in lists',
          validationResult: SemanticsValidationResult.none,
        ),
      );
      handle.dispose();
    });

    testWidgets('turns its control red, disabled or read-only', (tester) async {
      Future<FieldState> stateOf(Widget Function(Widget) build) async {
        late FieldState state;
        await tester.pumpWidget(
          _host(
            build(
              Builder(
                builder: (context) {
                  state = FieldStateScope.of(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        return state;
      }

      expect(
        await stateOf(
          (c) => LabeledField(label: 'A', errorText: 'x', child: c),
        ),
        const FieldState(invalid: true),
      );
      expect(
        await stateOf(
          (c) => LabeledField(label: 'A', enabled: false, child: c),
        ),
        const FieldState(enabled: false),
      );
      expect(
        await stateOf(
          (c) => LabeledField(label: 'A', readOnly: true, child: c),
        ),
        const FieldState(readOnly: true),
      );

      await tester.pumpWidget(_host(field(error: 'Required')));
      final d = tester.widget<InputDecorator>(find.byType(InputDecorator));
      expect(
        WidgetStateProperty.resolveAs(d.decoration.border, {})!.borderSide,
        BorderSide(color: _p.danger, width: 1.5),
      );
    });

    testWidgets('a tap on the label focuses the control', (tester) async {
      await tester.pumpWidget(_host(field()));
      await tester.tap(find.text('TITLE'));
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
    });

    testWidgets(
      'lays out on the 4px grid, the message glyph flush with the label',
      (tester) async {
        await tester.pumpWidget(
          _host(
            field(
              description: 'Shown in lists',
              error: 'Title is required',
              required: true,
              trailing: const Text('Optional'),
            ),
          ),
        );
        final label = tester.getRect(find.text('TITLE'));
        final star = tester.getRect(find.text('*'));
        final description = tester.getRect(find.text('Shown in lists'));
        final control = tester.getRect(find.byType(TextField));
        final message = tester.getRect(find.text('Title is required'));
        final glyph = tester.getRect(find.byIcon(Icons.error_outline_rounded));
        final top = tester.getTopLeft(find.byType(LabeledField)).dy;

        // The label row is the 24px inline slot, the label centred in it.
        expect(label.center.dy, top + 12);
        expect(star.left, greaterThan(label.right));
        expect(description.top, top + 24 + 4);
        expect(control.top, description.bottom + 8);
        expect(message.top, control.bottom + 8);
        // The glyph starts the line, inside the field's box, and the text
        // follows 6 on.
        expect(glyph.left, label.left);
        expect(glyph.width, 14);
        expect(message.left, glyph.right + 6);
        expect(glyph.center.dy, message.top + 8);
        // The trailing slot reads as a caption, on the label's baseline.
        final trailing = tester.widget<RichText>(
          find.descendant(
            of: find.text('Optional'),
            matching: find.byType(RichText),
          ),
        );
        expect(
          trailing.text.style!.fontSize,
          _tokens.typography.caption.fontSize,
        );
      },
    );

    testWidgets('dims the label when disabled; the star is danger text', (
      tester,
    ) async {
      await tester.pumpWidget(_host(field(enabled: false, required: true)));
      Color? colorOf(String text) => tester
          .widget<RichText>(
            find.descendant(
              of: find.text(text),
              matching: find.byType(RichText),
            ),
          )
          .text
          .style!
          .color;
      expect(colorOf('TITLE'), _p.foregroundSubtle);
      expect(colorOf('*'), _p.dangerText);
      await tester.pumpWidget(_host(field()));
      expect(colorOf('TITLE'), _p.foregroundSecondary);
    });
  });

  group('FieldMessage', () {
    TextStyle styleOf(WidgetTester tester, String text) =>
        tester.widget<Text>(find.text(text)).style!;

    testWidgets('an error: danger text at 500, a live region', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const FieldMessage(error: 'Too long')));
      final style = styleOf(tester, 'Too long');
      expect(style.color, _p.dangerText);
      expect(style.fontWeight, FontWeight.w500);
      expect(
        tester.getSemantics(find.text('Too long')),
        isSemantics(isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('a warning: warning text, not live; the error wins', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const FieldMessage(warning: 'Unusual')));
      expect(styleOf(tester, 'Unusual').color, _p.warningText);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Unusual')),
        isNot(isSemantics(isLiveRegion: true)),
      );
      await tester.pumpWidget(
        _host(const FieldMessage(error: 'Wrong', warning: 'Unusual')),
      );
      expect(find.text('Wrong'), findsOneWidget);
      expect(find.text('Unusual'), findsNothing);
      handle.dispose();
    });

    testWidgets('nothing without a message; FieldErrorText wraps it', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const FieldMessage()));
      expect(find.byType(Icon), findsNothing);
      await tester.pumpWidget(_host(const FieldErrorText('Required')));
      expect(find.byType(FieldMessage), findsOneWidget);
      expect(styleOf(tester, 'Required').color, _p.dangerText);
    });
  });

  group('field label casing', () {
    // Read in the test: a theme's tokens start loading its Google font.
    for (final (name, tokens, shown) in [
      ('Iris', () => defaultTokens, 'TITLE'),
      ('shadcn', () => shadcnTheme.tokens, 'Title'),
    ]) {
      testWidgets('$name: FieldShell and LabeledField set it alike', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(tokens()),
            home: const Scaffold(
              body: Column(
                children: [
                  FieldShell(
                    label: 'Title',
                    child: TextBody(hint: 'x'),
                  ),
                  LabeledField(label: 'Title', child: TextField()),
                ],
              ),
            ),
          ),
        );
        expect(find.text(shown), findsNWidgets(2));
      });
    }
  });
}
