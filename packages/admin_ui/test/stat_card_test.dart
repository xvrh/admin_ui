import 'package:admin_ui/src/common/ui/stat_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 600, child: child)),
  ),
);

void main() {
  testWidgets('renders label, value, delta and caption', (tester) async {
    await tester.pumpWidget(
      _host(
        const StatCard(
          label: 'Revenue',
          value: r'$48.2k',
          delta: StatDelta('12%', direction: TrendDirection.up),
          caption: 'vs last month',
        ),
      ),
    );

    expect(find.text('Revenue'), findsOneWidget);
    expect(find.text(r'$48.2k'), findsOneWidget);
    expect(find.text('12%'), findsOneWidget);
    expect(find.text('vs last month'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
  });

  testWidgets('onTap fires', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _host(StatCard(label: 'X', value: '1', onTap: () => tapped = true)),
    );

    await tester.tap(find.text('1'));
    expect(tapped, isTrue);
  });

  testWidgets('StatGrid lays out one slot per child', (tester) async {
    await tester.pumpWidget(
      _host(
        const StatGrid(
          minTileWidth: 160,
          children: [
            StatCard(label: 'A', value: '1'),
            StatCard(label: 'B', value: '2'),
            StatCard(label: 'C', value: '3'),
          ],
        ),
      ),
    );

    expect(find.byType(StatCard), findsNWidgets(3));
    // 600 / 160 → 3 columns, so all three sit on the same row.
    expect(
      tester.getTopLeft(find.text('A')).dy,
      tester.getTopLeft(find.text('C')).dy,
    );
  });

  testWidgets('StatGrid balances its rows instead of leaving an orphan', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const StatGrid(
          minTileWidth: 160,
          children: [
            StatCard(label: 'A', value: '1'),
            StatCard(label: 'B', value: '2'),
            StatCard(label: 'C', value: '3'),
            StatCard(label: 'D', value: '4'),
          ],
        ),
      ),
    );

    // Room for three, but four tiles: 2 + 2 rather than 3 + 1.
    double top(String label) => tester.getTopLeft(find.text(label)).dy;
    double left(String label) => tester.getTopLeft(find.text(label)).dx;
    expect(top('B'), top('A'));
    expect(top('C'), greaterThan(top('B')));
    expect(top('D'), top('C'));
    expect(left('C'), left('A'));
    expect(left('D'), left('B'));
  });
}
