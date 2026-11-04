import 'package:admin_ui/src/common/ui/button.dart';
import 'package:admin_ui/src/common/ui/menu.dart';
import 'package:admin_ui/src/common/ui/spinner.dart';
import 'package:admin_ui/src/theme/palette.dart';
import 'package:admin_ui/src/theme/sizes.dart';
import 'package:admin_ui/src/theme/theme.dart';
import 'package:admin_ui/src/theme/themes/iris.dart';
import 'package:admin_ui/src/theme/tokens.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(
  Widget child, {
  AdminPalette palette = irisPalette,
  AdminControlSizes sizes = defaultControlSizes,
}) => MaterialApp(
  theme: buildAppTheme(AdminTokens.from(palette: palette, sizes: sizes)),
  home: Scaffold(body: Center(child: child)),
);

/// The neutral disabled fill: the foreground's pressed wash on the surface.
Color _disabledFill(AdminPalette palette) =>
    Color.alphaBlend(palette.pressedOverlay, palette.surface);

/// The [Material] a button paints its fill and border with.
Material _surface(WidgetTester tester, String label) => tester.widget<Material>(
  find.ancestor(of: find.text(label), matching: find.byType(Material)).first,
);

void main() {
  group('type and glyphs', _typeAndGlyphs);

  testWidgets('fires onPressed when enabled', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(Button.primary('Save', onPressed: () => taps++)),
    );

    await tester.tap(find.text('Save'));
    expect(taps, 1);
  });

  testWidgets('a null onPressed renders disabled and never fires', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const Button('Save')));

    await tester.tap(find.text('Save'), warnIfMissed: false);
    expect(tester.takeException(), isNull);
    // No callback exists, so nothing to assert beyond "no crash"; the disabled
    // look is covered by the palette resolver.
  });

  testWidgets('loading blocks the tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(Button.primary('Save', loading: true, onPressed: () => taps++)),
    );

    await tester.tap(find.text('Save'), warnIfMissed: false);
    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  for (final palette in [irisPalette, irisDarkPalette]) {
    final mode = palette.brightness.name;

    testWidgets('primary swaps to the hover and active fills ($mode)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const Button.primary('Save', onPressed: _noop), palette: palette),
      );
      expect(_surface(tester, 'Save').color, palette.primary);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Save')));
      await tester.pump();
      expect(_surface(tester, 'Save').color, palette.primaryHover);

      await mouse.down(tester.getCenter(find.text('Save')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(_surface(tester, 'Save').color, palette.primaryActive);
      await mouse.up();
    });

    testWidgets('danger hovers to dangerHover, with onDanger text ($mode)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Button.danger('Delete', onPressed: _noop),
          palette: palette,
        ),
      );
      final label = tester.widget<Text>(find.text('Delete'));
      expect(label.style!.color, palette.onDanger);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Delete')));
      await tester.pump();
      expect(_surface(tester, 'Delete').color, palette.dangerHover);
    });

    testWidgets('disabled secondary keeps the enabled border ($mode)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Button('On', onPressed: _noop),
              Button('Off'),
            ],
          ),
          palette: palette,
        ),
      );
      BorderSide side(String label) =>
          (_surface(tester, label).shape! as RoundedRectangleBorder).side;
      expect(side('Off').color, palette.border);
      expect(side('Off').color, side('On').color);
    });
  }

  testWidgets('a seeded states controller pins the pressed fill', (
    tester,
  ) async {
    final states = WidgetStatesController({WidgetState.pressed});
    addTearDown(states.dispose);
    await tester.pumpWidget(
      _host(Button.primary('Save', onPressed: _noop, statesController: states)),
    );
    expect(_surface(tester, 'Save').color, irisPalette.primaryActive);
  });

  testWidgets('disabling a pressed button drops the pressed fill', (
    tester,
  ) async {
    Widget button(VoidCallback? onPressed) =>
        _host(Button.primary('Save', onPressed: onPressed));
    await tester.pumpWidget(button(_noop));
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Save')),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.pumpWidget(button(null));
    expect(tester.takeException(), isNull);
    expect(_surface(tester, 'Save').color, _disabledFill(irisPalette));
    await gesture.up();
  });

  testWidgets('swapping the states controller carries the live hover over', (
    tester,
  ) async {
    Widget button(WidgetStatesController? states) => _host(
      Button.primary('Save', onPressed: _noop, statesController: states),
    );
    await tester.pumpWidget(button(null));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('Save')));
    addTearDown(mouse.removePointer);
    await tester.pump();
    expect(_surface(tester, 'Save').color, irisPalette.primaryHover);

    final external = WidgetStatesController();
    addTearDown(external.dispose);
    await tester.pumpWidget(button(external));
    expect(external.value, contains(WidgetState.hovered));
    expect(_surface(tester, 'Save').color, irisPalette.primaryHover);

    await tester.pumpWidget(button(null));
    expect(tester.takeException(), isNull);
    expect(_surface(tester, 'Save').color, irisPalette.primaryHover);
  });

  group('sizes', () {
    for (final (name, sizes) in [
      ('the default ramp', defaultControlSizes),
      (
        'a 24/32/40 ramp',
        const AdminControlSizes(small: 24, medium: 32, large: 40),
      ),
      (
        'a 32/40/48 ramp',
        const AdminControlSizes(small: 32, medium: 40, large: 48),
      ),
    ]) {
      testWidgets('each size is the control height, padding growing with it '
          '($name)', (tester) async {
        for (final (size, height) in [
          (ControlSize.small, sizes.small),
          (ControlSize.medium, sizes.medium),
          (ControlSize.large, sizes.large),
        ]) {
          await tester.pumpWidget(
            _host(
              Button('Save', size: size, onPressed: _noop),
              sizes: sizes,
            ),
          );
          final button = tester.getRect(find.byType(Button));
          final label = tester.getRect(find.text('Save'));
          expect(button.height, height, reason: '$size');
          expect(label.left - button.left, height / 2 - 4, reason: '$size');
        }
      });
    }
  });

  group('Button.icon', () {
    testWidgets('is a square of the control height, named and tipped', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      for (final (size, side) in [
        (ControlSize.small, 28.0),
        (ControlSize.medium, 36.0),
        (ControlSize.large, 40.0),
      ]) {
        await tester.pumpWidget(
          _host(
            Button.icon(
              Icons.tune_rounded,
              semanticLabel: 'Filters',
              size: size,
              onPressed: _noop,
            ),
          ),
        );
        expect(tester.getSize(find.byType(Button)), Size.square(side));
        expect(
          tester.getCenter(find.byIcon(Icons.tune_rounded)),
          tester.getCenter(find.byType(Button)),
        );
      }
      expect(
        tester.getSemantics(find.bySemanticsLabel('Filters')),
        isSemantics(label: 'Filters', isButton: true, isEnabled: true),
      );
      expect(tester.widget<Tooltip>(find.byType(Tooltip)).message, 'Filters');
      handle.dispose();
    });

    testWidgets('fires, and loads in place', (tester) async {
      var taps = 0;
      Widget button({bool loading = false}) => _host(
        Button.icon(
          Icons.refresh_rounded,
          semanticLabel: 'Refresh',
          loading: loading,
          onPressed: () => taps++,
        ),
      );
      await tester.pumpWidget(button());
      await tester.tap(find.byType(Button));
      expect(taps, 1);
      await tester.pumpWidget(button(loading: true));
      expect(tester.getSize(find.byType(Button)), const Size.square(36));
      expect(find.byType(Spinner), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsNothing);
      await tester.tap(find.byType(Button), warnIfMissed: false);
      expect(taps, 1);
    });
  });

  group('tooltip and accessible name', () {
    testWidgets('a labelled button has no tooltip unless given one', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const Button('Save', onPressed: _noop)));
      expect(find.byType(Tooltip), findsNothing);

      await tester.pumpWidget(
        _host(
          const Button('Save', tooltip: 'Save the draft', onPressed: _noop),
        ),
      );
      expect(
        tester.widget<Tooltip>(find.byType(Tooltip)).message,
        'Save the draft',
      );
    });

    testWidgets('the tooltip shows on hover', (tester) async {
      await tester.pumpWidget(
        _host(
          const Button('Save', tooltip: 'Save the draft', onPressed: _noop),
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(Button)));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Save the draft'), findsOneWidget);
    });

    testWidgets('semanticLabel replaces the label as the name, once', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const Button('Edit', semanticLabel: 'Edit title', onPressed: _noop),
        ),
      );
      expect(find.text('Edit'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Edit title')),
        isSemantics(label: 'Edit title', isButton: true, isEnabled: true),
      );
      expect(find.bySemanticsLabel('Edit'), findsNothing);
      handle.dispose();
    });

    testWidgets('an icon-only button can take a tooltip of its own', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          const Button.icon(
            Icons.tune_rounded,
            semanticLabel: 'Filters',
            tooltip: 'Filters (F)',
            onPressed: _noop,
          ),
        ),
      );
      expect(
        tester.widget<Tooltip>(find.byType(Tooltip)).message,
        'Filters (F)',
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Filters')),
        isSemantics(label: 'Filters', isButton: true, isEnabled: true),
      );
      handle.dispose();
    });

    testWidgets('a tooltip that repeats the name is not read twice', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const Button('Save', tooltip: 'Save', onPressed: _noop)),
      );
      expect(tester.getSemantics(find.bySemanticsLabel('Save')).tooltip, '');

      await tester.pumpWidget(
        _host(
          const Button('Save', tooltip: 'Save the draft', onPressed: _noop),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Save')).tooltip,
        'Save the draft',
      );
      handle.dispose();
    });

    testWidgets('disabledHint explains a disabled button, in place of the '
        'tooltip', (tester) async {
      Widget button({VoidCallback? onPressed}) => _host(
        Button(
          'Publish',
          tooltip: 'Publish the page',
          disabledHint: 'Nothing to publish',
          onPressed: onPressed,
        ),
      );
      await tester.pumpWidget(button());
      expect(
        tester.widget<Tooltip>(find.byType(Tooltip)).message,
        'Nothing to publish',
      );
      await tester.pumpWidget(button(onPressed: _noop));
      expect(
        tester.widget<Tooltip>(find.byType(Tooltip)).message,
        'Publish the page',
      );
    });

    testWidgets('tooltip, hint and name change nothing at rest', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const Button('Publish')));
      final plain = tester.getRect(find.byType(Button));
      final fill = _surface(tester, 'Publish').color;
      await tester.pumpWidget(
        _host(
          const Button(
            'Publish',
            tooltip: 'Publish the page',
            disabledHint: 'Nothing to publish',
            semanticLabel: 'Publish the page',
          ),
        ),
      );
      expect(tester.getRect(find.byType(Button)), plain);
      expect(_surface(tester, 'Publish').color, fill);
    });
  });

  group('loading keeps the resting width', () {
    for (final (name, build) in <(String, Button Function(bool))>[
      (
        'label only',
        (l) => Button.primary('Save', loading: l, onPressed: _noop),
      ),
      (
        'with an icon',
        (l) => Button(
          'Refresh',
          icon: Icons.refresh_rounded,
          loading: l,
          onPressed: _noop,
        ),
      ),
      (
        'small',
        (l) => Button.danger(
          'Delete',
          size: ControlSize.small,
          loading: l,
          onPressed: _noop,
        ),
      ),
    ]) {
      testWidgets(name, (tester) async {
        await tester.pumpWidget(_host(build(false)));
        final resting = tester.getSize(find.byType(Button));
        await tester.pumpWidget(_host(build(true)));
        expect(tester.getSize(find.byType(Button)), resting);
        expect(find.byType(Spinner), findsOneWidget);
      });
    }
  });

  group('SplitButton', () {
    final published = <String>[];
    List<MenuEntry> entries() => [
      MenuItem('Schedule…', onSelect: () => published.add('schedule')),
      MenuItem('Publish to…', onSelect: () => published.add('to')),
    ];
    Widget split({
      VoidCallback? onPressed = _noop,
      ButtonVariant variant = ButtonVariant.primary,
      bool loading = false,
      String? disabledHint,
    }) => SplitButton(
      label: 'Publish',
      onPressed: onPressed,
      entries: entries(),
      menuSemanticLabel: 'More publish options',
      variant: variant,
      loading: loading,
      disabledHint: disabledHint,
    );
    Finder segment(String text) =>
        find.ancestor(of: find.text(text), matching: find.byType(Button));
    final caret = find.ancestor(
      of: find.byIcon(Icons.keyboard_arrow_down_rounded),
      matching: find.byType(Button),
    );

    setUp(published.clear);

    testWidgets('runs its action, and opens its menu from the caret', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(_host(split(onPressed: () => taps++)));
      await tester.tap(find.text('Publish'));
      expect(taps, 1);
      await tester.tap(caret);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Schedule…'));
      await tester.pumpAndSettle();
      expect(published, ['schedule']);
      expect(taps, 1);
    });

    testWidgets('one outer shape: square inner corners, a 1px divider, a '
        'square caret', (tester) async {
      await tester.pumpWidget(_host(split()));
      final action = tester.getRect(segment('Publish'));
      final menu = tester.getRect(caret);
      expect(action.height, 36);
      expect(menu.size, const Size.square(36));
      expect(menu.left - action.right, 1);
      expect(
        tester.getSize(find.byType(SplitButton)).width,
        action.width + 1 + 36,
      );

      RoundedRectangleBorder shape(Finder of) =>
          tester
                  .widget<Material>(
                    find
                        .descendant(of: of, matching: find.byType(Material))
                        .first,
                  )
                  .shape!
              as RoundedRectangleBorder;
      const r = Radius.circular(9);
      expect(
        shape(segment('Publish')).borderRadius,
        const BorderRadiusDirectional.horizontal(start: r),
      );
      expect(
        shape(caret).borderRadius,
        const BorderRadiusDirectional.horizontal(end: r),
      );

      final divider = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(SplitButton),
          matching: find.byWidgetPredicate(
            (w) =>
                w is ColoredBox &&
                w.color ==
                    Color.alphaBlend(
                      irisPalette.onPrimary.withValues(alpha: 0.25),
                      irisPalette.primary,
                    ),
          ),
        ),
      );
      expect(divider, isNotNull);
    });

    testWidgets('an outlined variant draws one outline around both', (
      tester,
    ) async {
      await tester.pumpWidget(_host(split(variant: ButtonVariant.secondary)));
      final side =
          (tester
                      .widget<Material>(
                        find
                            .descendant(
                              of: segment('Publish'),
                              matching: find.byType(Material),
                            )
                            .first,
                      )
                      .shape!
                  as RoundedRectangleBorder)
              .side;
      expect(side, BorderSide.none);
      final group = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(SplitButton),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(group.position, DecorationPosition.foreground);
      expect(
        (group.decoration as BoxDecoration).border,
        Border.all(color: irisPalette.border),
      );
    });

    testWidgets('each segment is a Tab stop; the caret is a named menu '
        'button', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(split()));
      expect(
        tester.getSemantics(caret),
        isSemantics(
          label: 'More publish options',
          isButton: true,
          hasExpandedState: true,
          isExpanded: false,
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final first = FocusManager.instance.primaryFocus;
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, isNot(first));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Schedule…'), findsOneWidget);
      expect(
        tester.getSemantics(caret),
        isSemantics(hasExpandedState: true, isExpanded: true),
      );
      handle.dispose();
    });

    testWidgets('a disabled action keeps its menu and explains itself', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(split(onPressed: null, disabledHint: 'Nothing to publish')),
      );
      expect(
        tester.widgetList<Tooltip>(find.byType(Tooltip)).map((t) => t.message),
        contains('Nothing to publish'),
      );
      await tester.tap(caret);
      await tester.pumpAndSettle();
      expect(find.text('Publish to…'), findsOneWidget);
    });

    testWidgets('loading spins the action in place and locks the menu', (
      tester,
    ) async {
      await tester.pumpWidget(_host(split()));
      final resting = tester.getSize(find.byType(SplitButton));
      await tester.pumpWidget(_host(split(loading: true)));
      expect(tester.getSize(find.byType(SplitButton)), resting);
      expect(find.byType(Spinner), findsOneWidget);
      await tester.tap(caret, warnIfMissed: false);
      // The spinner never settles.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Schedule…'), findsNothing);
    });

    group('the caret reads as live only when it is', () {
      Color fill(WidgetTester tester, Finder segment) => tester
          .widget<Material>(
            find.descendant(of: segment, matching: find.byType(Material)).first,
          )
          .color!;
      Color divider(WidgetTester tester) => tester
          .widget<ColoredBox>(
            find.descendant(
              of: find.byType(SplitButton),
              matching: find.byType(ColoredBox),
            ),
          )
          .color;
      Color dividerOf(Color fg, Color fill) =>
          Color.alphaBlend(fg.withValues(alpha: 0.25), fill);
      Color caretGlyph(WidgetTester tester) => tester
          .widget<Icon>(find.byIcon(Icons.keyboard_arrow_down_rounded))
          .color!;
      SplitButton splitWith(
        List<MenuEntry> entries, {
        VoidCallback? onPressed = _noop,
        bool loading = false,
      }) => SplitButton(
        label: 'Publish',
        onPressed: onPressed,
        entries: entries,
        menuSemanticLabel: 'More publish options',
        loading: loading,
      );

      testWidgets('loading: the disabled look, and no menu', (tester) async {
        await tester.pumpWidget(_host(split(loading: true)));
        expect(fill(tester, segment('Publish')), irisPalette.primary);
        expect(fill(tester, caret), _disabledFill(irisPalette));
        expect(tester.widget<Button>(caret).onPressed, isNull);
        expect(
          divider(tester),
          dividerOf(caretGlyph(tester), _disabledFill(irisPalette)),
        );
        final handle = tester.ensureSemantics();
        expect(
          tester.getSemantics(caret),
          isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
        );
        handle.dispose();
      });

      testWidgets('every entry disabled: the disabled look, and no menu', (
        tester,
      ) async {
        await tester.pumpWidget(
          _host(
            splitWith(const [
              MenuItem('Schedule…'),
              MenuDivider(),
              MenuItem('Unpublish'),
            ]),
          ),
        );
        expect(fill(tester, segment('Publish')), irisPalette.primary);
        expect(fill(tester, caret), _disabledFill(irisPalette));
        await tester.tap(caret, warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Unpublish'), findsNothing);
      });

      testWidgets('a disabled action with a live entry: the caret stays '
          'primary and opens', (tester) async {
        var unpublished = 0;
        await tester.pumpWidget(
          _host(
            splitWith([
              const MenuItem('Schedule…'),
              MenuItem('Unpublish', onSelect: () => unpublished++),
            ], onPressed: null),
          ),
        );
        expect(fill(tester, segment('Publish')), _disabledFill(irisPalette));
        expect(fill(tester, caret), irisPalette.primary);
        expect(
          divider(tester),
          dividerOf(
            tester.widget<Text>(find.text('Publish')).style!.color!,
            _disabledFill(irisPalette),
          ),
        );
        await tester.tap(caret);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Unpublish'));
        await tester.pumpAndSettle();
        expect(unpublished, 1);
      });

      testWidgets('both live: the divider in their tone', (tester) async {
        await tester.pumpWidget(_host(split()));
        expect(fill(tester, caret), irisPalette.primary);
        expect(
          divider(tester),
          dividerOf(irisPalette.onPrimary, irisPalette.primary),
        );
      });

      testWidgets('a checkbox item or a submenu is something to open', (
        tester,
      ) async {
        const later = [MenuItem('Tomorrow', onSelect: _noop)];
        for (final (entry, live) in [
          (MenuCheckboxItem('Notify', checked: false, onChanged: (_) {}), true),
          (
            const MenuCheckboxItem('Notify', checked: false, onChanged: null),
            false,
          ),
          (const MenuSubmenu('Later', entries: later), true),
          (const MenuSubmenu('Later', entries: []), false),
          (const MenuSubmenu('Later', enabled: false, entries: later), false),
        ]) {
          await tester.pumpWidget(_host(splitWith([entry])));
          expect(
            fill(tester, caret),
            live ? irisPalette.primary : _disabledFill(irisPalette),
            reason: '$entry',
          );
        }
      });
    });

    testWidgets('given less than its width, the action’s label ellipsises', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 90,
            child: Align(alignment: Alignment.centerLeft, child: split()),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(SplitButton)).width, 90);
      expect(tester.getSize(caret), const Size.square(36));
    });
  });
}

void _noop() {}

/// Each size's label style and glyph size, and a status-tinted glyph.
void _typeAndGlyphs() {
  final tokens = AdminTokens.from(palette: irisPalette);

  for (final (size, text, glyph) in [
    (ControlSize.small, tokens.typography.buttonSmall, tokens.iconSizes.sm),
    (ControlSize.medium, tokens.typography.button, tokens.iconSizes.md),
    (ControlSize.large, tokens.typography.button, tokens.iconSizes.md),
  ]) {
    testWidgets('a ${size.name} button takes its label and glyph from the '
        'type ramp and the icon sizes', (tester) async {
      await tester.pumpWidget(
        _host(Button('Save', icon: Icons.add, size: size, onPressed: _noop)),
      );
      final label = tester.widget<Text>(find.text('Save')).style!;
      expect(label.fontSize, text.fontSize);
      expect(label.height, text.height);
      expect(tester.widget<Icon>(find.byIcon(Icons.add)).size, glyph);
    });
  }

  testWidgets('iconColor tints the glyph, not the label, while enabled', (
    tester,
  ) async {
    const tint = Color(0xFF00A86B);
    await tester.pumpWidget(
      _host(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Button.ghost(
              'Copied',
              icon: Icons.check,
              iconColor: tint,
              onPressed: _noop,
            ),
            Button.ghost('Off', icon: Icons.close, iconColor: tint),
          ],
        ),
      ),
    );
    expect(tester.widget<Icon>(find.byIcon(Icons.check)).color, tint);
    expect(tester.widget<Text>(find.text('Copied')).style!.color, isNot(tint));
    expect(
      tester.widget<Icon>(find.byIcon(Icons.close)).color,
      tester.widget<Text>(find.text('Off')).style!.color,
      reason: 'a disabled button keeps its own glyph colour',
    );
  });
}
