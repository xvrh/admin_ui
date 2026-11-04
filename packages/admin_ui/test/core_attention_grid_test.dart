import 'dart:io';

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _tokens = defaultTokens;
final _c = _tokens.palette;

Widget _host(Widget child, {double width = 800}) => MaterialApp(
  theme: buildAppTheme(_tokens),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: width, child: child),
    ),
  ),
);

AttentionItem _item({
  String label = 'requests to approve',
  int count = 5,
  Severity tone = Severity.info,
  String? caption = 'oldest 3 days ago',
  VoidCallback? onTap,
}) => AttentionItem(
  label: label,
  count: count,
  icon: Icons.fact_check_outlined,
  tone: tone,
  caption: caption,
  onTap: onTap,
);

/// The fill of the tile holding [text].
Color _fillOf(WidgetTester tester, String text) {
  final panel = tester.widget<Container>(
    find.ancestor(of: find.text(text), matching: find.byType(Container)).last,
  );
  return (panel.decoration! as BoxDecoration).color!;
}

void main() {
  testWidgets('a tile says its count, label and caption, and taps', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      _host(AttentionGrid(items: [_item(onTap: () => taps++)])),
    );
    expect(find.text('Needs your attention'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('requests to approve'), findsOneWidget);
    expect(
      find.bySemanticsLabel('5 requests to approve, oldest 3 days ago'),
      findsOneWidget,
    );
    await tester.tap(find.byType(AttentionTile));
    expect(taps, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 2);
    handle.dispose();
  });

  testWidgets('hovering an actionable tile darkens its fill', (tester) async {
    await tester.pumpWidget(_host(AttentionGrid(items: [_item(onTap: () {})])));
    final style = severityStyleOf(
      tester.element(find.byType(AttentionTile)),
      Severity.info,
    );
    expect(_fillOf(tester, 'requests to approve'), style.surface);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(
      location: tester.getCenter(find.byType(AttentionTile)),
    );
    await tester.pump();
    expect(
      _fillOf(tester, 'requests to approve'),
      Color.alphaBlend(_c.hoverOverlay, style.surface),
    );
    await mouse.removePointer();
  });

  testWidgets('a tile with no action is not a button', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(AttentionGrid(items: [_item()])));
    expect(find.byType(Tappable), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    final node = tester.getSemantics(find.byType(AttentionTile));
    expect(node.label, '5 requests to approve, oldest 3 days ago');
    expect(node.getSemanticsData().flagsCollection.isButton, isFalse);
    handle.dispose();
  });

  testWidgets('each tone tints its tile and glyph', (tester) async {
    await tester.pumpWidget(
      _host(
        AttentionGrid(
          items: [
            for (final tone in Severity.values)
              _item(label: tone.name, tone: tone, onTap: () {}),
          ],
        ),
      ),
    );
    final context = tester.element(find.byType(AttentionGrid));
    for (final tone in Severity.values) {
      final style = severityStyleOf(context, tone);
      expect(_fillOf(tester, tone.name), style.surface, reason: tone.name);
      final chevron = tester.widget<Icon>(
        find.descendant(
          of: find.ancestor(
            of: find.text(tone.name),
            matching: find.byType(AttentionTile),
          ),
          matching: find.byIcon(Icons.chevron_right_rounded),
        ),
      );
      expect(chevron.color, style.foreground, reason: tone.name);
    }
  });

  testWidgets('tiles flow into as many balanced columns as fit', (
    tester,
  ) async {
    final items = [for (var i = 0; i < 4; i++) _item(label: 'item $i')];
    Set<double> rows() => {
      for (final e in find.byType(AttentionTile).evaluate())
        tester.getRect(find.byWidget(e.widget)).top,
    };
    await tester.pumpWidget(_host(AttentionGrid(items: items), width: 800));
    expect(rows(), hasLength(2), reason: 'three fit at 800: two by two');

    await tester.pumpWidget(_host(AttentionGrid(items: items), width: 300));
    expect(rows(), hasLength(4), reason: 'one per row at 300');
  });

  testWidgets('with nothing to show it says all is caught up', (tester) async {
    await tester.pumpWidget(_host(const AttentionGrid(items: [])));
    expect(find.text('Needs your attention'), findsNothing);
    expect(
      find.text("You're all caught up — nothing needs attention."),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    await tester.pumpWidget(
      _host(const AttentionGrid(items: [], emptyMessage: 'Inbox zero')),
    );
    expect(find.text('Inbox zero'), findsOneWidget);
  });

  testWidgets('loading holds the height of the tiles to come', (tester) async {
    await tester.pumpWidget(_host(AttentionGrid(items: [_item()])));
    final tile = tester.getSize(find.byType(AttentionTile));
    final grid = tester.getSize(find.byType(AttentionGrid));

    await tester.pumpWidget(
      _host(const AttentionGrid(items: [], loading: true, placeholderCount: 1)),
    );
    expect(find.byType(AttentionTile), findsNothing);
    expect(find.byType(Skeleton), findsWidgets);
    expect(find.text('Needs your attention'), findsOneWidget);
    expect(tester.getSize(find.byType(AttentionGrid)), grid);
    final placeholder = tester.getSize(
      find
          .ancestor(
            of: find.byType(Skeleton).first,
            matching: find.byType(Container),
          )
          .last,
    );
    expect(placeholder.height, tile.height);
  });

  testWidgets("loading keeps the tiles' height through a late font load", (
    tester,
  ) async {
    const family = 'Attention late font';
    // Type large enough that the text, not the glyph box, sets the height.
    // Every kit style has a fixed line box, so the late font cannot move
    // the lines: the placeholder only has to match a loaded tile.
    final tokens = AdminTokens.from(
      palette: irisPalette,
      type: const AdminTypeSpec(fontFamily: family, scale: 1.5),
    );
    Widget host(Widget child) => MaterialApp(
      theme: buildAppTheme(tokens),
      home: Scaffold(
        body: DefaultTextStyle(
          style: const TextStyle(),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 800, child: child),
          ),
        ),
      ),
    );
    double placeholder() => tester
        .getSize(
          find
              .ancestor(
                of: find.byType(Skeleton).first,
                matching: find.byType(Container),
              )
              .last,
        )
        .height;

    await tester.pumpWidget(
      host(const AttentionGrid(items: [], loading: true, placeholderCount: 2)),
    );
    final before = placeholder();
    final font = File('example/assets/fonts/IBMPlexSans-Regular.ttf')
        .readAsBytesSync();
    await tester.runAsync(
      () => (FontLoader(
        family,
      )..addFont(Future.value(ByteData.sublistView(font)))).load(),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    final after = placeholder();
    expect(after, before, reason: 'the line boxes do not follow the font');

    await tester.pumpWidget(host(AttentionGrid(items: [_item()])));
    expect(after, tester.getSize(find.byType(AttentionTile)).height);
  });

  testWidgets('loading is announced once, not per bar', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(const AttentionGrid(items: [], loading: true)),
    );
    expect(find.bySemanticsLabel('Loading…'), findsOneWidget);
    handle.dispose();
  });
}
