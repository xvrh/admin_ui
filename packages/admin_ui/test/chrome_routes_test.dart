import 'package:admin_ui/admin_ui.dart';
import 'package:admin_ui/src/common/ui/chrome_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// A route opened from chrome drawn in a palette of its own is the page's:
/// a dark sider's account menu opens a modal in the page's light palette.
void main() {
  final tokens = antTheme.tokens;
  final page = tokens.palette;
  final sider = tokens.shell.sidebarPalette!;

  Future<void> pumpInSider(
    WidgetTester tester,
    void Function(BuildContext context) open,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(tokens),
        home: AdminScope(
          child: Scaffold(
            body: ChromeTheme(
              palette: sider,
              child: Builder(
                builder: (context) => Center(
                  child: TextButton(
                    onPressed: () => open(context),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  test('the sider is drawn in another palette than the page', () {
    expect(sider.foreground, isNot(page.foreground));
  });

  testWidgets('a modal opened from chrome is drawn in the page palette', (
    tester,
  ) async {
    late AdminPalette drawnIn;
    await pumpInSider(
      tester,
      (context) => showModal<void>(
        context,
        builder: (context) {
          drawnIn = context.colors;
          return const Modal(title: 'Two-step sign-in', body: Text('On'));
        },
      ),
    );
    expect(drawnIn.foreground, page.foreground);
    expect(drawnIn.surface, page.modalSurface);
    final scrim = tester.widget<ModalBarrier>(find.byType(ModalBarrier).last);
    expect(scrim.color, page.scrim);
  });

  testWidgets('a side sheet opened from chrome is drawn in the page palette', (
    tester,
  ) async {
    late AdminPalette drawnIn;
    await pumpInSider(
      tester,
      (context) => showSideSheet<void>(
        context,
        builder: (context) {
          drawnIn = context.colors;
          return const SideSheet(title: 'Details', child: Text('Body'));
        },
      ),
    );
    expect(drawnIn.foreground, page.foreground);
    expect(drawnIn.surface, page.sheetSurface);
    final scrim = tester.widget<ModalBarrier>(find.byType(ModalBarrier).last);
    expect(scrim.color, page.scrim);
  });
}
