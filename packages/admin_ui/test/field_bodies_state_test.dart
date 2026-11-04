import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'shipped_palettes.dart';

const _p = irisPalette;

Widget _host(Widget child, {AdminPalette palette = _p}) => MaterialApp(
  theme: buildAppTheme(AdminTokens.from(palette: palette)),
  home: Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(40),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 360, child: child),
      ),
    ),
  ),
);

/// The one value every body shows while read-only, disabled or invalid.
enum _Mode { editable, readOnly, disabled, invalid }

/// A body under test: how to build it in a [_Mode], and where its outline
/// and value are drawn.
class _Body {
  final String name;
  final Widget Function(bool editable) build;

  /// The outline colour at rest.
  final Color Function(WidgetTester tester) outline;

  /// The fill at rest.
  final Color Function(WidgetTester tester) fill;

  /// The colour the value is drawn in.
  final Color Function(WidgetTester tester) text;

  const _Body(this.name, this.build, this.outline, this.fill, this.text);
}

InputDecoration _decoration(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField).first).decoration!;

Color _inputOutline(WidgetTester tester) =>
    (_decoration(tester).border! as WidgetStateInputBorder)
        .resolve(const {})
        .borderSide
        .color;

Color _inputFill(WidgetTester tester) =>
    WidgetStateProperty.resolveAs(_decoration(tester).fillColor!, const {});

Color _inputText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField).first).style!.color!;

BoxDecoration _chrome(WidgetTester tester) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(FieldChrome).first,
          matching: find.byType(Container),
        )
        .first,
  );
  return container.decoration! as BoxDecoration;
}

Color _chromeOutline(WidgetTester tester) =>
    (_chrome(tester).border! as Border).top.color;

Color _chromeFill(WidgetTester tester) => _chrome(tester).color!;

Color Function(WidgetTester) _textOf(String text) =>
    (tester) => tester.widget<Text>(find.text(text).first).style!.color!;

void _ignore(Object? _) {}

final _bodies = [
  _Body(
    'TextBody',
    (editable) =>
        TextBody(value: 'Hello', onChanged: editable ? _ignore : null),
    _inputOutline,
    _inputFill,
    _inputText,
  ),
  _Body(
    'NumberBody',
    (editable) => NumberBody(value: 42, onChanged: editable ? _ignore : null),
    _inputOutline,
    _inputFill,
    _inputText,
  ),
  _Body(
    'MaskedBody',
    (editable) => MaskedBody(
      mask: Masks.phoneUS,
      value: '5551234567',
      onChanged: editable ? _ignore : null,
    ),
    _inputOutline,
    _inputFill,
    _inputText,
  ),
  _Body(
    'KeyValueBody',
    (editable) => KeyValueBody(
      value: const {'region': 'eu'},
      onChanged: editable ? _ignore : null,
    ),
    _inputOutline,
    _inputFill,
    _inputText,
  ),
  _Body(
    'ColorBody',
    (editable) =>
        ColorBody(value: '#5B5BD6', onChanged: editable ? _ignore : null),
    _chromeOutline,
    _chromeFill,
    _textOf('#5B5BD6'),
  ),
  _Body(
    'TagsBody',
    (editable) => TagsBody(
      value: const ['featured'],
      onChanged: editable ? _ignore : null,
    ),
    _chromeOutline,
    _chromeFill,
    // The chip keeps its own text colour; the box is what reads the state.
    (tester) => tester.widget<Text>(find.text('featured')).style!.color!,
  ),
  _Body(
    'BooleanBody',
    (editable) => BooleanBody(
      value: true,
      description: 'Visible',
      onChanged: editable ? _ignore : null,
    ),
    _chromeOutline,
    _chromeFill,
    _textOf('Visible'),
  ),
];

void main() {
  for (final body in _bodies) {
    group(body.name, () {
      Future<void> pump(WidgetTester tester, _Mode mode) {
        final child = body.build(mode != _Mode.readOnly);
        return tester.pumpWidget(
          _host(switch (mode) {
            _Mode.editable || _Mode.readOnly => child,
            _Mode.disabled => FieldStateScope(enabled: false, child: child),
            _Mode.invalid => FieldStateScope(invalid: true, child: child),
          }),
        );
      }

      final disabledFill = fieldFillColor(_p, {WidgetState.disabled});

      testWidgets('read-only keeps full contrast on the resting box', (
        tester,
      ) async {
        await pump(tester, _Mode.editable);
        final editableText = body.text(tester);
        final editableFill = body.fill(tester);
        await pump(tester, _Mode.readOnly);
        expect(body.text(tester), editableText);
        expect(body.fill(tester), editableFill);
        expect(body.fill(tester), isNot(disabledFill));
      });

      testWidgets('disabled dims the value onto the disabled fill', (
        tester,
      ) async {
        await pump(tester, _Mode.disabled);
        expect(body.fill(tester), disabledFill);
        expect(
          body.outline(tester),
          fieldBorderSide(_p, {
            WidgetState.disabled,
          }, stroke: const AdminStroke()).color,
        );
        if (body.name != 'TagsBody') {
          expect(body.text(tester), _p.foregroundSubtle);
        }
      });

      testWidgets('an invalid scope turns the outline red', (tester) async {
        await pump(tester, _Mode.editable);
        expect(body.outline(tester), isNot(_p.danger));
        await pump(tester, _Mode.invalid);
        expect(body.outline(tester), _p.danger);
      });

      testWidgets('it is the medium control height', (tester) async {
        await pump(tester, _Mode.editable);
        final box = switch (body.name) {
          'ColorBody' => find.byType(FieldTrigger),
          'TagsBody' || 'BooleanBody' => find.byType(FieldChrome),
          _ => find.byType(TextField).first,
        };
        expect(tester.getSize(box).height, defaultTokens.sizes.medium);
      });
    });
  }

  group('round trip', () {
    testWidgets('TextBody reports typing and reseeds from the host', (
      tester,
    ) async {
      String? typed;
      Widget build(String value) =>
          _host(TextBody(value: value, onChanged: (v) => typed = v));
      await tester.pumpWidget(build('a'));
      await tester.enterText(find.byType(TextField), 'ab');
      expect(typed, 'ab');
      await tester.pumpWidget(build('reverted'));
      expect(find.text('reverted'), findsOneWidget);
    });

    testWidgets('MaskedBody reports the formatted text', (tester) async {
      String? typed;
      await tester.pumpWidget(
        _host(MaskedBody(mask: Masks.phoneUS, onChanged: (v) => typed = v)),
      );
      await tester.enterText(find.byType(TextField), '5551234567');
      expect(typed, '(555) 123-4567');
    });

    testWidgets('BooleanBody toggles on tap', (tester) async {
      bool? toggled;
      await tester.pumpWidget(
        _host(BooleanBody(value: false, onChanged: (v) => toggled = v)),
      );
      await tester.tap(find.byType(BooleanBody));
      expect(toggled, isTrue);
    });

    testWidgets('CodeBody reports edits', (tester) async {
      String? typed;
      await tester.pumpWidget(
        _host(CodeBody(value: '{}', onChanged: (v) => typed = v)),
      );
      await tester.enterText(find.byType(TextField), '[1]');
      expect(typed, '[1]');
    });
  });

  group('read-only', () {
    testWidgets('a read-only text body is focusable and selectable', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const TextBody(value: 'Hello')));
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.readOnly, isTrue);
      expect(field.decoration!.enabled, isTrue);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
    });

    testWidgets('a disabled text body takes no focus', (tester) async {
      await tester.pumpWidget(
        _host(
          const TextBody(value: 'Hello', onChanged: _ignore, enabled: false),
        ),
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration!.enabled,
        isFalse,
      );
    });

    testWidgets('a read-only boolean is a Tab stop announced read-only', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const BooleanBody(value: true, description: 'Visible')),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Visible')),
        matchesSemantics(
          label: 'Visible',
          isReadOnly: true,
          hasToggledState: true,
          isToggled: true,
          isFocusable: true,
          isFocused: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    for (final (name, body, empty) in [
      ('TagsBody', const TagsBody(), 'No tags'),
      ('KeyValueBody', const KeyValueBody(), 'No entries'),
      ('MediaBody', const MediaBody(readOnly: true), 'No media'),
    ]) {
      testWidgets('$name keeps its box when empty, with neutral text', (
        tester,
      ) async {
        await tester.pumpWidget(_host(body));
        expect(find.text(empty), findsOneWidget);
        expect(find.text('Add a tag…'), findsNothing);
        final box = tester.getSize(find.byType(FieldChrome));
        expect(box.height, defaultTokens.sizes.medium);
        expect(
          tester.widget<Text>(find.text(empty)).style!.color,
          _p.foregroundMuted,
        );
      });
    }

    testWidgets('an empty read-only reference keeps its box', (tester) async {
      await tester.pumpWidget(
        _host(
          ReferenceBody<String, String>(
            value: const [],
            onChanged: null,
            idOf: (s) => s,
            resolve: (ids) async => ids.toList(),
            search: (q, {cursor}) async => const ReferencePage([]),
            tile: (context, s) => Text(s),
          ),
        ),
      );
      expect(find.text('No reference'), findsOneWidget);
      expect(find.byType(FieldChrome), findsOneWidget);
    });

    for (final MapEntry(key: name, value: palette) in shippedPalettes.entries) {
      testWidgets('$name: read-only values read at 4.5:1 on their box', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            palette: palette,
            const Column(
              children: [
                TextBody(value: 'Text'),
                NumberBody(value: 7),
                ColorBody(value: '#5B5BD6'),
                BooleanBody(value: true, description: 'Visible'),
              ],
            ),
          ),
        );
        final surface = palette.surface;
        for (final field in tester.widgetList<TextField>(
          find.byType(TextField),
        )) {
          final fill = WidgetStateProperty.resolveAs(
            field.decoration!.fillColor!,
            const <WidgetState>{},
          );
          expect(
            contrastRatio(field.style!.color!, fill),
            greaterThanOrEqualTo(4.5),
          );
        }
        for (final text in ['#5B5BD6', 'Visible']) {
          final color = tester.widget<Text>(find.text(text)).style!.color!;
          expect(contrastRatio(color, surface), greaterThanOrEqualTo(4.5));
        }
      });
    }
  });

  group('invalid', () {
    testWidgets(
      'CodeBody turns red on invalid JSON as well as from the scope',
      (tester) async {
        Color outline() {
          final box = tester
              .widgetList<Container>(
                find.descendant(
                  of: find.byType(CodeBody),
                  matching: find.byType(Container),
                ),
              )
              .map((c) => c.decoration)
              .whereType<BoxDecoration>()
              .firstWhere((d) => d.border != null);
          return (box.border! as Border).top.color;
        }

        await tester.pumpWidget(
          _host(const CodeBody(value: '{}', onChanged: _ignore)),
        );
        expect(outline(), isNot(_p.danger));
        await tester.pumpWidget(
          _host(const CodeBody(value: '{"a": }', onChanged: _ignore)),
        );
        expect(outline(), _p.danger);
        await tester.pumpWidget(
          _host(
            const FieldStateScope(
              invalid: true,
              child: CodeBody(value: '{}', onChanged: _ignore),
            ),
          ),
        );
        expect(outline(), _p.danger);
      },
    );

    testWidgets('a duplicate key is red, stays red while focused, and says '
        'the lower row wins', (tester) async {
      await tester.pumpWidget(
        _host(
          const KeyValueBody(value: {'a': '1', 'b': '2'}, onChanged: _ignore),
        ),
      );
      final keys = find.byType(TextField);
      await tester.enterText(keys.at(2), 'a');
      await tester.pump();
      expect(
        find.text('Duplicate key “a” — the lower row wins'),
        findsOneWidget,
      );
      for (final i in [0, 2]) {
        final border =
            tester.widget<TextField>(keys.at(i)).decoration!.border!
                as WidgetStateInputBorder;
        expect(border.resolve(const {}).borderSide.color, _p.danger);
        expect(
          border.resolve({WidgetState.focused}).borderSide.color,
          _p.danger,
        );
      }
    });

    testWidgets('an empty media field under an invalid scope reddens its '
        'drop zone', (tester) async {
      await tester.pumpWidget(
        _host(const FieldStateScope(invalid: true, child: MediaBody())),
      );
      expect(
        tester.widget<DashedBorder>(find.byType(DashedBorder)).color,
        _p.danger,
      );
    });

    testWidgets('an empty reference under an invalid scope keeps its add '
        'button and leaves the red to the shell message', (tester) async {
      await tester.pumpWidget(
        _host(
          FieldStateScope(
            invalid: true,
            child: ReferenceBody<String, String>(
              value: const [],
              onChanged: _ignore,
              idOf: (s) => s,
              resolve: (ids) async => ids.toList(),
              search: (q, {cursor}) async => const ReferencePage([]),
              tile: (context, s) => Text(s),
            ),
          ),
        ),
      );
      // Like KeyValue's and Repeater's add, it is a button, not a field
      // box, so there is no outline to turn red.
      final add = find.byType(AddRowButton);
      expect(add, findsOneWidget);
      expect(
        tester
            .widget<Button>(
              find.descendant(of: add, matching: find.byType(Button)),
            )
            .onPressed,
        isNotNull,
      );
      expect(find.byType(FieldChrome), findsNothing);
    });
  });

  group('hover', () {
    testWidgets('the tags box takes the hover outline from the core', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const TagsBody(value: ['a'], onChanged: _ignore)),
      );
      final rest = _chromeOutline(tester);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getCenter(find.byType(TagsBody)));
      await tester.pump();
      expect(_chromeOutline(tester), isNot(rest));
      expect(
        _chromeOutline(tester),
        fieldBorderSide(_p, {
          WidgetState.hovered,
        }, stroke: const AdminStroke()).color,
      );
      await mouse.removePointer();
    });

    testWidgets('a read-only tags box does not hover', (tester) async {
      await tester.pumpWidget(_host(const TagsBody(value: ['a'])));
      final rest = _chromeOutline(tester);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getCenter(find.byType(TagsBody)));
      await tester.pump();
      expect(_chromeOutline(tester), rest);
      await mouse.removePointer();
    });
  });

  testWidgets('a number prefix and unit merge under a field label without '
      'a semantics error', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const FieldShell(
          label: 'Price',
          child: NumberBody(
            value: 5,
            prefix: r'$',
            unit: 'USD',
            onChanged: _ignore,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    handle.dispose();
  });
}
