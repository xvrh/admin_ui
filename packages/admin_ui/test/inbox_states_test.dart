import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(body: Center(child: child)),
);

final _bell = find.byIcon(Icons.notifications_none_rounded);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(_bell);
  await tester.pumpAndSettle();
}

const _today = NotificationSection(
  title: 'Today',
  items: [
    NotificationItem(title: 'Mentioned you', unread: true),
    NotificationItem(title: 'Build passed'),
  ],
);

const _earlier = NotificationSection(
  title: 'Earlier',
  items: [
    NotificationItem(title: 'Invited you', unread: true),
    NotificationItem(title: 'Digest ready'),
  ],
);

void main() {
  testWidgets('sections caption their rows in order, and the badge counts '
      'the unread rows of every section', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(const NotificationCenter(sections: [_today, _earlier])),
    );
    expect(find.text('2'), findsOneWidget);
    expect(tester.getSemantics(_bell).label, 'Notifications, 2 unread');

    await _open(tester);
    // Iris sets labels in capitals; the caption is the theme's label case.
    final today = find.text('TODAY');
    final earlier = find.text('EARLIER');
    expect(today, findsOneWidget);
    expect(earlier, findsOneWidget);
    double top(Finder f) => tester.getTopLeft(f).dy;
    expect(top(today), lessThan(top(find.text('Mentioned you'))));
    expect(top(find.text('Build passed')), lessThan(top(earlier)));
    expect(top(earlier), lessThan(top(find.text('Invited you'))));
    expect(
      tester.getSemantics(today),
      isSemantics(label: 'Today', isHeader: true),
    );
    semantics.dispose();
  });

  testWidgets('items and sections are either or', (tester) async {
    await tester.pumpWidget(
      _host(
        const NotificationCenter(
          items: [NotificationItem(title: 'Loose')],
          sections: [_today],
        ),
      ),
    );
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('rows sit on the 4px grid', (tester) async {
    await tester.pumpWidget(
      _host(
        NotificationCenter(
          sections: [
            NotificationSection(
              title: 'Today',
              items: [
                const NotificationItem(title: 'Title only'),
                const NotificationItem(title: 'With time', timestamp: 'Now'),
                const NotificationItem(
                  title: 'With a body',
                  body: 'And some detail',
                  timestamp: '5 min ago',
                  icon: Icons.check_rounded,
                  unread: true,
                ),
                NotificationItem(
                  title: 'With an action',
                  timestamp: 'Yesterday',
                  actionLabel: 'Accept',
                  onAction: () {},
                  onDismiss: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await _open(tester);
    for (final title in [
      'TODAY',
      'Title only',
      'With time',
      'With a body',
      'With an action',
    ]) {
      // The row: the first box around the title as wide as the panel.
      final row = find
          .ancestor(of: find.text(title), matching: find.byType(Semantics))
          .evaluate()
          .map((e) => e.renderObject! as RenderBox)
          .firstWhere((box) => box.size.width == 340);
      expect(row.size.height % 4, 0, reason: '$title: ${row.size.height}');
    }
  });

  testWidgets('loading with no rows shows three skeleton rows, announced', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_host(const NotificationCenter(loading: true)));
    await tester.tap(_bell);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SkeletonGroup), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is Skeleton && w.width == w.height && w.height == 28,
      ),
      findsNWidgets(3),
    );
    expect(find.bySemanticsLabel('Loading…'), findsOneWidget);
    expect(find.byType(EmptyState), findsNothing);
    semantics.dispose();
  });

  testWidgets('a failed load with no rows is an ErrorState with a retry', (
    tester,
  ) async {
    var retried = 0;
    await tester.pumpWidget(
      _host(
        NotificationCenter(
          errorText: 'The server did not answer.',
          onRetry: () => retried++,
        ),
      ),
    );
    await _open(tester);
    expect(find.byType(ErrorState), findsOneWidget);
    expect(find.text('Couldn’t load notifications'), findsOneWidget);
    expect(find.text('The server did not answer.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retried, 1);
  });

  testWidgets('a failed load below rows keeps them, with a retry row', (
    tester,
  ) async {
    var retried = 0;
    await tester.pumpWidget(
      _host(
        NotificationCenter(
          items: const [NotificationItem(title: 'Mentioned you')],
          errorText: '',
          hasMore: true,
          onLoadMore: () {},
          onRetry: () => retried++,
        ),
      ),
    );
    await _open(tester);
    expect(find.text('Mentioned you'), findsOneWidget);
    expect(find.byType(ErrorState), findsNothing);
    expect(find.text('Couldn’t load notifications'), findsOneWidget);
    expect(find.text('Load more'), findsNothing, reason: 'the error wins');
    await tester.tap(find.text('Retry'));
    expect(retried, 1);
  });

  testWidgets('hasMore ends the list in Load more, busy while loading', (
    tester,
  ) async {
    var more = 0;
    Widget inbox({required bool loading}) => _host(
      NotificationCenter(
        items: const [NotificationItem(title: 'Mentioned you')],
        hasMore: true,
        loading: loading,
        onLoadMore: () => more++,
      ),
    );
    await tester.pumpWidget(inbox(loading: false));
    await _open(tester);
    await tester.tap(find.text('Load more'));
    expect(more, 1);

    await tester.pumpWidget(inbox(loading: true));
    await tester.pump();
    expect(find.text('Mentioned you'), findsOneWidget, reason: 'rows stay');
    expect(find.byType(Skeleton), findsNothing);
    final button = find.ancestor(
      of: find.text('Load more'),
      matching: find.byType(Button),
    );
    expect(tester.widget<Button>(button).loading, isTrue);
    await tester.tap(button, warnIfMissed: false);
    expect(more, 1);
  });

  testWidgets('an empty inbox is an EmptyState with the bell and emptyText', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const NotificationCenter(emptyText: 'Nothing here')),
    );
    await _open(tester);
    final empty = tester.widget<EmptyState>(find.byType(EmptyState));
    expect(empty.title, 'Nothing here');
    expect(empty.icon, Icons.notifications_none_rounded);
  });

  testWidgets('the unread filter keeps the unread rows, drops emptied '
      'sections, and outlasts a close', (tester) async {
    await tester.pumpWidget(
      _host(
        const NotificationCenter(
          sections: [
            _today,
            NotificationSection(
              title: 'Older',
              items: [NotificationItem(title: 'Archived')],
            ),
          ],
          showUnreadFilter: true,
        ),
      ),
    );
    await _open(tester);
    expect(find.text('Build passed'), findsOneWidget);

    await tester.tap(find.text('Unread'));
    await tester.pumpAndSettle();
    expect(find.text('Mentioned you'), findsOneWidget);
    expect(find.text('Build passed'), findsNothing);
    expect(find.text('OLDER'), findsNothing, reason: 'no unread row left');

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await _open(tester);
    expect(find.text('Build passed'), findsNothing);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.text('Build passed'), findsOneWidget);
    expect(find.text('OLDER'), findsOneWidget);
  });

  testWidgets('Unread with nothing unread says the inbox is caught up', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const NotificationCenter(
          items: [NotificationItem(title: 'Digest ready')],
          showUnreadFilter: true,
        ),
      ),
    );
    await _open(tester);
    await tester.tap(find.text('Unread'));
    await tester.pumpAndSettle();
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('You’re all caught up'), findsOneWidget);
  });

  testWidgets('View all closes the inbox and calls onViewAll; a footer wins', (
    tester,
  ) async {
    var viewed = 0;
    await tester.pumpWidget(
      _host(
        NotificationCenter(
          items: const [NotificationItem(title: 'Mentioned you')],
          onViewAll: () => viewed++,
        ),
      ),
    );
    await _open(tester);
    await tester.tap(find.text('View all'));
    await tester.pumpAndSettle();
    expect(viewed, 1);
    expect(find.text('Mentioned you'), findsNothing);

    await tester.pumpWidget(
      _host(
        NotificationCenter(
          items: const [NotificationItem(title: 'Mentioned you')],
          onViewAll: () => viewed++,
          footer: const Text('Custom footer'),
        ),
      ),
    );
    await _open(tester);
    expect(find.text('Custom footer'), findsOneWidget);
    expect(find.text('View all'), findsNothing);
  });
}
