import 'package:material_ui/material_ui.dart';

import '../../common/ui/button.dart';
import '../../common/ui/error_text.dart';
import '../../common/ui/icon_action.dart';
import '../../common/ui/menu.dart';
import '../../common/ui/popover.dart';
import '../../common/ui/tabs.dart';
import '../../common/ui/tip.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/breakpoints.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../saved_view.dart';
import 'save_view_dialog.dart';

/// Which form a [SavedViewsBar] takes.
enum SavedViewsLayout {
  /// [menu] while the bar is narrower than the theme's medium breakpoint
  /// (`context.breakpoints.medium`, 600 in every shipped theme), [strip]
  /// from there up. The bar goes by its own width, not the window's.
  auto,

  /// A tab per view, which scrolls behind an edge fade, with a menu of every
  /// view, once the views outgrow the row.
  strip,

  /// The active view's name as a button that opens a menu of every view,
  /// then the active view's own actions: for a phone, where a strip would
  /// cut the name of the view at its edge. Its controls are the theme's
  /// medium size, as the top bar's are, to take a finger, Reset as an icon.
  /// Moving a view is left to the strip.
  menu,
}

/// The height of a small [Tabs] strip, under which the
/// [SavedViewsLayout.menu] row never goes.
const _stripHeight = 32.0;

/// The saved-views bar — the row above a collection that switches between
/// named filter/sort presets. Shows the active view, a dirty indicator with
/// Save / Reset, a "+" to save the current query as a new view, and a per-view
/// menu (rename / duplicate / move / set default / delete).
///
/// From the medium breakpoint up ([layout]) it is a [Tabs] strip (selection,
/// scroll, keyboard focus, a11y, an overflow menu when the views outgrow the
/// row) with each view's actions as its [TabItem.menu]: a caret on the
/// hovered, focused or active view, a secondary click or long press, or
/// Shift+F10 on the focused view. Narrower, it is a menu under the active
/// view's name, so no name is cut at the edge of a phone.
///
/// With [onSelectAll] it leads with a tab meaning no view ([allLabel], "All"
/// by default), selected while [activeId] is null: every row, as
/// `SavedViewsController.clearView` restores them.
///
/// Pure View — controlled by [views] / [activeId] / [dirty] and reports intent
/// through callbacks; a null action callback hides its menu entry. [onCreate]
/// and [onRenamed] take the name the bar asks for with [showSaveViewDialog]:
/// a Screen that names views another way leaves them null and offers its own
/// action.
class SavedViewsBar extends StatelessWidget {
  final List<SavedView> views;

  /// The active view's id; null while no view is active, which selects the
  /// [allLabel] tab.
  final String? activeId;

  /// Whether the query has drifted from the active view, or, with none
  /// active, from every row: a dot on its tab, with Reset and (for a view)
  /// Save.
  final bool dirty;
  final ValueChanged<SavedView> onSelect;

  /// Which form the bar takes; [SavedViewsLayout.auto] by default.
  final SavedViewsLayout layout;

  /// Leads the views with a tab meaning no view, selected while [activeId]
  /// is null, and is called when it is picked: typically
  /// `SavedViewsController.clearView`. Null shows no such tab.
  final VoidCallback? onSelectAll;

  /// The [onSelectAll] tab's label; the localized "All" when null.
  final String? allLabel;

  final VoidCallback? onSaveChanges;
  final VoidCallback? onDiscardChanges;

  /// Offers the "+" and saves the current query as a new view under the
  /// name, and with the scope, that the bar asks for with
  /// [showSaveViewDialog]: typically `SavedViewsController.saveAsNew`.
  final ValueChanged<({String name, SavedViewScope scope})>? onCreate;

  /// Whether [onCreate]'s dialog asks who sees the view. Without the
  /// question every new view is [SavedViewScope.personal].
  final bool askScope;

  /// Offers "Rename" in each view's menu and renames the view to the name
  /// the bar asks for with [showSaveViewDialog]: typically
  /// `SavedViewsController.rename`. Not called when the name is unchanged.
  final void Function(SavedView view, String name)? onRenamed;

  /// Copies a view, with the name its copy takes in the app's language:
  /// "Leads copy", "Leads (copie)". `SavedViewsController.duplicate` takes
  /// both.
  final void Function(SavedView view, String copyName)? onDuplicate;

  final ValueChanged<SavedView>? onDelete;
  final ValueChanged<SavedView>? onSetDefault;

  /// The views' new order, as every id first to last, after a "Move left" /
  /// "Move right". Null hides those entries.
  final ValueChanged<List<String>>? onReorder;

  /// The raw error of the last failed store call (e.g.
  /// `SavedViewsController.lastError`), shown inline in words from
  /// [ErrorTextScope.describe]; null shows nothing.
  final Object? error;

  /// Offers "Retry" beside [error].
  final VoidCallback? onRetry;

  /// Offers a dismiss beside [error].
  final VoidCallback? onDismissError;

  const SavedViewsBar({
    super.key,
    required this.views,
    required this.activeId,
    required this.dirty,
    required this.onSelect,
    this.layout = SavedViewsLayout.auto,
    this.onSelectAll,
    this.allLabel,
    this.onSaveChanges,
    this.onDiscardChanges,
    this.onCreate,
    this.askScope = true,
    this.onRenamed,
    this.onDuplicate,
    this.onDelete,
    this.onSetDefault,
    this.onReorder,
    this.error,
    this.onRetry,
    this.onDismissError,
  }) : assert(
         allLabel == null || onSelectAll != null,
         'allLabel names the tab onSelectAll adds',
       );

  String _allLabel(BuildContext context) =>
      allLabel ?? context.adminL10n.collection.allViews;

  /// [views]' ids with the one at [from] moved to [to].
  List<String> _moved(int from, int to) {
    final ids = [for (final v in views) v.id];
    final id = ids.removeAt(from);
    ids.insert(to, id);
    return ids;
  }

  Future<void> _create(BuildContext context) async {
    final answer = await showSaveViewDialog(context, askScope: askScope);
    if (answer != null) onCreate?.call(answer);
  }

  Future<void> _rename(BuildContext context, SavedView view) async {
    final answer = await showSaveViewDialog(
      context,
      initialName: view.name,
      initialScope: view.scope,
      askScope: false,
      rename: true,
    );
    if (answer != null && answer.name != view.name) {
      onRenamed?.call(view, answer.name);
    }
  }

  /// The actions on the view at [index]: rename, duplicate and set as
  /// default, then, with [moves], move left and right, then delete.
  List<MenuEntry> _menuFor(
    BuildContext context,
    int index, {
    bool moves = true,
  }) {
    final v = views[index];
    final strings = context.adminL10n.collection;
    // Left and right as drawn: a right-to-left strip runs the other way.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final leftward = rtl ? index + 1 : index - 1;
    final rightward = rtl ? index - 1 : index + 1;
    bool inRange(int i) => i >= 0 && i < views.length;
    final reorder = moves ? onReorder : null;
    // The arrows mirror right to left, so the one drawn pointing left is
    // "forward" there.
    final left = rtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded;
    final right = rtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded;
    final moveEntries = [
      if (reorder != null && inRange(leftward))
        MenuItem(
          strings.moveLeft,
          icon: left,
          onSelect: () => reorder(_moved(index, leftward)),
        ),
      if (reorder != null && inRange(rightward))
        MenuItem(
          strings.moveRight,
          icon: right,
          onSelect: () => reorder(_moved(index, rightward)),
        ),
    ];
    final edits = [
      if (onRenamed != null)
        MenuItem(
          strings.rename,
          icon: Icons.edit_outlined,
          onSelect: () => _rename(context, v),
        ),
      if (onDuplicate != null)
        MenuItem(
          strings.duplicate,
          icon: Icons.copy_rounded,
          onSelect: () => onDuplicate!(v, strings.copyOf(v.name)),
        ),
      if (onSetDefault != null && !v.isDefault)
        MenuItem(
          strings.setAsDefault,
          icon: Icons.star_outline_rounded,
          onSelect: () => onSetDefault!(v),
        ),
    ];
    return [
      ...edits,
      if (edits.isNotEmpty && moveEntries.isNotEmpty) const MenuDivider(),
      ...moveEntries,
      if (onDelete != null) ...[
        if (edits.isNotEmpty || moveEntries.isNotEmpty) const MenuDivider(),
        MenuItem(
          MaterialLocalizations.of(context).deleteButtonTooltip,
          icon: Icons.delete_outline,
          danger: true,
          onSelect: () => onDelete!(v),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final error = this.error;

    return LayoutBuilder(
      builder: (context, constraints) {
        final menu = switch (layout) {
          SavedViewsLayout.strip => false,
          SavedViewsLayout.menu => true,
          SavedViewsLayout.auto => AdminBreakpoint.forWidth(
            constraints.maxWidth,
            context.breakpoints,
          ).isCompact,
        };
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (menu) _menuRow(context) else _strip(context),
              if (error != null)
                _ErrorNote(
                  error: error,
                  onRetry: onRetry,
                  onDismiss: onDismissError,
                ),
            ],
          ),
        );
      },
    );
  }

  /// Reset and Save while [dirty], then the "+": small beside the strip;
  /// in the [SavedViewsLayout.menu] form, [touch], the theme's medium size,
  /// with Reset as an icon and Save without one, so they still leave the
  /// active view's name room on a phone.
  List<Widget> _actions(BuildContext context, {bool touch = false}) {
    final strings = context.adminL10n;
    final size = touch ? ControlSize.medium : ControlSize.small;
    final create = onCreate == null ? null : () => _create(context);
    return [
      if (dirty) ...[
        const Gap(AdminSpacing.sm),
        if (onDiscardChanges != null)
          touch
              ? Button.icon(
                  Icons.undo_rounded,
                  semanticLabel: strings.reset,
                  variant: ButtonVariant.ghost,
                  size: size,
                  onPressed: onDiscardChanges,
                )
              : Button.ghost(
                  strings.reset,
                  size: size,
                  onPressed: onDiscardChanges,
                ),
        // Nothing to save into while no view is active.
        if (onSaveChanges != null && activeId != null) ...[
          const Gap(AdminSpacing.xs),
          Button.primary(
            MaterialLocalizations.of(context).saveButtonLabel,
            size: size,
            icon: touch ? null : Icons.bookmark_added_outlined,
            onPressed: onSaveChanges,
          ),
        ],
      ],
      if (create != null) ...[
        const Gap(AdminSpacing.xs),
        Button.icon(
          Icons.add,
          semanticLabel: strings.collection.saveAsNewView,
          variant: ButtonVariant.ghost,
          size: size,
          onPressed: create,
        ),
      ],
    ];
  }

  Widget _strip(BuildContext context) {
    final strings = context.adminL10n;
    final onSelectAll = this.onSelectAll;
    final lead = onSelectAll == null ? 0 : 1;
    final activeIndex = views.indexWhere((v) => v.id == activeId);
    return Row(
      children: [
        Expanded(
          child: Tabs(
            baseline: false,
            size: ControlSize.small,
            selected: activeId == null
                ? lead - 1
                : activeIndex < 0
                ? -1
                : activeIndex + lead,
            onChanged: (i) =>
                i < lead ? onSelectAll!() : onSelect(views[i - lead]),
            overflowMenuLabel: strings.collection.moreViews,
            tabs: [
              if (onSelectAll != null)
                TabItem(
                  _allLabel(context),
                  trailing: _CaretRoom(
                    child: _badges(false, dirty && activeId == null),
                  ),
                ),
              for (final (i, v) in views.indexed) _tabFor(context, i, v),
            ],
          ),
        ),
        ..._actions(context),
      ],
    );
  }

  Widget _menuRow(BuildContext context) {
    final strings = context.adminL10n.collection;
    final index = views.indexWhere((v) => v.id == activeId);
    final active = index < 0 ? null : views[index];
    final all = onSelectAll != null && activeId == null;
    final name = active?.name ?? (all ? _allLabel(context) : null);
    final actions = index < 0
        ? const <MenuEntry>[]
        : _menuFor(context, index, moves: false);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _stripHeight),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Menu(
                align: PopoverAlign.start,
                entries: [
                  ..._choices(context),
                  if (actions.isNotEmpty) ...[const MenuDivider(), ...actions],
                ],
                builder: (context, menu) => Button.ghost(
                  name ?? strings.moreViews,
                  semanticLabel: name == null
                      ? null
                      : strings.currentView(name),
                  trailingIcon: Icons.expand_more_rounded,
                  onPressed: menu.toggle,
                ),
              ),
            ),
          ),
          ..._actions(context, touch: true),
        ],
      ),
    );
  }

  /// Every view as a choice in the [SavedViewsLayout.menu] form, the active
  /// one checked and the default one captioned, after the [onSelectAll]
  /// choice.
  List<MenuEntry> _choices(BuildContext context) {
    final strings = context.adminL10n.collection;
    final onSelectAll = this.onSelectAll;
    return [
      if (onSelectAll != null)
        MenuItem(
          _allLabel(context),
          checked: activeId == null,
          onSelect: () {
            if (activeId != null) onSelectAll();
          },
        ),
      for (final v in views)
        MenuItem(
          v.name,
          icon: _scopeIcon(v),
          description: v.isDefault ? strings.defaultView : null,
          checked: v.id == activeId,
          onSelect: () {
            if (v.id != activeId) onSelect(v);
          },
        ),
    ];
  }

  static IconData _scopeIcon(SavedView v) => v.scope == SavedViewScope.shared
      ? Icons.group_outlined
      : Icons.person_outline;

  TabItem _tabFor(BuildContext context, int index, SavedView v) {
    final entries = _menuFor(context, index);
    final isActiveDirty = dirty && v.id == activeId;
    return TabItem(
      v.name,
      icon: _scopeIcon(v),
      trailing: _badges(v.isDefault, isActiveDirty),
      menu: entries.isEmpty ? null : entries,
      menuLabel: context.adminL10n.collection.viewOptions(v.name),
    );
  }

  Widget? _badges(bool isDefault, bool isActiveDirty) {
    if (!isDefault && !isActiveDirty) return null;
    return _Badges(isDefault: isDefault, dirty: isActiveDirty);
  }
}

/// [child], then the room a view tab's menu caret takes, for the "All" tab,
/// which has no menu: so it stands as far from the tab after it as the views
/// do from each other.
class _CaretRoom extends StatelessWidget {
  final Widget? child;

  const _CaretRoom({required this.child});

  @override
  Widget build(BuildContext context) {
    final room = SizedBox(width: IconActionSize.inline.glyph);
    final child = this.child;
    if (child == null) return room;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [child, const Gap(AdminSpacing.sm), room],
    );
  }
}

/// The default star and the unsaved-changes dot, each at least 3:1 on the
/// bar, and named for assistive technology.
class _Badges extends StatelessWidget {
  final bool isDefault;
  final bool dirty;
  const _Badges({required this.isDefault, required this.dirty});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDefault)
          Icon(
            Icons.star_rounded,
            size: context.iconSizes.xs,
            semanticLabel: context.adminL10n.collection.defaultView,
            color: colors.readableOn(
              colors.foregroundMuted,
              surfaces: [colors.surface],
              minContrast: 3,
            ),
          ),
        if (isDefault && dirty) const Gap(AdminSpacing.xs),
        if (dirty)
          Semantics(
            label: context.adminL10n.unsavedChanges,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.readableOn(
                  colors.warning,
                  surfaces: [colors.surface],
                  minContrast: 3,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

/// A failed store call, in words, under the strip with its retry and
/// dismiss — announced as it appears.
class _ErrorNote extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const _ErrorNote({required this.error, this.onRetry, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final message = ErrorTextScope.describe(context, error);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AdminSpacing.md,
        0,
        0,
        AdminSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: context.iconSizes.md,
            color: colors.dangerText,
          ),
          const Gap(AdminSpacing.sm),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Tip(
                message: message,
                excludeFromSemantics: true,
                child: Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.bodySmall.copyWith(
                    color: colors.dangerText,
                  ),
                ),
              ),
            ),
          ),
          if (onRetry != null) ...[
            const Gap(AdminSpacing.sm),
            Button.ghost(
              context.adminL10n.retry,
              size: ControlSize.small,
              onPressed: onRetry,
            ),
          ],
          if (onDismiss != null) ...[
            const Gap(AdminSpacing.xs),
            IconAction.close(
              label: MaterialLocalizations.of(context).modalBarrierDismissLabel,
              size: IconActionSize.small,
              onPressed: onDismiss,
            ),
          ],
        ],
      ),
    );
  }
}
