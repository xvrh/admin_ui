import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/bidi.dart';
import '../../l10n/shortcut_label.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'button.dart';
import 'focus_ring.dart';
import 'icon_action.dart';
import 'menu.dart';
import 'menu_button.dart';
import 'panel.dart';
import 'severity.dart';
import 'tag.dart';
import 'tappable.dart';
import 'tree.dart';

/// The inline badge of one entry: an icon, a short label (a link's resolved
/// title, host or path, say) and a status, so a tree's health reads at a
/// glance before anything is opened.
@immutable
class TreeEntryBadge {
  final IconData icon;
  final String label;

  /// The status the badge reports, in its severity colours. Null draws a
  /// neutral badge.
  final Severity? tone;

  /// Draws an untoned badge in the primary colour, to set an entry apart (a
  /// link to live content, say). Ignored when [tone] is set.
  final bool emphasised;

  const TreeEntryBadge({
    required this.icon,
    required this.label,
    this.tone,
    this.emphasised = false,
  });
}

/// A presentational view of one entry: the flat shape [TreeEditor]
/// reconstructs the tree from. [parentId] is the parent entry's id (null at
/// the root); sibling order is the order entries appear in
/// [TreeEditor.entries].
@immutable
class TreeEditorEntry {
  final String id;
  final String? parentId;

  /// The entry's title for the active locale (empty renders as the localized
  /// "Untitled").
  final String title;

  /// A header that groups its children and points nowhere itself: shown
  /// muted, and tagged [TreeEditor.headerLabel] when it has no [badge].
  final bool isHeader;
  final bool visible;
  final TreeEntryBadge? badge;

  /// This entry differs from what's live — renders the standard amber dot.
  final bool modified;

  const TreeEditorEntry({
    required this.id,
    this.parentId,
    required this.title,
    this.isHeader = false,
    this.visible = true,
    this.badge,
    this.modified = false,
  });
}

/// Where the selected entry's editor (built by [TreeEditor.detailBuilder])
/// appears:
///
/// - [inline] — spliced as a faint indented card beneath its row, pushing the
///   rows below it down.
/// - [focusCard] — the selected row becomes the *header* of a lifted editor
///   card (the editor grows inside it) while the other rows recede. The
///   connection is intrinsic — the editor is the row's own card — so it works
///   in a single column at any width.
enum TreeEditorLayout { inline, focusCard }

/// A View-pure editor for a sortable tree, such as a navigation menu or a
/// category tree: a [Tree] over a flat [entries] list (drag to reorder and
/// re-nest, per-row visibility, a status badge and actions), with the
/// selected entry's editor presented per [layout] via [detailBuilder]. It owns
/// no data — every mutation is a callback ([onMove] re-parents/reorders, the
/// rest act on an id), and the host maps those onto its model. Hierarchy is
/// reconstructed from [TreeEditorEntry.parentId], so the host can keep a
/// parent and an ordinal as flat fields.
///
/// Every row ends in the same trailing column — add child and delete
/// (revealed on hover, keyboard focus or selection), the visibility eye, and a
/// ⋯ menu — so the actions line up down the list. The menu holds every action,
/// including Move up / Move down / Indent / Outdent, which Alt+↑ / ↓ / → / ←
/// also run on a focused row: reordering never needs a drag. Right to left the
/// tree mirrors, and Indent takes Alt+← instead, toward the end edge.
class TreeEditor extends StatelessWidget {
  final List<TreeEditorEntry> entries;

  /// Deepest nesting in *levels* (1 = flat, 2 = one level of children).
  /// Converted to the [Tree]'s 0-based depth cap.
  final int maxDepth;

  final String? selectedId;
  final ValueChanged<String>? onSelect;

  /// Move `id` under `newParentId` (null = root) at `index` among that
  /// parent's children. Null makes the tree read-only (no drag handles).
  final void Function(String id, String? newParentId, int index)? onMove;

  final ValueChanged<String>? onToggleVisible;
  final ValueChanged<String>? onAddChild;
  final ValueChanged<String>? onDelete;
  final VoidCallback? onAddRoot;

  /// Builds the selected entry's editor, presented per [layout]. Null shows no
  /// detail pane (the host edits elsewhere, or the tree is a read-only
  /// preview).
  final Widget Function(BuildContext context, String id)? detailBuilder;

  /// Where the [detailBuilder] editor is shown for the selected entry.
  final TreeEditorLayout layout;

  /// Shown when [entries] is empty.
  final Widget? empty;

  /// Caps the tree height (it scrolls internally past this). Null shrink-wraps.
  final double? maxHeight;

  /// The add button's label; the localized "Add item" when null.
  final String? addLabel;

  /// The tag on a [TreeEditorEntry.isHeader] row; the localized "Group" when
  /// null.
  final String? headerLabel;

  const TreeEditor({
    super.key,
    required this.entries,
    this.maxDepth = 1,
    this.selectedId,
    this.onSelect,
    this.onMove,
    this.onToggleVisible,
    this.onAddChild,
    this.onDelete,
    this.onAddRoot,
    this.detailBuilder,
    this.layout = TreeEditorLayout.inline,
    this.empty,
    this.maxHeight,
    this.addLabel,
    this.headerLabel,
  });

  bool get _focus =>
      layout == TreeEditorLayout.focusCard && detailBuilder != null;

  TreeEditorEntry? _entry(String id) {
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  List<TreeNode> _roots() {
    final byParent = <String?, List<TreeEditorEntry>>{};
    for (final e in entries) {
      (byParent[e.parentId] ??= []).add(e);
    }
    List<TreeNode> build(String? parent) => [
      for (final e in byParent[parent] ?? const <TreeEditorEntry>[])
        TreeNode(id: e.id, children: build(e.id)),
    ];
    return build(null);
  }

  int _depthOf(String id) {
    var depth = 0;
    var cur = _entry(id);
    while (cur?.parentId != null) {
      cur = _entry(cur!.parentId!);
      if (cur == null) break;
      depth++;
    }
    return depth;
  }

  List<TreeEditorEntry> _children(String? parentId) => [
    for (final e in entries)
      if (e.parentId == parentId) e,
  ];

  /// Levels below [id]: 0 for a leaf.
  int _height(String id) {
    var height = 0;
    for (final child in _children(id)) {
      final h = _height(child.id) + 1;
      if (h > height) height = h;
    }
    return height;
  }

  /// The keyboard and menu moves [id] can make at [depth]: one step among
  /// its siblings, under the sibling above it, or out beside its parent.
  _Moves _moves(String id, int depth) {
    final entry = _entry(id)!;
    final parent = entry.parentId;
    final siblings = _children(parent);
    final index = siblings.indexWhere((e) => e.id == id);
    void move(String? to, int at) => onMove!(id, to, at);

    VoidCallback? indent;
    if (index > 0 && depth + 1 + _height(id) < maxDepth) {
      final above = siblings[index - 1].id;
      indent = () => move(above, _children(above).length);
    }
    VoidCallback? outdent;
    if (parent != null) {
      final grandparent = _entry(parent)?.parentId;
      final at = _children(grandparent).indexWhere((e) => e.id == parent);
      outdent = () => move(grandparent, at + 1);
    }
    return _Moves(
      up: index > 0 ? () => move(parent, index - 1) : null,
      down: index < siblings.length - 1 ? () => move(parent, index + 1) : null,
      indent: indent,
      outdent: outdent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDetail = detailBuilder != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          padding: const EdgeInsets.symmetric(vertical: AdminSpacing.md),
          child: Tree(
            roots: _roots(),
            maxDepth: maxDepth - 1,
            maxHeight: maxHeight,
            rowHeight: _rowHeight,
            onMove: onMove,
            empty: empty,
            expandedId: hasDetail ? selectedId : null,
            expansionBuilder: !hasDetail
                ? null
                : (context, id) => _focus
                      ? _FocusCardBody(
                          depth: _depthOf(id),
                          onDismiss: () => onSelect?.call(id),
                          child: detailBuilder!(context, id),
                        )
                      : _ExpansionCard(child: detailBuilder!(context, id)),
            itemBuilder: (context, id, info) {
              final entry = _entry(id);
              if (entry == null) return const SizedBox.shrink();
              final selected = id == selectedId;
              return _TreeEntryRow(
                entry: entry,
                headerLabel: headerLabel,
                selected: selected,
                cardHeader: _focus && selected,
                recede: _focus && selectedId != null && !selected,
                canAddChild: onAddChild != null && info.depth < maxDepth - 1,
                moves: onMove == null ? null : _moves(id, info.depth),
                onSelect: onSelect == null ? null : () => onSelect!(id),
                onToggleVisible: onToggleVisible == null
                    ? null
                    : () => onToggleVisible!(id),
                onAddChild: onAddChild == null ? null : () => onAddChild!(id),
                onDelete: onDelete == null ? null : () => onDelete!(id),
              );
            },
          ),
        ),
        if (onAddRoot != null) ...[
          const Gap(AdminSpacing.lg),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Button(
              addLabel ?? context.adminL10n.display.addItem,
              icon: Icons.add_rounded,
              onPressed: onAddRoot,
            ),
          ),
        ],
      ],
    );
  }
}

/// Tree row height — shared with [Tree] so the focus-card body can line up under
/// the selected row's content.
const _rowHeight = 44.0;

/// Start offset of a [Tree] row's itemBuilder content — mirrors the tree's
/// caret (22) + drag-handle (26) gutter and per-depth indent (28). The
/// focus-card body indents by this so it lines up under the selected row's
/// content (its header).
const _treeContentStart = 48.0;
const _treeIndent = 28.0;

/// The body half of the focus-card layout: the editor, rendered as the lower
/// part of the card the selected row's header opened into. Its accent side
/// and bottom borders and rounded bottom meet the header's borders to form
/// one outlined, lifted card; [depth] indents it from the start edge to line
/// up under the row's content. Escape closes (deselects via [onDismiss]).
class _FocusCardBody extends StatelessWidget {
  final int depth;
  final VoidCallback onDismiss;
  final Widget child;

  const _FocusCardBody({
    required this.depth,
    required this.onDismiss,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = Radius.circular(context.radii.radiusLarge);
    final edge = BorderSide(color: c.primary, width: context.stroke.fieldFocus);
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: _treeContentStart + depth * _treeIndent,
        bottom: AdminSpacing.md,
      ),
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): onDismiss},
        child: Focus(
          autofocus: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.only(
                bottomLeft: radius,
                bottomRight: radius,
              ),
              border: Border(left: edge, right: edge, bottom: edge),
              boxShadow: context.elevation.md,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AdminSpacing.lg),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// The inline editor card that hangs beneath the selected row — a faintly
/// primary-tinted, indented panel so it reads as the row's own expanded detail
/// rather than a detached section.
class _ExpansionCard extends StatelessWidget {
  final Widget child;

  const _ExpansionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AdminSpacing.xxl,
        AdminSpacing.xxs,
        AdminSpacing.sm,
        AdminSpacing.md,
      ),
      child: Container(
        decoration: BoxDecoration(
          // token-literal: the detail card, fainter than the selection
          color: context.colors.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(context.radii.radius),
          border: Border.all(
            // token-literal: the detail card's edge
            color: context.colors.primary.withValues(alpha: 0.16),
          ),
        ),
        padding: const EdgeInsets.all(AdminSpacing.lg),
        child: child,
      ),
    );
  }
}

/// The reorder moves open to one row; a null move is not possible there.
@immutable
class _Moves {
  final VoidCallback? up;
  final VoidCallback? down;
  final VoidCallback? indent;
  final VoidCallback? outdent;

  const _Moves({this.up, this.down, this.indent, this.outdent});
}

class _TreeEntryRow extends StatefulWidget {
  final TreeEditorEntry entry;
  final bool selected;
  final bool canAddChild;

  /// [TreeEditor.headerLabel].
  final String? headerLabel;

  /// Focus-card layout: the selected row is the *header* of the editor card —
  /// accent fill, rounded top, borders on top/left/right, open at the bottom so
  /// it meets the [_FocusCardBody] below it.
  final bool cardHeader;

  /// Focus-card layout: a non-selected row while something else is open —
  /// dimmed back so the open card holds focus.
  final bool recede;

  /// Null when the tree is read-only.
  final _Moves? moves;

  final VoidCallback? onSelect;
  final VoidCallback? onToggleVisible;
  final VoidCallback? onAddChild;
  final VoidCallback? onDelete;

  const _TreeEntryRow({
    required this.entry,
    required this.selected,
    required this.canAddChild,
    this.headerLabel,
    this.cardHeader = false,
    this.recede = false,
    this.moves,
    this.onSelect,
    this.onToggleVisible,
    this.onAddChild,
    this.onDelete,
  });

  @override
  State<_TreeEntryRow> createState() => _TreeEntryRowState();
}

class _TreeEntryRowState extends State<_TreeEntryRow> {
  bool _hover = false;

  /// The row's own Tab stop; its ring shows only while the row itself, not
  /// one of its actions, holds focus.
  final _focus = FocusNode(debugLabel: 'tree entry');

  /// Holds the row's Tab stop and its actions' as siblings: the actions sit
  /// inside the row's [Tappable] on screen, but are Tab stops of their own,
  /// not a second stop on the row.
  final _within = FocusNode(debugLabel: 'tree entry and its actions');

  /// Focus is on the row or one of its actions, which then show as they do
  /// under the pointer.
  bool _focusWithin = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void dispose() {
    _focus.dispose();
    _within.dispose();
    super.dispose();
  }

  void _onFocus() => setState(() {});

  String get _title => widget.entry.title.trim().isEmpty
      ? context.adminL10n.display.untitled
      : widget.entry.title;

  /// Runs [move] and tells a screen reader where the row went, since focus
  /// stays on it.
  VoidCallback? _announced(
    VoidCallback? move,
    String Function(String title) done,
  ) {
    if (move == null) return null;
    return () {
      move();
      SemanticsService.sendAnnouncement(
        View.of(context),
        done(_title),
        Directionality.of(context),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final dim = !entry.visible;
    final row = _row(context, entry, dim, _title);
    return widget.recede ? Opacity(opacity: 0.45, child: row) : row;
  }

  Widget _row(
    BuildContext context,
    TreeEditorEntry entry,
    bool dim,
    String title,
  ) {
    final c = context.colors;
    final radius = Radius.circular(context.radii.radius);
    final big = Radius.circular(context.radii.radiusLarge);
    // The focus card's outline, which [_FocusCardBody] continues below.
    final edge = BorderSide(color: c.primary, width: context.stroke.fieldFocus);
    final moves = widget.moves;
    final strings = context.adminL10n.display;
    final up = _announced(moves?.up, strings.movedUp);
    final down = _announced(moves?.down, strings.movedDown);
    final indent = _announced(moves?.indent, strings.indented);
    final outdent = _announced(moves?.outdent, strings.outdented);
    Widget row = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Focus(
        focusNode: _within,
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (f) => setState(() => _focusWithin = f),
        child: Tappable(
          onTap: widget.onSelect,
          focusNode: _focus,
          selected: widget.selected,
          showFocusRing: false,
          child: FocusRing(
            focused: _focus.hasPrimaryFocus,
            radius: widget.cardHeader ? 0 : context.radii.radius,
            child: Container(
              height: widget.cardHeader ? _rowHeight : null,
              decoration: widget.cardHeader
                  ? BoxDecoration(
                      color: c.primary.withValues(alpha: c.stateLayer.selected),
                      borderRadius: BorderRadius.vertical(top: big),
                      border: Border(top: edge, left: edge, right: edge),
                    )
                  : BoxDecoration(
                      color: widget.selected
                          ? c.primary.withValues(alpha: c.stateLayer.selected)
                          : null,
                      borderRadius: BorderRadius.all(radius),
                    ),
              padding: const EdgeInsetsDirectional.only(
                start: AdminSpacing.sm,
                end: AdminSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Opacity(
                      opacity: dim ? 0.5 : 1,
                      child: _label(context, entry, title),
                    ),
                  ),
                  const Gap(AdminSpacing.sm),
                  Focus(
                    parentNode: _within,
                    canRequestFocus: false,
                    skipTraversal: true,
                    child: _trailing(
                      context,
                      entry,
                      up: up,
                      down: down,
                      indent: indent,
                      outdent: outdent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (moves != null) {
      row = CallbackShortcuts(
        bindings: {
          _upKey: ?up,
          _downKey: ?down,
          _inwardKey(context): ?indent,
          _outwardKey(context): ?outdent,
        },
        child: row,
      );
    }
    return row;
  }

  static const _upKey = SingleActivator(LogicalKeyboardKey.arrowUp, alt: true);
  static const _downKey = SingleActivator(
    LogicalKeyboardKey.arrowDown,
    alt: true,
  );

  /// Alt and the arrow toward the end edge, where nesting deeper moves the
  /// row: → left to right, ← right to left.
  static SingleActivator _inwardKey(BuildContext context) => SingleActivator(
    Directionality.of(context) == TextDirection.rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight,
    alt: true,
  );

  static SingleActivator _outwardKey(BuildContext context) => SingleActivator(
    Directionality.of(context) == TextDirection.rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft,
    alt: true,
  );

  /// The title, the modified dot and the link badge, which take whatever the
  /// trailing actions leave; the title gives way first.
  Widget _label(BuildContext context, TreeEditorEntry entry, String title) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final badge = entry.badge != null
            ? _badge(context, entry.badge!)
            : entry.isHeader
            ? Tag(
                widget.headerLabel ?? context.adminL10n.display.treeHeader,
                color: c.foregroundMuted,
                variant: TagVariant.soft,
              )
            : null;
        return Row(
          children: [
            if (entry.isHeader)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: AdminSpacing.sm),
                child: Icon(
                  Icons.segment_rounded,
                  size: context.iconSizes.md,
                  color: c.foregroundMuted,
                ),
              ),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: entry.isHeader
                    ? context.type.bodyStrong.copyWith(
                        color: c.foregroundMuted,
                        letterSpacing: 0.3,
                      )
                    : context.type.bodyStrong,
              ),
            ),
            if (entry.modified)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AdminSpacing.sm,
                ),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: c.warning,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            if (badge != null) ...[
              const Gap(AdminSpacing.md),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.45,
                ),
                child: badge,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _trailing(
    BuildContext context,
    TreeEditorEntry entry, {
    VoidCallback? up,
    VoidCallback? down,
    VoidCallback? indent,
    VoidCallback? outdent,
  }) {
    final shown = _hover || _focusWithin || widget.selected;
    final addChild = widget.canAddChild ? widget.onAddChild : null;
    final onDelete = widget.onDelete;
    final l10n = context.adminL10n;
    final strings = l10n.display;
    final delete = MaterialLocalizations.of(context).deleteButtonTooltip;
    final menu = [
      if (widget.moves != null) ...[
        MenuItem(
          l10n.moveUp,
          icon: Icons.arrow_upward_rounded,
          shortcut: shortcutLabel(context, _upKey),
          onSelect: up,
        ),
        MenuItem(
          l10n.moveDown,
          icon: Icons.arrow_downward_rounded,
          shortcut: shortcutLabel(context, _downKey),
          onSelect: down,
        ),
        MenuItem(
          strings.indent,
          icon: Icons.format_indent_increase_rounded,
          shortcut: shortcutLabel(context, _inwardKey(context)),
          onSelect: indent,
        ),
        MenuItem(
          strings.outdent,
          icon: Icons.format_indent_decrease_rounded,
          shortcut: shortcutLabel(context, _outwardKey(context)),
          onSelect: outdent,
        ),
      ],
      if (addChild != null || onDelete != null) ...[
        if (widget.moves != null) const MenuDivider(),
        if (addChild != null)
          MenuItem(
            strings.addChild,
            icon: Icons.subdirectory_arrow_right_rounded,
            onSelect: addChild,
          ),
        if (onDelete != null)
          MenuItem(
            delete,
            icon: Icons.delete_outline_rounded,
            danger: true,
            onSelect: onDelete,
          ),
      ],
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Revealed on hover, focus or selection; hidden, they are no tap
        // target and no screen-reader stop — the ⋯ menu carries both — but
        // stay in the Tab order, and taking focus reveals them.
        AnimatedOpacity(
          opacity: shown ? 1 : 0,
          duration: context.motion.fast,
          curve: context.motion.standard,
          child: IgnorePointer(
            ignoring: !shown,
            child: ExcludeSemantics(
              excluding: !shown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _action(
                    context,
                    Icons.subdirectory_arrow_right_rounded,
                    strings.addChild,
                    addChild,
                  ),
                  _action(
                    context,
                    Icons.delete_outline_rounded,
                    delete,
                    onDelete,
                    danger: true,
                  ),
                ],
              ),
            ),
          ),
        ),
        _action(
          context,
          entry.visible
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          entry.visible ? strings.hideEntry : strings.showEntry,
          widget.onToggleVisible,
        ),
        if (menu.isNotEmpty)
          MenuButton(
            icon: Icons.more_horiz_rounded,
            tooltip: l10n.moreActions,
            entries: menu,
          ),
      ],
    );
  }

  Widget _badge(BuildContext context, TreeEntryBadge badge) {
    // A status takes the severity tones (and their text-safe foregrounds); an
    // emphasised badge reads in the primary, any other stays neutral.
    return Tag(
      // A path or a URL keeps its slashes in place in right-to-left text.
      bidiIsolate(badge.label),
      icon: badge.icon,
      severity: badge.tone,
      color: badge.emphasised ? context.colors.primaryText : null,
      variant: TagVariant.soft,
    );
  }

  Widget _action(
    BuildContext context,
    IconData icon,
    String tip,
    VoidCallback? onTap, {
    bool danger = false,
  }) {
    if (onTap == null) return const SizedBox.shrink();
    return IconAction(
      icon,
      label: tip,
      size: IconActionSize.small,
      danger: danger,
      color: danger ? context.colors.dangerText : null,
      onPressed: onTap,
    );
  }
}
