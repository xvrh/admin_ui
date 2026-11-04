import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../common/fuzzy.dart';
import '../common/ui/icon_action.dart';
import '../common/ui/input_decoration.dart';
import '../common/ui/listbox.dart';
import '../common/ui/tappable.dart';
import '../l10n/admin_ui_localizations.dart';
import '../theme/palette.dart';
import '../theme/spacing.dart';
import '../theme/tokens.dart';

/// One entry in an [InsertPicker]: something a host can insert, such as a
/// section of a page or a block in prose. Surface-agnostic: a layout gallery
/// and a prose insert menu both build these from their catalogs.
class InsertPickerEntry {
  final String id;
  final String label;
  final String description;
  final IconData icon;

  /// A pre-built icon widget shown in place of [icon] — for catalogs whose icons
  /// aren't [IconData] (e.g. appflowy's SVG glyphs). [icon] stays the fallback.
  final Widget? iconWidget;

  /// Section header this entry groups under. Entries sharing a category render
  /// together; category order follows first appearance. Empty groups the entry
  /// under no header.
  final String category;

  /// Extra search terms beyond [label]/[description].
  final List<String> keywords;

  /// Builds a live preview of this entry for the picker's preview pane, shown
  /// when this entry is highlighted. Null marks an entry with no preview
  /// (rendered as an inline-insert hint instead). Built lazily per selection,
  /// so the builder may own throwaway state (a scratch model) it disposes when
  /// unmounted.
  final WidgetBuilder? preview;

  const InsertPickerEntry({
    required this.id,
    required this.label,
    required this.icon,
    this.iconWidget,
    this.description = '',
    this.category = '',
    this.keywords = const [],
    this.preview,
  });
}

/// A searchable, sectioned insert picker, like a slash menu or a block
/// inserter: type to fuzzy-filter, ↑/↓ (and Home/End, PageUp/PageDown) to
/// move the highlight, ↵ to insert, esc to dismiss. Renders the search field
/// + grouped list only (no dialog/popover chrome) so a host can mount it in
/// either. Fires [onSelect] with the chosen entry; [onDismiss] on escape.
///
/// The list is a listbox: focus stays in the search field while the
/// highlighted option reads as focused, and a screen reader hears each option
/// as the keyboard reaches it ("Hero, 1 of 12").
///
/// When some entry has an [InsertPickerEntry.preview], the preview sits in a
/// second pane beside the list — or, where [width] + [previewWidth] does not
/// fit, below it on demand, behind a Preview toggle by the search field.
class InsertPicker extends StatefulWidget {
  final List<InsertPickerEntry> entries;

  /// Called with the entry the user picks.
  final ValueChanged<InsertPickerEntry> onSelect;

  final VoidCallback? onDismiss;

  /// The search field's placeholder; null reads "Search…" in the app's
  /// language.
  final String? hint;

  /// The accessible name of the list; null reads "Choices" in the app's
  /// language. A host names what its entries are ("Blocks").
  final String? semanticLabel;

  final double width;
  final double maxListHeight;
  final double previewWidth;

  const InsertPicker({
    super.key,
    required this.entries,
    required this.onSelect,
    this.onDismiss,
    this.hint,
    this.semanticLabel,
    this.width = 360,
    this.maxListHeight = 420,
    this.previewWidth = 300,
  });

  @override
  State<InsertPicker> createState() => _InsertPickerState();
}

/// One row of the list: a category header, or an entry and its place among
/// the entries.
typedef _Item = ({String? header, InsertPickerEntry? entry, int ordinal});

class _InsertPickerState extends State<InsertPicker> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  late final _listbox = ListboxController(onActivate: _activate);
  String _query = '';
  List<_Item> _items = const [];
  int _count = 0;

  /// The one-pane layout's preview, shown on demand.
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _rebuild();
  }

  @override
  void didUpdateWidget(InsertPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.entries, widget.entries)) _rebuild();
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    _listbox.dispose();
    super.dispose();
  }

  /// Best fuzzy score for [e] against the current query, or null to exclude.
  /// Label matches outrank keyword matches, which outrank description matches.
  int? _score(InsertPickerEntry e) {
    if (_query.isEmpty) return 0;
    int? best;
    void consider(FuzzyMatch? m, int boost) {
      if (m == null) return;
      final s = m.score + boost;
      if (best == null || s > best!) best = s;
    }

    consider(fuzzyMatch(_query, e.label), 100);
    for (final k in e.keywords) {
      consider(fuzzyMatch(_query, k), 20);
    }
    consider(fuzzyMatch(_query, e.description), 0);
    return best;
  }

  /// The entries to show, in display order. Empty query groups by category
  /// (first-seen order, stable within a category) so headers stay contiguous;
  /// a query flattens and sorts by score (best first).
  List<InsertPickerEntry> get _visible {
    if (_query.isEmpty) return _byCategory(widget.entries);
    final scored = <(int, int, InsertPickerEntry)>[];
    for (var i = 0; i < widget.entries.length; i++) {
      final s = _score(widget.entries[i]);
      if (s != null) scored.add((s, i, widget.entries[i]));
    }
    // Higher score first; original order breaks ties (stable).
    scored.sort((a, b) => a.$1 == b.$1 ? a.$2.compareTo(b.$2) : b.$1 - a.$1);
    return [for (final r in scored) r.$3];
  }

  static List<InsertPickerEntry> _byCategory(List<InsertPickerEntry> es) {
    final order = <String>[];
    final buckets = <String, List<InsertPickerEntry>>{};
    for (final e in es) {
      buckets
          .putIfAbsent(e.category, () {
            order.add(e.category);
            return [];
          })
          .add(e);
    }
    return [for (final cat in order) ...buckets[cat]!];
  }

  /// Lays the visible entries out as rows — headers only while browsing —
  /// and hands the listbox the new options, highlighting the first.
  void _rebuild() {
    final grouped = _query.isEmpty;
    final items = <_Item>[];
    String? lastCat;
    var ordinal = 0;
    for (final e in _visible) {
      if (grouped && e.category.isNotEmpty && e.category != lastCat) {
        items.add((header: e.category, entry: null, ordinal: -1));
        lastCat = e.category;
      }
      items.add((header: null, entry: e, ordinal: ordinal++));
    }
    _items = items;
    _count = ordinal;
    _listbox.reset(
      items.length,
      labelOf: (i) => items[i].entry?.label ?? '',
      enabledOf: (i) => items[i].entry != null,
    );
  }

  InsertPickerEntry? get _highlighted {
    final i = _listbox.highlighted;
    return i == null ? null : _items[i].entry;
  }

  void _activate(int index) {
    final entry = _items[index].entry;
    if (entry != null) widget.onSelect(entry);
  }

  void _commit() {
    final i = _listbox.highlighted;
    if (i != null) _activate(i);
  }

  void _onQueryChanged(String v) => setState(() {
    _query = v;
    _rebuild();
  });

  KeyEventResult _onSearchKey(FocusNode node, KeyEvent event) {
    final result = _listbox.handleKey(event, textInput: true);
    final enter =
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    // Enter with nothing to pick stays in the field.
    return enter ? KeyEventResult.handled : result;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasPreview = widget.entries.any((e) => e.preview != null);

    return CallbackShortcuts(
      bindings: {
        if (widget.onDismiss != null)
          const SingleActivator(LogicalKeyboardKey.escape): widget.onDismiss!,
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final room = constraints.maxWidth;
          final twoPane =
              widget.width + widget.previewWidth + context.stroke.hairline;
          if (!hasPreview) {
            return _singlePane(context, c, math.min(widget.width, room));
          }
          if (room >= twoPane) return _twoPane(context, c);
          return _onePane(context, c, math.min(twoPane, room));
        },
      ),
    );
  }

  Widget _singlePane(BuildContext context, AdminPalette c, double width) =>
      SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _searchField(),
            const Gap(AdminSpacing.sm),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: widget.maxListHeight),
                child: _count == 0 ? _empty(c) : _list(context),
              ),
            ),
          ],
        ),
      );

  Widget _twoPane(BuildContext context, AdminPalette c) => SizedBox(
    width: widget.width + widget.previewWidth + context.stroke.hairline,
    height: widget.maxListHeight,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: widget.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _searchField(),
              const Gap(AdminSpacing.sm),
              Expanded(child: _count == 0 ? _empty(c) : _list(context)),
            ],
          ),
        ),
        Container(width: context.stroke.hairline, color: c.border),
        SizedBox(width: widget.previewWidth, child: _previewPane(context, c)),
      ],
    ),
  );

  /// Too narrow for two panes: the list takes the width, and the preview
  /// opens below it on demand.
  Widget _onePane(BuildContext context, AdminPalette c, double width) =>
      SizedBox(
        width: width,
        height: widget.maxListHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: _searchField()),
                const Gap(AdminSpacing.sm),
                IconAction(
                  Icons.visibility_outlined,
                  label: context.adminL10n.display.preview,
                  selected: _showPreview,
                  expanded: _showPreview,
                  onPressed: () => setState(() => _showPreview = !_showPreview),
                ),
              ],
            ),
            const Gap(AdminSpacing.sm),
            Expanded(child: _count == 0 ? _empty(c) : _list(context)),
            if (_showPreview) ...[
              Container(height: context.stroke.hairline, color: c.border),
              SizedBox(
                height: widget.maxListHeight / 2,
                child: _previewPane(context, c),
              ),
            ],
          ],
        ),
      );

  Widget _previewPane(BuildContext context, AdminPalette c) =>
      ListenableBuilder(
        listenable: _listbox,
        builder: (context, _) {
          final sel = _highlighted;
          final hasLive = sel?.preview != null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AdminSpacing.lg,
                  AdminSpacing.sm,
                  AdminSpacing.lg,
                  AdminSpacing.md,
                ),
                child: Row(
                  children: [
                    Icon(
                      hasLive
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: context.iconSizes.sm,
                      color: c.foregroundMuted,
                    ),
                    const Gap(AdminSpacing.sm),
                    Text(
                      hasLive
                          ? context.adminL10n.display.previewHeading
                          : context.adminL10n.display.noPreviewHeading,
                      style: context.type.caption.copyWith(
                        color: c.foregroundMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: sel == null
                    ? const SizedBox.shrink()
                    : hasLive
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AdminSpacing.md,
                          0,
                          AdminSpacing.md,
                          AdminSpacing.md,
                        ),
                        child: KeyedSubtree(
                          key: ValueKey(sel.id),
                          child: sel.preview!(context),
                        ),
                      )
                    : _previewEmpty(c, sel),
              ),
            ],
          );
        },
      );

  Widget _previewEmpty(AdminPalette c, InsertPickerEntry e) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.background,
              borderRadius: BorderRadius.circular(context.radii.radius),
              border: Border.all(color: c.border),
            ),
            child: Icon(
              e.icon,
              size: context.iconSizes.xl,
              color: c.foregroundMuted,
            ),
          ),
          const Gap(AdminSpacing.md),
          Text(
            e.label,
            style: context.type.bodyStrong,
            textAlign: TextAlign.center,
          ),
          const Gap(AdminSpacing.xs),
          Text(
            context.adminL10n.display.insertsInline,
            style: context.type.bodySmall.copyWith(color: c.foregroundMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _searchField() => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onKeyEvent: _onSearchKey,
    child: TextField(
      controller: _search,
      focusNode: _searchFocus,
      autofocus: true,
      onChanged: _onQueryChanged,
      onSubmitted: (_) => _commit(),
      style: fieldTextStyle(context),
      decoration: fieldInputDecoration(
        context,
        hint: widget.hint ?? context.adminL10n.searchPlaceholder,
        leadingIcon: Icons.search,
      ),
    ),
  );

  Widget _empty(AdminPalette c) => Padding(
    padding: const EdgeInsets.all(AdminSpacing.xxl),
    child: Center(
      child: Text(
        context.adminL10n.display.nothingMatches(_query),
        style: context.type.body.copyWith(color: c.foregroundMuted),
      ),
    ),
  );

  Widget _list(BuildContext context) => Listbox(
    controller: _listbox,
    itemCount: _items.length,
    padding: const EdgeInsets.symmetric(vertical: AdminSpacing.xs),
    semanticLabel: widget.semanticLabel ?? context.adminL10n.display.choices,
    itemBuilder: (context, i) {
      final item = _items[i];
      final entry = item.entry;
      if (entry == null) return _header(item.header!);
      return ListenableBuilder(
        listenable: _listbox,
        builder: (context, _) => _row(
          entry,
          index: i,
          ordinal: item.ordinal,
          highlighted: _listbox.highlighted == i,
        ),
      );
    },
  );

  Widget _header(String text) => Semantics(
    header: true,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminSpacing.md,
        AdminSpacing.md,
        AdminSpacing.md,
        AdminSpacing.xs,
      ),
      child: Text(
        text.toUpperCase(),
        style: context.type.caption.copyWith(
          color: context.colors.foregroundMuted,
          letterSpacing: 0.5,
        ),
      ),
    ),
  );

  Widget _row(
    InsertPickerEntry e, {
    required int index,
    required int ordinal,
    required bool highlighted,
  }) {
    final c = context.colors;
    final muted = c.foregroundMutedOnTint;
    void pick() => widget.onSelect(e);
    return Semantics(
      container: true,
      button: true,
      focused: highlighted,
      label: e.description.isEmpty ? e.label : '${e.label}\n${e.description}',
      hint: context.adminL10n.countOf(ordinal + 1, _count),
      onTap: pick,
      excludeSemantics: true,
      child: CursorRegion(
        cursor: SystemMouseCursors.click,
        // Movement, not entry: a row the list scrolls under a still pointer
        // must not take the highlight from the keyboard.
        onHover: (_) {
          if (!highlighted) _listbox.highlight(index);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: pick,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AdminSpacing.md,
              vertical: AdminSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: highlighted ? c.primarySubtle : null,
              borderRadius: BorderRadius.circular(context.radii.radius),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: highlighted ? c.surface : c.background,
                    borderRadius: BorderRadius.circular(
                      context.radii.radiusSmall,
                    ),
                    border: Border.all(color: c.border),
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(
                      size: context.iconSizes.lg,
                      color: c.foregroundMuted,
                    ),
                    child: e.iconWidget ?? Icon(e.icon),
                  ),
                ),
                const Gap(AdminSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        e.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.type.bodyStrong,
                      ),
                      if (e.description.isNotEmpty) ...[
                        const Gap(AdminSpacing.xxs),
                        Text(
                          e.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.type.bodySmall.copyWith(color: muted),
                        ),
                      ],
                    ],
                  ),
                ),
                if (highlighted)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: AdminSpacing.sm,
                    ),
                    child: Icon(
                      Icons.keyboard_return,
                      size: context.iconSizes.sm,
                      color: muted,
                    ),
                  )
                else if (e.preview != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: AdminSpacing.sm,
                    ),
                    child: Icon(
                      Icons.visibility_outlined,
                      size: context.iconSizes.sm,
                      color: muted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
