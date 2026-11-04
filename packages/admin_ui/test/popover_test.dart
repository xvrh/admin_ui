import 'package:admin_ui/src/common/ui/modal_anchor.dart';
import 'package:admin_ui/src/common/ui/popover.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Popover popover) => MaterialApp(
  home: Scaffold(body: Center(child: popover)),
);

Popover _popover() => Popover(
  anchor: (context, c) =>
      ElevatedButton(onPressed: c.toggle, child: const Text('open')),
  content: (context, c) => const Material(
    child: SizedBox(
      width: 200,
      child: TextField(decoration: InputDecoration(hintText: 'reply')),
    ),
  ),
);

void main() {
  testWidgets('opens on anchor tap and closes on re-tap', (tester) async {
    await tester.pumpWidget(_host(_popover()));
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('content is interactive — typing works through the overlay', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_popover()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('tapping outside dismisses the popover', (tester) async {
    await tester.pumpWidget(_host(_popover()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('Escape dismisses the popover', (tester) async {
    await tester.pumpWidget(_host(_popover()));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('Escape closes a pointer-opened popover wherever focus is, and '
      'returns focus to the anchor', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const TextField(key: Key('elsewhere')),
              Popover(
                autofocus: false,
                anchor: (context, c) => ElevatedButton(
                  onPressed: c.toggle,
                  child: const Text('open'),
                ),
                content: (context, c) =>
                    const SizedBox(width: 100, height: 40, child: Text('tip')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('elsewhere')));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('tip'), findsOneWidget);
    final field = tester.state<EditableTextState>(find.byType(EditableText));
    expect(field.widget.focusNode.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('tip'), findsNothing);
    expect(Focus.of(tester.element(find.text('open'))).hasPrimaryFocus, isTrue);
  });

  testWidgets('nested popovers close one Escape at a time', (tester) async {
    await tester.pumpWidget(
      _host(
        Popover(
          autofocus: false,
          anchor: (context, c) =>
              ElevatedButton(onPressed: c.toggle, child: const Text('outer')),
          content: (context, c) => Material(
            child: Popover(
              autofocus: false,
              anchor: (context, c) => ElevatedButton(
                onPressed: c.toggle,
                child: const Text('inner'),
              ),
              content: (context, c) => const Material(child: Text('innermost')),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('outer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('inner'));
    await tester.pumpAndSettle();
    expect(find.text('innermost'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('innermost'), findsNothing);
    expect(find.text('inner'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('inner'), findsNothing);
  });

  testWidgets('a dialog opened from the popover takes Escape first', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModalAnchor(
            child: Center(
              child: Popover(
                anchor: (context, c) => ElevatedButton(
                  onPressed: c.toggle,
                  child: const Text('open'),
                ),
                content: (context, c) => Material(
                  child: TextButton(
                    onPressed: () => ModalAnchor.of(context).show<void>(
                      builder: (context) =>
                          const Material(child: Text('dialog')),
                    ),
                    child: const Text('more'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('more'));
    await tester.pumpAndSettle();
    expect(find.text('dialog'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('dialog'), findsNothing);
    expect(find.text('more'), findsOneWidget, reason: 'the popover stays');

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('more'), findsNothing);
  });

  testWidgets('closeOnFocusOut closes when focus moves on, not when it '
      'returns to the anchor', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextButton(onPressed: () {}, child: const Text('elsewhere')),
              Popover(
                closeOnFocusOut: true,
                anchor: (context, c) => ElevatedButton(
                  onPressed: c.toggle,
                  child: const Text('open'),
                ),
                content: (context, c) => const Material(
                  child: SizedBox(width: 200, child: TextField()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    FocusNode nodeOf(String text) => Focus.of(tester.element(find.text(text)));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pump();
    nodeOf('open').requestFocus();
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    nodeOf('elsewhere').requestFocus();
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('onOpenChanged reports every open and close', (tester) async {
    final changes = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Popover(
              onOpenChanged: changes.add,
              anchor: (context, c) => ElevatedButton(
                onPressed: c.toggle,
                child: const Text('open'),
              ),
              content: (context, c) =>
                  const Material(child: SizedBox(width: 200, height: 40)),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(changes, [true, false, true, false]);
  });

  testWidgets('dismiss closes from the content and refocuses the trigger', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Popover(
              anchor: (context, c) => ElevatedButton(
                onPressed: c.toggle,
                child: const Text('open'),
              ),
              content: (context, c) => Material(
                child: TextButton(
                  autofocus: true,
                  onPressed: () => Popover.dismiss(context),
                  child: const Text('pick'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('pick'));
    await tester.pumpAndSettle();
    expect(find.text('pick'), findsNothing);
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<ElevatedButton>(),
      isNotNull,
    );
  });
}
