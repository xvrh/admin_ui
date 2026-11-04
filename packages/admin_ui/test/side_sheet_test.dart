import 'package:admin_ui/src/common/ui/icon_action.dart';
import 'package:admin_ui/src/common/ui/side_sheet.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host({SideSheetSide side = SideSheetSide.end, Widget? footer}) =>
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showSideSheet(
                context,
                side: side,
                builder: (_) => SideSheet(
                  title: 'Sheet',
                  footer: footer,
                  child: const Text('sheet-body'),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('opens on demand and renders title + body', (tester) async {
    await tester.pumpWidget(_host());
    expect(find.text('sheet-body'), findsNothing);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Sheet'), findsOneWidget);
    expect(find.text('sheet-body'), findsOneWidget);
  });

  testWidgets('the close button dismisses it', (tester) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('sheet-body'), findsNothing);
  });

  testWidgets('tapping the scrim dismisses it', (tester) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Tap top-left, away from a right-docked sheet — hits the barrier.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    expect(find.text('sheet-body'), findsNothing);
  });

  testWidgets('Escape dismisses it', (tester) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.text('sheet-body'), findsNothing);
  });

  testWidgets('renders a footer when given', (tester) async {
    await tester.pumpWidget(_host(footer: const Text('footer-row')));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('footer-row'), findsOneWidget);
  });

  testWidgets('the close matches the Modal\'s: a 28px box whose glyph keeps '
      'the inset, 8px clear of a long title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 320,
              child: SideSheet(
                title: List.filled(20, 'Very long title').join(' '),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );
    final sheet = tester.getRect(find.byType(SideSheet));
    final close = tester.getRect(find.byType(IconAction));
    final glyph = tester.getRect(
      find.descendant(of: find.byType(IconAction), matching: find.byType(Icon)),
    );
    final title = tester.getRect(find.textContaining('Very long title'));
    expect(close.size, const Size(28, 28));
    expect(glyph.size, const Size(16, 16));
    expect(sheet.right - glyph.right, 16);
    expect(close.left - title.right, 8);
  });
}
