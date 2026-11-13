import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _header = Offset(400, 30);
const _rows = Offset(400, 300);

void main() {
  testWidgets('over a page that does not scroll sideways, the browser gets '
      'no scroll', (tester) async {
    await _pump(
      tester,
      ListView(children: [for (var i = 0; i < 100; i++) Text('row $i')]),
    );
    expect(await _wheel(tester, _rows, const Offset(-5, 0)), [false]);
    // The list is at its top: nothing uses a scroll up.
    expect(await _wheel(tester, _rows, const Offset(0, -2)), [false]);
  });

  testWidgets('scroll views still get their scrolls first', (tester) async {
    final sideways = ScrollController();
    final rows = ScrollController();
    addTearDown(sideways.dispose);
    addTearDown(rows.dispose);
    // A header over a list of rows, in a view that scrolls sideways.
    await _pump(
      tester,
      SingleChildScrollView(
        controller: sideways,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 3000,
          child: Column(
            children: [
              const SizedBox(height: 60),
              Expanded(
                child: ListView.builder(
                  controller: rows,
                  itemCount: 200,
                  itemExtent: 30,
                  itemBuilder: (context, i) => Text('row $i'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(await _wheel(tester, _rows, const Offset(400, 0)), [false]);
    expect(sideways.offset, 400);
    expect(await _wheel(tester, _rows, const Offset(0, 90)), [false]);
    expect(rows.offset, 90);

    // Back to the start, then on past it, over the rows and the header.
    await _wheel(tester, _rows, const Offset(-5000, 0));
    expect(sideways.offset, 0);
    expect(await _wheel(tester, _rows, const Offset(-5, 0)), [false]);
    expect(await _wheel(tester, _header, const Offset(-5, 0)), [false]);
  });

  testWidgets('a dialog, a route outside AdminScope, is covered', (
    tester,
  ) async {
    await _pump(
      tester,
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) =>
                  const Dialog(child: SizedBox(width: 300, height: 200)),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final dialog = tester.getCenter(find.byType(Dialog));
    expect(await _wheel(tester, dialog, const Offset(-5, 0)), [false]);
  });

  testWidgets('once the last guard is gone, the browser gets what nothing '
      'uses', (tester) async {
    await tester.pumpWidget(
      const BrowserSwipeGuard(
        child: BrowserSwipeGuard(child: SizedBox.expand()),
      ),
    );
    expect(await _wheel(tester, _rows, const Offset(-5, 0)), [false]);

    await tester.pumpWidget(const BrowserSwipeGuard(child: SizedBox.expand()));
    expect(await _wheel(tester, _rows, const Offset(-5, 0)), [false]);

    await tester.pumpWidget(const SizedBox.expand());
    expect(await _wheel(tester, _rows, const Offset(-5, 0)), [true]);
  });
}

Future<void> _pump(WidgetTester tester, Widget page) => tester.pumpWidget(
  MaterialApp(
    theme: buildAppTheme(defaultTokens),
    home: AdminScope(child: page),
  ),
);

/// What the app answered the browser for one trackpad scroll: `true` lets the
/// browser act on it, which for a sideways swipe on a Mac is "back".
Future<List<bool>> _wheel(WidgetTester tester, Offset at, Offset delta) async {
  final answers = <bool>[];
  await tester.sendEventToBinding(
    PointerScrollEvent(
      kind: PointerDeviceKind.trackpad,
      position: at,
      scrollDelta: delta,
      onRespond: ({required allowPlatformDefault}) =>
          answers.add(allowPlatformDefault),
    ),
  );
  await tester.pump();
  return answers;
}
