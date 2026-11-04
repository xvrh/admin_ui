import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _tokens = defaultTokens;

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(_tokens),
  home: Scaffold(body: Center(child: child)),
);

/// The node the action announces as.
SemanticsNode _node(WidgetTester tester) => tester.getSemantics(
  find.descendant(
    of: find.byType(IconAction),
    matching: find.byType(GestureDetector),
  ),
);

Finder _ring() => find.byWidgetPredicate((w) {
  if (w is! DecoratedBox) return false;
  final d = w.decoration;
  return d is BoxDecoration &&
      d.border is Border &&
      (d.border! as Border).top.color == _tokens.palette.focusRing;
});

void main() {
  testWidgets('announces its label once: a button, no repeated tooltip', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        IconAction(Icons.delete_outline, label: 'Delete', onPressed: () {}),
      ),
    );
    expect(
      _node(tester),
      matchesSemantics(
        label: 'Delete',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    expect(_node(tester).getSemanticsData().tooltip, isEmpty);
    handle.dispose();
  });

  test('medium has no fixed box: reading it asserts', () {
    expect(IconActionSize.inline.box, 24);
    expect(IconActionSize.small.box, 28);
    expect(() => IconActionSize.medium.box, throwsAssertionError);
  });

  for (final size in IconActionSize.values) {
    testWidgets('${size.name}: its square hit box, labelled', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _host(
          IconAction(
            Icons.more_horiz,
            label: 'More options',
            size: size,
            onPressed: () => taps++,
          ),
        ),
      );
      final box = tester.getSize(find.byType(IconAction));
      final context = tester.element(find.byType(IconAction));
      expect(box, Size.square(size.boxOf(context)));
      expect(box.shortestSide, greaterThanOrEqualTo(24));
      expect(tester.getSize(find.byType(Icon)), Size.square(size.glyph));

      // The corner of the box, away from the glyph, still hits.
      await tester.tapAt(
        tester.getTopLeft(find.byType(IconAction)) + const Offset(1, 1),
      );
      expect(taps, 1);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }

  testWidgets('IconAction.close reads the localized "Close"', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(IconAction.close(onPressed: () {})));
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(_node(tester), isSemantics(label: 'Close', isButton: true));
    expect(
      tester.widget<Tooltip>(find.byType(Tooltip)).message,
      const DefaultMaterialLocalizations().closeButtonTooltip,
    );
    handle.dispose();
  });

  testWidgets('selected and expanded reach semantics; disabled is inert', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        IconAction(
          Icons.push_pin_outlined,
          label: 'Pin',
          selected: true,
          expanded: false,
          onPressed: () {},
        ),
      ),
    );
    expect(
      _node(tester),
      isSemantics(isSelected: true, hasExpandedState: true, isExpanded: false),
    );

    await tester.pumpWidget(
      _host(const IconAction(Icons.push_pin_outlined, label: 'Pin')),
    );
    expect(
      _node(tester),
      isSemantics(label: 'Pin', hasEnabledState: true, isEnabled: false),
    );
    handle.dispose();
  });

  testWidgets('Tab draws the focus ring; Enter activates', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        IconAction(Icons.edit_outlined, label: 'Edit', onPressed: () => taps++),
      ),
    );
    expect(_ring(), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_ring(), findsOneWidget);
    final spec = _tokens.focus;
    expect(
      tester.getRect(_ring()),
      tester.getRect(find.byType(IconAction)).inflate(spec.offset + spec.width),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 1);
  });

  testWidgets('keyboard focus opens the tooltip', (tester) async {
    await tester.pumpWidget(
      _host(IconAction(Icons.edit_outlined, label: 'Edit', onPressed: () {})),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
  });

  group('fills', () {
    final colors = _tokens.palette;

    Color? fillOf(WidgetTester tester) {
      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(IconAction),
              matching: find.byType(DecoratedBox),
            )
            .last,
      );
      return (box.decoration as BoxDecoration).color;
    }

    Color glyphOf(WidgetTester tester) =>
        tester.widget<Icon>(find.byType(Icon)).color!;

    testWidgets('rest, hover, pressed and disabled', (tester) async {
      final pinned = WidgetStatesController();
      addTearDown(pinned.dispose);
      Widget build({VoidCallback? onPressed, bool danger = false}) => _host(
        IconAction(
          Icons.delete_outline,
          label: 'Delete',
          danger: danger,
          statesController: pinned,
          onPressed: onPressed,
        ),
      );

      await tester.pumpWidget(build(onPressed: () {}));
      expect(fillOf(tester), isNull);
      expect(glyphOf(tester), colors.foregroundMuted);

      pinned.update(WidgetState.hovered, true);
      await tester.pump();
      expect(fillOf(tester), colors.hoverOverlay);
      expect(glyphOf(tester), colors.foregroundSecondary);

      await tester.pumpWidget(build(onPressed: () {}, danger: true));
      expect(glyphOf(tester), colors.dangerText);

      pinned.update(WidgetState.pressed, true);
      await tester.pump();
      expect(fillOf(tester), colors.pressedOverlay);

      await tester.pumpWidget(build());
      expect(fillOf(tester), isNull);
      expect(glyphOf(tester), colors.foregroundSubtle);
    });

    testWidgets('selected sits on primarySubtle with a primaryText glyph', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          IconAction(
            Icons.push_pin_outlined,
            label: 'Pin',
            selected: true,
            onPressed: () {},
          ),
        ),
      );
      expect(fillOf(tester), colors.primarySubtle);
      expect(glyphOf(tester), colors.primaryText);
    });

    testWidgets('a real pointer hovers it', (tester) async {
      await tester.pumpWidget(
        _host(IconAction(Icons.edit_outlined, label: 'Edit', onPressed: () {})),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(IconAction)));
      await tester.pump();
      expect(fillOf(tester), colors.hoverOverlay);
    });
  });

  group('CircleButton', () {
    testWidgets('a 22px disc in a 24px hit box, named by its label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _host(
          CircleButton(icon: Icons.close, label: 'Remove', onTap: () => taps++),
        ),
      );
      expect(tester.getSize(find.byType(CircleButton)), const Size.square(24));
      // The first Container is the disc; keyboard focus also opens the
      // label's tooltip.
      final disc = find
          .descendant(
            of: find.byType(CircleButton),
            matching: find.byType(Container),
          )
          .first;
      expect(tester.getSize(disc), const Size.square(22));
      expect(
        tester.getSemantics(disc),
        isSemantics(label: 'Remove', isButton: true),
      );
      expect(tester.widget<Tooltip>(find.byType(Tooltip)).message, 'Remove');

      await tester.tapAt(
        tester.getTopLeft(find.byType(CircleButton)) + const Offset(1, 1),
      );
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('Tab rings the disc itself', (tester) async {
      await tester.pumpWidget(
        _host(CircleButton(icon: Icons.refresh, label: 'Retry', onTap: () {})),
      );
      expect(_ring(), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_ring(), findsOneWidget);
      final spec = _tokens.focus;
      // The first Container is the disc; keyboard focus also opens the
      // label's tooltip.
      final disc = find
          .descendant(
            of: find.byType(CircleButton),
            matching: find.byType(Container),
          )
          .first;
      expect(
        tester.getRect(_ring()),
        tester.getRect(disc).inflate(spec.offset + spec.width),
      );
      final ring = tester.widget<DecoratedBox>(_ring()).decoration;
      expect(
        (ring as BoxDecoration).borderRadius,
        BorderRadius.circular(11 + spec.offset + spec.width),
      );
    });
  });
}
