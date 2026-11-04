import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'shipped_palettes.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

const _items = [
  NotificationItem(title: 'Mentioned you', unread: true),
  NotificationItem(title: 'Build passed', unread: true),
  NotificationItem(title: 'Digest ready'),
];

void main() {
  testWidgets('badge shows the unread count and opens the inbox', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const NotificationCenter(items: _items)));

    expect(find.text('2'), findsOneWidget); // two unread
    expect(find.text('Mentioned you'), findsNothing); // closed

    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Mentioned you'), findsOneWidget);
    expect(find.text('Digest ready'), findsOneWidget);
  });

  testWidgets('the bell is a Tab stop named with the unread count; Enter '
      'opens the inbox on its first row', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        NotificationCenter(
          items: [
            for (final item in _items)
              NotificationItem(
                title: item.title,
                unread: item.unread,
                onTap: () {},
              ),
          ],
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final bell = find.descendant(
      of: find.byType(NotificationCenter),
      matching: find.byType(GestureDetector),
    );
    expect(
      tester.getSemantics(bell.first),
      isSemantics(
        label: 'Notifications, 2 unread',
        isButton: true,
        isFocused: true,
        hasExpandedState: true,
        isExpanded: false,
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(
      Focus.of(tester.element(find.text('Mentioned you'))).hasPrimaryFocus,
      isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Mentioned you'), findsNothing);
    semantics.dispose();
  });

  testWidgets('mark all read fires', (tester) async {
    var marked = false;
    await tester.pumpWidget(
      _host(
        NotificationCenter(items: _items, onMarkAllRead: () => marked = true),
      ),
    );

    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark all read'));
    expect(marked, isTrue);
  });

  testWidgets('an unread row says so to a screen reader', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        NotificationCenter(
          items: [
            for (final item in _items)
              NotificationItem(
                title: item.title,
                unread: item.unread,
                onTap: () {},
              ),
          ],
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('Mentioned you')).label,
      allOf(contains('Mentioned you'), contains('Unread')),
    );
    expect(
      tester.getSemantics(find.text('Digest ready')).label,
      isNot(contains('Unread')),
    );
    semantics.dispose();
  });

  testWidgets('empty inbox shows the empty text', (tester) async {
    await tester.pumpWidget(
      _host(const NotificationCenter(items: [], emptyText: 'Nothing here')),
    );

    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Nothing here'), findsOneWidget);
  });

  const teal = Color(0xFF0D9488);
  for (final (name, palette) in [
    ('Iris Dark + Teal', irisDarkPalette.branded(teal)),
    ('Material Dark', materialDarkPalette),
    ('Carbon Dark + Teal', carbonDarkPalette.branded(teal)),
    ('shadcn Dark', shadcnDarkPalette),
    ('Ant Light', antPalette),
  ]) {
    testWidgets('$name: unread rows stay readable on the primary tint', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(AdminTokens.from(palette: palette)),
          home: Scaffold(
            body: Center(
              child: NotificationCenter(
                items: [
                  NotificationItem(
                    title: 'Build passed',
                    body: 'main · #1482',
                    timestamp: '1 hour ago',
                    icon: Icons.check_circle_outline_rounded,
                    color: palette.success,
                    unread: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pumpAndSettle();

      final tint = palette.primaryFaint;
      Color textColor(String text) =>
          tester.widget<Text>(find.text(text)).style!.color!;
      expect(
        contrastRatio(textColor('Build passed'), tint),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrastRatio(textColor('main · #1482'), tint),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrastRatio(textColor('1 hour ago'), tint),
        greaterThanOrEqualTo(4.5),
      );

      // The glyph against its own 12% wash of the accent over the tint.
      final glyph = tester
          .widget<Icon>(find.byIcon(Icons.check_circle_outline_rounded))
          .color!;
      final wash = Color.alphaBlend(
        palette.success.withValues(alpha: 0.12),
        tint,
      );
      expect(contrastRatio(glyph, wash), greaterThanOrEqualTo(3));
    });
  }

  group(
    'the unread dot holds 3:1 on its row, at rest and under the pointer',
    () {
      const brands = {
        'Default': null,
        'Crimson': Color(0xFFE11D48),
        'Violet': Color(0xFF7C3AED),
        'Teal': Color(0xFF0D9488),
        'Amber': Color(0xFFD97706),
      };
      for (final MapEntry(key: name, value: base) in shippedPalettes.entries) {
        for (final MapEntry(key: brand, value: seed) in brands.entries) {
          final p = seed == null ? base : base.branded(seed);
          testWidgets('$name · $brand', (tester) async {
            await tester.pumpWidget(
              MaterialApp(
                theme: buildAppTheme(AdminTokens.from(palette: p)),
                home: const Scaffold(
                  body: Center(
                    child: NotificationCenter(
                      items: [
                        NotificationItem(
                          title: 'Mentioned you',
                          body: 'Can you review the copy?',
                          unread: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            await tester.tap(find.byIcon(Icons.notifications_none_rounded));
            await tester.pumpAndSettle();

            final dot = tester.widget<Container>(
              find.byWidgetPredicate(
                (w) =>
                    w is Container &&
                    w.decoration is BoxDecoration &&
                    (w.decoration! as BoxDecoration).shape == BoxShape.circle &&
                    w.constraints == BoxConstraints.tight(const Size(8, 8)),
              ),
            );
            final color = (dot.decoration! as BoxDecoration).color!;
            final body = tester
                .widget<Text>(find.text('Can you review the copy?'))
                .style!
                .color!;
            for (final (fill, on) in [
              (p.primaryFaint, 'the unread tint'),
              (p.listHighlight, 'the hovered row'),
              (p.surface, 'the surface'),
            ]) {
              expect(
                contrastRatio(color, fill),
                greaterThanOrEqualTo(3),
                reason: 'the dot on $on',
              );
              expect(
                contrastRatio(body, fill),
                greaterThanOrEqualTo(4.5),
                reason: 'the body on $on',
              );
            }
          });
        }
      }
    },
  );
}
