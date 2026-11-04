import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/sections/display_messages.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/syntax.dart';
import '../../theme/tokens.dart';
import '../text_metrics.dart';
import 'copy_button.dart';
import 'icon_action.dart';
import 'search_field.dart';
import 'tappable.dart';

/// The structural class of a [JsonNode], used to pick its highlight colour and
/// whether it folds.
enum JsonNodeKind { object, array, string, number, boolean, nul }

/// One node of a parsed JSON document. Built once by [buildJsonTree] and walked
/// by [flattenJson] to produce the visible rows. [path] is a stable id
/// (`$.user.tags[0]`) used as the expansion-set key.
class JsonNode {
  final String path;
  final int depth;

  /// The owning object member's key, unquoted; null for the root and array
  /// elements.
  final String? key;

  /// The element index within the owning array; null otherwise.
  final int? index;

  final JsonNodeKind kind;

  /// The original decoded value (`Map`/`List` for containers, the scalar for
  /// leaves) — re-encoded for copy and used for leaf display/search.
  final Object? raw;

  final List<JsonNode> children;

  JsonNode({
    required this.path,
    required this.depth,
    required this.key,
    required this.index,
    required this.kind,
    required this.raw,
    required this.children,
  });

  bool get isContainer =>
      kind == JsonNodeKind.object || kind == JsonNodeKind.array;

  bool get isEmpty => isContainer && children.isEmpty;

  int get childCount => children.length;

  /// The leaf text used for display, JSON-encoded so strings keep their quotes
  /// and escapes (`"hi"`, `14.5`, `true`, `null`). Memoised — encoded once per
  /// node, on first access, so rebuilds don't re-serialise.
  late final String encoded = jsonEncode(raw);

  /// The unquoted text matched against a search query. Memoised likewise so a
  /// per-keystroke search doesn't re-encode every leaf.
  late final String searchText = raw is String ? raw as String : encoded;
}

/// Parses an already-decoded JSON value (`Map`/`List`/`String`/`num`/`bool`/
/// `null`) into a [JsonNode] tree rooted at `$`.
JsonNode buildJsonTree(Object? value) => _node(value, r'$', 0, null, null);

JsonNode _node(Object? value, String path, int depth, String? key, int? index) {
  if (value is Map) {
    final children = <JsonNode>[];
    for (final entry in value.entries) {
      final k = entry.key.toString();
      children.add(_node(entry.value, '$path.$k', depth + 1, k, null));
    }
    return JsonNode(
      path: path,
      depth: depth,
      key: key,
      index: index,
      kind: JsonNodeKind.object,
      raw: value,
      children: children,
    );
  }
  if (value is List) {
    final children = <JsonNode>[];
    for (var i = 0; i < value.length; i++) {
      children.add(_node(value[i], '$path[$i]', depth + 1, null, i));
    }
    return JsonNode(
      path: path,
      depth: depth,
      key: key,
      index: index,
      kind: JsonNodeKind.array,
      raw: value,
      children: children,
    );
  }
  final kind = switch (value) {
    String() => JsonNodeKind.string,
    num() => JsonNodeKind.number,
    bool() => JsonNodeKind.boolean,
    _ => JsonNodeKind.nul,
  };
  return JsonNode(
    path: path,
    depth: depth,
    key: key,
    index: index,
    kind: kind,
    raw: value,
    children: const [],
  );
}

/// A single rendered line. A container yields an open line and — when expanded —
/// a [closing] line; collapsed it folds to one line ([collapsed] is true).
/// [last] drives the trailing comma.
class JsonRow {
  final JsonNode node;
  final bool closing;
  final bool collapsed;
  final bool last;

  const JsonRow(
    this.node, {
    required this.closing,
    required this.collapsed,
    required this.last,
  });
}

/// Walks [root] into the flat, ordered list of currently-visible [JsonRow]s.
///
/// Without [visible] (no active search) a container is expanded when its path is
/// in [expanded]. With [visible] (a search filter), only nodes whose path is in
/// the set are kept, and kept containers are forced open so every match stays
/// revealed.
List<JsonRow> flattenJson(
  JsonNode root, {
  required Set<String> expanded,
  Set<String>? visible,
}) {
  final out = <JsonRow>[];

  void visit(JsonNode node, bool last) {
    final searching = visible != null;
    if (searching && !visible.contains(node.path)) return;

    final foldable = node.isContainer && !node.isEmpty;
    final kids = searching
        ? node.children.where((c) => visible.contains(c.path)).toList()
        : node.children;
    // While searching, a container opens only when it still has a kept child;
    // one matched by its own key alone stays collapsed for the user to open.
    final isOpen =
        foldable &&
        (searching ? kids.isNotEmpty : expanded.contains(node.path));

    if (!isOpen) {
      out.add(JsonRow(node, closing: false, collapsed: foldable, last: last));
      return;
    }

    out.add(JsonRow(node, closing: false, collapsed: false, last: last));
    for (var i = 0; i < kids.length; i++) {
      visit(kids[i], i == kids.length - 1);
    }
    out.add(JsonRow(node, closing: true, collapsed: false, last: last));
  }

  visit(root, true);
  return out;
}

/// The outcome of a [jsonSearch]: every node [matched] by the query, and the
/// [keep] set (matches plus their ancestors) used to filter and force-expand.
class JsonSearchResult {
  final Set<String> matched;
  final Set<String> keep;

  const JsonSearchResult(this.matched, this.keep);
}

/// Case-insensitive substring search over keys and leaf values. Returns the
/// matched paths and the closure of paths to keep visible (each match and all
/// its ancestors).
JsonSearchResult jsonSearch(JsonNode root, String query) {
  final q = query.toLowerCase();
  final matched = <String>{};
  final keep = <String>{};

  bool visit(JsonNode node) {
    var self = false;
    if (node.key != null && node.key!.toLowerCase().contains(q)) self = true;
    if (!node.isContainer && node.searchText.toLowerCase().contains(q)) {
      self = true;
    }
    if (self) matched.add(node.path);

    var keptChild = false;
    for (final c in node.children) {
      if (visit(c)) keptChild = true;
    }
    final kept = self || keptChild;
    if (kept) keep.add(node.path);
    return kept;
  }

  visit(root);
  return JsonSearchResult(matched, keep);
}

/// A read-only, collapsible JSON tree viewer. Built for inspecting payloads —
/// API responses, webhook bodies, `jsonb` columns — including large ones: rows
/// are virtualised, so a multi-thousand-node document scrolls smoothly.
///
/// It complements (rather than duplicates) the `CodeBody` editor: that edits raw
/// text, this folds parsed structure. Pass already-decoded data, or
/// [JsonView.source] to decode a raw string and surface a parse error inline.
///
/// Every line but a closing one is a Tab stop, and offers to copy its value
/// (a subtree as indented JSON, a string without its quotes) and its path
/// (`$.user.tags[0]`): under the pointer or with keyboard focus as two
/// buttons at its end, from the keyboard with the platform's copy shortcut
/// (Shift added for the path), and to a screen reader as two actions of the
/// line. A line too long for the view ends in an ellipsis, and a click or
/// Enter on it wraps it to show the whole value. The text of every line is
/// selectable.
///
/// The toolbar follows the reading direction; the tree itself is code, and
/// reads left to right in every locale.
class JsonView extends StatefulWidget {
  /// The decoded value to display (`Map`/`List`/scalar/null).
  final Object? data;

  /// Raw JSON text to decode internally; mutually exclusive with [data].
  final String? source;

  /// Containers shallower than this auto-expand on first render. 0 collapses
  /// everything but the root.
  final int initialExpandDepth;

  /// Show the header: root summary, expand/collapse-all, search, copy-all.
  final bool showToolbar;

  /// Offer the search field in the toolbar.
  final bool searchable;

  /// Tallest the viewport grows before it scrolls.
  final double maxHeight;

  const JsonView({
    super.key,
    required this.data,
    this.initialExpandDepth = 2,
    this.showToolbar = true,
    this.searchable = true,
    this.maxHeight = 480,
  }) : source = null;

  const JsonView.source(
    String this.source, {
    super.key,
    this.initialExpandDepth = 2,
    this.showToolbar = true,
    this.searchable = true,
    this.maxHeight = 480,
  }) : data = null;

  @override
  State<JsonView> createState() => _JsonViewState();
}

/// The search field's width in the toolbar.
const _searchWidth = 180.0;

/// The narrowest the search gets in a narrow toolbar, before the summary
/// gives up its width instead.
const _minSearchWidth = 120.0;

/// How strongly a search match tints its line.
const _matchAlpha = 0.12;

/// One line of code under [context]'s theme and text size.
double _lineHeight(BuildContext context) =>
    lineHeightOf(context, context.type.mono);

/// A row: a line of code with room for a fallback font's taller line (an
/// emoji, a CJK run), and never shorter than the copy actions it shows
/// under the pointer.
double _rowHeight(BuildContext context) =>
    math.max(_lineHeight(context) + AdminSpacing.xs, IconActionSize.inline.box);

/// One depth step, and the width of the disclosure column.
double _indentOf(BuildContext context) => context.iconSizes.md;

/// The room [node]'s text has in a list [width] wide: the width less the
/// row's padding, its indent and the disclosure column.
double _textWidth(BuildContext context, JsonNode node, double width) =>
    math.max(
      0.0,
      width - 2 * AdminSpacing.md - (node.depth + 1) * _indentOf(context),
    );

/// Whether [row] is a line that holds a value rather than opening, closing
/// or folding a container.
bool _isLeaf(JsonRow row) =>
    !row.closing && !(row.node.isContainer && !row.node.isEmpty);

class _JsonViewState extends State<JsonView> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  /// The selection's focus: out of the Tab order, which the fold lines keep.
  final _selectionFocus = FocusNode(
    debugLabel: 'JsonView selection',
    skipTraversal: true,
  );

  JsonNode? _root;
  String? _parseError;

  /// The whole document pretty-printed for the toolbar's copy action. Serialised
  /// once per data change, not per rebuild.
  String _pretty = '';

  final _expanded = <String>{};

  /// The paths of the long values shown whole, wrapped over as many lines as
  /// they take.
  final _wrapped = <String>{};

  String _query = '';

  /// [jsonSearch] is an O(N) tree walk; cache it so it only re-runs when the
  /// query text actually changes, not on every unrelated rebuild.
  String? _searchKey;
  JsonSearchResult? _searchCache;

  @override
  void initState() {
    super.initState();
    _rebuild();
    _search.addListener(() {
      if (_search.text == _query) return;
      setState(() => _query = _search.text);
    });
  }

  @override
  void didUpdateWidget(covariant JsonView old) {
    super.didUpdateWidget(old);
    if (widget.data != old.data || widget.source != old.source) {
      _expanded.clear();
      _wrapped.clear();
      _rebuild();
    }
  }

  void _rebuild() {
    _parseError = null;
    _searchKey = null;
    _searchCache = null;
    Object? value = widget.data;
    if (widget.source != null) {
      try {
        value = jsonDecode(widget.source!);
      } on FormatException catch (e) {
        _root = null;
        _parseError = e.message;
        return;
      }
    }
    _root = buildJsonTree(value);
    _pretty = const JsonEncoder.withIndent('  ').convert(value);
    _seedExpansion(_root!);
  }

  /// The search result for the active query, recomputed only when the query
  /// changes; null when not searching.
  JsonSearchResult? _activeSearch() {
    final q = _query.trim();
    if (q.isEmpty) {
      _searchKey = null;
      _searchCache = null;
      return null;
    }
    if (q != _searchKey) {
      _searchKey = q;
      _searchCache = jsonSearch(_root!, q);
    }
    return _searchCache;
  }

  void _seedExpansion(JsonNode node) {
    if (node.isContainer &&
        !node.isEmpty &&
        node.depth < widget.initialExpandDepth) {
      _expanded.add(node.path);
    }
    for (final c in node.children) {
      _seedExpansion(c);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    _selectionFocus.dispose();
    super.dispose();
  }

  void _toggle(String path) {
    setState(() {
      if (!_expanded.remove(path)) _expanded.add(path);
    });
  }

  void _toggleWrap(String path) {
    setState(() {
      if (!_wrapped.remove(path)) _wrapped.add(path);
    });
  }

  void _expandAll() {
    setState(() {
      void walk(JsonNode n) {
        if (n.isContainer && !n.isEmpty) _expanded.add(n.path);
        n.children.forEach(walk);
      }

      walk(_root!);
    });
  }

  void _collapseAll() {
    setState(() {
      _expanded
        ..clear()
        ..add(_root!.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = context.radii.radius;

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A source that fails to parse has nothing to summarise, search
            // or copy: its error stands alone.
            if (widget.showToolbar && _root != null) _toolbar(context),
            if (_parseError != null) _errorBanner(context) else _body(context),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final root = _root!;
    final search = _activeSearch();
    final rows = flattenJson(root, expanded: _expanded, visible: search?.keep);

    if (rows.isEmpty) {
      return _hint(context, context.adminL10n.noMatches);
    }

    final rowH = _rowHeight(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final extents = [
          for (final row in rows)
            _isLeaf(row) && _wrapped.contains(row.node.path)
                ? _wrappedHeight(context, row, width)
                : rowH,
        ];
        final contentH =
            extents.fold(0.0, (sum, h) => sum + h) + 2 * AdminSpacing.md;

        return SizedBox(
          height: math.min(contentH, widget.maxHeight),
          child: Directionality(
            // Physical: JSON is code, which reads left to right in any locale.
            textDirection: TextDirection.ltr,
            child: SelectionArea(
              focusNode: _selectionFocus,
              child: Scrollbar(
                controller: _scroll,
                child: ListView.builder(
                  controller: _scroll,
                  itemExtentBuilder: (i, _) =>
                      i < extents.length ? extents[i] : null,
                  padding: const EdgeInsets.symmetric(
                    vertical: AdminSpacing.md,
                  ),
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final row = rows[i];
                    final path = row.node.path;
                    final wrapped = !_isLeaf(row)
                        ? null
                        : _wrapped.contains(path)
                        ? true
                        : _overflows(context, row, width)
                        ? false
                        : null;
                    return _JsonRowView(
                      key: ValueKey(row.closing ? '$path/' : path),
                      row: row,
                      height: extents[i],
                      matched: search?.matched.contains(path) ?? false,
                      wrapped: wrapped,
                      onToggle: _toggle,
                      onWrap: _toggleWrap,
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// A painter for [row]'s line as its row lays it out, in a list [width]
  /// wide; one line at most with [maxLines].
  TextPainter _painter(
    BuildContext context,
    JsonRow row,
    double width, {
    int? maxLines,
  }) => TextPainter(
    text: TextSpan(
      style: DefaultTextStyle.of(context).style,
      children: [_lineSpan(context, row)],
    ),
    // Physical: the rows are code, laid out left to right.
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: maxLines,
    ellipsis: maxLines == null ? null : '\u2026',
  )..layout(maxWidth: _textWidth(context, row.node, width));

  /// Whether [row]'s line is cut short by an ellipsis in a list [width] wide.
  bool _overflows(BuildContext context, JsonRow row, double width) {
    final painter = _painter(context, row, width, maxLines: 1);
    final overflows = painter.didExceedMaxLines;
    painter.dispose();
    return overflows;
  }

  /// The height of [row] wrapped over as many lines as it takes in a list
  /// [width] wide.
  double _wrappedHeight(BuildContext context, JsonRow row, double width) {
    final painter = _painter(context, row, width);
    final text = painter.height;
    painter.dispose();
    final rowH = _rowHeight(context);
    return math.max(rowH, text + rowH - _lineHeight(context));
  }

  Widget _toolbar(BuildContext context) {
    final colors = context.colors;
    final root = _root!;
    final strings = context.adminL10n.display;
    final summary = _rootSummary(root, strings);
    final summaryStyle = context.type.monoSmall.copyWith(
      color: colors.foregroundMuted,
    );
    final actions = [
      IconAction(
        Icons.unfold_more_rounded,
        label: strings.expandAll,
        size: IconActionSize.small,
        onPressed: _expandAll,
      ),
      IconAction(
        Icons.unfold_less_rounded,
        label: strings.collapseAll,
        size: IconActionSize.small,
        onPressed: _collapseAll,
      ),
      CopyButton(
        _pretty,
        tooltip: strings.copyJson,
        iconSize: context.iconSizes.md,
      ),
    ];
    final actionsWidth =
        2 * IconActionSize.small.box + IconActionSize.inline.box;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AdminSpacing.lg,
        AdminSpacing.xs,
        AdminSpacing.xs,
        AdminSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The actions always fit: the search gives up width first, down to
          // its least, and then the summary ellipsizes.
          final painter = TextPainter(
            text: TextSpan(text: summary, style: summaryStyle),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )..layout();
          final summaryWidth = painter.width;
          painter.dispose();
          final search =
              (constraints.maxWidth -
                      summaryWidth -
                      actionsWidth -
                      AdminSpacing.md -
                      AdminSpacing.xs)
                  .clamp(_minSearchWidth, _searchWidth);
          return Row(
            children: [
              Expanded(
                child: Text(
                  summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: summaryStyle,
                ),
              ),
              if (widget.searchable) ...[
                const Gap(AdminSpacing.md),
                SearchField(
                  controller: _search,
                  size: ControlSize.small,
                  width: search,
                ),
                const Gap(AdminSpacing.xs),
              ],
              ...actions,
            ],
          );
        },
      ),
    );
  }

  Widget _errorBanner(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: context.iconSizes.md,
            color: colors.dangerText,
          ),
          const Gap(AdminSpacing.md),
          Expanded(
            child: Text(
              context.adminL10n.display.invalidJson(_parseError!),
              style: context.type.monoSmall.copyWith(color: colors.dangerText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: context.type.bodySmall.copyWith(
          color: context.colors.foregroundMuted,
        ),
      ),
    );
  }

  String _rootSummary(JsonNode root, DisplayMessages strings) =>
      switch (root.kind) {
        JsonNodeKind.object => '{ } ${strings.jsonKeys(root.childCount)}',
        JsonNodeKind.array => '[ ] ${strings.jsonItems(root.childCount)}',
        _ => root.kind.name,
      };
}

/// A single line of the tree. Container open/collapsed/closing lines are tap
/// targets that fold; a leaf line too long for the view is one that wraps
/// it; other leaf lines take no tap. A container's opening line, and a long
/// leaf's, is also the keyboard's toggle — a Tab stop announcing its
/// expanded state — while a closing line is a pointer shortcut only.
///
/// Every line but a closing one is a Tab stop. Under the pointer or with
/// keyboard focus it shows its copy actions at its end; they are pointer
/// targets only, so the line stays one stop: a focused line copies its value
/// with the platform's copy shortcut, and its path with Shift added. A
/// screen reader finds both as custom actions of the line.
class _JsonRowView extends StatefulWidget {
  final JsonRow row;
  final double height;
  final bool matched;

  /// For a leaf, whether its long value is wrapped over several lines; null
  /// for a line that fits, and for a container's.
  final bool? wrapped;

  final ValueChanged<String> onToggle;
  final ValueChanged<String> onWrap;

  const _JsonRowView({
    super.key,
    required this.row,
    required this.height,
    required this.matched,
    required this.wrapped,
    required this.onToggle,
    required this.onWrap,
  });

  @override
  State<_JsonRowView> createState() => _JsonRowViewState();
}

class _JsonRowViewState extends State<_JsonRowView> {
  bool _hovered = false;
  bool _focused = false;

  /// Whether a plain leaf line shows the keyboard focus highlight.
  bool _highlighted = false;

  /// The path action's last outcome while it shows: true copied, false
  /// failed, null neither.
  bool? _pathCopied;
  Timer? _revert;

  JsonNode get _node => widget.row.node;

  /// What copying the line's value puts on the clipboard: a subtree as
  /// indented JSON, a string as its text, any other value as JSON.
  String get _value => switch (_node.raw) {
    final String text => text,
    _ when _node.isContainer => const JsonEncoder.withIndent(
      '  ',
    ).convert(_node.raw),
    _ => _node.encoded,
  };

  @override
  void dispose() {
    _revert?.cancel();
    super.dispose();
  }

  /// Copies [text] and announces the outcome; the path action shows it.
  Future<void> _copy(String text, {bool path = false}) async {
    final copied = await copyText(context, text);
    if (!mounted || !path) return;
    setState(() => _pathCopied = copied);
    _revert?.cancel();
    _revert = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _pathCopied = null);
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.keyC ||
        widget.row.closing) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    final apple = switch (defaultTargetPlatform) {
      TargetPlatform.macOS || TargetPlatform.iOS => true,
      _ => false,
    };
    if (!(apple ? keyboard.isMetaPressed : keyboard.isControlPressed)) {
      return KeyEventResult.ignored;
    }
    final path = keyboard.isShiftPressed;
    unawaited(_copy(path ? _node.path : _value, path: path));
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final node = _node;
    final colors = context.colors;
    final foldable = node.isContainer && !node.isEmpty;
    final wraps = !foldable && widget.wrapped != null;

    Color? fill(Set<WidgetState> states) => widget.matched
        ? colors.warning.withValues(alpha: _matchAlpha)
        : states.contains(WidgetState.pressed)
        ? colors.pressedOverlay
        : _hovered
        ? colors.hoverOverlay
        : null;

    final l10n = context.adminL10n.display;
    final copyActions = row.closing
        ? null
        : {
            CustomSemanticsAction(label: l10n.copyValue): () =>
                unawaited(_copy(_value)),
            CustomSemanticsAction(label: l10n.copyPath): () =>
                unawaited(_copy(node.path, path: true)),
          };
    // Rows sit edge to edge in a clipped list, so the ring is drawn inside
    // the row rather than around it.
    BoxDecoration? ring(bool focused) => focused
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(context.radii.radiusSmall),
            border: Border.all(
              color: colors.focusRing,
              width: context.focus.width,
            ),
          )
        : null;

    Widget line;
    if (!foldable && !wraps) {
      // The detector's focus semantics merge into this node, beside the
      // copy actions.
      line = Semantics(
        container: true,
        customSemanticsActions: copyActions,
        child: FocusableActionDetector(
          onShowFocusHighlight: (shown) {
            if (shown != _highlighted) setState(() => _highlighted = shown);
          },
          child: Container(
            height: widget.height,
            foregroundDecoration: ring(_highlighted),
            color: fill(const {}),
            child: _content(context),
          ),
        ),
      );
    } else {
      line = Tappable.states(
        onTap: () =>
            foldable ? widget.onToggle(node.path) : widget.onWrap(node.path),
        focusable: !row.closing,
        expanded: row.closing
            ? null
            : foldable
            ? !row.collapsed
            : widget.wrapped,
        customSemanticsActions: copyActions,
        showFocusRing: false,
        builder: (context, states) => Container(
          height: widget.height,
          foregroundDecoration: ring(states.contains(WidgetState.focused)),
          color: fill(states),
          child: _content(context),
        ),
      );
      if (row.closing) line = ExcludeSemantics(child: line);
    }

    final actions = !row.closing && (_hovered || _focused);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (focused) => setState(() => _focused = focused),
        onKeyEvent: _onKey,
        child: Stack(
          children: [
            line,
            if (actions)
              PositionedDirectional(
                top: (_rowHeight(context) - IconActionSize.inline.box) / 2,
                end: AdminSpacing.xs,
                child: _actions(context, fill(const {})),
              ),
          ],
        ),
      ),
    );
  }

  /// The copy actions, on the line's own fill made opaque so the text they
  /// cover doesn't show through.
  Widget _actions(BuildContext context, Color? fill) {
    final colors = context.colors;
    final l10n = context.adminL10n.display;
    final background = fill == null
        ? colors.background
        : Color.alphaBlend(fill, colors.background);
    return ExcludeFocus(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(context.radii.radiusSmall),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: AdminSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CopyButton(
                _value,
                tooltip: l10n.copyValue,
                iconSize: context.iconSizes.md,
              ),
              IconAction(
                switch (_pathCopied) {
                  true => Icons.check_rounded,
                  false => Icons.error_outline_rounded,
                  null => Icons.link_rounded,
                },
                // The path is in the name, so a screen reader moving from
                // button to button hears which line each one copies.
                label: l10n.joinParts([l10n.copyPath, _node.path]),
                size: IconActionSize.inline,
                color: switch (_pathCopied) {
                  true => colors.successText,
                  false => colors.dangerText,
                  null => null,
                },
                onPressed: () => _copy(_node.path, path: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final node = _node;
    final indent = _indentOf(context);
    final wrapped = widget.wrapped ?? false;
    // A single line is centred in its row; a wrapped value starts where
    // that line would, and runs down.
    final inset = wrapped
        ? (_rowHeight(context) - _lineHeight(context)) / 2
        : 0.0;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: AdminSpacing.md + node.depth * indent,
        end: AdminSpacing.md,
        top: inset,
      ),
      child: Row(
        crossAxisAlignment: wrapped
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: indent,
            height: _lineHeight(context),
            child: _disclosure(context),
          ),
          Expanded(
            child: Text.rich(
              _lineSpan(context, widget.row),
              maxLines: wrapped ? null : 1,
              overflow: wrapped ? TextOverflow.clip : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _disclosure(BuildContext context) {
    final row = widget.row;
    final node = row.node;
    if (row.closing || !node.isContainer || node.isEmpty) return null;
    return Icon(
      row.collapsed ? Icons.chevron_right_rounded : Icons.expand_more_rounded,
      size: context.iconSizes.md,
      color: context.colors.foregroundMuted,
    );
  }
}

/// [row]'s line as styled text: key, punctuation and value in the syntax
/// colours, in the theme's monospace style.
TextSpan _lineSpan(BuildContext context, JsonRow row) {
  final colors = context.colors;
  final syntax = colors.syntax;
  final punctuation = syntax.punctuation;
  final node = row.node;
  final spans = <InlineSpan>[];

  InlineSpan span(String text, Color color) => TextSpan(
    text: text,
    style: TextStyle(color: color),
  );

  final open = node.kind == JsonNodeKind.array ? '[' : '{';
  final close = node.kind == JsonNodeKind.array ? ']' : '}';

  if (row.closing) {
    spans.add(span(close, punctuation));
    if (!row.last) spans.add(span(',', punctuation));
  } else {
    if (node.key != null) {
      spans
        ..add(span(jsonEncode(node.key), syntax.key))
        ..add(span(': ', punctuation));
    }
    if (!node.isContainer) {
      spans.add(span(node.encoded, _leafColor(node.kind, syntax)));
    } else if (node.isEmpty) {
      spans.add(span('$open$close', punctuation));
    } else if (row.collapsed) {
      final strings = context.adminL10n.display;
      final n = node.childCount;
      final count = node.kind == JsonNodeKind.array
          ? strings.jsonItems(n)
          : strings.jsonKeys(n);
      // Isolated, so a right-to-left language's count reads in its own
      // order inside the left-to-right line.
      spans
        ..add(span('$open ', punctuation))
        ..add(span('\u2068$count\u2069', colors.foregroundMuted))
        ..add(span(' $close', punctuation));
    } else {
      spans.add(span(open, punctuation));
    }
    final opens = node.isContainer && !node.isEmpty && !row.collapsed;
    if (!opens && !row.last) spans.add(span(',', punctuation));
  }
  return TextSpan(style: context.type.mono, children: spans);
}

Color _leafColor(JsonNodeKind kind, AdminSyntaxColors syntax) => switch (kind) {
  JsonNodeKind.string => syntax.string,
  JsonNodeKind.number => syntax.number,
  JsonNodeKind.boolean || JsonNodeKind.nul => syntax.literal,
  JsonNodeKind.object || JsonNodeKind.array => syntax.punctuation,
};
