import 'dart:ui' show SemanticsValidationResult;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// [theme]'s palette, radii and sizes, without its font.
AdminTokens _tokens(AdminTheme theme, {bool dark = false}) {
  final source = dark ? theme.dark! : theme.tokens;
  return AdminTokens.from(
    palette: source.palette,
    radii: source.radii,
    focus: source.focus,
    sizes: source.sizes,
  );
}

final _iris = _tokens(irisTheme);

Widget _host(Widget child, {AdminTokens? tokens}) => MaterialApp(
  theme: buildAppTheme(tokens ?? _iris),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            child,
            TextButton(onPressed: () {}, child: const Text('After')),
          ],
        ),
      ),
    ),
  ),
);

String _text(WidgetTester tester, [Finder? within]) => tester
    .widget<EditableText>(
      within == null
          ? find.byType(EditableText)
          : find.descendant(of: within, matching: find.byType(EditableText)),
    )
    .controller
    .text;

FocusNode _focusOf(WidgetTester tester, Finder finder) =>
    tester.widget<EditableText>(finder).focusNode;

/// The drawn box of the only input: its [InputDecorator].
Rect _box(WidgetTester tester) => tester.getRect(find.byType(InputDecorator));

/// Builds one of the three inputs from the shared parameter set.
typedef _Build = Widget Function({
  String value,
  ValueChanged<String>? onChanged,
  TextEditingController? controller,
  String? label,
  String? errorText,
  ControlSize size,
  bool enabled,
  bool readOnly,
});

final Map<String, _Build> _inputs = {
  'InputField':
      ({
        value = '',
        onChanged,
        controller,
        label,
        errorText,
        size = ControlSize.medium,
        enabled = true,
        readOnly = false,
      }) => InputField(
        value: value,
        onChanged: onChanged,
        controller: controller,
        label: label,
        errorText: errorText,
        size: size,
        enabled: enabled,
        readOnly: readOnly,
      ),
  'PasswordField':
      ({
        value = '',
        onChanged,
        controller,
        label,
        errorText,
        size = ControlSize.medium,
        enabled = true,
        readOnly = false,
      }) => PasswordField(
        value: value,
        onChanged: onChanged,
        controller: controller,
        label: label,
        errorText: errorText,
        size: size,
        enabled: enabled,
        readOnly: readOnly,
      ),
  'SearchField':
      ({
        value = '',
        onChanged,
        controller,
        label,
        errorText,
        size = ControlSize.medium,
        enabled = true,
        readOnly = false,
      }) => SearchField(
        value: value,
        onChanged: onChanged,
        controller: controller,
        errorText: errorText,
        size: size,
        enabled: enabled,
        readOnly: readOnly,
      ),
};

void main() {
  group('value', () {
    for (final MapEntry(key: name, value: build) in _inputs.entries) {
      testWidgets('$name takes a new value from its parent', (tester) async {
        await tester.pumpWidget(_host(build(value: 'first')));
        expect(_text(tester), 'first');

        await tester.pumpWidget(_host(build(value: 'reset')));
        expect(_text(tester), 'reset');

        await tester.pumpWidget(_host(build(value: '')));
        expect(_text(tester), '');
      });

      testWidgets('$name keeps what was typed while its value stays', (
        tester,
      ) async {
        await tester.pumpWidget(_host(build(onChanged: (_) {})));
        await tester.enterText(find.byType(EditableText), 'typed');
        // A parent rebuilding with the same value doesn't wipe the text.
        await tester.pumpWidget(_host(build(onChanged: (_) {})));
        expect(_text(tester), 'typed');
      });

      testWidgets('$name ignores value when given a controller', (
        tester,
      ) async {
        final controller = TextEditingController(text: 'owned');
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          _host(build(value: 'a', controller: controller)),
        );
        await tester.pumpWidget(
          _host(build(value: 'b', controller: controller)),
        );
        expect(_text(tester), 'owned');
      });
    }

    testWidgets('a controlled parent echoing each edit keeps the caret', (
      tester,
    ) async {
      var value = '';
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _host(
            InputField(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), 'abc');
      await tester.pump();
      expect(value, 'abc');
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(
        editable.controller.selection,
        const TextSelection.collapsed(offset: 3),
      );
    });
  });

  group('SearchField', () {
    testWidgets('onChanged fires for text changes, never for caret moves', (
      tester,
    ) async {
      final changes = <String>[];
      await tester.pumpWidget(
        _host(SearchField(value: 'hello', onChanged: changes.add)),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(changes, isEmpty);

      await tester.enterText(find.byType(EditableText), 'hello!');
      await tester.pump();
      expect(changes, ['hello!']);

      await tester.tap(find.byType(ClearButton));
      await tester.pump();
      expect(changes, ['hello!', '']);
    });

    testWidgets('a value from the parent is not reported back', (tester) async {
      final changes = <String>[];
      await tester.pumpWidget(
        _host(SearchField(value: 'a', onChanged: changes.add)),
      );
      await tester.pumpWidget(
        _host(SearchField(value: 'b', onChanged: changes.add)),
      );
      expect(_text(tester), 'b');
      expect(changes, isEmpty);
      expect(find.byType(ClearButton), findsOneWidget);
    });

    testWidgets('moves its listener when the controller changes', (
      tester,
    ) async {
      final a = TextEditingController(text: 'a');
      final b = TextEditingController(text: 'b');
      addTearDown(a.dispose);
      addTearDown(b.dispose);
      final changes = <String>[];

      await tester.pumpWidget(
        _host(SearchField(controller: a, onChanged: changes.add)),
      );
      a.text = 'a1';
      expect(changes, ['a1']);

      await tester.pumpWidget(
        _host(SearchField(controller: b, onChanged: changes.add)),
      );
      expect(_text(tester), 'b');
      a.text = 'a2';
      b.text = 'b1';
      expect(changes, ['a1', 'b1']);

      // Back to its own controller, seeded from value.
      await tester.pumpWidget(
        _host(SearchField(value: 'own', onChanged: changes.add)),
      );
      expect(_text(tester), 'own');
      b.text = 'b2';
      expect(changes, ['a1', 'b1']);

      // Disposed, it listens to nothing.
      await tester.pumpWidget(_host(const SizedBox()));
      a.text = 'a3';
      b.text = 'b3';
      expect(changes, ['a1', 'b1']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty, the clear slot holds no Tab stop and no hit box', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const SearchField()));
      final search = find.byType(SearchField);
      expect(find.byType(ClearButton), findsNothing);
      expect(
        find.descendant(of: search, matching: find.byType(Tappable)),
        findsNothing,
      );
      final slot = find.descendant(
        of: search,
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == 0 && w.height == 0,
        ),
      );
      expect(slot, findsWidgets);
      for (final e in slot.evaluate()) {
        expect((e.renderObject! as RenderBox).size, Size.zero);
      }

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        _focusOf(tester, find.byType(EditableText)).hasPrimaryFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        Focus.of(tester.element(find.text('After'))).hasPrimaryFocus,
        isTrue,
      );
    });

    testWidgets('the clear is an inline action that keeps the field height', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const SearchField(value: 'lamp')));
      expect(tester.getSize(find.byType(ClearButton)), const Size.square(24));
      expect(_box(tester).height, _iris.sizes.medium);

      // Clearing from the keyboard returns focus to the text.
      Focus.of(
        tester.element(
          find.descendant(
            of: find.byType(ClearButton),
            matching: find.byType(Icon),
          ),
        ),
      ).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(_text(tester), '');
      expect(
        _focusOf(tester, find.byType(EditableText)).hasPrimaryFocus,
        isTrue,
      );
    });

    testWidgets('onSubmitted and a search action key', (tester) async {
      String? submitted;
      await tester.pumpWidget(
        _host(SearchField(value: 'q', onSubmitted: (v) => submitted = v)),
      );
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.textInputAction, TextInputAction.search);
      await tester.showKeyboard(find.byType(EditableText));
      await tester.testTextInput.receiveAction(TextInputAction.search);
      expect(submitted, 'q');
    });
  });

  group('PasswordField', () {
    testWidgets('the reveal is an inline, named action in the end slot', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const PasswordField(value: 'secret')));
      final reveal = find.byType(IconAction);
      expect(tester.getSize(reveal), const Size.square(24));
      expect(_box(tester).height, _iris.sizes.medium);
      expect(find.bySemanticsLabel('Show password'), findsOneWidget);
      // Its glyph sits 12 from the field's end.
      expect(_box(tester).right - tester.getCenter(reveal).dx, 12 + 8);

      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isTrue,
      );
      await tester.tap(reveal);
      await tester.pump();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isFalse,
      );
      expect(find.bySemanticsLabel('Hide password'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('has no placeholder unless given one', (tester) async {
      await tester.pumpWidget(_host(const PasswordField(label: 'Password')));
      final decorator = tester.widget<InputDecorator>(
        find.byType(InputDecorator),
      );
      expect(decorator.decoration.hintText, isNull);
    });

    testWidgets('disabled, the reveal is disabled too', (tester) async {
      await tester.pumpWidget(
        _host(const PasswordField(value: 'secret', enabled: false)),
      );
      expect(
        tester.widget<IconAction>(find.byType(IconAction)).onPressed,
        isNull,
      );
    });
  });

  group('heights', () {
    for (final theme in adminThemes) {
      final tokens = _tokens(theme);
      for (final size in ControlSize.values) {
        final height = tokens.sizes.height(size);
        testWidgets('${theme.name} ${size.name}: every input is $height tall', (
          tester,
        ) async {
          for (final MapEntry(key: name, value: build) in _inputs.entries) {
            for (final label in [null, 'Label']) {
              await tester.pumpWidget(
                _host(
                  build(value: 'Value', label: label, size: size),
                  tokens: tokens,
                ),
              );
              expect(_box(tester).height, height, reason: '$name $label');
            }
          }
          // An empty search field and a medium button line up.
          await tester.pumpWidget(
            _host(
              Row(
                children: [
                  Expanded(child: SearchField(size: size)),
                  Button(
                    'New',
                    size: switch (size) {
                      ControlSize.small => ControlSize.small,
                      ControlSize.medium => ControlSize.medium,
                      ControlSize.large => ControlSize.large,
                    },
                    onPressed: () {},
                  ),
                ],
              ),
              tokens: tokens,
            ),
          );
          expect(_box(tester).height, height);
          expect(tester.getSize(find.byType(Button)).height, height);
        });
      }
    }

    for (final theme in adminThemes) {
      for (final dark in [false, true]) {
        final tokens = _tokens(theme, dark: dark);
        final mode = dark ? 'Dark' : 'Light';
        final height = tokens.sizes.medium;
        testWidgets('${theme.name} $mode: a toolbar row is one height, '
            '$height', (tester) async {
          // The test font draws every glyph a square: room for one line.
          tester.view.physicalSize = const Size(1600, 400);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            MaterialApp(
              theme: buildAppTheme(tokens),
              home: Scaffold(
                body: SizedBox(
                  width: 1600,
                  child: CollectionToolbar(
                    onSearch: (_) {},
                    searchWidth: 200,
                    filterBar: FilterBar(
                      fields: const [
                        OptionsFilterField('status', 'Status', [
                          FilterOption('draft', 'Draft'),
                        ]),
                        BoolFilterField('featured', 'Featured'),
                      ],
                      active: const [
                        OptionsFilter('status', {'draft'}, label: 'Status'),
                      ],
                      onChanged: (_) {},
                    ),
                    trailing: [Button.primary('New product', onPressed: () {})],
                  ),
                ),
              ),
            ),
          );
          expect(_box(tester).height, height);
          for (final (label, type) in const [
            ('Status', Tappable),
            ('Featured', Tappable),
            ('New product', Button),
          ]) {
            final box = find
                .ancestor(of: find.text(label), matching: find.byType(type))
                .first;
            expect(tester.getSize(box).height, height, reason: label);
          }
          // Everything in the row shares one centre line.
          final centre = _box(tester).center.dy;
          for (final label in ['Status', 'Featured', 'New product']) {
            expect(tester.getCenter(find.text(label)).dy, closeTo(centre, 1));
          }
        });

        testWidgets('${theme.name} $mode: row controls take the control '
            'heights', (tester) async {
          await tester.pumpWidget(
            _host(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Segmented<String>(
                    value: 'a',
                    onChanged: (_) {},
                    segments: const [
                      SegmentOption('a', 'List'),
                      SegmentOption('b', 'Grid'),
                    ],
                  ),
                  Segmented<String>(
                    value: 'a',
                    size: ControlSize.small,
                    onChanged: (_) {},
                    segments: const [
                      SegmentOption('a', 'Day'),
                      SegmentOption('b', 'Week'),
                    ],
                  ),
                  const CopyButton('id_1', label: 'Copy id'),
                  const CopyButton('id_2', key: Key('icon-copy')),
                  const Row(
                    children: [
                      Tag('Soft'),
                      Tag('Outline', variant: TagVariant.outline),
                      Tag('Solid', variant: TagVariant.solid),
                    ],
                  ),
                ],
              ),
              tokens: tokens,
            ),
          );
          Size sizeOf(String text, Type type) => tester.getSize(
            find
                .ancestor(of: find.text(text), matching: find.byType(type))
                .first,
          );
          expect(sizeOf('List', Tappable).height, tokens.sizes.medium);
          expect(sizeOf('Day', Tappable).height, tokens.sizes.small);
          expect(sizeOf('Copy id', InkWell).height, tokens.sizes.small);
          expect(
            tester.getSize(
              find.descendant(
                of: find.byKey(const Key('icon-copy')),
                matching: find.byType(Tappable),
              ),
            ),
            const Size.square(24),
          );
          final tags = {
            for (final t in ['Soft', 'Outline', 'Solid'])
              sizeOf(t, Container).height,
          };
          expect(tags, {20});
        });
      }
    }

    testWidgets('an icon puts the text at 36, without it at 12', (
      tester,
    ) async {
      for (final (icon, inset) in [(null, 12.0), (Icons.link, 36.0)]) {
        await tester.pumpWidget(_host(InputField(value: 'x', icon: icon)));
        expect(
          tester.getTopLeft(find.byType(EditableText)).dx - _box(tester).left,
          inset,
        );
      }
    });
  });

  group('validation semantics', () {
    for (final MapEntry(key: name, value: build) in _inputs.entries) {
      for (final label in [null, 'Title']) {
        if (name == 'SearchField' && label != null) continue;
        testWidgets('$name ${label == null ? 'bare' : 'labelled'}: the error '
            'is its hint and fails its validation', (tester) async {
          final handle = tester.ensureSemantics();
          await tester.pumpWidget(
            _host(build(label: label, errorText: 'Title is required')),
          );
          expect(
            tester.getSemantics(find.byType(EditableText)),
            isSemantics(
              hint: 'Title is required',
              isTextField: true,
              validationResult: SemanticsValidationResult.invalid,
            ),
          );
          if (label != null) {
            expect(
              tester.getSemantics(find.byType(EditableText)).label,
              startsWith(label),
            );
          }
          expect(
            tester.getSemantics(find.text('Title is required')),
            isSemantics(isLiveRegion: true),
          );
          // The border turns red.
          final decorator = tester.widget<InputDecorator>(
            find.byType(InputDecorator),
          );
          expect(
            WidgetStateProperty.resolveAs(
              decorator.decoration.border,
              const <WidgetState>{},
            )!.borderSide.color,
            _iris.palette.danger,
          );

          await tester.pumpWidget(_host(build(label: label)));
          expect(
            tester.getSemantics(find.byType(EditableText)),
            isSemantics(validationResult: SemanticsValidationResult.none),
          );
          handle.dispose();
        });
      }
    }

    testWidgets('a message appearing mid-typing keeps the focus', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          _LiveError(
            builder: (value, onChanged) => InputField(
              onChanged: onChanged,
              errorText: value.length > 3 ? 'Too long' : null,
            ),
          ),
        ),
      );
      await tester.showKeyboard(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'abcd');
      await tester.pump();
      expect(find.text('Too long'), findsOneWidget);
      expect(_focusOf(tester, find.byType(EditableText)).hasFocus, isTrue);
      expect(_text(tester), 'abcd');
    });
  });

  group('read-only and disabled', () {
    for (final MapEntry(key: name, value: build) in _inputs.entries) {
      testWidgets('$name read-only: focusable, full contrast, not editable', (
        tester,
      ) async {
        await tester.pumpWidget(_host(build(value: 'Kept', readOnly: true)));
        final editable = tester.widget<EditableText>(find.byType(EditableText));
        expect(editable.readOnly, isTrue);
        expect(editable.style.color, _iris.palette.foreground);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(editable.focusNode.hasPrimaryFocus, isTrue);
        // A read-only search shows no clear.
        expect(
          find.byType(IconAction),
          name == 'PasswordField' ? findsOneWidget : findsNothing,
        );
      });

      testWidgets('$name disabled: dimmed and out of the Tab order', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(_host(build(value: 'Off', enabled: false)));
        final editable = tester.widget<EditableText>(find.byType(EditableText));
        expect(editable.style.color, _iris.palette.foregroundSubtle);
        expect(
          tester.getSemantics(find.byType(EditableText)),
          isSemantics(isTextField: true, isEnabled: false),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(editable.focusNode.hasFocus, isFalse);
        handle.dispose();
      });
    }

    testWidgets('a bare input takes its red outline from its shell', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const FieldStateScope(invalid: true, child: InputField())),
      );
      final decorator = tester.widget<InputDecorator>(
        find.byType(InputDecorator),
      );
      expect(
        WidgetStateProperty.resolveAs(
          decorator.decoration.border,
          const <WidgetState>{},
        )!.borderSide.color,
        _iris.palette.danger,
      );
    });

    testWidgets('an enclosing scope disables and marks read-only', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const FieldStateScope(enabled: false, child: InputField(value: 'x')),
        ),
      );
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      await tester.pumpWidget(
        _host(
          const FieldStateScope(readOnly: true, child: InputField(value: 'x')),
        ),
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).readOnly,
        isTrue,
      );
    });

    for (final name in ['shadcn', 'Material', 'Fluent']) {
      testWidgets('$name Dark: a disabled input reads dimmer than an enabled '
          'one', (tester) async {
        final theme = adminThemes.firstWhere((t) => t.name == name);
        final tokens = _tokens(theme, dark: true);
        final p = tokens.palette;
        double contrast(bool enabled) {
          final decorator = tester.widget<InputDecorator>(
            find.byType(InputDecorator),
          );
          final fill = WidgetStateProperty.resolveAs(
            decorator.decoration.fillColor!,
            {if (!enabled) WidgetState.disabled},
          );
          final text = tester
              .widget<EditableText>(find.byType(EditableText))
              .style
              .color!;
          return contrastRatio(text, Color.alphaBlend(fill, p.surface));
        }

        await tester.pumpWidget(
          _host(const InputField(value: 'On'), tokens: tokens),
        );
        final on = contrast(true);
        await tester.pumpWidget(
          _host(const InputField(value: 'Off', enabled: false), tokens: tokens),
        );
        final off = contrast(false);
        expect(off, lessThan(on));
        expect(on / off, greaterThan(1.5));
      });
    }
  });
}

/// A value held above a field, for a message that follows what is typed.
class _LiveError extends StatefulWidget {
  final Widget Function(String value, ValueChanged<String> onChanged) builder;

  const _LiveError({required this.builder});

  @override
  State<_LiveError> createState() => _LiveErrorState();
}

class _LiveErrorState extends State<_LiveError> {
  String _value = '';

  @override
  Widget build(BuildContext context) =>
      widget.builder(_value, (v) => setState(() => _value = v));
}
