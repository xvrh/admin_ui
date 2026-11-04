import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

class NotificationCenterDemo extends StatefulWidget {
  @Preview(name: 'Notification center', wrapper: adminUiPreview)
  const NotificationCenterDemo({super.key});

  @override
  State<NotificationCenterDemo> createState() => _NotificationCenterDemoState();
}

/// One sample notification, as a host would keep it.
class _Notice {
  final String id;
  final String title;
  final String? body;
  final String timestamp;
  final bool today;
  final String? person;
  final IconData? icon;
  final String? action;

  const _Notice(
    this.id,
    this.title, {
    this.body,
    required this.timestamp,
    this.today = false,
    this.person,
    this.icon,
    this.action,
  });
}

const _notices = [
  _Notice(
    'mention',
    'Ana Ruiz mentioned you',
    body: '“Can you check the launch checklist?”',
    timestamp: '5 min ago',
    today: true,
    person: 'Ana Ruiz',
    action: 'Reply',
  ),
  _Notice(
    'build',
    'Build passed',
    body: 'main · #1482',
    timestamp: '1 hour ago',
    today: true,
    icon: Icons.check_circle_outline_rounded,
  ),
  _Notice(
    'invite',
    'Sam Ito invited you to Marketing',
    timestamp: 'Yesterday',
    person: 'Sam Ito',
    action: 'Accept',
  ),
  _Notice(
    'digest',
    'Weekly digest is ready',
    timestamp: 'Monday',
    icon: Icons.summarize_outlined,
  ),
];

/// The sample inbox's state, as a host keeps it: which rows are read and
/// which dismissed.
mixin _SampleInbox<T extends StatefulWidget> on State<T> {
  final _read = <String>{'invite', 'digest'};
  final _dismissed = <String>{};

  // Built per frame, not held in state, so the accents follow the live theme
  // (mode and brand switches included).
  NotificationItem _item(BuildContext context, _Notice notice) {
    return NotificationItem(
      title: notice.title,
      body: notice.body,
      timestamp: notice.timestamp,
      leading: notice.person == null ? null : Avatar(name: notice.person),
      icon: notice.icon,
      color: notice.icon == Icons.check_circle_outline_rounded
          ? context.colors.success
          : null,
      unread: !_read.contains(notice.id),
      onTap: () {},
      actionLabel: notice.action,
      onAction: notice.action == null ? null : () {},
      onReadChanged: (read) =>
          setState(() => read ? _read.add(notice.id) : _read.remove(notice.id)),
      onDismiss: () => setState(() => _dismissed.add(notice.id)),
    );
  }

  /// Today's and earlier notifications, the dismissed ones gone; [only]
  /// keeps those ids alone.
  List<NotificationSection> _sections(
    BuildContext context, {
    Set<String>? only,
  }) {
    final shown = _notices.where(
      (n) => !_dismissed.contains(n.id) && (only?.contains(n.id) ?? true),
    );
    return [
      NotificationSection(
        title: 'Today',
        items: [
          for (final n in shown)
            if (n.today) _item(context, n),
        ],
      ),
      NotificationSection(
        title: 'Earlier',
        items: [
          for (final n in shown)
            if (!n.today) _item(context, n),
        ],
      ),
    ];
  }

  void _markAllRead() =>
      setState(() => _read.addAll(_notices.map((n) => n.id)));
}

class _NotificationCenterDemoState extends State<NotificationCenterDemo>
    with _SampleInbox {
  @override
  Widget build(BuildContext context) {
    // The open inboxes side by side, each in a column as wide as its panel,
    // with their bells on one line near the top where the page is wide
    // enough: a popover whose bell lies outside the first window it lays out
    // in measures no room to open in.
    return DemoPage(
      maxWidth: 3 * _panel + 2 * AdminSpacing.xxl + 64,
      children: [
        _Cases([
          _Case(
            'Open — sections and row actions',
            PinnedHover(
              target: (w) => w is Text && w.data == 'Build passed',
              child: PinnedOpen(
                makeRoom: true,
                child: NotificationCenter(
                  // Three rows, so the pinned inbox shows whole.
                  sections: _sections(
                    context,
                    only: const {'mention', 'build', 'digest'},
                  ),
                  onMarkAllRead: _markAllRead,
                  onViewAll: () {},
                  showUnreadFilter: true,
                ),
              ),
            ),
          ),
          const _Case(
            'Loading',
            PinnedOpen(
              makeRoom: true,
              child: NotificationCenter(loading: true),
            ),
          ),
          _Case(
            'Load failed',
            PinnedOpen(
              makeRoom: true,
              child: NotificationCenter(
                errorText: 'The server did not answer.',
                onRetry: () {},
              ),
            ),
          ),
        ]),
        const Gap(AdminSpacing.xxxl),
        _Cases([
          _Case(
            'Bell + inbox (click the bell)',
            NotificationCenter(
              sections: _sections(context),
              onMarkAllRead: _markAllRead,
              onViewAll: () {},
              showUnreadFilter: true,
            ),
          ),
          const _Case('Empty', NotificationCenter()),
        ]),
      ],
    );
  }
}

/// The inbox's width, and so each case's.
const _panel = 340.0;

/// Up to three cases in a row, in equal columns, as many to a row as have
/// room for a whole inbox: a narrower page wraps them onto more rows, so no
/// pinned inbox runs under the next.
class _Cases extends StatelessWidget {
  final List<_Case> cases;

  const _Cases(this.cases);

  static const _gap = AdminSpacing.xxl;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final fit = ((box.maxWidth + _gap) / (_panel + _gap)).floor();
        final columns = fit.clamp(1, 3);
        final width = ((box.maxWidth - (columns - 1) * _gap) / columns)
            .floorToDouble();
        return Wrap(
          spacing: _gap,
          runSpacing: AdminSpacing.xxxl,
          children: [for (final c in cases) SizedBox(width: width, child: c)],
        );
      },
    );
  }
}

/// A captioned case, its bell at the end as an app bar puts it, so its inbox
/// drops in below it, lined up with its end.
class _Case extends StatelessWidget {
  final String caption;
  final Widget child;

  const _Case(this.caption, this.child);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoSection(caption),
        Align(alignment: AlignmentDirectional.centerEnd, child: child),
      ],
    );
  }
}

/// The inbox on a phone: a [NotificationInbox] in a sheet over the whole
/// screen, as a phone's bell ([NotificationBell]) opens it, the header's
/// close button closing it. Drawn in place at a phone's 360px; rendered on
/// a device with insets, its header keeps below the status bar.
class NotificationInboxSheetDemo extends StatefulWidget {
  @Preview(name: 'Notification inbox (phone sheet)', wrapper: adminUiPreview)
  const NotificationInboxSheetDemo({super.key});

  @override
  State<NotificationInboxSheetDemo> createState() =>
      _NotificationInboxSheetDemoState();
}

class _NotificationInboxSheetDemoState extends State<NotificationInboxSheetDemo>
    with _SampleInbox {
  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).width;
    final width = screen < context.breakpoints.medium ? screen : 360.0;
    return ColoredBox(
      color: context.colors.surfaceMuted,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox(
          width: width,
          child: SideSheet(
            semanticLabel: 'Notifications',
            child: NotificationInbox(
              sections: _sections(context),
              onMarkAllRead: _markAllRead,
              showUnreadFilter: true,
              onDismiss: () {},
            ),
          ),
        ),
      ),
    );
  }
}
