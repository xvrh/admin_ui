import 'package:admin_ui/src/common/ui/list_row.dart';
import 'package:admin_ui/src/theme/theme.dart';
import 'package:admin_ui/src/theme/themes/iris.dart';
import 'package:admin_ui/src/theme/tokens.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The fill the row paints, or null for none.
Color? _fill(WidgetTester tester, Finder row) {
  final box = find.descendant(of: row, matching: find.byType(ColoredBox));
  if (box.evaluate().isEmpty) return null;
  return tester.widget<ColoredBox>(box.first).color;
}

Future<TestGesture> _mouseOver(WidgetTester tester, Finder target) async {
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  addTearDown(mouse.removePointer);
  await mouse.addPointer(location: tester.getCenter(target));
  await tester.pump();
  return mouse;
}

MouseCursor? _cursor() =>
    RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1);

void main() {
  final tokens = irisTheme.tokens;
  final palette = tokens.palette;

  testWidgets('a tap calls onTap, under the hand and the state layer', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _Host(
        ListRow('Order #10482', subtitle: 'Paid', onTap: () => taps++),
        tokens: tokens,
      ),
    );
    final row = find.byType(ListRow);
    expect(_fill(tester, row), isNull);

    await _mouseOver(tester, row);
    expect(_cursor(), SystemMouseCursors.click);
    expect(_fill(tester, row), palette.hoverOverlay);

    await tester.tap(row);
    expect(taps, 1);
  });

  testWidgets('the selected row is filled and announced as selected', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _Host(
        Column(
          children: [
            ListRow('Order #10481', key: const Key('other'), onTap: () {}),
            ListRow(
              'Order #10482',
              key: const Key('picked'),
              selected: true,
              onTap: () {},
            ),
          ],
        ),
        tokens: tokens,
      ),
    );
    final picked = find.byKey(const Key('picked'));
    final other = find.byKey(const Key('other'));

    expect(_fill(tester, picked), palette.tableRowSelected);
    expect(_fill(tester, other), isNull);
    // The node is the row's own, which its text merges into.
    expect(
      tester.getSemantics(find.text('Order #10482')),
      isSemantics(
        label: 'Order #10482',
        isButton: true,
        hasTapAction: true,
        hasSelectedState: true,
        isSelected: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Order #10481')),
      isSemantics(isButton: true, isSelected: false),
    );

    // Hover lays the state layer over the selection, never under it.
    await _mouseOver(tester, picked);
    expect(
      _fill(tester, picked),
      Color.alphaBlend(palette.hoverOverlay, palette.tableRowSelected),
    );
    semantics.dispose();
  });

  testWidgets('a row without onTap is read, but is no button', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _Host(
        const ListRow('Invoice 2026-031.pdf', subtitle: 'Archived'),
        tokens: tokens,
      ),
    );
    final row = find.byType(ListRow);
    expect(
      tester.getSemantics(find.text('Archived')),
      isSemantics(
        label: 'Invoice 2026-031.pdf\nArchived',
        isButton: false,
        hasTapAction: false,
        isFocusable: false,
      ),
    );

    await _mouseOver(tester, row);
    expect(_cursor(), SystemMouseCursors.basic);
    expect(_fill(tester, row), isNull);
    semantics.dispose();
  });

  for (final direction in TextDirection.values) {
    testWidgets(
      'a long title ends in an ellipsis and leaves the trailing widget '
      'its width (${direction.name})',
      (tester) async {
        Widget host(String title, double width) => _Host(
          Directionality(
            textDirection: direction,
            child: SizedBox(
              width: width,
              child: ListRow(
                title,
                subtitle: 'release/4.2 · 9c41e07 · started by the schedule',
                leading: const Icon(Icons.rocket_launch_outlined),
                trailing: const Text('12 min ago'),
                onTap: () {},
              ),
            ),
          ),
          tokens: tokens,
        );

        await tester.pumpWidget(host('web', 600));
        final width = tester.getSize(find.text('12 min ago')).width;

        const title =
            'deploy · release 4.2.0 to the production cluster, eu-west and '
            'us-east, after the migration window';
        await tester.pumpWidget(host(title, 280));

        expect(tester.takeException(), isNull);
        expect(
          tester
              .renderObject<RenderParagraph>(find.text(title))
              .didExceedMaxLines,
          isTrue,
        );
        final row = tester.getRect(find.byType(ListRow));
        final end = tester.getRect(find.text('12 min ago'));
        final start = tester.getRect(find.byIcon(Icons.rocket_launch_outlined));
        expect(end.width, width);
        if (direction == TextDirection.ltr) {
          expect(end.right, lessThanOrEqualTo(row.right));
          expect(start.left, lessThan(end.left));
        } else {
          expect(end.left, greaterThanOrEqualTo(row.left));
          expect(start.right, greaterThan(end.right));
        }
      },
    );
  }
}

class _Host extends StatelessWidget {
  final Widget child;
  final AdminTokens tokens;
  const _Host(this.child, {required this.tokens});

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: buildAppTheme(tokens),
    home: Scaffold(body: Center(child: child)),
  );
}
