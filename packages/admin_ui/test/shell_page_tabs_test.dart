import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _page({
  double? maxWidth = 640,
  double? headerMaxWidth,
  bool scrollable = true,
}) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: PageScaffold(
      title: 'Aurora Lamp',
      maxWidth: maxWidth,
      headerMaxWidth: headerMaxWidth,
      scrollable: scrollable,
      tabs: Tabs(
        tabs: const [TabItem('Details'), TabItem('History')],
        selected: 0,
        onChanged: (_) {},
      ),
      body: const SizedBox(
        key: ValueKey('body'),
        width: double.infinity,
        height: 1600,
      ),
    ),
  ),
);

Future<void> _window(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(1200, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(page);
}

void main() {
  testWidgets('the tabs sit under the header, in its column and gutter', (
    tester,
  ) async {
    await _window(tester, _page());
    final title = tester.getRect(find.text('Aurora Lamp'));
    final tabs = tester.getRect(find.byType(Tabs));
    final body = tester.getRect(find.byKey(const ValueKey('body')));

    expect(tabs.top, greaterThan(title.bottom));
    expect(body.top, greaterThan(tabs.bottom));
    // One column: the strip spans the body's width, its first tab under the
    // title's start.
    expect(tabs.left, body.left);
    expect(tabs.right, body.right);
    expect(tabs.width, 640);
    expect(tester.getRect(find.text('Details')).left, greaterThan(title.left));
  });

  testWidgets('a header wider than the body takes the tabs with it', (
    tester,
  ) async {
    await _window(tester, _page(headerMaxWidth: double.infinity));
    final tabs = tester.getRect(find.byType(Tabs));
    final body = tester.getRect(find.byKey(const ValueKey('body')));
    expect(tabs.width, greaterThan(body.width));
    expect(tabs.left, lessThan(body.left));
  });

  for (final scrollable in [true, false]) {
    testWidgets('the body starts a gap below the tabs '
        '(scrollable: $scrollable)', (tester) async {
      await _window(tester, _page(scrollable: scrollable, maxWidth: null));
      final tabs = tester.getRect(find.byType(Tabs));
      final body = tester.getRect(find.byKey(const ValueKey('body')));
      expect(body.top - tabs.bottom, AdminSpacing.xl);
    });
  }

  testWidgets('the tabs stay put while the body scrolls under them', (
    tester,
  ) async {
    await _window(tester, _page());
    final before = tester.getRect(find.byType(Tabs));
    final bodyBefore = tester.getRect(find.byKey(const ValueKey('body')));
    await tester.dragFrom(const Offset(600, 500), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(Tabs)), before);
    expect(
      tester.getRect(find.byKey(const ValueKey('body'))).top,
      lessThan(bodyBefore.top),
    );
  });

  testWidgets('without tabs the body starts right under the header', (
    tester,
  ) async {
    await _window(
      tester,
      MaterialApp(
        theme: buildAppTheme(defaultTokens),
        home: const Scaffold(
          body: PageScaffold(
            title: 'Aurora Lamp',
            body: SizedBox(key: ValueKey('body'), height: 100),
          ),
        ),
      ),
    );
    final header = tester.getRect(find.byType(PageHeader));
    final body = tester.getRect(find.byKey(const ValueKey('body')));
    expect(body.top, header.bottom);
  });
}
