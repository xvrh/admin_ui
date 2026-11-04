import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _selected = <String>[];
final _arrows = <LogicalKeyboardKey>[];

List<MenuEntry> _entries(BuildContext context) => [
  MenuItem('Open', onSelect: () => _selected.add('Open')),
  MenuSubmenu(
    'Move to',
    entries: [MenuItem('Archive', onSelect: () => _selected.add('Archive'))],
  ),
  const MenuDivider(),
  MenuItem('Delete', danger: true, onSelect: () => _selected.add('Delete')),
];

const _rowKey = Key('row');

/// A list whose second row sits in a [ContextMenuRegion] at [at], sized
/// [size]; the list answers ↑ and ↓ itself, above the region.
Widget _host({
  Offset at = const Offset(100, 100),
  Size size = const Size(300, 40),
  TextDirection direction = TextDirection.ltr,
  bool enabled = true,
  ValueChanged<bool>? onOpenChanged,
}) => MaterialApp(
  home: Directionality(
    textDirection: direction,
    child: Scaffold(
      body: Focus(
        canRequestFocus: false,
        onKeyEvent: (node, event) {
          final key = event.logicalKey;
          if (event is KeyDownEvent &&
              (key == LogicalKeyboardKey.arrowDown ||
                  key == LogicalKeyboardKey.arrowUp)) {
            _arrows.add(key);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            Positioned(
              left: at.dx,
              top: at.dy,
              width: size.width,
              height: size.height,
              child: ContextMenuRegion(
                enabled: enabled,
                entries: _entries,
                onOpenChanged: onOpenChanged,
                child: Row(
                  key: _rowKey,
                  children: [
                    TextButton(onPressed: () {}, child: const Text('Title')),
                    TextButton(onPressed: () {}, child: const Text('Status')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);

Rect _menu(WidgetTester tester) =>
    tester.getRect(find.byType(PopoverMenuSurface));

String? _focused() => FocusManager.instance.primaryFocus?.debugLabel;

bool _hasFocus(WidgetTester tester, String text) =>
    Focus.maybeOf(tester.element(find.text(text)))?.hasPrimaryFocus ?? false;

Future<void> _rightClick(WidgetTester tester, Offset at) async {
  final mouse = await tester.startGesture(
    at,
    kind: PointerDeviceKind.mouse,
    buttons: kSecondaryMouseButton,
  );
  await mouse.up();
  await tester.pumpAndSettle();
}

Future<void> _press(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pumpAndSettle();
}

/// Focuses the region's "Status" button.
Future<void> _focusStatus(WidgetTester tester) async {
  Focus.of(tester.element(find.text('Status'))).requestFocus();
  await tester.pumpAndSettle();
  expect(_hasFocus(tester, 'Status'), isTrue);
}

void main() {
  setUp(() {
    _selected.clear();
    _arrows.clear();
  });

  testWidgets('a right-click opens the menu with its top-left at the point, '
      'and focuses the menu', (tester) async {
    await tester.pumpWidget(_host());
    await _rightClick(tester, const Offset(180, 112));
    expect(find.text('Open'), findsOneWidget);
    final menu = _menu(tester);
    expect(menu.left, 180);
    expect(menu.top, closeTo(112, 2), reason: 'a 2px gap below the point');
    expect(_focused(), 'Menu');

    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(_focused(), 'Open', reason: 'the menu keys work from there');
    await _press(tester, LogicalKeyboardKey.enter);
    expect(_selected, ['Open']);
    expect(find.text('Open'), findsNothing);
  });

  testWidgets('a left click stays the row\'s; one on the row closes the open '
      'menu, and a right-click elsewhere moves it', (tester) async {
    await tester.pumpWidget(_host());
    await tester.tapAt(const Offset(180, 112));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsNothing);

    await _rightClick(tester, const Offset(180, 112));
    await tester.tapAt(const Offset(390, 120));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsNothing);

    await _rightClick(tester, const Offset(180, 112));
    await _rightClick(tester, const Offset(300, 110));
    expect(find.text('Open'), findsOneWidget);
    expect(_menu(tester).left, 300);
  });

  testWidgets('onOpenChanged reports the menu opening and closing', (
    tester,
  ) async {
    final changes = <bool>[];
    await tester.pumpWidget(_host(onOpenChanged: changes.add));
    await _rightClick(tester, const Offset(180, 112));
    expect(changes, [true]);
    await _press(tester, LogicalKeyboardKey.escape);
    expect(changes, [true, false]);

    await _focusStatus(tester);
    await _press(tester, LogicalKeyboardKey.contextMenu);
    await _press(tester, LogicalKeyboardKey.enter);
    expect(_selected, ['Open']);
    expect(changes, [true, false, true, false]);
  });

  testWidgets('a long press opens it at the touch point', (tester) async {
    await tester.pumpWidget(_host());
    await tester.longPressAt(const Offset(220, 118));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(_menu(tester).topLeft, const Offset(220, 120));
  });

  testWidgets('a mouse long press is a click, not a context menu', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.longPressAt(
      const Offset(220, 118),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsNothing);
  });

  testWidgets('Shift+F10 opens it below the focused control on its first '
      'item; Escape hands focus back', (tester) async {
    await tester.pumpWidget(_host());
    await _focusStatus(tester);
    final status = tester.getRect(
      find.ancestor(of: find.text('Status'), matching: find.byType(TextButton)),
    );

    await _press(tester, LogicalKeyboardKey.f10, shift: true);
    expect(find.text('Open'), findsOneWidget);
    expect(_menu(tester).topLeft, status.bottomLeft + const Offset(0, 2));
    expect(_focused(), 'Open');

    await _press(tester, LogicalKeyboardKey.escape);
    expect(find.text('Open'), findsNothing);
    expect(_hasFocus(tester, 'Status'), isTrue);
  });

  testWidgets('the context-menu key opens it too; choosing an item hands '
      'focus back', (tester) async {
    await tester.pumpWidget(_host());
    await _focusStatus(tester);
    await _press(tester, LogicalKeyboardKey.contextMenu);
    expect(_focused(), 'Open');
    await _press(tester, LogicalKeyboardKey.arrowDown);
    await _press(tester, LogicalKeyboardKey.arrowRight);
    expect(_focused(), 'Archive', reason: 'its submenu opens from the keys');
    await _press(tester, LogicalKeyboardKey.enter);
    expect(_selected, ['Archive']);
    expect(find.text('Open'), findsNothing);
    expect(_hasFocus(tester, 'Status'), isTrue);
  });

  testWidgets('the arrows are left to the row and what holds it', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await _focusStatus(tester);
    await _press(tester, LogicalKeyboardKey.arrowDown);
    await _press(tester, LogicalKeyboardKey.arrowUp);
    expect(find.text('Open'), findsNothing);
    expect(_arrows, [LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.arrowUp]);
    expect(_hasFocus(tester, 'Status'), isTrue);
  });

  testWidgets('a disabled region opens nothing', (tester) async {
    await tester.pumpWidget(_host(enabled: false));
    await _rightClick(tester, const Offset(180, 112));
    await _focusStatus(tester);
    await _press(tester, LogicalKeyboardKey.f10, shift: true);
    expect(find.text('Open'), findsNothing);
  });

  testWidgets('in a right-to-left app it opens with its top-right at the '
      'point', (tester) async {
    await tester.pumpWidget(_host(direction: TextDirection.rtl));
    await _rightClick(tester, const Offset(300, 112));
    final menu = _menu(tester);
    expect(menu.right, 300);
    expect(menu.top, closeTo(112, 2));

    await _press(tester, LogicalKeyboardKey.escape);
    await _focusStatus(tester);
    final status = tester.getRect(
      find.ancestor(of: find.text('Status'), matching: find.byType(TextButton)),
    );
    await _press(tester, LogicalKeyboardKey.f10, shift: true);
    expect(_menu(tester).topRight, status.bottomRight + const Offset(0, 2));
  });

  testWidgets('near the window\'s bottom-end corner it flips above the point '
      'and shifts in from the edge', (tester) async {
    await tester.pumpWidget(
      _host(at: const Offset(500, 540), size: const Size(300, 60)),
    );
    const point = Offset(780, 580);
    await _rightClick(tester, point);
    final menu = _menu(tester);
    expect(menu.bottom, closeTo(point.dy, 2), reason: 'above the point');
    expect(menu.right, 800 - 8, reason: 'shifted in to the 8px margin');
    expect(menu.left, lessThan(point.dx));
  });
}
