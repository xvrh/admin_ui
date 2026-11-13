import 'package:admin_ui/src/common/ui/clear_button.dart';
import 'package:admin_ui/src/common/ui/combobox.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _opts = [
  ComboboxOption('a', 'Apple'),
  ComboboxOption('b', 'Banana'),
  ComboboxOption('c', 'Cherry'),
];

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 300, child: child)),
  ),
);

void main() {
  testWidgets('opens on tap and filters as you type', (tester) async {
    String? picked;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => Combobox<String>(
            value: picked,
            onChanged: (v) => setState(() => picked = v),
            options: _opts,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(find.text('Banana'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ch');
    await tester.pumpAndSettle();
    expect(find.text('Cherry'), findsOneWidget);
    expect(find.text('Apple'), findsNothing);

    await tester.tap(find.text('Cherry'));
    await tester.pumpAndSettle();
    expect(picked, 'c');
  });

  testWidgets('keyboard arrows + enter select a value', (tester) async {
    String? picked;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => Combobox<String>(
            value: picked,
            onChanged: (v) => setState(() => picked = v),
            options: _opts,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // -> Banana
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(picked, 'b');
  });

  testWidgets('clearable resets to null', (tester) async {
    String? picked = 'a';
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => Combobox<String>(
            value: picked,
            onChanged: (v) => setState(() => picked = v),
            options: _opts,
            clearable: true,
          ),
        ),
      ),
    );

    final clear = find.byType(ClearButton);
    expect(tester.widget<ClearButton>(clear).label, 'Clear selection');
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(picked, isNull);
  });

  group('under a SelectionArea around the app', () {
    // As an app mounts it: above the navigator, so the list, in the
    // navigator's overlay, is inside it too. The area needs an overlay of
    // its own.
    Widget host(Widget child) => MaterialApp(
      builder: (context, navigator) => Overlay(
        initialEntries: [
          OverlayEntry(builder: (_) => SelectionArea(child: navigator!)),
        ],
      ),
      home: Scaffold(
        body: Column(
          children: [
            const Text('Some text'),
            SizedBox(width: 300, child: child),
          ],
        ),
      ),
    );

    /// A mouse click held past the tap timeout, as a hand clicks: the area
    /// takes focus on its tap down.
    Future<void> click(WidgetTester tester, Finder finder) async {
      final gesture = await tester.startGesture(
        tester.getCenter(finder),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(kPressTimeout * 2);
      await gesture.up();
      await tester.pumpAndSettle();
      await gesture.removePointer();
    }

    Future<String? Function()> pump(WidgetTester tester) async {
      String? picked = 'a';
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => Combobox<String>(
              value: picked,
              onChanged: (v) => setState(() => picked = v),
              options: _opts,
            ),
          ),
        ),
      );
      return () => picked;
    }

    bool fieldFocused() =>
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<Combobox<String>>() !=
        null;

    testWidgets('a click picks an option and the field keeps focus', (
      tester,
    ) async {
      final picked = await pump(tester);
      await click(tester, find.byType(TextField));
      expect(find.text('Banana'), findsOneWidget);

      await click(tester, find.text('Banana'));
      expect(picked(), 'b');
      expect(find.text('Cherry'), findsNothing);
      expect(fieldFocused(), isTrue);
    });

    testWidgets('a click on text outside still closes the list', (
      tester,
    ) async {
      final picked = await pump(tester);
      await click(tester, find.byType(TextField));
      expect(find.text('Banana'), findsOneWidget);

      await click(tester, find.text('Some text'));
      expect(find.text('Banana'), findsNothing);
      expect(picked(), 'a');
    });
  });
}
