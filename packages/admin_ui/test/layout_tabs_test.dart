import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      theme: buildAppTheme(defaultTokens),
      home: Directionality(
        textDirection: direction,
        child: Scaffold(
          body: Align(alignment: Alignment.topLeft, child: child),
        ),
      ),
    );

/// A strip that keeps its own selection, reporting every change.
class _Strip extends StatefulWidget {
  final List<TabItem> tabs;
  final int initial;
  final List<int> changes;

  const _Strip({required this.tabs, required this.changes, this.initial = 0});

  @override
  State<_Strip> createState() => _StripState();
}

class _StripState extends State<_Strip> {
  late int _selected = widget.initial;

  @override
  Widget build(BuildContext context) => Tabs(
    tabs: widget.tabs,
    selected: _selected,
    onChanged: (i) {
      widget.changes.add(i);
      setState(() => _selected = i);
    },
  );
}

const _five = [
  TabItem('Details'),
  TabItem('Pricing'),
  TabItem('Hidden', enabled: false),
  TabItem('SEO'),
  TabItem('Audit'),
];

/// The tab whose label is [label], as the node it announces as.
SemanticsNode _tab(WidgetTester tester, String label) => tester.getSemantics(
  find.descendant(
    of: find.ancestor(of: find.text(label), matching: find.byType(Tappable)),
    matching: find.byType(GestureDetector),
  ),
);

/// Whether keyboard focus sits on the control labelled [label].
bool _focused(WidgetTester tester, String label) {
  final focus = FocusManager.instance.primaryFocus?.context;
  if (focus == null) return false;
  var found = false;
  tester.element(find.text(label)).visitAncestorElements((e) {
    found = e == focus;
    return !found;
  });
  return found;
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the strip is one Tab stop that lands on the selected tab', (
    tester,
  ) async {
    final changes = <int>[];
    await tester.pumpWidget(
      _host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Button('Before', onPressed: () {}),
            SizedBox(
              width: 500,
              child: _Strip(tabs: _five, initial: 3, changes: changes),
            ),
            Button('After', onPressed: () {}),
          ],
        ),
      ),
    );

    await _key(tester, LogicalKeyboardKey.tab); // Before
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_focused(tester, 'SEO'), isTrue);
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_focused(tester, 'After'), isTrue);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await _key(tester, LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    expect(_focused(tester, 'SEO'), isTrue);
    expect(changes, isEmpty);
  });

  testWidgets('arrows move and select, skipping disabled tabs and wrapping', (
    tester,
  ) async {
    final changes = <int>[];
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 500,
          child: _Strip(tabs: _five, changes: changes),
        ),
      ),
    );
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_focused(tester, 'Details'), isTrue);

    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_focused(tester, 'Pricing'), isTrue);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_focused(tester, 'SEO'), isTrue, reason: 'Hidden is disabled');
    await _key(tester, LogicalKeyboardKey.arrowRight);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_focused(tester, 'Details'), isTrue, reason: 'wraps to the start');
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    expect(_focused(tester, 'Audit'), isTrue, reason: 'wraps to the end');
    expect(changes, [1, 3, 4, 0, 4]);

    // Tab now leaves from the newly selected tab, not the first.
    expect(_tab(tester, 'Audit'), isSemantics(isSelected: true));
  });

  testWidgets('Home and End jump to the first and last enabled tabs', (
    tester,
  ) async {
    final changes = <int>[];
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 500,
          child: _Strip(
            tabs: const [
              TabItem('Off', enabled: false),
              ..._five,
              TabItem('Off too', enabled: false),
            ],
            initial: 2,
            changes: changes,
          ),
        ),
      ),
    );
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.end);
    expect(_focused(tester, 'Audit'), isTrue);
    await _key(tester, LogicalKeyboardKey.home);
    expect(_focused(tester, 'Details'), isTrue);
    expect(changes, [5, 1]);
  });

  testWidgets('arrows follow the reading direction right to left', (
    tester,
  ) async {
    final changes = <int>[];
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 500,
          child: _Strip(tabs: _five, initial: 1, changes: changes),
        ),
        direction: TextDirection.rtl,
      ),
    );
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_focused(tester, 'Pricing'), isTrue);
    await _key(tester, LogicalKeyboardKey.arrowLeft);
    expect(_focused(tester, 'SEO'), isTrue);
    await _key(tester, LogicalKeyboardKey.arrowRight);
    expect(_focused(tester, 'Pricing'), isTrue);
    expect(changes, [3, 1]);
  });

  testWidgets('Enter and Space activate the focused tab', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 500,
          child: Tabs(tabs: _five, selected: 0, onChanged: (_) => taps++),
        ),
      ),
    );
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.enter);
    await _key(tester, LogicalKeyboardKey.space);
    expect(taps, 2);
  });

  testWidgets('announces a tab bar of tabs, each label read once', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 500,
          child: Tabs(
            tabs: [
              const TabItem('Details'),
              const TabItem('Comments', trailing: Tag('3')),
              const TabItem('Hidden', enabled: false),
            ],
            selected: 0,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    final details = _tab(tester, 'Details');
    expect(details.getSemanticsData().role, SemanticsRole.tab);
    expect(details.parent!.getSemanticsData().role, SemanticsRole.tabBar);
    expect(
      details,
      isSemantics(
        label: 'Details',
        isSelected: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        isButton: false,
      ),
    );
    expect(_tab(tester, 'Comments'), isSemantics(isSelected: false));
    expect(
      _tab(tester, 'Hidden'),
      isSemantics(isEnabled: false, isFocusable: false, hasTapAction: false),
    );
    handle.dispose();
  });

  testWidgets('tabs keep a fixed height, whatever trails the label', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 500,
          child: Column(
            children: [
              Tabs(
                tabs: [
                  const TabItem('Open'),
                  const TabItem('Comments', trailing: Tag('3')),
                ],
                selected: 0,
                onChanged: (_) {},
              ),
              Tabs(
                size: ControlSize.small,
                tabs: [
                  const TabItem('All'),
                  const TabItem('Mine', trailing: Tag('12')),
                ],
                selected: 0,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    Rect tabRect(String label) => tester.getRect(
      find
          .ancestor(of: find.text(label), matching: find.byType(Tappable))
          .first,
    );
    expect(tabRect('Open').height, 40);
    expect(tabRect('Comments').height, 40);
    expect(tabRect('Open').top, tabRect('Comments').top);
    expect(tabRect('All').height, 32);
    expect(tabRect('Mine').height, 32);
  });

  final overflow = [
    for (final label in [
      'Overview',
      'Content',
      'Translations',
      'Media',
      'Pricing',
      'Inventory',
      'SEO',
      'Audit log',
      'Permissions',
    ])
      TabItem(label),
  ];

  testWidgets('a vertical wheel scrolls an overflowing strip sideways', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 300,
          child: Tabs(tabs: overflow, selected: 0, onChanged: (_) {}),
        ),
      ),
    );
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    expect(scrollable.position.pixels, 0);

    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(
      pointer.hover(tester.getCenter(find.text('Content'))),
    );
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 120)));
    await tester.pump();
    expect(scrollable.position.pixels, 120);

    // Back at the start there is nowhere to go, so the wheel is not taken.
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, -500)));
    await tester.pump();
    expect(scrollable.position.pixels, 0);
  });

  testWidgets('a mouse drag scrolls the strip', (tester) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 300,
          child: Tabs(tabs: overflow, selected: 0, onChanged: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    await tester.dragFrom(
      tester.getCenter(find.text('Content')),
      const Offset(-150, 0),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(scrollable.position.pixels, greaterThan(100));
  });

  testWidgets('the selected tab is scrolled into view, first and on change', (
    tester,
  ) async {
    const width = 300.0;
    var selected = 7;
    late StateSetter setOuter;
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: width,
          child: StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return Tabs(
                tabs: overflow,
                selected: selected,
                onChanged: (_) {},
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    void expectVisible(String label) {
      final rect = tester.getRect(find.text(label));
      expect(rect.left, greaterThanOrEqualTo(0), reason: label);
      expect(rect.right, lessThanOrEqualTo(width), reason: label);
    }

    expectVisible('Audit log');

    setOuter(() => selected = 1);
    await tester.pumpAndSettle();
    expectVisible('Content');
  });

  testWidgets('dropping tabs releases their focus nodes cleanly', (
    tester,
  ) async {
    Widget strip(int count) => _host(
      SizedBox(
        width: 500,
        child: Tabs(
          tabs: [for (var i = 0; i < count; i++) TabItem('Tab $i')],
          selected: 0,
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpWidget(strip(4));
    await _key(tester, LogicalKeyboardKey.tab);
    await _key(tester, LogicalKeyboardKey.end);
    expect(_focused(tester, 'Tab 3'), isTrue);

    await tester.pumpWidget(strip(2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Tab 3'), findsNothing);
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_focused(tester, 'Tab 0'), isTrue);
  });

  group('the focused tab draws the theme FocusRing inside itself', () {
    // Each theme's own ring: offset outside, flush, and inset. Under a brand
    // shadcn's ring is the primary, so FocusRing moves its flush ring out by
    // one.
    for (final (name, palette, spec) in [
      ('Iris', irisPalette, const AdminFocusSpec(width: 2, offset: 2)),
      (
        'Material Dark',
        materialDarkPalette,
        const AdminFocusSpec(width: 3, offset: 2),
      ),
      ('shadcn', shadcnPalette, const AdminFocusSpec(width: 3, offset: 0)),
      (
        'shadcn + Crimson',
        shadcnPalette.branded(const Color(0xFFE11D48)),
        const AdminFocusSpec(width: 3, offset: 0),
      ),
      (
        'Fluent Dark',
        fluentDarkPalette,
        const AdminFocusSpec(width: 2, offset: 0),
      ),
      ('Carbon', carbonPalette, const AdminFocusSpec(width: 2, offset: -2)),
    ]) {
      final offset =
          spec.offset == 0 &&
              contrastRatio(palette.focusRing, palette.primary) < 3
          ? 1.0
          : spec.offset;
      for (final variant in TabsVariant.values) {
        for (final dense in [false, true]) {
          final label =
              '$name, ${variant.name}${dense ? ', dense' : ''}: offset '
              '${spec.offset}, width ${spec.width}';
          testWidgets(label, (tester) async {
            await tester.pumpWidget(
              MaterialApp(
                theme: buildAppTheme(
                  AdminTokens.from(palette: palette, focus: spec),
                ),
                home: Scaffold(
                  body: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: 300,
                      child: Tabs(
                        tabs: [
                          const TabItem('Details'),
                          TabItem(
                            'Pricing',
                            menu: [MenuItem('Rename', onSelect: () {})],
                          ),
                          const TabItem('SEO'),
                        ],
                        selected: 1,
                        variant: variant,
                        size: dense ? ControlSize.small : ControlSize.medium,
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                ),
              ),
            );
            final tab = find
                .ancestor(
                  of: find.text('Pricing'),
                  matching: find.byType(Tappable),
                )
                .first;
            final resting = tester.getRect(tab);
            // The tab's own ring; its caret's comes after it.
            final ring = find
                .descendant(of: tab, matching: find.byType(FocusRing))
                .first;
            expect(tester.widget<FocusRing>(ring).focused, isFalse);

            await _key(tester, LogicalKeyboardKey.tab);
            expect(_focused(tester, 'Pricing'), isTrue);
            expect(tester.widget<FocusRing>(ring).focused, isTrue);
            expect(tester.getRect(tab), resting, reason: 'no layout shift');

            Finder band(Color color) => find.descendant(
              of: ring,
              matching: find.byWidgetPredicate((w) {
                if (w is! DecoratedBox) return false;
                final border = (w.decoration as BoxDecoration).border;
                return border is Border && border.top.color == color;
              }),
            );
            final box = tester.getRect(
              find.descendant(of: ring, matching: find.byType(SizedBox)).first,
            );
            final stroke = band(palette.focusRing);
            expect(stroke, findsOneWidget);
            expect(
              tester.getRect(stroke),
              box.inflate(math.max(0, offset + spec.width)),
              reason: 'the ring stands context.focus.offset off its box',
            );
            if (offset > 0) {
              expect(
                tester.getRect(band(palette.surface)),
                box.inflate(offset),
                reason: 'the surface gap band fills the offset',
              );
            }

            // Inside the tab, so the strip's scroll clip never cuts it, and
            // clear of the selected line tab's underline.
            final outer = tester.getRect(stroke);
            final viewport = tester.getRect(
              find.descendant(
                of: find.byType(Tabs),
                matching: find.byType(Scrollable),
              ),
            );
            expect(resting.contains(outer.topLeft), isTrue);
            expect(
              resting.contains(outer.bottomRight - const Offset(1, 1)),
              isTrue,
            );
            expect(viewport.contains(outer.topLeft), isTrue);
            if (variant == TabsVariant.line) {
              final underline = resting.bottom - 2;
              expect(outer.bottom, lessThan(underline));
            }
          });
        }
      }
    }
  });

  testWidgets('the selected line tab underlines in the control accent', (
    tester,
  ) async {
    // Fluent Dark's brand primary is too dark to mark a selection on its
    // surface; the control accent reaches 3:1.
    const palette = fluentDarkPalette;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(AdminTokens.from(palette: palette)),
        home: Scaffold(
          body: Tabs(
            tabs: const [TabItem('Details'), TabItem('SEO')],
            selected: 0,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    final underline = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(Tabs),
            matching: find.byWidgetPredicate(
              (w) => w is Container && w.constraints?.maxHeight == 2,
            ),
          )
          .first,
    );
    expect(underline.color, palette.controlAccent);
    expect(
      contrastRatio(underline.color!, palette.surface),
      greaterThanOrEqualTo(3),
    );
  });
}
