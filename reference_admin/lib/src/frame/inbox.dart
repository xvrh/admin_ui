import 'package:admin_ui/theme.dart';
import 'package:admin_ui/widgets.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:material_ui/material_ui.dart';

import '../api/shop_api.dart';
import '../keys/shell_keys.dart';
import '../l10n/money.dart';
import '../l10n/ref_strings.dart';
import '../routing/route_parser.dart';
import '../services.dart';

/// The top bar's bell: today's and earlier notifications, worded in the
/// app's language, each opening the page it is about.
///
/// A window wide enough drops the inbox down from the bell. On a phone the
/// bell opens it in a sheet as wide as the screen, above the frame, which
/// follows [notifications] as they change.
class FrameInbox extends StatelessWidget {
  final ValueListenable<List<AppNotification>> notifications;

  /// Marks one read here, before the shop answers.
  final void Function(String id) onRead;
  final VoidCallback onAllRead;

  const FrameInbox({
    super.key,
    required this.notifications,
    required this.onRead,
    required this.onAllRead,
  });

  @override
  Widget build(BuildContext context) {
    final compact = AdminBreakpoint.of(context).isCompact;
    return ValueListenableBuilder(
      valueListenable: notifications,
      builder: (context, notifications, _) {
        final strings = context.strings.shell;
        final sections = _sections(context, notifications);
        final onMarkAllRead = notifications.any((n) => !n.read)
            ? () => _markAllRead(context)
            : null;
        if (!compact) {
          return NotificationCenter(
            key: ShellKeys.bell,
            title: strings.notifications,
            sections: sections,
            showUnreadFilter: true,
            onMarkAllRead: onMarkAllRead,
          );
        }
        return NotificationBell(
          key: ShellKeys.bell,
          title: strings.notifications,
          unreadCount: notifications.where((n) => !n.read).length,
          onPressed: () => _openSheet(context),
        );
      },
    );
  }

  /// The inbox in a sheet over the whole screen, from the bell's side.
  void _openSheet(BuildContext context) {
    final modals = ModalAnchor.of(context);
    modals.showSheet<void>(
      side: SideSheetSide.end,
      width: double.infinity,
      builder: (sheet) => ValueListenableBuilder(
        valueListenable: notifications,
        builder: (sheet, notifications, _) {
          final title = sheet.strings.shell.notifications;
          return SideSheet(
            semanticLabel: title,
            child: NotificationInbox(
              title: title,
              sections: _sections(sheet, notifications),
              showUnreadFilter: true,
              onMarkAllRead: notifications.any((n) => !n.read)
                  ? () => _markAllRead(sheet)
                  : null,
              onDismiss: modals.close,
            ),
          );
        },
      ),
    );
  }

  /// [notifications] as rows, today's and earlier ones apart.
  List<NotificationSection> _sections(
    BuildContext context,
    List<AppNotification> notifications,
  ) {
    final strings = context.strings.shell;
    final language = Localizations.localeOf(context).languageCode;
    final now = clock.now();
    final today = DateTime(now.year, now.month, now.day);
    NotificationItem item(AppNotification n) => NotificationItem(
      title: strings.notificationTitle(n.kind, inLanguage(n.subject, language)),
      body: strings.notificationBody(n.kind, n.actor),
      timestamp: formatAgo(context, n.at, now),
      icon: switch (n.kind) {
        NotificationKind.lowStock => Icons.inventory_2_outlined,
        NotificationKind.newOrder => Icons.shopping_bag_outlined,
        NotificationKind.refundRequest => Icons.undo_outlined,
        NotificationKind.mention => Icons.alternate_email,
        NotificationKind.system => Icons.info_outline,
      },
      unread: !n.read,
      onTap: () => _open(context, n),
      onReadChanged: n.read ? null : (_) => _markRead(context, n),
    );

    final todays = [
      for (final n in notifications)
        if (!n.at.isBefore(today)) item(n),
    ];
    final earlier = [
      for (final n in notifications)
        if (n.at.isBefore(today)) item(n),
    ];
    return [
      if (todays.isNotEmpty)
        NotificationSection(title: strings.today, items: todays),
      if (earlier.isNotEmpty)
        NotificationSection(title: strings.earlier, items: earlier),
    ];
  }

  void _markRead(BuildContext context, AppNotification n) {
    onRead(n.id);
    context.api.markRead(n.id).ignore();
  }

  void _markAllRead(BuildContext context) {
    onAllRead();
    context.api.markAllRead().ignore();
  }

  void _open(BuildContext context, AppNotification n) {
    final router = context.services.router;
    if (!n.read) _markRead(context, n);
    router.go(AppRouteParser.parse(Uri.parse(n.route)));
  }
}
