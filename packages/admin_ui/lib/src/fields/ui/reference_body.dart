import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../common/ui/button.dart';
import '../../common/ui/checkbox.dart';
import '../../common/ui/field_chrome.dart';
import '../../common/ui/input_decoration.dart';
import '../../common/ui/popover.dart';
import '../../common/ui/popover_menu.dart';
import '../../common/ui/skeleton.dart';
import '../../common/ui/spinner.dart';
import '../../common/ui/thumbnail_image.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'field_primitives.dart';

/// Resolves stored ids into their entities, batched. The body calls this once
/// per wave of unresolved ids — back it with a shared loader to coalesce across
/// fields. Ids absent from the result render as missing/dangling tiles.
typedef ReferenceResolver<T, K> = Future<List<T>> Function(Iterable<K> ids);

/// One page of search results. [nextCursor] null = last page.
class ReferencePage<T> {
  final List<T> items;
  final String? nextCursor;

  const ReferencePage(this.items, {this.nextCursor});
}

/// Remote, debounced, paginated lookup feeding the picker. An empty [query]
/// should return the default/recent set.
typedef ReferenceSearch<T> = Future<ReferencePage<T>> Function(
  String query, {
  String? cursor,
});

/// Renders one resolved entity — the seam for a custom look. Gets the real [T],
/// not a flattened struct; compose [ReferenceTileCard] for the standard row.
typedef ReferenceTile<T> = Widget Function(BuildContext context, T value);

enum _Phase { loading, ready, missing, error }

class _Entry<T> {
  final _Phase phase;
  final T? value;
  const _Entry(this.phase, [this.value]);
}

/// The bare reference control — selected rows + an "add" trigger that opens a
/// search picker, no label or capability chrome — so the same body sits inside
/// a [FieldShell] or one lane of a translatable field.
///
/// Generic over the caller's domain type [T] and primary-key type [K] (`int`,
/// `String`, a typed id…; [K] needs value equality, as it keys the resolve
/// cache and dedup). The stored value is a list of ids ([value]); the body
/// lazily [resolve]s them into [T]s for display, painting skeletons until each
/// arrives, so the editor renders immediately. Selecting from [search] appends
/// an id and seeds the cache.
///
/// A null [onChanged] renders it read-only: the rows with no add, remove or
/// reorder; with none, the field box shows "No reference" (see
/// [FieldState]). [enabled] false, or a disabled [FieldStateScope], disables
/// it.
class ReferenceBody<T, K extends Object> extends StatefulWidget {
  final List<K> value;
  final ValueChanged<List<K>>? onChanged;

  /// Identity: maps a resolved [T] back to its stored id.
  final K Function(T) idOf;

  final ReferenceResolver<T, K> resolve;
  final ReferenceSearch<T> search;

  /// Renders one resolved entity. Compose [ReferenceTileCard] for the default.
  final ReferenceTile<T> tile;

  /// Entities the host already holds — prefills the cache so those tiles skip
  /// the skeleton on first paint.
  final List<T>? seed;

  /// Cap on selections. `1` = single (replace-in-place, no reorder); `null`/N =
  /// multi (reorderable). The add trigger hides at the cap.
  final int? maxItems;

  /// Label on the add trigger; null reads "Link…" in the app's language.
  final String? addLabel;

  /// Placeholder in the picker's search box; null reads "Search…".
  final String? searchHint;

  final bool enabled;

  const ReferenceBody({
    super.key,
    required this.value,
    required this.onChanged,
    required this.idOf,
    required this.resolve,
    required this.search,
    required this.tile,
    this.seed,
    this.maxItems,
    this.addLabel,
    this.searchHint,
    this.enabled = true,
  });

  @override
  State<ReferenceBody<T, K>> createState() => _ReferenceBodyState<T, K>();
}

class _ReferenceBodyState<T, K extends Object>
    extends State<ReferenceBody<T, K>> {
  final _cache = <K, _Entry<T>>{};
  final _pending = <K>{};
  bool _flushScheduled = false;

  /// The picker's search box, focused when the keyboard opens the picker.
  final _searchFocus = FocusNode();

  bool get _single => widget.maxItems == 1;
  bool get _multiple => !_single;
  bool get _atCap =>
      widget.maxItems != null && widget.value.length >= widget.maxItems!;

  @override
  void initState() {
    super.initState();
    for (var t in widget.seed ?? const []) {
      _cache[widget.idOf(t)] = _Entry(_Phase.ready, t);
    }
    _ensureResolved();
  }

  @override
  void didUpdateWidget(ReferenceBody<T, K> old) {
    super.didUpdateWidget(old);
    _ensureResolved();
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  /// Mark every unresolved id loading and schedule one batched [resolve].
  void _ensureResolved() {
    var need = [
      for (var id in widget.value)
        if (!_cache.containsKey(id)) id,
    ];
    if (need.isEmpty) return;
    for (var id in need) {
      _cache[id] = const _Entry(_Phase.loading);
      _pending.add(id);
    }
    if (!_flushScheduled) {
      _flushScheduled = true;
      scheduleMicrotask(_flush);
    }
  }

  Future<void> _flush() async {
    _flushScheduled = false;
    if (_pending.isEmpty) return;
    var ids = _pending.toList();
    _pending.clear();
    try {
      var found = await widget.resolve(ids);
      if (!mounted) return;
      var byId = {for (var t in found) widget.idOf(t): t};
      setState(() {
        for (var id in ids) {
          _cache[id] = byId.containsKey(id)
              ? _Entry(_Phase.ready, byId[id])
              : const _Entry(_Phase.missing);
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        for (var id in ids) {
          _cache[id] = const _Entry(_Phase.error);
        }
      });
    }
  }

  void _retry(K id) {
    setState(() => _cache.remove(id));
    _ensureResolved();
  }

  void _remove(K id) {
    widget.onChanged?.call([
      for (var v in widget.value)
        if (v != id) v,
    ]);
  }

  void _pick(T item) {
    var id = widget.idOf(item);
    _cache[id] = _Entry(_Phase.ready, item);
    if (_single) {
      widget.onChanged?.call([id]);
    } else if (!widget.value.contains(id) && !_atCap) {
      widget.onChanged?.call([...widget.value, id]);
    }
  }

  void _reorder(int oldIndex, int newIndex) {
    var ids = [...widget.value];
    var moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);
    widget.onChanged?.call(ids);
  }

  @override
  Widget build(BuildContext context) {
    return FieldBodyScope(
      enabled: widget.enabled,
      readOnly: widget.onChanged == null,
      builder: _build,
    );
  }

  Widget _build(BuildContext context) {
    final state = FieldStateScope.of(context);
    final editable = state.enabled && !state.readOnly;
    if (widget.value.isEmpty) {
      // Disabled keeps the trigger, dimmed, like any other field.
      return state.readOnly
          ? readOnlyEmpty(context, context.adminL10n.fields.noReference)
          : _trigger();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _multiple
            ? _reorderableList(editable)
            : _row(widget.value.first, 0, editable: editable),
        if (editable && !_atCap) ...[const Gap(AdminSpacing.md), _trigger()],
      ],
    );
  }

  Widget _reorderableList(bool editable) {
    var canReorder = editable && widget.value.length > 1;
    final last = widget.value.length - 1;
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      padding: EdgeInsets.zero,
      onReorderItem: _reorder,
      children: [
        for (var i = 0; i < widget.value.length; i++)
          Padding(
            key: ValueKey(widget.value[i]),
            padding: EdgeInsets.only(bottom: i == last ? 0 : AdminSpacing.md),
            child: _row(
              widget.value[i],
              i,
              editable: editable,
              reorderable: canReorder,
            ),
          ),
      ],
    );
  }

  Widget _row(
    K id,
    int index, {
    required bool editable,
    bool reorderable = false,
  }) {
    var entry = _cache[id] ?? const _Entry(_Phase.loading);
    var content = switch (entry.phase) {
      _Phase.ready => widget.tile(context, entry.value as T),
      _Phase.loading => const _SkeletonRow(),
      _Phase.missing => _MissingRow(id: '$id'),
      _Phase.error => _ErrorRow(id: '$id', onRetry: () => _retry(id)),
    };
    return _SelectedRow(
      index: index,
      reorderable: reorderable,
      onRemove: editable ? () => _remove(id) : null,
      onRetry: entry.phase == _Phase.error ? () => _retry(id) : null,
      invalid: entry.phase == _Phase.error,
      child: content,
    );
  }

  Widget _trigger() {
    var selectedIds = widget.value.toSet();
    return Popover(
      side: PopoverSide.bottom,
      align: PopoverAlign.start,
      autofocus: false,
      anchor: (context, controller) => _AddTrigger(
        label: widget.addLabel ?? context.adminL10n.linkPlaceholder,
        controller: controller,
        searchFocus: _searchFocus,
      ),
      content: (context, controller) => _ReferencePicker<T, K>(
        searchFocus: _searchFocus,
        search: widget.search,
        idOf: widget.idOf,
        tile: widget.tile,
        selectedIds: selectedIds,
        single: _single,
        maxItems: widget.maxItems,
        hint: widget.searchHint ?? context.adminL10n.searchPlaceholder,
        onSelect: (item) {
          _pick(item);
          if (_single) controller.close();
        },
        onDeselect: _remove,
      ),
    );
  }
}

/// The standard reference row content: an optional thumbnail/glyph, a title and
/// a subtitle. Compose it inside [ReferenceTile] for the common case; return any
/// widget for a fully custom tile.
class ReferenceTileCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final ImageProvider? thumbnail;
  final IconData? icon;
  final Color? swatch;

  const ReferenceTileCard({
    super.key,
    required this.title,
    this.subtitle,
    this.thumbnail,
    this.icon,
    this.swatch,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _leading(context),
        const Gap(AdminSpacing.lg),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.type.bodyStrong,
              ),
              if (subtitle != null) ...[
                const Gap(AdminSpacing.xxs),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // The picker lays the tile on its selected and hovered
                  // row fills.
                  style: context.type.caption.copyWith(
                    color: context.colors.foregroundMutedOnTint,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _leading(BuildContext context) {
    if (thumbnail != null) {
      return ThumbnailImage(
        image: thumbnail!,
        size: _thumb,
        borderRadius: BorderRadius.circular(context.radii.radiusSmall),
      );
    }
    final colors = context.colors;
    final tint = swatch;
    return _ThumbBox(
      fill: tint == null ? colors.background : colors.statusFill(tint),
      child: Icon(
        icon ?? Icons.link_rounded,
        size: context.iconSizes.lg,
        color: tint == null
            ? colors.foregroundMuted
            : colors.readableOn(tint, surfaces: [colors.statusFill(tint)]),
      ),
    );
  }
}

/// Bordered container + leading drag handle + trailing remove, wrapped around
/// the caller's tile content (or a skeleton / missing / error stand-in).
class _SelectedRow extends StatelessWidget {
  final int index;
  final bool reorderable;
  final bool invalid;
  final VoidCallback? onRemove;
  final VoidCallback? onRetry;
  final Widget child;

  const _SelectedRow({
    required this.index,
    required this.reorderable,
    required this.invalid,
    required this.child,
    this.onRemove,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.adminL10n;
    return FieldChrome(
      invalid: invalid,
      padding: const EdgeInsets.all(AdminSpacing.md),
      child: Row(
        children: [
          if (reorderable)
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: AdminSpacing.sm),
                child: Icon(
                  Icons.drag_indicator,
                  size: context.iconSizes.md,
                  color: context.colors.foregroundFaint,
                ),
              ),
            ),
          Expanded(child: child),
          if (onRetry != null) ...[
            const Gap(AdminSpacing.md),
            CircleButton(
              icon: Icons.refresh,
              onTap: onRetry!,
              label: l10n.retry,
            ),
          ],
          if (onRemove != null) ...[
            const Gap(AdminSpacing.md),
            CircleButton(
              icon: Icons.close,
              onTap: onRemove!,
              label: l10n.remove,
            ),
          ],
        ],
      ),
    );
  }
}

class _MissingRow extends StatelessWidget {
  final String id;
  const _MissingRow({required this.id});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ThumbBox(
          fill: context.colors.background,
          child: Icon(
            Icons.link_off_rounded,
            size: context.iconSizes.lg,
            color: context.colors.foregroundMuted,
          ),
        ),
        const Gap(AdminSpacing.lg),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.adminL10n.fields.unavailable,
                style: context.type.bodyStrong.copyWith(
                  color: context.colors.foregroundMuted,
                ),
              ),
              const Gap(AdminSpacing.xxs),
              Text(
                id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.type.caption.copyWith(
                  color: context.colors.foregroundMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final String id;
  final VoidCallback onRetry;
  const _ErrorRow({required this.id, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        _ThumbBox(
          fill: colors.statusFill(colors.danger),
          border: colors.statusBorder(colors.danger),
          child: Icon(
            Icons.error_outline_rounded,
            size: context.iconSizes.lg,
            color: colors.dangerText,
          ),
        ),
        const Gap(AdminSpacing.lg),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.adminL10n.couldNotLoad,
                style: context.type.bodyStrong.copyWith(
                  color: colors.dangerText,
                ),
              ),
              const Gap(AdminSpacing.xxs),
              Text(
                id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.type.caption.copyWith(
                  color: colors.foregroundMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const SkeletonGroup(
      child: Row(
        children: [
          Skeleton(width: _thumb, height: _thumb),
          Gap(AdminSpacing.lg),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 140, height: 10),
                Gap(AdminSpacing.md),
                Skeleton(width: 90, height: 9),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The add trigger: an [AddRowButton] with the link glyph that opens the
/// picker — on Enter and Space, or ArrowDown as a field trigger does. Opened
/// from the keyboard, the picker's [searchFocus] takes focus, as a pointer's
/// open gives it anyway.
class _AddTrigger extends StatefulWidget {
  final String label;
  final PopoverController controller;
  final FocusNode searchFocus;

  const _AddTrigger({
    required this.label,
    required this.controller,
    required this.searchFocus,
  });

  @override
  State<_AddTrigger> createState() => _AddTriggerState();
}

class _AddTriggerState extends State<_AddTrigger> {
  final _focus = FocusNode(debugLabel: 'ReferenceBody add');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _toggle() {
    final controller = widget.controller;
    if (controller.isOpen) {
      controller.close();
      return;
    }
    // A pointer press leaves focus where it was, so holding it here means
    // the keyboard pressed the button.
    final fromKeyboard = _focus.hasPrimaryFocus;
    controller.open();
    if (!fromKeyboard) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && controller.isOpen) widget.searchFocus.requestFocus();
    });
  }

  void _open() {
    if (!widget.controller.isOpen) _toggle();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = FieldStateScope.of(context).enabled;
    return CallbackShortcuts(
      bindings: {
        if (enabled) ...{
          const SingleActivator(LogicalKeyboardKey.arrowDown): _open,
          const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): _open,
        },
      },
      child: AddRowButton(
        label: widget.label,
        icon: Icons.add_link_rounded,
        focusNode: _focus,
        expanded: widget.controller.isOpen,
        onPressed: enabled ? _toggle : null,
      ),
    );
  }
}

/// The picker popover: a search box over [search] with its own state machine —
/// loading / results / empty / error / load-more.
class _ReferencePicker<T, K extends Object> extends StatefulWidget {
  final FocusNode searchFocus;
  final ReferenceSearch<T> search;
  final K Function(T) idOf;
  final ReferenceTile<T> tile;
  final Set<K> selectedIds;
  final bool single;
  final int? maxItems;
  final String hint;
  final ValueChanged<T> onSelect;
  final ValueChanged<K> onDeselect;

  const _ReferencePicker({
    required this.searchFocus,
    required this.search,
    required this.idOf,
    required this.tile,
    required this.selectedIds,
    required this.single,
    required this.maxItems,
    required this.hint,
    required this.onSelect,
    required this.onDeselect,
  });

  @override
  State<_ReferencePicker<T, K>> createState() => _ReferencePickerState<T, K>();
}

class _ReferencePickerState<T, K extends Object>
    extends State<_ReferencePicker<T, K>> {
  final _controller = TextEditingController();
  late final Set<K> _selected = {...widget.selectedIds};

  Timer? _debounce;
  int _req = 0;
  String _query = '';
  List<T> _results = [];
  String? _cursor;
  bool _loading = false;
  bool _loadingMore = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _run(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQuery(String q) {
    setState(() => _query = q);
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 250),
      () => _run(reset: true),
    );
  }

  Future<void> _run({required bool reset}) async {
    var token = ++_req;
    setState(() {
      _failed = false;
      if (reset) {
        _loading = true;
        _results = [];
        _cursor = null;
      } else {
        _loadingMore = true;
      }
    });
    try {
      var page = await widget.search(_query, cursor: reset ? null : _cursor);
      if (token != _req || !mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _results = reset ? page.items : [..._results, ...page.items];
        _cursor = page.nextCursor;
      });
    } catch (_) {
      if (token != _req || !mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _failed = true;
      });
    }
  }

  void _tap(T item) {
    if (widget.single) {
      widget.onSelect(item);
      return;
    }
    var id = widget.idOf(item);
    if (_selected.contains(id)) {
      widget.onDeselect(id);
      setState(() => _selected.remove(id));
    } else if (!_atCap) {
      widget.onSelect(item);
      setState(() => _selected.add(id));
    }
  }

  bool get _atCap =>
      !widget.single &&
      widget.maxItems != null &&
      _selected.length >= widget.maxItems!;

  @override
  Widget build(BuildContext context) {
    return PopoverMenuSurface(
      width: 360,
      maxHeight: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _searchBox(),
          Divider(height: 1, thickness: 1, color: context.colors.separator),
          Flexible(child: _results.isEmpty ? _placeholder() : _list()),
        ],
      ),
    );
  }

  /// The search box, drawn as a listbox menu's filter box is.
  Widget _searchBox() {
    return Padding(
      padding: const EdgeInsets.all(AdminSpacing.sm),
      // The field's own state is not the box's.
      child: FieldStateScope(
        child: ChromelessFieldScope.reset(
          child: Builder(
            builder: (context) => TextField(
              controller: _controller,
              focusNode: widget.searchFocus,
              autofocus: true,
              onChanged: _onQuery,
              style: fieldTextStyle(context),
              decoration: fieldInputDecoration(
                context,
                hint: widget.hint,
                size: ControlSize.small,
                leadingIcon: Icons.search_rounded,
                suffix: _loading
                    ? Spinner(size: context.sizes.fieldIcon, announce: false)
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AdminSpacing.xxl),
        child: Center(child: Spinner(size: context.iconSizes.lg)),
      );
    }
    final l10n = context.adminL10n;
    if (_failed) return _message(l10n.searchFailed, retry: true);
    if (_query.trim().isEmpty) return _message(l10n.fields.typeToSearch);
    return _message(l10n.noResults);
  }

  Widget _message(String text, {bool retry = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AdminSpacing.xl,
        horizontal: AdminSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: context.type.bodySmall.copyWith(
              color: context.colors.foregroundMuted,
            ),
          ),
          if (retry) ...[
            const Gap(AdminSpacing.md),
            Button.ghost(
              context.adminL10n.retry,
              size: ControlSize.small,
              onPressed: () => _run(reset: true),
            ),
          ],
        ],
      ),
    );
  }

  Widget _list() {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: AdminSpacing.xs),
      itemCount: _results.length + (_cursor != null ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _results.length) return _loadMore();
        return _resultRow(_results[i]);
      },
    );
  }

  Widget _resultRow(T item) {
    var id = widget.idOf(item);
    var selected = _selected.contains(id);
    var inert = !selected && _atCap;
    // The fill is the ink's own Material, so hover and focus show over a
    // selected row too.
    var row = Material(
      color: selected ? context.colors.primaryFaint : Colors.transparent,
      child: InkWell(
        onTap: inert ? null : () => _tap(item),
        mouseCursor: WidgetStateMouseCursor.clickable,
        hoverColor: context.colors.hoverOverlay,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AdminSpacing.lg,
            vertical: AdminSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Opacity(
                  opacity: inert
                      ? context.colors.stateLayer.disabledContent
                      : 1,
                  child: SelectionContainer.disabled(
                    child: widget.tile(context, item),
                  ),
                ),
              ),
              const Gap(AdminSpacing.md),
              if (widget.single)
                Icon(
                  selected ? Icons.check_circle_rounded : null,
                  size: context.iconSizes.lg,
                  color: context.colors.primaryText,
                )
              else
                // Drawn only: the row is the control.
                IgnorePointer(
                  child: ExcludeFocus(
                    child: ExcludeSemantics(
                      child: Check(value: selected, readOnly: !inert),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return Semantics(
      container: true,
      selected: widget.single ? selected : null,
      checked: widget.single ? null : selected,
      enabled: !inert,
      child: row,
    );
  }

  Widget _loadMore() {
    if (_loadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AdminSpacing.lg),
        child: Center(child: Spinner(size: context.iconSizes.md)),
      );
    }
    return InkWell(
      onTap: () => _run(reset: false),
      mouseCursor: WidgetStateMouseCursor.clickable,
      hoverColor: context.colors.background,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AdminSpacing.lg),
        child: Center(
          child: SelectionContainer.disabled(
            child: Text(
              context.adminL10n.loadMore,
              style: context.type.weighted(
                context.type.bodySmall.copyWith(
                  color: context.colors.primaryText,
                ),
                FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The side of a reference row's leading thumbnail.
const _thumb = 36.0;

/// A reference row's leading square: [fill] under a hairline [border] (the
/// theme's border when null), on the small radius, holding [child].
class _ThumbBox extends StatelessWidget {
  final Color fill;
  final Color? border;
  final Widget child;

  const _ThumbBox({required this.fill, this.border, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _thumb,
      height: _thumb,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(context.radii.radiusSmall),
        border: Border.all(color: border ?? context.colors.border),
      ),
      child: child,
    );
  }
}
