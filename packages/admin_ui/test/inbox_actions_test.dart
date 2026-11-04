import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'shipped_palettes.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(body: Center(child: child)),
);

final _bell = find.byIcon(Icons.notifications_none_rounded);
final _more = find.byIcon(Icons.more_horiz_rounded);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(_bell);
  await tester.pumpAndSettle();
}

/// The opacity the row's menu button is drawn at.
double _menuOpacity(WidgetTester tester, int index) => tester
    .widget<Opacity>(
      find.ancestor(of: _more.at(index), matching: find.byType(Opacity)).first,
    )
    .opacity;

bool _focused(WidgetTester tester, Finder finder) =>
    Focus.of(tester.element(finder)).hasPrimaryFocus;

void main() {
  group('the row menu', () {
    testWidgets('holds the read toggle, the host entries, then Dismiss', (
      tester,
    ) async {
      final read = <bool>[];
      var dismissed = 0;
      var pinned = 0;
      await tester.pumpWidget(
        _host(
          NotificationCenter(
            items: [
              NotificationItem(
                title: 'Mentioned you',
                unread: true,
                onReadChanged: read.add,
                onDismiss: () => dismissed++,
                menu: [
                  MenuItem(
                    'Pin',
                    icon: Icons.push_pin_outlined,
                    onSelect: () => pinned++,
                  ),
                ],
              ),
              NotificationItem(title: 'Digest ready', onReadChanged: read.add),
            ],
          ),
        ),
      );
      await _open(tester);

      // Hidden, the menu button takes no pointer: a click there is the row's.
      await tester.tap(_more.first, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Mark as read'), findsNothing);
      expect(find.text('Mentioned you'), findsNothing, reason: 'the row ran');
      await _open(tester);

      // Under the pointer the row shows its menu button.
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(
        location: tester.getCenter(find.text('Mentioned you')),
      );
      await tester.pump();
      expect(_menuOpacity(tester, 0), 1);
      expect(_menuOpacity(tester, 1), 0);

      await tester.tap(_more.first);
      await tester.pumpAndSettle();
      expect(find.text('Mark as read'), findsOneWidget);
      expect(find.text('Pin'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Mark as read')).dy,
        lessThan(tester.getTopLeft(find.text('Pin')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Pin')).dy,
        lessThan(tester.getTopLeft(find.text('Dismiss')).dy),
      );

      await tester.tap(find.text('Mark as read'));
      await tester.pumpAndSettle();
      expect(read, [true]);
      expect(
        find.text('Digest ready'),
        findsOneWidget,
        reason: 'the inbox stays open for more triage',
      );

      await tester.tap(_more.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pin'));
      await tester.pumpAndSettle();
      expect(pinned, 1);

      await tester.tap(_more.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
      expect(dismissed, 1);
      await mouse.removePointer();
    });

    testWidgets('a read row offers Mark as unread, which reports false', (
      tester,
    ) async {
      final read = <bool>[];
      await tester.pumpWidget(
        _host(
          NotificationCenter(
            items: [
              NotificationItem(title: 'Digest ready', onReadChanged: read.add),
            ],
          ),
        ),
      );
      await _open(tester);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(
        location: tester.getCenter(find.text('Digest ready')),
      );
      await tester.pump();
      await tester.tap(_more);
      await tester.pumpAndSettle();
      expect(find.text('Mark as read'), findsNothing);
      await tester.tap(find.text('Mark as unread'));
      await tester.pumpAndSettle();
      expect(read, [false]);
      await mouse.removePointer();
    });

    testWidgets('Dismiss shows exactly when onDismiss is set, and a row with '
        'no actions has no menu', (tester) async {
      await tester.pumpWidget(
        _host(
          NotificationCenter(
            items: [
              NotificationItem(title: 'Read only', onReadChanged: (_) {}),
              const NotificationItem(title: 'Nothing to do'),
            ],
          ),
        ),
      );
      await _open(tester);
      expect(_more, findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab); // onto the first row
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab); // onto its menu
      await tester.pump();
      expect(_focused(tester, _more), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Mark as unread'), findsOneWidget);
      expect(find.text('Dismiss'), findsNothing);
      expect(find.byType(MenuDivider), findsNothing);
    });
  });

  testWidgets('the inline action closes the inbox and calls onAction, not '
      'onTap', (tester) async {
    var actions = 0;
    var taps = 0;
    await tester.pumpWidget(
      _host(
        NotificationCenter(
          items: [
            NotificationItem(
              title: 'Invited you',
              actionLabel: 'Accept',
              onAction: () => actions++,
              onTap: () => taps++,
            ),
          ],
        ),
      ),
    );
    await _open(tester);
    expect(find.widgetWithText(Button, 'Accept'), findsOneWidget);

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(actions, 1);
    expect(taps, 0);
    expect(find.text('Invited you'), findsNothing, reason: 'closed');

    await _open(tester);
    await tester.tap(find.text('Invited you'));
    await tester.pumpAndSettle();
    expect(taps, 1, reason: 'a tap on the row still calls onTap');
    expect(find.text('Invited you'), findsNothing);
  });

  testWidgets('Tab visits a row, its inline action, its menu, then the next '
      'row; focus reveals the menu', (tester) async {
    await tester.pumpWidget(
      _host(
        NotificationCenter(
          items: [
            NotificationItem(
              title: 'Mentioned you',
              unread: true,
              actionLabel: 'Reply',
              onAction: () {},
              onTap: () {},
              onDismiss: () {},
            ),
            NotificationItem(
              title: 'Build passed',
              onTap: () {},
              onDismiss: () {},
            ),
          ],
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(_focused(tester, find.text('Mentioned you')), isTrue);
    expect(_menuOpacity(tester, 0), 1, reason: 'the focused row shows it');
    expect(_menuOpacity(tester, 1), 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_focused(tester, find.text('Reply')), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_focused(tester, _more.first), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_focused(tester, find.text('Build passed')), isTrue);
    expect(_menuOpacity(tester, 0), 0);
    expect(_menuOpacity(tester, 1), 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_focused(tester, _more.last), isTrue);

    // Its menu opens on its first item; Escape closes the menu alone and
    // hands focus back to its button.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(_focused(tester, find.text('Dismiss')), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Dismiss'), findsNothing);
    expect(find.text('Build passed'), findsOneWidget, reason: 'inbox open');
    expect(_focused(tester, _more.last), isTrue);
  });

  testWidgets('the controls are named apart from the row', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        NotificationCenter(
          items: [
            NotificationItem(
              title: 'Mentioned you',
              body: 'Can you review the copy?',
              unread: true,
              actionLabel: 'Reply',
              onAction: () {},
              onTap: () {},
              onReadChanged: (_) {},
            ),
          ],
        ),
      ),
    );
    await _open(tester);

    final row = tester.getSemantics(find.text('Mentioned you')).label;
    expect(row, allOf(contains('Mentioned you'), contains('Unread')));
    expect(row, isNot(contains('Reply')));
    expect(row, isNot(contains('More actions')));

    expect(
      tester.getSemantics(_more),
      isSemantics(
        label: 'More actions',
        isButton: true,
        isFocusable: true,
        hasExpandedState: true,
        isExpanded: false,
      ),
      reason: 'announced while hidden, as it stays a Tab stop',
    );
    expect(
      tester.getSemantics(find.text('Reply')),
      isSemantics(label: 'Reply', isButton: true),
    );
    semantics.dispose();
  });

  group('rows with their controls meet the guidelines, the first row '
      'hovered', () {
    for (final MapEntry(key: name, value: palette) in {
      for (final e in shippedPalettes.entries)
        if (!shippedChromePalettes.containsKey(e.key)) e.key: e.value,
    }.entries) {
      testWidgets(name, (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(AdminTokens.from(palette: palette)),
            home: Scaffold(
              body: Center(
                child: NotificationCenter(
                  items: [
                    for (final unread in [true, false])
                      NotificationItem(
                        title: unread ? 'Mentioned you' : 'Invited you',
                        body: 'Can you check the copy?',
                        timestamp: '5 min ago',
                        unread: unread,
                        actionLabel: 'Reply',
                        onAction: () {},
                        onTap: () {},
                        onReadChanged: (_) {},
                        onDismiss: () {},
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        await _open(tester);
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(
          location: tester.getCenter(find.text('Mentioned you')),
        );
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(_targetSize));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await mouse.removePointer();
        semantics.dispose();
      });
    }
  });
}

/// WCAG 2.2 SC 2.5.8: a pointer target of at least 24 by 24 CSS pixels.
const _targetSize = MinimumTapTargetGuideline(
  size: Size(24, 24),
  link: 'https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum',
);
