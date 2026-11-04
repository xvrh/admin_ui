import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// The kit's tokens with the medium breakpoint at 800 rather than 600.
final _late = defaultTokens.copyWith(
  breakpoints: const AdminBreakpoints(medium: 800),
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required AdminTokens tokens,
  double width = 700,
}) async {
  tester.view.physicalSize = Size(width, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(tokens),
      home: Scaffold(body: child),
    ),
  );
  // Past the theme's cross-fade, whose breakpoints snap halfway.
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the top bar folds its search under the theme\'s medium '
      'breakpoint', (tester) async {
    Widget bar() => Column(
      children: [
        TopBar(
          search: CommandTrigger(onTap: () {}),
          onSearch: () {},
        ),
      ],
    );
    await _pump(tester, bar(), tokens: defaultTokens);
    expect(find.byType(CommandTrigger), findsOneWidget);
    await _pump(tester, bar(), tokens: _late);
    expect(find.byType(CommandTrigger), findsNothing);
    expect(find.widgetWithIcon(IconAction, Icons.search_rounded), findsOne);
  });

  testWidgets('the page gutter narrows under the theme\'s medium '
      'breakpoint', (tester) async {
    late BuildContext context;
    final probe = Builder(
      builder: (c) {
        context = c;
        return const SizedBox();
      },
    );
    await _pump(tester, probe, tokens: defaultTokens);
    expect(PageHeader.gutterOf(context), AdminSpacing.xxl);
    await _pump(tester, probe, tokens: _late);
    expect(PageHeader.gutterOf(context), AdminSpacing.xl);
  });

  testWidgets('the save bar compacts under the theme\'s medium breakpoint', (
    tester,
  ) async {
    Widget bar() => Column(
      children: [
        SaveBar(state: SaveState.unsaved, onDiscard: () {}, onSave: () {}),
      ],
    );
    await _pump(tester, bar(), tokens: defaultTokens);
    expect(find.text('Discard'), findsOneWidget);
    await _pump(tester, bar(), tokens: _late);
    expect(find.text('Discard'), findsNothing, reason: 'in the ⋯ menu');
  });
}
