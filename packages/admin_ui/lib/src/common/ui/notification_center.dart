/// @docImport 'avatar.dart';
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../text_metrics.dart';
import 'button.dart';
import 'count_badge.dart';
import 'empty_state.dart';
import 'error_state.dart';
import 'icon_action.dart';
import 'menu.dart';
import 'menu_button.dart';
import 'popover.dart';
import 'popover_menu.dart';
import 'segmented.dart';
import 'skeleton.dart';
import 'tappable.dart';

/// One row in a [NotificationInbox], such as a [NotificationCenter]'s.
///
/// A tap on the row closes the inbox and calls [onTap]. Its other actions sit
/// in a menu at its end, shown while the row is hovered or holds focus and
/// always a Tab stop: "Mark as read" or "Mark as unread" with
/// [onReadChanged], the host's [menu] entries, then "Dismiss" with
/// [onDismiss]. A row with none of them has no menu. One inline action,
/// [actionLabel] and [onAction], shows under its text as a small ghost
/// button.
class NotificationItem {
  final String title;
  final String? body;
  final String? timestamp;
  final IconData? icon;

  /// The icon's accent colour; the primary when null. The unread dot is
  /// always the primary, so unread reads the same on every row.
  final Color? color;

  /// Takes the place of the [icon] badge: an [Avatar] of whoever acted, a
  /// thumbnail. The badge is 28px square, as an [Avatar] is by default.
  final Widget? leading;
  final bool unread;
  final VoidCallback? onTap;

  /// Called with the row's new read state: true from "Mark as read" on an
  /// [unread] row, false from "Mark as unread" on a read one.
  final ValueChanged<bool>? onReadChanged;

  /// Dismisses the row, as its menu's "Dismiss", which shows exactly when
  /// this is set. The host takes the row out of the list.
  final VoidCallback? onDismiss;

  /// The inline action's label, such as "Review" or "Accept".
  final String? actionLabel;

  /// Called by the inline action after the inbox closes, as [onTap] is.
  final VoidCallback? onAction;

  /// More entries for the row's menu, between the read toggle and "Dismiss".
  /// Give them icons, as those two have, so the labels line up.
  final List<MenuEntry> menu;

  const NotificationItem({
    required this.title,
    this.body,
    this.timestamp,
    this.icon,
    this.color,
    this.leading,
    this.unread = false,
    this.onTap,
    this.onReadChanged,
    this.onDismiss,
    this.actionLabel,
    this.onAction,
    this.menu = const [],
  }) : assert(
         onAction == null || actionLabel != null,
         'An onAction needs its actionLabel',
       );

  bool get _hasMenu =>
      onReadChanged != null || onDismiss != null || menu.isNotEmpty;
}

/// A group of [NotificationInbox] rows under a caption, such as "Today" and
/// "Earlier".
class NotificationSection {
  final String title;
  final List<NotificationItem> items;

  const NotificationSection({required this.title, required this.items});
}

/// A bell button with an unread [CountBadge] that opens a [NotificationInbox]
/// of [items], or of [sections], in a dropdown. View-pure: the host supplies
/// the rows, the unread tally, the load state and the callbacks; this owns
/// only the open/closed popover and its [showUnreadFilter] choice, which it
/// keeps from one opening to the next.
///
/// The bell is an [IconAction] named after [title] and the unread count
/// ("Notifications, 2 unread"), since the badge itself is not read out; each
/// row is a focusable button, followed in the Tab order by its inline action
/// and its menu (see [NotificationItem]). Opened from the keyboard, focus
/// lands on the first row.
///
/// The list can end in the state of its next load: a "Load more" row while
/// [hasMore], busy while [loading], or the error with a retry while
/// [errorText] is set. With no rows those states fill the panel instead:
/// three skeleton rows while [loading], an [ErrorState], or an [EmptyState]
/// saying [emptyText].
///
/// For the inbox elsewhere (a full-width sheet on a phone, a page), place a
/// [NotificationInbox] there, opened from a [NotificationBell].
class NotificationCenter extends StatefulWidget {
  /// The rows, ungrouped. Pass either these or [sections].
  final List<NotificationItem> items;

  /// The rows in captioned groups, in order. Pass either these or [items].
  final List<NotificationSection> sections;

  /// Overrides the badge count; defaults to the number of unread rows, in
  /// [items] or across [sections].
  final int? unreadCount;
  final VoidCallback? onMarkAllRead;

  /// The inbox's title; the localized "Notifications" when null.
  final String? title;

  /// Shown in place of an empty inbox; the localized "You’re all caught up"
  /// when null.
  final String? emptyText;
  final double width;

  /// Closes the panel under a hairline: a link to the notifications page, a
  /// "Clear all". Wins over [onViewAll].
  final Widget? footer;

  /// Shows a full-width "View all" button as the [footer], which closes the
  /// inbox and calls this.
  final VoidCallback? onViewAll;

  /// The rows are loading: three skeleton rows stand in for an empty list,
  /// and the "Load more" button of a list with rows turns busy.
  final bool loading;

  /// The load failed: the panel says "Couldn’t load notifications", with
  /// this below it when it is not empty, and a retry when [onRetry] is set.
  final String? errorText;
  final VoidCallback? onRetry;

  /// More rows follow: the list ends in a "Load more" row that calls
  /// [onLoadMore].
  final bool hasMore;
  final VoidCallback? onLoadMore;

  /// Shows an All / Unread choice under the header, which filters the rows
  /// here, without asking the host.
  final bool showUnreadFilter;

  const NotificationCenter({
    super.key,
    this.items = const [],
    this.sections = const [],
    this.unreadCount,
    this.onMarkAllRead,
    this.title,
    this.emptyText,
    this.width = 340,
    this.footer,
    this.onViewAll,
    this.loading = false,
    this.errorText,
    this.onRetry,
    this.hasMore = false,
    this.onLoadMore,
    this.showUnreadFilter = false,
  });

  @override
  State<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends State<NotificationCenter> {
  bool _unreadOnly = false;

  @override
  Widget build(BuildContext context) {
    assert(
      widget.items.isEmpty || widget.sections.isEmpty,
      'Pass items or sections, not both',
    );
    final title = widget.title ?? context.adminL10n.inputs.notifications;
    return Popover(
      align: PopoverAlign.end,
      anchor: (context, controller) => NotificationBell(
        unreadCount: _unreadCountOf(
          widget.unreadCount,
          widget.items,
          widget.sections,
        ),
        title: title,
        expanded: controller.isOpen,
        onPressed: controller.toggle,
      ),
      content: (context, controller) => PopoverMenuSurface(
        width: widget.width,
        maxHeight: _maxHeight,
        fitAvailableHeight: true,
        child: NotificationInbox._inPopover(
          items: widget.items,
          sections: widget.sections,
          unreadCount: widget.unreadCount,
          onMarkAllRead: widget.onMarkAllRead,
          title: widget.title,
          emptyText: widget.emptyText,
          footer: widget.footer,
          onViewAll: widget.onViewAll,
          loading: widget.loading,
          errorText: widget.errorText,
          onRetry: widget.onRetry,
          hasMore: widget.hasMore,
          onLoadMore: widget.onLoadMore,
          showUnreadFilter: widget.showUnreadFilter,
          close: controller.close,
          unreadOnly: _unreadOnly,
          onUnreadOnlyChanged: (unreadOnly) =>
              setState(() => _unreadOnly = unreadOnly),
        ),
      ),
    );
  }
}

/// [unreadCount], or the unread rows among [items] or across [sections].
int _unreadCountOf(
  int? unreadCount,
  List<NotificationItem> items,
  List<NotificationSection> sections,
) =>
    unreadCount ??
    [
      ...items,
      for (final section in sections) ...section.items,
    ].where((item) => item.unread).length;

/// The bell alone: an [IconAction] with an unread [CountBadge] on its
/// glyph's corner, named after [title] and the count ("Notifications, 2
/// unread") since the badge is not read out. What a [NotificationCenter]
/// opens its dropdown from; on its own, it opens a [NotificationInbox]
/// wherever [onPressed] puts it, such as a full-width sheet on a phone.
class NotificationBell extends StatelessWidget {
  /// The count on the badge; none shows at zero.
  final int unreadCount;

  /// The accessible name and tooltip; the localized "Notifications" when
  /// null.
  final String? title;

  /// Whether the inbox it opens is open: the bell keeps its hover fill, and
  /// says so to assistive technology. Null for a bell whose inbox is not
  /// tracked.
  final bool? expanded;

  final VoidCallback? onPressed;

  const NotificationBell({
    super.key,
    this.unreadCount = 0,
    this.title,
    this.expanded,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.adminL10n.inputs;
    final title = this.title ?? strings.notifications;
    const size = IconActionSize.medium;
    final glyphInset = (size.boxOf(context) - size.glyph) / 2;
    final open = expanded ?? false;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          // The open inbox keeps the bell's hover fill.
          decoration: BoxDecoration(
            color: open ? context.colors.hoverOverlay : null,
            borderRadius: BorderRadius.circular(context.radii.radiusSmall),
          ),
          child: IconAction(
            Icons.notifications_none_rounded,
            label: unreadCount > 0
                ? strings.unreadCount(title, unreadCount)
                : title,
            onPressed: onPressed,
            expanded: expanded,
            size: size,
          ),
        ),
        // The badge rides the glyph's corner, nudged out so the bell still
        // reads under it; the label already carries the count.
        PositionedDirectional(
          start: glyphInset,
          top: glyphInset,
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: CountBadge(
                count: unreadCount,
                child: SizedBox(
                  width: size.glyph + AdminSpacing.xs,
                  height: size.glyph,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The notifications panel: a header with its [title] and "Mark all read",
/// an optional All / Unread choice, the rows of [items] or of [sections],
/// and an optional [footer]. What a [NotificationCenter] drops down from
/// its bell; placed on its own, it is the inbox of a sheet (a phone's, full
/// width, opened from a [NotificationBell]) or of a page. Give it a bounded
/// height: its rows scroll in what the header and footer leave, and the
/// footer stays at the bottom.
///
/// View-pure, as the [NotificationCenter] is: the host supplies the rows,
/// the unread tally, the load state and the callbacks, and the inbox owns
/// only its [showUnreadFilter] choice. With [onDismiss] its header ends in a
/// close button, and a row's tap, its inline action and "View all" call it
/// first, to close the sheet the inbox is in before they go on.
///
/// The list can end in the state of its next load: a "Load more" row while
/// [hasMore], busy while [loading], or the error with a retry while
/// [errorText] is set. With no rows those states fill the panel instead:
/// three skeleton rows while [loading], an [ErrorState], or an [EmptyState]
/// saying [emptyText].
class NotificationInbox extends StatefulWidget {
  /// The rows, ungrouped. Pass either these or [sections].
  final List<NotificationItem> items;

  /// The rows in captioned groups, in order. Pass either these or [items].
  final List<NotificationSection> sections;

  /// Overrides the unread count "Mark all read" goes by; defaults to the
  /// number of unread rows, in [items] or across [sections].
  final int? unreadCount;

  /// Shows "Mark all read" in the header while a row is unread.
  final VoidCallback? onMarkAllRead;

  /// The inbox's title; the localized "Notifications" when null.
  final String? title;

  /// Shown in place of an empty inbox; the localized "You’re all caught up"
  /// when null.
  final String? emptyText;

  /// Closes the panel under a hairline: a link to the notifications page, a
  /// "Clear all". Wins over [onViewAll].
  final Widget? footer;

  /// Shows a full-width "View all" button as the [footer], which calls
  /// [onDismiss] and then this.
  final VoidCallback? onViewAll;

  /// The rows are loading: three skeleton rows stand in for an empty list,
  /// and the "Load more" button of a list with rows turns busy.
  final bool loading;

  /// The load failed: the panel says "Couldn’t load notifications", with
  /// this below it when it is not empty, and a retry when [onRetry] is set.
  final String? errorText;
  final VoidCallback? onRetry;

  /// More rows follow: the list ends in a "Load more" row that calls
  /// [onLoadMore].
  final bool hasMore;
  final VoidCallback? onLoadMore;

  /// Shows an All / Unread choice under the header, which filters the rows
  /// here, without asking the host.
  final bool showUnreadFilter;

  /// Closes what the inbox is in: the header's close button, which shows
  /// exactly when this is set, and the rows' taps and actions call it.
  final VoidCallback? onDismiss;

  /// A popover's inbox: the popover closes it, so no close button shows.
  final bool _inPopover;

  /// The unread filter's choice, when the host keeps it.
  final bool? _unreadOnly;
  final ValueChanged<bool>? _onUnreadOnlyChanged;

  const NotificationInbox({
    super.key,
    this.items = const [],
    this.sections = const [],
    this.unreadCount,
    this.onMarkAllRead,
    this.title,
    this.emptyText,
    this.footer,
    this.onViewAll,
    this.loading = false,
    this.errorText,
    this.onRetry,
    this.hasMore = false,
    this.onLoadMore,
    this.showUnreadFilter = false,
    this.onDismiss,
  }) : _inPopover = false,
       _unreadOnly = null,
       _onUnreadOnlyChanged = null;

  const NotificationInbox._inPopover({
    required this.items,
    required this.sections,
    required this.unreadCount,
    required this.onMarkAllRead,
    required this.title,
    required this.emptyText,
    required this.footer,
    required this.onViewAll,
    required this.loading,
    required this.errorText,
    required this.onRetry,
    required this.hasMore,
    required this.onLoadMore,
    required this.showUnreadFilter,
    required VoidCallback close,
    required bool this._unreadOnly,
    required ValueChanged<bool> this._onUnreadOnlyChanged,
  }) : onDismiss = close,
       _inPopover = true;

  @override
  State<NotificationInbox> createState() => _NotificationInboxState();
}

class _NotificationInboxState extends State<NotificationInbox> {
  bool _ownUnreadOnly = false;

  bool get _unreadOnly => widget._unreadOnly ?? _ownUnreadOnly;

  void _setUnreadOnly(bool unreadOnly) {
    if (widget._onUnreadOnlyChanged case final onChanged?) {
      onChanged(unreadOnly);
    } else {
      setState(() => _ownUnreadOnly = unreadOnly);
    }
  }

  /// The groups to show, the unread filter applied: one untitled group for
  /// [NotificationInbox.items]. A group left empty drops out.
  List<(String?, List<NotificationItem>)> get _groups {
    final unreadOnly = _unreadOnly;
    bool shown(NotificationItem item) => !unreadOnly || item.unread;
    return [
      if (widget.sections.isEmpty)
        (null, widget.items.where(shown).toList())
      else
        for (final section in widget.sections)
          (section.title, section.items.where(shown).toList()),
    ].where((group) => group.$2.isNotEmpty).toList();
  }

  /// [then], after closing what the inbox is in.
  VoidCallback _closing(VoidCallback? then) => () {
    widget.onDismiss?.call();
    then?.call();
  };

  @override
  Widget build(BuildContext context) {
    assert(
      widget.items.isEmpty || widget.sections.isEmpty,
      'Pass items or sections, not both',
    );
    final strings = context.adminL10n.inputs;
    final title = widget.title ?? strings.notifications;
    final unread = _unreadCountOf(
      widget.unreadCount,
      widget.items,
      widget.sections,
    );
    final onViewAll = widget.onViewAll;
    final footer =
        widget.footer ??
        (onViewAll == null
            ? null
            : _Strip(
                child: Button(
                  strings.viewAll,
                  variant: ButtonVariant.ghost,
                  expand: true,
                  onPressed: _closing(onViewAll),
                ),
              ));
    final body = _body(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context, title, unread),
        if (widget.showUnreadFilter) _filter(context, title),
        const _Hairline(),
        // A popover sizes to its rows; elsewhere the footer stays at the
        // bottom.
        if (widget._inPopover) Flexible(child: body) else Expanded(child: body),
        if (footer != null) ...[const _Hairline(), footer],
      ],
    );
  }

  Widget _header(BuildContext context, String title, int unread) {
    const closeSize = IconActionSize.small;
    final onDismiss = widget._inPopover ? null : widget.onDismiss;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        AdminSpacing.lg,
        AdminSpacing.md,
        // The close glyph, not its box, keeps the rows' inset.
        onDismiss == null
            ? AdminSpacing.md
            : AdminSpacing.lg - (closeSize.box - closeSize.glyph) / 2,
        AdminSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: context.type.bodyStrong.copyWith(
                  color: context.colors.foreground,
                ),
              ),
            ),
          ),
          if (widget.onMarkAllRead != null && unread > 0)
            Button(
              context.adminL10n.inputs.markAllRead,
              variant: ButtonVariant.ghost,
              size: ControlSize.small,
              onPressed: widget.onMarkAllRead,
            ),
          if (onDismiss != null) ...[
            const Gap(AdminSpacing.sm),
            IconAction.close(size: closeSize, onPressed: onDismiss),
          ],
        ],
      ),
    );
  }

  Widget _filter(BuildContext context, String title) {
    final strings = context.adminL10n.inputs;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AdminSpacing.lg,
        0,
        AdminSpacing.lg,
        AdminSpacing.md,
      ),
      child: Segmented<bool>(
        size: ControlSize.small,
        expand: true,
        value: _unreadOnly,
        semanticLabel: title,
        onChanged: _setUnreadOnly,
        segments: [
          SegmentOption(false, strings.allNotifications),
          SegmentOption(true, strings.unread),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    final groups = _groups;
    final strings = context.adminL10n.inputs;
    if (groups.isEmpty) {
      final errorText = widget.errorText;
      // Scrolled, so each takes its own height rather than the panel's.
      return SingleChildScrollView(
        child: widget.loading
            ? const _SkeletonRows()
            : errorText != null
            ? ErrorState(
                title: strings.couldNotLoadNotifications,
                message: errorText.isEmpty ? null : errorText,
                onRetry: widget.onRetry,
                minHeight: 0,
              )
            : EmptyState(
                icon: Icons.notifications_none_rounded,
                title: widget.emptyText ?? strings.allCaughtUp,
                minHeight: 0,
              ),
      );
    }
    final reserveMenu = groups.any((group) => group.$2.any((i) => i._hasMenu));
    return _RowList(
      children: [
        for (final (title, items) in groups) ...[
          if (title != null) _SectionCaption(title),
          for (final item in items)
            _Row(
              item: item,
              reserveMenu: reserveMenu,
              onTap: _closing(item.onTap),
              onAction: switch (item.onAction) {
                final onAction? => _closing(onAction),
                null => null,
              },
            ),
        ],
        if (widget.errorText case final errorText?)
          _ErrorRow(errorText: errorText, onRetry: widget.onRetry)
        else if (widget.hasMore)
          _Strip(
            child: Button(
              context.adminL10n.loadMore,
              variant: ButtonVariant.ghost,
              size: ControlSize.small,
              expand: true,
              loading: widget.loading,
              onPressed: widget.onLoadMore,
            ),
          ),
      ],
    );
  }
}

/// The inbox's height cap: its header, a filter, a footer and some four rows.
const _maxHeight = 480.0;

/// The hairline between the inbox's header, list and footer.
class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) => Divider(
    height: context.stroke.hairline,
    thickness: context.stroke.hairline,
    color: context.colors.separator,
  );
}

/// The row of a full-width button: the footer's "View all", "Load more".
class _Strip extends StatelessWidget {
  final Widget child;

  const _Strip({required this.child});

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.all(AdminSpacing.xs), child: child);
}

/// The inbox rows: after a keyboard open, focus starts on the first.
class _RowList extends StatefulWidget {
  final List<Widget> children;

  const _RowList({required this.children});

  @override
  State<_RowList> createState() => _RowListState();
}

class _RowListState extends State<_RowList> {
  final _node = FocusNode(
    debugLabel: 'Inbox',
    canRequestFocus: false,
    skipTraversal: true,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Popover.openedByKeyboard(context)) {
        _node.traversalDescendants.firstOrNull?.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _node,
      includeSemantics: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.children,
        ),
      ),
    );
  }
}

/// A section's caption, in the theme's label case.
class _SectionCaption extends StatelessWidget {
  final String title;

  const _SectionCaption(this.title);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AdminSpacing.lg,
          AdminSpacing.md,
          AdminSpacing.lg,
          AdminSpacing.xs,
        ),
        child: _OnGrid(
          child: Text(
            context.type.fieldLabelText(title),
            semanticsLabel: title,
            style: context.type.micro,
          ),
        ),
      ),
    );
  }
}

class _Row extends StatefulWidget {
  final NotificationItem item;

  /// Keeps the menu's slot at the end even when this row has no menu, so the
  /// unread dots of a list line up.
  final bool reserveMenu;
  final VoidCallback onTap;
  final VoidCallback? onAction;

  const _Row({
    required this.item,
    required this.reserveMenu,
    required this.onTap,
    required this.onAction,
  });

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  /// Holds the row's Tab stop and its controls' as siblings: the controls
  /// sit inside the row's [Tappable] on screen, but are Tab stops of their
  /// own, after the row's.
  final _within = FocusNode(debugLabel: 'Notification and its controls');

  /// Focus is on the row, on one of its controls, or in its open menu.
  bool _focusWithin = false;

  @override
  void dispose() {
    _within.dispose();
    super.dispose();
  }

  List<MenuEntry> _entries(BuildContext context) {
    final item = widget.item;
    final strings = context.adminL10n.inputs;
    final entries = <MenuEntry>[
      if (item.onReadChanged case final onReadChanged?)
        MenuItem(
          item.unread ? strings.markAsRead : strings.markAsUnread,
          icon: item.unread
              ? Icons.mark_email_read_outlined
              : Icons.mark_email_unread_outlined,
          onSelect: () => onReadChanged(item.unread),
        ),
      ...item.menu,
    ];
    return [
      ...entries,
      if (item.onDismiss case final onDismiss?) ...[
        if (entries.isNotEmpty) const MenuDivider(),
        MenuItem(
          MaterialLocalizations.of(context).modalBarrierDismissLabel,
          icon: Icons.close_rounded,
          onSelect: onDismiss,
        ),
      ],
    ];
  }

  /// [child], a control inside the row, as a Tab stop beside the row's own,
  /// at [order] among the row's.
  Widget _control(double order, Widget child) => Focus(
    parentNode: _within,
    canRequestFocus: false,
    skipTraversal: true,
    child: FocusTraversalOrder(order: NumericFocusOrder(order), child: child),
  );

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final colors = context.colors;
    final accent = item.color ?? colors.primary;
    // The glyph sits on a 12% wash of its own accent over the unread tint; it
    // is lifted to 3:1 there, since a raw accent (a light-theme green, a dark
    // brand) can vanish on its own wash.
    final rowFill = item.unread ? colors.primaryFaint : colors.surface;
    // token-literal: a glyph's wash of its own accent
    final badgeFill = Color.alphaBlend(accent.withValues(alpha: 0.12), rowFill);
    final glyph = colors.readableOn(
      accent,
      surfaces: [badgeFill],
      minContrast: 3,
    );
    // The dot is what marks a row unread (the tint can all but vanish on the
    // surface, as in shadcn light), so it holds 3:1 on the tint, under the
    // pointer and on the plain surface.
    final dot = colors.readableOn(
      colors.primary,
      surfaces: [colors.primaryFaint, colors.listHighlight, colors.surface],
      minContrast: 3,
    );
    // Body and timestamp stay AA on the unread tint and under the pointer.
    final secondary = colors.foregroundMutedOnTint;
    final title = context.type.weighted(
      context.type.body.copyWith(color: colors.foreground),
      item.unread ? FontWeight.w600 : FontWeight.w400,
    );
    // The dot and the menu button centre on the title's first line.
    final line = lineHeightOf(context, title);
    const menuSize = IconActionSize.small;
    final hasMenu = item._hasMenu;
    final onAction = widget.onAction;
    // The inline action's box reaches past its label into the gap above it
    // and the row's padding below, so the label keeps the text's rhythm and
    // the row's bottom edge the padding of its top.
    final actionInset = onAction == null
        ? 0.0
        : math.max(
            0.0,
            (context.sizes.height(ControlSize.small) -
                    lineHeightOf(context, context.type.buttonSmall)) /
                2,
          );

    final row = Tappable.states(
      onTap: widget.onTap,
      // The highlight fill marks keyboard focus, as in a menu.
      showFocusRing: false,
      builder: (context, states) {
        final active = states.contains(WidgetState.hovered) || _focusWithin;
        final showMenu = hasMenu && active;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: active
                ? colors.listHighlight
                : (item.unread ? colors.primaryFaint : null),
          ),
          child: Stack(
            children: [
              _OnGrid(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AdminSpacing.lg,
                    AdminSpacing.lg,
                    AdminSpacing.lg,
                    AdminSpacing.lg - math.min(actionInset, AdminSpacing.lg),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.leading case final leading?) ...[
                        leading,
                        const Gap(AdminSpacing.lg),
                      ] else if (item.icon != null) ...[
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            // token-literal: a glyph's wash of its own accent
                            color: accent.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.icon,
                            size: context.iconSizes.md,
                            color: glyph,
                          ),
                        ),
                        const Gap(AdminSpacing.lg),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: title),
                            if (item.body != null) ...[
                              const Gap(AdminSpacing.xxs),
                              Text(
                                item.body!,
                                style: context.type.caption.copyWith(
                                  color: secondary,
                                ),
                              ),
                            ],
                            if (item.timestamp != null) ...[
                              const Gap(AdminSpacing.xs),
                              Text(
                                item.timestamp!,
                                style: context.type.micro.copyWith(
                                  color: secondary,
                                ),
                              ),
                            ],
                            if (onAction != null) ...[
                              Gap(math.max(0, AdminSpacing.xs - actionInset)),
                              _control(
                                1,
                                Button.ghost(
                                  item.actionLabel!,
                                  size: ControlSize.small,
                                  flush: true,
                                  onPressed: onAction,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (item.unread || widget.reserveMenu) ...[
                        const Gap(AdminSpacing.md),
                        SizedBox(
                          width: widget.reserveMenu ? menuSize.box : _unreadDot,
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: (line - _unreadDot) / 2,
                            ),
                            child: item.unread
                                ? Center(
                                    heightFactor: 1,
                                    // Named for a screen reader too; the
                                    // menu button covers it while it shows.
                                    child: Semantics(
                                      label: context.adminL10n.inputs.unread,
                                      child: Opacity(
                                        opacity: showMenu ? 0 : 1,
                                        alwaysIncludeSemantics: true,
                                        child: Container(
                                          width: _unreadDot,
                                          height: _unreadDot,
                                          decoration: BoxDecoration(
                                            color: dot,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (hasMenu)
                PositionedDirectional(
                  top: AdminSpacing.lg + (line - menuSize.box) / 2,
                  end: AdminSpacing.lg,
                  child: _control(
                    2,
                    // Hidden, it keeps its Tab stop and its name, and a click
                    // there opens the row.
                    MenuButton(
                      icon: Icons.more_horiz_rounded,
                      size: menuSize,
                      tooltip: context.adminL10n.moreActions,
                      revealed: showMenu,
                      entries: _entries(context),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );

    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Focus(
        focusNode: _within,
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        onFocusChange: (focused) => setState(() => _focusWithin = focused),
        child: FocusTraversalOrder(
          order: const NumericFocusOrder(0),
          child: row,
        ),
      ),
    );
  }
}

/// Three rows' skeletons, while the first rows load.
class _SkeletonRows extends StatelessWidget {
  const _SkeletonRows();

  /// Each row's title and body bars, as fractions of the text column.
  static const _widths = [(0.72, 0.9), (0.56, 0.7), (0.64, 0.8)];

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    // A bar centred in the line box of the text it stands for.
    Widget bar(TextStyle style, double width, double height) => SizedBox(
      height: lineHeightOf(context, style),
      child: FractionallySizedBox(
        widthFactor: width,
        alignment: AlignmentDirectional.centerStart,
        child: Center(child: Skeleton(height: height)),
      ),
    );
    return Semantics(
      container: true,
      label: context.adminL10n.loading,
      child: SkeletonGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (title, body) in _widths)
              Padding(
                padding: const EdgeInsets.all(AdminSpacing.lg),
                child: _OnGrid(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Skeleton.circle(size: 28),
                      const Gap(AdminSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            bar(type.body, title, 12),
                            const Gap(AdminSpacing.xxs),
                            bar(type.caption, body, 10),
                            const Gap(AdminSpacing.xs),
                            bar(type.micro, 0.24, 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A failed load of more rows, below the ones shown.
class _ErrorRow extends StatelessWidget {
  final String errorText;
  final VoidCallback? onRetry;

  const _ErrorRow({required this.errorText, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AdminSpacing.lg,
        AdminSpacing.md,
        AdminSpacing.md,
        AdminSpacing.md,
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: context.iconSizes.md,
            color: colors.danger,
          ),
          const Gap(AdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.adminL10n.inputs.couldNotLoadNotifications,
                  style: type.caption.copyWith(color: colors.foreground),
                ),
                if (errorText.isNotEmpty) Text(errorText, style: type.caption),
              ],
            ),
          ),
          if (onRetry != null) ...[
            const Gap(AdminSpacing.md),
            Button(
              context.adminL10n.retry,
              variant: ButtonVariant.ghost,
              size: ControlSize.small,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

/// Lays [child] out as it is and rounds its height up to the 4px grid, so a
/// row keeps the rhythm whatever the theme's line heights add up to.
class _OnGrid extends SingleChildRenderObjectWidget {
  const _OnGrid({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderOnGrid();
}

class _RenderOnGrid extends RenderProxyBox {
  static const _grid = 4.0;

  /// A hair over a step stays on it: a line box can measure 20.0000001.
  double _snap(double height) =>
      height.isFinite ? (height / _grid - 0.001).ceil() * _grid : height;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _snap(super.computeMinIntrinsicHeight(width));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _snap(super.computeMaxIntrinsicHeight(width));

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final size = child?.getDryLayout(constraints) ?? Size.zero;
    return constraints.constrain(Size(size.width, _snap(size.height)));
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(constraints, parentUsesSize: true);
    size = constraints.constrain(
      Size(child.size.width, _snap(child.size.height)),
    );
  }
}

/// The unread marker's diameter.
const _unreadDot = 8.0;
