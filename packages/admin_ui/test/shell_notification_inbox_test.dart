import 'package:admin_ui/admin_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildAppTheme(defaultTokens),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 360, height: 600, child: child),
    ),
  ),
);

final _close = find.widgetWithIcon(IconAction, Icons.close_rounded);

void main() {
  group('NotificationInbox', () {
    testWidgets('heads itself with its title, and a close button exactly '
        'when it has onDismiss', (tester) async {
      final semantics = tester.ensureSemantics();
      var dismissed = 0;
      await tester.pumpWidget(
        _host(
          NotificationInbox(
            items: const [NotificationItem(title: 'Mentioned you')],
            onDismiss: () => dismissed++,
          ),
        ),
      );
      expect(
        tester.getSemantics(find.text('Notifications')),
        isSemantics(label: 'Notifications', isHeader: true),
      );
      await tester.tap(_close);
      expect(dismissed, 1);
      // The close glyph keeps the rows' inset from the end.
      final glyph = tester.getRect(
        find.descendant(of: _close, matching: find.byType(Icon)),
      );
      expect(360 - glyph.right, AdminSpacing.lg);

      await tester.pumpWidget(
        _host(
          const NotificationInbox(
            items: [NotificationItem(title: 'Mentioned you')],
          ),
        ),
      );
      expect(_close, findsNothing);
      semantics.dispose();
    });

    testWidgets('a row, its action and View all close it before they go on', (
      tester,
    ) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _host(
          NotificationInbox(
            items: [
              NotificationItem(
                title: 'Mentioned you',
                onTap: () => calls.add('row'),
              ),
              NotificationItem(
                title: 'Invited you',
                actionLabel: 'Accept',
                onAction: () => calls.add('action'),
              ),
            ],
            onViewAll: () => calls.add('view all'),
            onDismiss: () => calls.add('dismiss'),
          ),
        ),
      );
      await tester.tap(find.text('Mentioned you'));
      await tester.tap(find.text('Accept'));
      await tester.tap(find.text('View all'));
      expect(calls, [
        'dismiss',
        'row',
        'dismiss',
        'action',
        'dismiss',
        'view all',
      ]);
    });

    testWidgets('fills a bounded height, its footer at the bottom', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          NotificationInbox(
            items: const [NotificationItem(title: 'Mentioned you')],
            onViewAll: () {},
          ),
        ),
      );
      expect(tester.getSize(find.byType(NotificationInbox)).height, 600);
      final viewAll = tester.getRect(
        find.ancestor(of: find.text('View all'), matching: find.byType(Button)),
      );
      expect(viewAll.bottom, 600 - AdminSpacing.xs);
    });

    testWidgets('keeps its own unread filter and Mark all read', (
      tester,
    ) async {
      var marked = 0;
      await tester.pumpWidget(
        _host(
          NotificationInbox(
            items: const [
              NotificationItem(title: 'Mentioned you', unread: true),
              NotificationItem(title: 'Build passed'),
            ],
            showUnreadFilter: true,
            onMarkAllRead: () => marked++,
          ),
        ),
      );
      await tester.tap(find.text('Unread'));
      await tester.pumpAndSettle();
      expect(find.text('Build passed'), findsNothing);
      expect(find.text('Mentioned you'), findsOneWidget);
      await tester.tap(find.text('Mark all read'));
      expect(marked, 1);
    });

    testWidgets('an empty, a loading and a failed inbox fill the panel', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const NotificationInbox()));
      expect(find.byType(EmptyState), findsOneWidget);
      await tester.pumpWidget(_host(const NotificationInbox(loading: true)));
      expect(find.byType(Skeleton), findsWidgets);
      await tester.pumpWidget(
        _host(const NotificationInbox(errorText: 'Offline')),
      );
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
    });

    testWidgets('in a sheet on a phone: as wide as the screen, its header '
        'under the status bar', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(defaultTokens),
          home: AdminScope(
            child: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: NotificationBell(
                    unreadCount: 1,
                    onPressed: () {
                      final modals = ModalAnchor.of(context);
                      modals.showSheet<void>(
                        width: double.infinity,
                        builder: (_) => SideSheet(
                          semanticLabel: 'Notifications',
                          child: NotificationInbox(
                            items: const [
                              NotificationItem(
                                title: 'Mentioned you',
                                unread: true,
                              ),
                            ],
                            onDismiss: modals.close,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(NotificationBell));
      await tester.pumpAndSettle();
      final inbox = tester.getRect(find.byType(NotificationInbox));
      expect(inbox.width, 393);
      expect(inbox.top, 59);
      expect(inbox.bottom, 852 - 34);
      await tester.tap(_close);
      await tester.pumpAndSettle();
      expect(find.byType(NotificationInbox), findsNothing);
    });
  });

  group('NotificationBell', () {
    testWidgets('is named with the unread count, which its badge shows', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var pressed = 0;
      await tester.pumpWidget(
        _host(
          Center(
            child: NotificationBell(
              unreadCount: 3,
              expanded: false,
              onPressed: () => pressed++,
            ),
          ),
        ),
      );
      final bell = find.byType(NotificationBell);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Notifications, 3 unread')),
        isSemantics(
          label: 'Notifications, 3 unread',
          isButton: true,
          hasExpandedState: true,
          isExpanded: false,
        ),
      );
      expect(find.text('3'), findsOneWidget);
      await tester.tap(bell);
      expect(pressed, 1);

      await tester.pumpWidget(
        _host(const Center(child: NotificationBell(title: 'Inbox'))),
      );
      expect(find.bySemanticsLabel('Inbox'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      semantics.dispose();
    });
  });

  testWidgets('NotificationCenter\'s dropdown has no close button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Center(
          child: NotificationCenter(
            items: [NotificationItem(title: 'Mentioned you')],
          ),
        ),
      ),
    );
    await tester.tap(find.byType(NotificationBell));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationInbox), findsOneWidget);
    expect(_close, findsNothing);
  });
}
