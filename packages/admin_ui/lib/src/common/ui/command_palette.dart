import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/bidi.dart';
import '../../l10n/shortcut_label.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../fuzzy.dart';
import '../motion.dart';
import '../text_metrics.dart';
import 'field_registry.dart' show FormFieldCommands;
import 'highlighted_text.dart';
import 'modal_anchor.dart';
import 'tappable.dart';

/// One searchable entry in a [CommandPalette] — a command (with a [shortcut]) or
/// a piece of content (a page, product, user). Matched on [title] and [keywords].
class PaletteItem {
  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;

  /// Section label this item is grouped under ("Commands", "Pages", …).
  final String group;

  /// Trailing shortcut hint, e.g. `⌘N`.
  final String? shortcut;

  /// Extra terms to match beyond [title].
  final List<String> keywords;

  /// A content excerpt shown below the title (e.g. where in the body the query
  /// matched). When set it replaces [subtitle] on the row. [snippetHighlights]
  /// are flat `[start,end, …]` offsets into [snippet] to emphasize.
  final String? snippet;
  final List<int> snippetHighlights;

  /// A short provenance chip shown on the trailing edge ("Name", "Body", …),
  /// optionally with [reasonIcon]. Distinct from [shortcut] (commands only).
  final String? reason;
  final IconData? reasonIcon;

  final VoidCallback onSelect;

  const PaletteItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.group,
    required this.onSelect,
    this.subtitle,
    this.shortcut,
    this.keywords = const [],
    this.snippet,
    this.snippetHighlights = const [],
    this.reason,
    this.reasonIcon,
  });
}

/// A fuzzy-scored match of a [PaletteItem]: [matched] are the title character
/// indexes to highlight, [score] ranks it within its section.
class ScoredItem {
  final PaletteItem item;
  final List<int> matched;
  final int score;
  const ScoredItem(this.item, this.matched, this.score);
}

/// A grouped block of results rendered under one section header.
class PaletteSection {
  final String title;
  final List<ScoredItem> entries;
  const PaletteSection(this.title, this.entries);
}

/// Feeds results to a [CommandPaletteController] for a query. Local sources
/// return a `List<PaletteSection>` directly; remote ones return a `Future`, and
/// the controller shows a progress line until they resolve.
abstract class SearchSource {
  FutureOr<List<PaletteSection>> search(String query);
}

List<PaletteSection> _groupByItem(List<ScoredItem> scored) {
  final byGroup = <String, List<ScoredItem>>{};
  for (final s in scored) {
    (byGroup[s.item.group] ??= []).add(s);
  }
  return [for (final e in byGroup.entries) PaletteSection(e.key, e.value)];
}

/// Fuzzy-matches a flat command/content list locally, grouping by
/// [PaletteItem.group]. An empty query yields nothing — recents are a separate
/// source. [items] is a builder so it reflects live registry state.
class CommandSource implements SearchSource {
  final List<PaletteItem> Function() items;
  const CommandSource(this.items);

  @override
  List<PaletteSection> search(String query) {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final scored = <ScoredItem>[];
    for (final it in items()) {
      final m = fuzzyMatch(q, it.title);
      if (m != null) {
        scored.add(ScoredItem(it, m.matched, m.score));
        continue;
      }
      if (it.keywords.any((k) => fuzzyMatch(q, k) != null)) {
        scored.add(ScoredItem(it, const [], 0));
      }
    }
    return _groupByItem(scored);
  }
}

/// Shows a fixed list under a single [title] section, but only while the query
/// is empty.
class RecentsSource implements SearchSource {
  /// The section a source with no [title] files its items under: a grouping
  /// key for [CommandPaletteController.groupOrder], which the palette shows
  /// as the localized "Recent".
  static const defaultSection = 'Recent';

  final List<PaletteItem> Function() items;

  /// The section title; [defaultSection] when null.
  final String? title;

  const RecentsSource(this.items, {this.title});

  @override
  List<PaletteSection> search(String query) {
    if (query.trim().isNotEmpty) return const [];
    final its = items();
    if (its.isEmpty) return const [];
    return [
      PaletteSection(title ?? defaultSection, [
        for (final it in its) ScoredItem(it, const [], 0),
      ]),
    ];
  }
}

/// Owns the palette's query, selection and merged results. Sync sources paint
/// immediately; async sources flip [loading] until they resolve, then merge in.
/// Sections sharing a title are combined and ordered by [groupOrder] (then by
/// first appearance); entries within a section sort by descending score.
class CommandPaletteController extends ChangeNotifier {
  final List<SearchSource> sources;
  final List<String> groupOrder;

  CommandPaletteController({
    required this.sources,
    this.groupOrder = const [],
  }) {
    _run();
  }

  String _query = '';
  bool _loading = false;
  int _selected = 0;
  int _token = 0;
  int _pending = 0;
  List<PaletteSection> _sections = const [];
  final _results = <SearchSource, List<PaletteSection>>{};

  String get query => _query;
  bool get loading => _loading;
  int get selected => _selected;
  List<PaletteSection> get sections => _sections;

  List<ScoredItem> get _flat => [for (final s in _sections) ...s.entries];
  int get resultCount => _flat.length;

  PaletteItem? get selectedItem {
    final flat = _flat;
    if (_selected < 0 || _selected >= flat.length) return null;
    return flat[_selected].item;
  }

  void setQuery(String q) {
    if (q == _query) return;
    _query = q;
    _selected = 0;
    _run();
  }

  void moveSelection(int delta) {
    final count = resultCount;
    if (count == 0) return;
    _selected = (_selected + delta).clamp(0, count - 1);
    notifyListeners();
  }

  void setSelected(int index) {
    if (index == _selected) return;
    _selected = index;
    notifyListeners();
  }

  void _run() {
    final token = ++_token;
    _results.clear();
    _pending = 0;
    for (final source in sources) {
      final r = source.search(_query);
      if (r is Future<List<PaletteSection>>) {
        _pending++;
        r
            .then((secs) {
              if (token != _token) return;
              _results[source] = secs;
              _settle();
            })
            .catchError((_) {
              if (token != _token) return;
              _settle();
            });
      } else {
        _results[source] = r;
      }
    }
    _loading = _pending > 0;
    _recompute();
    notifyListeners();
  }

  void _settle() {
    _pending--;
    if (_pending <= 0) _loading = false;
    _recompute();
    notifyListeners();
  }

  void _recompute() {
    final merged = <String, List<ScoredItem>>{};
    final order = <String>[];
    for (final source in sources) {
      final secs = _results[source];
      if (secs == null) continue;
      for (final sec in secs) {
        if (!merged.containsKey(sec.title)) order.add(sec.title);
        (merged[sec.title] ??= []).addAll(sec.entries);
      }
    }
    // By score, ties kept in source order: List.sort is not stable.
    for (final entries in merged.values) {
      final ranked = [for (var i = 0; i < entries.length; i++) (i, entries[i])]
        ..sort((a, b) {
          final byScore = b.$2.score - a.$2.score;
          return byScore != 0 ? byScore : a.$1 - b.$1;
        });
      entries
        ..clear()
        ..addAll([for (final (_, e) in ranked) e]);
    }
    final ordered = [
      ...groupOrder.where(merged.containsKey),
      ...order.where((t) => !groupOrder.contains(t)),
    ];
    _sections = [for (final t in ordered) PaletteSection(t, merged[t]!)];
    final count = _flat.length;
    if (_selected >= count) _selected = count == 0 ? 0 : count - 1;
  }
}

/// Opens a [CommandPalette] as a top-anchored overlay (⌘K style). Pass a
/// flat [items] list for the simple local case, or [sources] for full control
/// (commands + async entity search). A controller is created and disposed here.
///
/// Shows on [modals] when given, else on the nearest [ModalAnchor]. A
/// shell-level anchor (below CommandScope and friends) keeps the palette's
/// registry access live and lets it survive route changes underneath.
Future<void> showCommandPalette(
  BuildContext context, {
  List<PaletteItem> items = const [],
  List<PaletteItem> recent = const [],
  List<SearchSource>? sources,
  String? hint,
  List<String> groupOrder = const [],
  bool preview = false,
  ModalAnchorController? modals,
}) {
  final controller = CommandPaletteController(
    sources:
        sources ?? [CommandSource(() => items), RecentsSource(() => recent)],
    groupOrder: groupOrder,
  );
  final anchor = modals ?? ModalAnchor.of(context);
  return anchor
      .show<void>(
        // Top-anchored: the top edge (and search field) never moves; the
        // palette only grows downward, capped, then the list scrolls inside.
        alignment: Alignment.topCenter,
        slideFrom: const Offset(0, -0.03),
        fade: true,
        duration: context.motion.medium,
        builder: (context) {
          final screen = MediaQuery.sizeOf(context);
          // The preview pane needs room for the result list plus the panel
          // beside it.
          final maxWidth = preview ? 820.0 : 600.0;
          // 12% of the way down, as launchers place theirs: within reach on
          // a short window, not adrift on a tall one.
          final top = (screen.height * 0.12).clamp(AdminSpacing.xxl, 140.0);
          return Padding(
            padding: EdgeInsets.fromLTRB(
              AdminSpacing.xl,
              top,
              AdminSpacing.xl,
              AdminSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth.clamp(0, screen.width - AdminSpacing.xl * 2),
                maxHeight: (screen.height * 0.6).clamp(320.0, 560.0),
              ),
              child: CommandPalette.controller(
                controller,
                hint: hint,
                preview: preview,
                onDismiss: () => anchor.close(),
              ),
            ),
          );
        },
      )
      .whenComplete(controller.dispose);
}

/// A search-styled button for a top bar that opens the [CommandPalette]. Looks
/// like a search field — leading icon, muted [hint], trailing [shortcut] chip —
/// but is a button; [onTap] should call [showCommandPalette]. It takes the
/// medium button's corner (`AdminRadii.button`), as the actions beside it
/// in the bar do: M3's full-round search bar among its stadium buttons,
/// Carbon's square one. Bind the same
/// shortcut globally — `primaryModifierActivator(LogicalKeyboardKey.keyK)` —
/// so ⌘K or Ctrl+K and a click reach the same palette.
class CommandTrigger extends StatelessWidget {
  final VoidCallback onTap;

  /// The muted placeholder and the accessible name; the localized "Search…"
  /// when null.
  final String? hint;

  /// The shortcut chip; when null, the platform's label for the primary
  /// modifier and K: ⌘K on macOS and iOS, Ctrl+K elsewhere.
  final String? shortcut;

  const CommandTrigger({
    super.key,
    required this.onTap,
    this.hint,
    this.shortcut,
  });

  @override
  Widget build(BuildContext context) {
    final hint = this.hint ?? context.adminL10n.searchPlaceholder;
    final shortcut =
        this.shortcut ??
        shortcutLabel(
          context,
          primaryModifierActivator(LogicalKeyboardKey.keyK),
        );
    final radius = context.radii.button(ControlSize.medium);
    return Tappable.builder(
      onTap: onTap,
      semanticLabel: hint,
      excludeSemantics: true,
      focusRadius: radius,
      builder: (context, hover) {
        final sizes = context.sizes;
        final border = context.stroke.control;
        final text = context.type.fieldText;
        // The height, glyph, type and text insets of a search field, taller
        // by as much as the hint grows at a large text size; the padding
        // sits inside the border.
        return Container(
          height: sizes.medium + textGrowthOf(context, text),
          padding: EdgeInsets.symmetric(
            horizontal: sizes.fieldPaddingX - border,
          ),
          decoration: BoxDecoration(
            color: hover
                ? Color.alphaBlend(
                    context.colors.hoverOverlay,
                    context.colors.background,
                  )
                : context.colors.background,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: context.colors.border, width: border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: sizes.fieldIcon,
                color: context.colors.foregroundMuted,
              ),
              Gap(sizes.fieldIconGap),
              Expanded(
                child: Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.copyWith(color: context.colors.foregroundMuted),
                ),
              ),
              const Gap(AdminSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AdminSpacing.sm,
                  vertical: AdminSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(
                    context.radii.radiusSmall,
                  ),
                  border: Border.all(color: context.colors.border),
                ),
                child: Text(
                  shortcut,
                  // Physical: a shortcut reads left to right in any language.
                  textDirection: TextDirection.ltr,
                  style: context.type.micro.copyWith(
                    color: context.colors.foregroundMuted,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A Notion-style command + content search surface: an autofocused query field,
/// fuzzy-matched results grouped by section with the matched characters
/// highlighted, recents shown on an empty query, full keyboard navigation
/// (↑/↓ to move, Home/End to the ends, PageUp/PageDown by a screenful, ↵ to
/// run, esc to close). Pure View — the caller supplies the items and their
/// `onSelect`.
///
/// Focus stays in the field; the selected result follows the keyboard, and
/// the pointer only when it actually moves, so a list scrolling under a
/// still pointer keeps the keyboard's pick. Screen readers get the results
/// as a list whose rows say whether they are selected, and hear the result
/// count once a query settles. Below 640px wide the preview pane is left out.
class CommandPalette extends StatefulWidget {
  final List<PaletteItem> items;
  final List<PaletteItem> recent;

  /// The query's placeholder text; the localized "Search or jump to…" when
  /// null.
  final String? hint;

  final List<String> groupOrder;

  /// When true, a preview pane beside the list shows the selected hit's full
  /// excerpt + provenance — for content search. Off for command-only palettes.
  final bool preview;

  /// When non-null the palette renders from this controller (commands + async
  /// sources); otherwise it builds a local controller from [items]/[recent].
  final CommandPaletteController? controller;

  /// Called to close the palette (Escape, activating an item). Defaults to
  /// popping the enclosing route — [showCommandPalette] passes its anchor's
  /// close instead.
  final VoidCallback? onDismiss;

  const CommandPalette({
    super.key,
    required this.items,
    this.recent = const [],
    this.hint,
    this.groupOrder = const [],
    this.preview = false,
    this.onDismiss,
  }) : controller = null;

  const CommandPalette.controller(
    CommandPaletteController this.controller, {
    super.key,
    this.hint,
    this.preview = false,
    this.onDismiss,
  }) : items = const [],
       recent = const [],
       groupOrder = const [];

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  /// Below this width the preview pane would squeeze the results; it is
  /// left out.
  static const _previewMinWidth = 640.0;

  /// How long results must hold still before their count is announced, so
  /// typing is not read out keystroke by keystroke.
  static const _announceDelay = Duration(milliseconds: 500);

  final _textController = TextEditingController();
  final _scroll = ScrollController();
  late final FocusNode _focus = FocusNode(onKeyEvent: _onKey);
  final _rowKeys = <int, GlobalKey>{};

  late final CommandPaletteController _controller;
  bool _ownsController = false;

  Timer? _announceTimer;

  /// The query and count last announced; seeded with the opening state, so
  /// only a change is read out.
  (String, int)? _announced;

  @override
  void initState() {
    super.initState();
    final supplied = widget.controller;
    if (supplied != null) {
      _controller = supplied;
    } else {
      _ownsController = true;
      _controller = CommandPaletteController(
        sources: [
          CommandSource(() => widget.items),
          RecentsSource(() => widget.recent),
        ],
        groupOrder: widget.groupOrder,
      );
    }
    _controller.addListener(_onControllerChanged);
    _announced = (_controller.query, _controller.resultCount);
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
    _announceTimer?.cancel();
    _announceTimer = Timer(_announceDelay, _announceCount);
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
  }

  void _revealSelected({bool jumped = false}) {
    if (!mounted || !_scroll.hasClients) return;
    final ctx = _rowKeys[_controller.selected]?.currentContext;
    if (ctx != null && ctx.mounted) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: context.motion.fast,
      );
      return;
    }
    // A row far out of view (End, PageDown) is not built yet: jump to its
    // share of the list first, then bring it in once it is.
    final count = _controller.resultCount;
    if (jumped || count < 2) return;
    final position = _scroll.position;
    _scroll.jumpTo(
      position.maxScrollExtent * _controller.selected / (count - 1),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _revealSelected(jumped: true),
    );
  }

  void _announceCount() {
    if (!mounted || _controller.loading) return;
    final state = (_controller.query, _controller.resultCount);
    if (state == _announced) return;
    _announced = state;
    SemanticsService.sendAnnouncement(
      View.of(context),
      context.adminL10n.inputs.resultCount(state.$2),
      Directionality.of(context),
    );
  }

  @override
  void dispose() {
    _announceTimer?.cancel();
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    _textController.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        _controller.moveSelection(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _controller.moveSelection(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.pageDown:
        _controller.moveSelection(_pageSize());
        return KeyEventResult.handled;
      case LogicalKeyboardKey.pageUp:
        _controller.moveSelection(-_pageSize());
        return KeyEventResult.handled;
      case LogicalKeyboardKey.home:
        if (_controller.resultCount > 0) _controller.setSelected(0);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.end:
        final count = _controller.resultCount;
        if (count > 0) _controller.setSelected(count - 1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.numpadEnter:
        _activate();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        _dismiss();
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// About a viewport of rows: the list's height over the selected row's,
  /// less one so the row selected last stays in view.
  int _pageSize() {
    final row = _rowKeys[_controller.selected]?.currentContext?.size?.height;
    if (!_scroll.hasClients || row == null || row <= 0) return 8;
    final fit = (_scroll.position.viewportDimension / row).floor() - 1;
    return fit < 1 ? 1 : fit;
  }

  void _dismiss() {
    final onDismiss = widget.onDismiss;
    if (onDismiss != null) {
      onDismiss();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _activate() {
    final item = _controller.selectedItem;
    if (item == null) return;
    _dismiss();
    item.onSelect();
  }

  @override
  Widget build(BuildContext context) {
    final sections = _controller.sections;
    final flat = [for (final s in sections) ...s.entries];

    // Shadow on the OUTER box, clip and border on the INNER Material —
    // otherwise the Material's clip crops the shadow into a grey edge (cf.
    // Modal / SideSheet).
    final corners = BorderRadius.circular(context.radii.radiusMenu);
    final separator = context.colors.separator;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: corners,
        boxShadow: context.elevation.lg,
      ),
      child: Material(
        color: context.colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: corners,
          side: BorderSide(color: context.colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _searchField(context),
            SizedBox(
              height: context.stroke.indicator,
              child: switch (_controller.loading) {
                true when motionReduced(context) => StillLinearProgress(
                  minHeight: context.stroke.indicator,
                  backgroundColor: separator,
                  color: context.colors.primary,
                ),
                true => LinearProgressIndicator(
                  minHeight: context.stroke.indicator,
                  backgroundColor: separator,
                  color: context.colors.primary,
                ),
                false => Divider(
                  height: context.stroke.indicator,
                  thickness: context.stroke.hairline,
                  color: separator,
                ),
              },
            ),
            Flexible(
              child: flat.isEmpty
                  ? _empty(context)
                  : !widget.preview
                  ? _list(context, sections, flat)
                  : LayoutBuilder(
                      builder: (context, box) => box.maxWidth < _previewMinWidth
                          ? _list(context, sections, flat)
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _list(context, sections, flat),
                                ),
                                VerticalDivider(
                                  width: 1,
                                  thickness: 1,
                                  color: separator,
                                ),
                                Expanded(flex: 2, child: _previewPane(context)),
                              ],
                            ),
                    ),
            ),
            Divider(
              height: context.stroke.hairline,
              thickness: context.stroke.hairline,
              color: separator,
            ),
            _footer(context),
          ],
        ),
      ),
    );
  }

  Widget _searchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.xl,
        vertical: AdminSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: context.iconSizes.lg,
            color: context.colors.foregroundMuted,
          ),
          const Gap(AdminSpacing.md),
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focus,
              autofocus: true,
              onChanged: _controller.setQuery,
              onSubmitted: (_) => _activate(),
              style: context.type.fieldText,
              // Bare text in the header row: every border state is spelled
              // out so no theme-level focused or enabled border reaches it.
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                hintText:
                    widget.hint ?? context.adminL10n.inputs.searchOrJumpTo,
                hintStyle: context.type.fieldText.copyWith(
                  color: context.colors.placeholder,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AdminSpacing.lg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(
    BuildContext context,
    List<PaletteSection> sections,
    List<ScoredItem> flat,
  ) {
    return Semantics(
      container: true,
      role: SemanticsRole.list,
      explicitChildNodes: true,
      child: ListView(
        controller: _scroll,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: AdminSpacing.sm),
        children: [for (final s in sections) ..._section(context, s, flat)],
      ),
    );
  }

  List<Widget> _section(
    BuildContext context,
    PaletteSection section,
    List<ScoredItem> flat,
  ) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AdminSpacing.xl,
          AdminSpacing.md,
          AdminSpacing.xl,
          AdminSpacing.xs,
        ),
        child: _GroupLabel(_groupLabel(context, section.title)),
      ),
      for (final hit in section.entries) _row(context, hit, flat.indexOf(hit)),
    ];
  }

  Widget _row(BuildContext context, ScoredItem hit, int index) {
    final selected = index == _controller.selected;
    final key = _rowKeys[index] ??= GlobalKey();
    final item = hit.item;
    final secondary = item.snippet ?? item.subtitle;
    // Muted text that holds 4.5:1 on the selected and the hovered fill alike.
    final secondaryStyle = context.type.caption.copyWith(
      color: context.colors.foregroundMutedOnTint,
    );

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.sm),
      // Movement, not entry: a row the list scrolls under a still pointer
      // must not take the selection from the keyboard.
      child: MouseRegion(
        onHover: (_) => _controller.setSelected(index),
        child: Tappable.states(
          onTap: () {
            _controller.setSelected(index);
            _activate();
          },
          // Focus stays in the query field; rows are picked from there.
          focusable: false,
          selected: selected,
          semanticLabel: secondary == null
              ? item.title
              : '${item.title}, $secondary',
          excludeSemantics: true,
          builder: (context, states) => Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AdminSpacing.lg,
              vertical: AdminSpacing.md,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? context.colors.primarySubtle
                  : states.contains(WidgetState.hovered)
                  ? context.colors.listHighlight
                  : null,
              borderRadius: BorderRadius.circular(context.radii.radiusSmall),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: context.iconSizes.md,
                  color: selected
                      ? context.colors.primaryText
                      : context.colors.foregroundMuted,
                ),
                const Gap(AdminSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _highlightedTitle(
                        context,
                        item.title,
                        hit.matched,
                        selected,
                      ),
                      if (item.snippet != null) ...[
                        const Gap(AdminSpacing.xxs),
                        HighlightedText(
                          item.snippet!,
                          ranges: item.snippetHighlights,
                          style: secondaryStyle,
                        ),
                      ] else if (item.subtitle != null) ...[
                        const Gap(AdminSpacing.xxs),
                        Text(
                          bidiIsolate(item.subtitle!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: secondaryStyle,
                        ),
                      ],
                    ],
                  ),
                ),
                if (item.shortcut != null) ...[
                  const Gap(AdminSpacing.md),
                  _Kbd(item.shortcut!),
                ] else if (item.reason != null) ...[
                  const Gap(AdminSpacing.md),
                  _ReasonChip(item.reason!, icon: item.reasonIcon),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _highlightedTitle(
    BuildContext context,
    String text,
    List<int> matched,
    bool selected,
  ) {
    final base = context.type.weighted(
      context.type.body.copyWith(color: context.colors.foreground),
      FontWeight.w500,
    );
    if (matched.isEmpty) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: base,
      );
    }
    final hot = matched.toSet();
    final accent = context.type.weighted(
      base.copyWith(color: context.colors.primaryText),
      FontWeight.w700,
    );
    return Text.rich(
      TextSpan(
        children: [
          for (var i = 0; i < text.length; i++)
            TextSpan(text: text[i], style: hot.contains(i) ? accent : base),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// The selected hit's detail beside the list: section, title, attribution, and
  /// — for a content match — the full excerpt with the term highlighted.
  Widget _previewPane(BuildContext context) {
    final strings = context.adminL10n.inputs;
    final item = _controller.selectedItem;
    if (item == null) {
      return Center(
        child: Text(strings.selectAResult, style: context.type.bodyMuted),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GroupLabel(_groupLabel(context, item.group)),
          const Gap(AdminSpacing.xs),
          Text(item.title, style: context.type.heading),
          if (item.subtitle != null) ...[
            const Gap(AdminSpacing.xxs),
            Text(bidiIsolate(item.subtitle!), style: context.type.caption),
          ],
          if (item.snippet != null) ...[
            const Gap(AdminSpacing.lg),
            Row(
              children: [
                Icon(
                  item.reasonIcon ?? Icons.notes_rounded,
                  size: context.iconSizes.sm,
                  color: context.colors.foregroundMuted,
                ),
                const Gap(AdminSpacing.sm),
                Flexible(
                  child: Text(
                    switch (item.reason) {
                      final reason? => strings.matchedIn(reason),
                      null => strings.matchedInContent,
                    },
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.type.caption,
                  ),
                ),
              ],
            ),
            const Gap(AdminSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AdminSpacing.md,
                vertical: AdminSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: context.colors.background,
                borderRadius: BorderRadius.circular(context.radii.radius),
              ),
              child: HighlightedText(
                item.snippet!,
                ranges: item.snippetHighlights,
                style: context.type.body.copyWith(
                  color: context.colors.foregroundSecondary,
                ),
                maxLines: 8,
              ),
            ),
          ],
          const Gap(AdminSpacing.xl),
          MergeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  item.shortcut != null ? strings.run : strings.open,
                  style: context.type.caption,
                ),
                const Gap(AdminSpacing.sm),
                _Kbd('↵', semanticLabel: strings.keyEnter),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) {
    // Fixed height so an empty/loading state neither collapses nor balloons.
    final query = _controller.query;
    return SizedBox(
      height: 180,
      child: Center(
        child: _controller.loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  value: spinnerValue(context),
                  strokeWidth: 2,
                  color: context.colors.foregroundMuted,
                ),
              )
            : Text(
                query.trim().isEmpty
                    ? context.adminL10n.inputs.typeToSearch
                    : context.adminL10n.inputs.noResultsFor(query),
                style: context.type.bodyMuted,
              ),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final strings = context.adminL10n.inputs;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.xl,
        vertical: AdminSpacing.md,
      ),
      // Wraps rather than overflows on a phone-width palette.
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Wrap(
          spacing: AdminSpacing.xl,
          runSpacing: AdminSpacing.xs,
          children: [
            _hint(context, '↑↓', strings.keysUpDown, strings.navigateHint),
            _hint(
              context,
              shortcutLabel(
                context,
                const SingleActivator(LogicalKeyboardKey.enter),
              ),
              strings.keyEnter,
              strings.selectHint,
            ),
            _hint(
              context,
              shortcutLabel(
                context,
                const SingleActivator(LogicalKeyboardKey.escape),
              ),
              strings.keyEscape,
              strings.closeHint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _hint(BuildContext context, String key, String spoken, String label) {
    return MergeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Kbd(key, semanticLabel: spoken),
          const Gap(AdminSpacing.sm),
          Text(label, style: context.type.caption),
        ],
      ),
    );
  }
}

/// [group] as the palette shows it: the kit's own default groups,
/// [RecentsSource.defaultSection] and [FormFieldCommands.defaultGroup], in the
/// app's language.
String _groupLabel(BuildContext context, String group) => switch (group) {
  RecentsSource.defaultSection => context.adminL10n.inputs.recent,
  FormFieldCommands.defaultGroup => context.adminL10n.inputs.fieldsGroup,
  _ => group,
};

/// A section's name, over its rows and in the preview, cased by the theme as
/// a menu's header is: in tracked small capitals where its type spec sets
/// `uppercaseLabels`, and otherwise in sentence case, a muted caption as
/// shadcn's command group heading is.
class _GroupLabel extends StatelessWidget {
  final String label;

  const _GroupLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    if (!type.spec.uppercaseLabels) {
      return Text(label, style: type.weighted(type.caption, type.spec.strong));
    }
    return Text(
      label.toUpperCase(),
      semanticsLabel: label,
      style: type.weighted(
        type.micro.copyWith(
          color: context.colors.foregroundMuted,
          letterSpacing: 0.6,
        ),
        FontWeight.w700,
      ),
    );
  }
}

/// A small keycap chip, on `background` so its `foregroundMuted` label keeps
/// 4.5:1. A symbol such as ↵ is read as its key's name, [semanticLabel].
class _Kbd extends StatelessWidget {
  final String label;
  final String? semanticLabel;

  const _Kbd(this.label, {this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    final keycap = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.sm,
        vertical: AdminSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: BorderRadius.circular(context.radii.radiusSmall),
        border: Border.all(color: context.colors.borderSubtle),
      ),
      child: Text(
        label,
        // Physical: a key legend reads left to right in any language.
        textDirection: TextDirection.ltr,
        style: context.type.weighted(
          context.type.micro.copyWith(color: context.colors.foregroundMuted),
          FontWeight.w600,
        ),
      ),
    );
    return semanticLabel == null
        ? keycap
        : Semantics(
            label: semanticLabel,
            excludeSemantics: true,
            child: keycap,
          );
  }
}

/// A trailing provenance chip on a content hit — why it matched ("Name",
/// "Body", "Description"), with an optional leading [icon].
class _ReasonChip extends StatelessWidget {
  final String label;
  final IconData? icon;

  const _ReasonChip(this.label, {this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.sm,
        vertical: AdminSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: BorderRadius.circular(context.radii.radiusSmall),
        border: Border.all(color: context.colors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: context.iconSizes.xs,
              color: context.colors.foregroundMuted,
            ),
            const Gap(AdminSpacing.xs),
          ],
          Text(
            label,
            style: context.type.weighted(
              context.type.micro.copyWith(
                color: context.colors.foregroundMuted,
              ),
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
