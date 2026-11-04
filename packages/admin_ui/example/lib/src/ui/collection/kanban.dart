import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutterware/ui_catalog.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';

/// Demo — a generic [KanbanBoard]: cards flow across workflow columns and drag
/// between them (or move with Alt+← / Alt+→ once focused). Here it's an
/// editorial content pipeline (one card per content item), but the board is
/// domain-agnostic: give it columns, a `cardBuilder`, and an `onMove`, and it
/// stays a pure View — the demo holds the card→column assignment locally so
/// drags actually move cards. Two columns carry a subtitle and Backlog an
/// add action, and the first cards still line up; the Type filter empties
/// columns.
class KanbanDemo extends StatefulWidget {
  @Preview(name: 'Kanban board', wrapper: adminUiPreview)
  const KanbanDemo({super.key});

  @override
  State<KanbanDemo> createState() => _KanbanDemoState();
}

class _KanbanDemoState extends State<KanbanDemo> {
  List<_Item> _items = _seed();

  static List<_Item> _seed() => [
    _Item('a1', 'Autumn lookbook', _Kind.article, _backlog),
    _Item(
      'a2',
      'Founder interview',
      _Kind.article,
      _progress,
      assignee: 'Mara',
    ),
    _Item('a3', 'Pricing update', _Kind.page, _review, assignee: 'Ben'),
    _Item(
      'b1',
      'Summer collection 2026',
      _Kind.product,
      _progress,
      assignee: 'Mara',
    ),
    _Item('b2', 'Ceramic vase', _Kind.product, _backlog),
    _Item(
      'c1',
      'A very long editorial title that should wrap across two lines',
      _Kind.article,
      _review,
      assignee: 'Ben',
    ),
    _Item('d1', 'Autumn gala', _Kind.event, _published),
    _Item('d2', 'Winter gala', _Kind.event, _backlog),
    _Item('e1', 'Homepage refresh', _Kind.page, _published, flagged: true),
    _Item('f1', 'Contact', _Kind.page, _published, flagged: true),
    _Item('g1', 'Care & repair guide', _Kind.article, _backlog),
  ];

  static const _backlog = 'backlog';
  static const _progress = 'in_progress';
  static const _review = 'in_review';
  static const _published = 'published';

  void _move(_Item item, String from, String to) {
    setState(() {
      _items = [
        for (final i in _items)
          if (i.id == item.id) i.copyWith(status: to) else i,
      ];
    });
  }

  void _reset() => setState(() => _items = _seed());

  @override
  Widget build(BuildContext context) {
    final params = context.knobs;
    final showReview = params.bool('Review column', true);
    final kind = params.picker('Type filter', const {
      'All': '',
      'Articles': 'article',
      'Pages': 'page',
      'Products': 'product',
      'Events': 'event',
    }, '');
    params.button('Reset', 'Reset board', _reset);

    final visible = kind.isEmpty
        ? _items
        : _items.where((i) => i.kind.name == kind).toList();

    // Skipping the review column folds its cards back into "In progress".
    final effective = showReview
        ? visible
        : [
            for (final i in visible)
              i.status == _review ? i.copyWith(status: _progress) : i,
          ];

    final columns = <KanbanColumn<_Item>>[
      _col(
        _backlog,
        'Backlog',
        null,
        context.colors.foregroundMuted,
        effective,
        trailing: IconAction(
          Icons.add_rounded,
          label: 'Add to Backlog',
          size: IconActionSize.small,
          onPressed: () {},
        ),
      ),
      _col(_progress, 'In progress', null, context.colors.info, effective),
      if (showReview)
        _col(
          _review,
          'In review',
          'Awaiting sign-off',
          context.colors.warning,
          effective,
        ),
      _col(
        _published,
        'Published',
        'Live on site',
        context.colors.success,
        effective,
      ),
    ];

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _metrics(context, visible),
          Expanded(
            child: KanbanBoard<_Item>(
              columns: columns,
              itemKey: (i) => i.id,
              onMove: _move,
              onCardTap: (i) => ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  SnackBar(
                    content: Text('Open ${i.title}'),
                    duration: const Duration(milliseconds: 900),
                  ),
                ),
              cardBuilder: (context, i) => _ItemCard(item: i),
            ),
          ),
        ],
      ),
    );
  }

  KanbanColumn<_Item> _col(
    String id,
    String title,
    String? subtitle,
    Color accent,
    List<_Item> from, {
    Widget? trailing,
  }) => KanbanColumn(
    id: id,
    title: title,
    subtitle: subtitle,
    accent: accent,
    trailing: trailing,
    items: from.where((i) => i.status == id).toList(),
  );

  Widget _metrics(BuildContext context, List<_Item> items) {
    final backlog = items.where((i) => i.status == _backlog).length;
    final active = items
        .where((i) => i.status == _progress || i.status == _review)
        .length;
    final flagged = items.where((i) => i.flagged).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AdminSpacing.xl,
        AdminSpacing.xl,
        AdminSpacing.xl,
        0,
      ),
      child: Row(
        children: [
          _Metric(label: 'Backlog', value: backlog),
          const Gap(AdminSpacing.lg),
          _Metric(
            label: 'Active',
            value: active,
            tone: context.colors.infoText,
          ),
          const Gap(AdminSpacing.lg),
          _Metric(
            label: 'Needs attention',
            value: flagged,
            tone: flagged > 0 ? context.colors.dangerText : null,
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final int value;
  final Color? tone;
  const _Metric({required this.label, required this.value, this.tone});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.xl,
        vertical: AdminSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(context.radii.radiusLarge),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: context.type.heading.copyWith(color: tone ?? c.foreground),
          ),
          const Gap(AdminSpacing.md),
          Text(
            label,
            style: context.type.bodySmall.copyWith(color: c.foregroundMuted),
          ),
        ],
      ),
    );
  }
}

/// A content-item tile: entity title, type footer, assignee. A flagged item
/// (e.g. needs attention) wears a red border.
class _ItemCard extends StatelessWidget {
  final _Item item;
  const _ItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final i = item;
    return Container(
      padding: KanbanBoard.cardPadding,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(context.radii.radiusLarge),
        border: Border.all(
          color: i.flagged ? c.danger : c.border,
          width: i.flagged ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(i.kind.icon, size: 14, color: c.foregroundMuted),
              const Gap(AdminSpacing.xs),
              Text(
                i.kind.label,
                style: context.type.caption.copyWith(color: c.foregroundMuted),
              ),
              const Spacer(),
              if (i.flagged)
                Icon(Icons.flag_rounded, size: 14, color: c.danger),
            ],
          ),
          const Gap(AdminSpacing.md),
          Text(
            i.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.type.bodyStrong,
          ),
          if (i.assignee != null) ...[
            const Gap(AdminSpacing.lg),
            Row(
              children: [
                const Spacer(),
                _Initials(name: i.assignee!),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String name;
  const _Initials({required this.name});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: name,
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          shape: BoxShape.circle,
          border: Border.all(color: c.border),
        ),
        child: Text(
          name.characters.first.toUpperCase(),
          // Sized to the mark, as an avatar's initials are.
          textScaler: TextScaler.noScaling,
          style: context.type.micro.copyWith(
            color: c.foregroundSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

enum _Kind {
  article('Article', Icons.article_outlined),
  page('Page', Icons.description_outlined),
  event('Event', Icons.event_outlined),
  product('Product', Icons.inventory_2_outlined);

  final String label;
  final IconData icon;
  const _Kind(this.label, this.icon);
}

class _Item {
  final String id;
  final String title;
  final _Kind kind;
  final String status;
  final bool flagged;
  final String? assignee;

  const _Item(
    this.id,
    this.title,
    this.kind,
    this.status, {
    this.flagged = false,
    this.assignee,
  });

  _Item copyWith({String? status}) => _Item(
    id,
    title,
    kind,
    status ?? this.status,
    flagged: flagged,
    assignee: assignee,
  );
}
