import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart' show Bidi;
import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../theme/palette.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'severity.dart';

/// One line of a [LogView]: its [text], with an optional [prefix] and
/// [severity].
@immutable
class LogLine {
  /// The line as the job wrote it, without its line break.
  final String text;

  /// Drawn muted in a column before [text]: a time, an elapsed "12.4 s", a
  /// source.
  final String? prefix;

  /// Tints [text]: success, warning and danger in their text-safe colours.
  /// Info is drawn plain, as most of a log is, so the lines that need a look
  /// stand out.
  final Severity? severity;

  const LogLine(this.text, {this.prefix, this.severity});
}

/// The output of a job, a deploy, an import, a build or a worker, as lines of
/// monospaced text, oldest first: while it runs, or after.
///
/// It scrolls, and fills the height its parent gives it, so it needs a
/// bounded height, as a [ListView] does: a [SizedBox], an [Expanded]. Lines
/// are built as they scroll into view, so a log of thousands of lines stays
/// cheap.
///
/// With [follow], it opens on the last line and keeps the last line in view
/// as [lines] grows. A reader who scrolls up stays on the lines they are
/// reading while more arrive below; once they scroll back to the end, it
/// follows again. Without [follow], it opens on the first line and moves only
/// when the reader scrolls it.
///
/// Long lines wrap. A [LogLine.prefix] sits in a column as wide as the widest
/// prefix, right-aligned in tabular figures, so times and durations line up.
/// The text is in the theme's `monoSmall` step: a log is scanned more than
/// read, and the denser step keeps more of it in view and wraps fewer lines.
///
/// The log is a read-only place: a selection runs across lines, and copies
/// one line per line, a tab between a prefix and its text.
///
/// Right to left, the prefix column moves to the right. Each line's text keeps
/// the direction of its first letter, so a path or a command reads as it was
/// written in an Arabic admin, beside its prefix.
class LogView extends StatefulWidget {
  /// The lines, oldest first. The list may be a new one each build or the
  /// same one grown in place.
  final List<LogLine> lines;

  /// Keep the last line in view as lines arrive, while the reader is at the
  /// end.
  final bool follow;

  /// Shown when there are no lines: "No output yet" unless set.
  final String? emptyText;

  const LogView({
    super.key,
    required this.lines,
    this.follow = true,
    this.emptyText,
  });

  @override
  State<LogView> createState() => _LogViewState();
}

/// The direction of [text]'s first letter that has one, or null for a line of
/// digits and punctuation.
TextDirection? _directionOf(String text) {
  if (Bidi.startsWithRtl(text)) return TextDirection.rtl;
  // Physical: the direction the line itself is written in.
  if (Bidi.startsWithLtr(text)) return TextDirection.ltr;
  return null;
}

/// Whether every character of [text] is printable ASCII, whose glyphs a
/// monospaced font draws one advance wide.
bool _plain(String text) {
  for (final unit in text.codeUnits) {
    if (unit < 0x20 || unit > 0x7E) return false;
  }
  return true;
}

/// The colour [severity] gives a line's text, or null for the plain one.
Color? _toneOf(AdminPalette colors, Severity? severity) => switch (severity) {
  Severity.success => colors.successText,
  Severity.warning => colors.warningText,
  Severity.danger => colors.dangerText,
  Severity.info || null => null,
};

class _LogViewState extends State<LogView> {
  late final _scroll = _FollowingScrollController(
    () => widget.follow && _atEnd,
  );

  /// The selection's focus: out of the Tab order, as nothing shows it has
  /// focus.
  final _selectionFocus = FocusNode(
    debugLabel: 'LogView selection',
    skipTraversal: true,
  );

  final _measure = _Measure();

  /// Whether the reader is at the end, as of their last scroll.
  var _atEnd = true;

  /// How far from the end the reader may stop and still be at it.
  var _slop = 0.0;

  @override
  void initState() {
    super.initState();
    PaintingBinding.instance.systemFonts.addListener(_onFontsChanged);
  }

  @override
  void didUpdateWidget(LogView old) {
    super.didUpdateWidget(old);
    if (widget.lines.isEmpty) {
      _atEnd = true;
    } else if (widget.follow && !old.follow) {
      _atEnd = !_scroll.hasClients || _scroll.position.extentAfter <= _slop;
    }
  }

  @override
  void dispose() {
    PaintingBinding.instance.systemFonts.removeListener(_onFontsChanged);
    _scroll.dispose();
    _selectionFocus.dispose();
    _measure.dispose();
    super.dispose();
  }

  /// A line measured before its font loaded was measured in a fallback.
  void _onFontsChanged() => setState(_measure.forget);

  bool _onScroll(ScrollUpdateNotification notification) {
    if (notification.depth == 0) {
      _atEnd = notification.metrics.extentAfter <= _slop;
    }
    return false;
  }

  /// The view grew taller or the log shorter, which can bring the end into
  /// view without a scroll.
  bool _onMetrics(ScrollMetricsNotification notification) {
    if (notification.depth == 0 && notification.metrics.extentAfter <= _slop) {
      _atEnd = true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(context.radii.radius);
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: radius,
        border: Border.all(
          color: colors.border,
          width: context.stroke.hairline,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: widget.lines.isEmpty ? _empty(context) : _log(context),
      ),
    );
  }

  Widget _empty(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AdminSpacing.xl),
      child: Text(
        widget.emptyText ?? context.adminL10n.display.logEmpty,
        textAlign: TextAlign.center,
        style: context.type.bodySmall.copyWith(
          color: context.colors.foregroundMuted,
        ),
      ),
    ),
  );

  Widget _log(BuildContext context) {
    final inherited = DefaultTextStyle.of(context);
    var style = inherited.style.merge(context.type.monoSmall);
    // Bold already, so the bold a Text adds for the platform's bold text
    // setting changes nothing, and the lines lay out as measured.
    if (MediaQuery.boldTextOf(context)) {
      style = context.type.weighted(style, FontWeight.bold);
    }
    // The lines set every default a Text reads from the ambient style, so
    // they lay out exactly as measured.
    return DefaultTextStyle(
      style: style,
      textHeightBehavior:
          inherited.textHeightBehavior ??
          DefaultTextHeightBehavior.maybeOf(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final lines = widget.lines;
          _measure.update(context, lines, constraints.maxWidth);
          final extents = _measure.extents;
          final prefixWidth = _measure.prefixWidth;
          _slop = _measure.lineHeight / 2;
          return SelectionArea(
            focusNode: _selectionFocus,
            child: Scrollbar(
              controller: _scroll,
              child: NotificationListener<ScrollMetricsNotification>(
                onNotification: _onMetrics,
                child: NotificationListener<ScrollUpdateNotification>(
                  onNotification: _onScroll,
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(AdminSpacing.md),
                    itemCount: lines.length,
                    itemExtentBuilder: (i, _) =>
                        i < extents.length ? extents[i] : null,
                    itemBuilder: (context, i) => _LineView(
                      line: lines[i],
                      prefixWidth: prefixWidth,
                      breaks: i < lines.length - 1,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A [ScrollController] whose positions hold the end in view while [follows]
/// says so.
class _FollowingScrollController extends ScrollController {
  final ValueGetter<bool> follows;

  // A log opens on its end or its start, never where an earlier one was.
  _FollowingScrollController(this.follows) : super(keepScrollOffset: false);

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) => _FollowingScrollPosition(
    follows,
    physics: physics,
    context: context,
    initialPixels: initialScrollOffset,
    keepScrollOffset: keepScrollOffset,
    oldPosition: oldPosition,
    debugLabel: debugLabel,
  );
}

/// Holds the end in view while [follows] says so, through every change of
/// the content's height or the view's: the first layout, lines arriving
/// however many at once, lines wrapping anew, a resize, a theme. It moves as
/// the list lays out, so the list never paints short of the end. A scroll in
/// progress is the reader's, and is left alone.
///
/// The list replaces its position when an inherited widget it reads changes,
/// a theme for one, and the new one takes the old one's offset as it stood:
/// so this checks every layout, not only a change of the content's height.
class _FollowingScrollPosition extends ScrollPositionWithSingleContext {
  final ValueGetter<bool> follows;

  _FollowingScrollPosition(
    this.follows, {
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    // Moved before the new extent is taken in, so the position is never out
    // of range, which would start a scroll back. The list's extent is an
    // estimate until it lays out its last line: laid out again at the end it
    // reports the real one, and this moves again until the two agree.
    final moves =
        follows() && !activity!.isScrolling && pixels != maxScrollExtent;
    if (moves) correctPixels(maxScrollExtent);
    return super.applyContentDimensions(minScrollExtent, maxScrollExtent) &&
        !moves;
  }
}

/// The style, text size and direction lines are laid out in: what a line's
/// height depends on beside its own words and the width it wraps in.
@immutable
class _Typeset {
  final TextStyle text;
  final TextStyle prefix;
  final TextScaler scaler;
  final TextHeightBehavior? heightBehavior;
  final Locale? locale;
  final TextDirection direction;

  const _Typeset({
    required this.text,
    required this.prefix,
    required this.scaler,
    required this.heightBehavior,
    required this.locale,
    required this.direction,
  });

  /// The typeset of a [Text] under [context], as [_LineView] builds them.
  factory _Typeset.of(BuildContext context) {
    final defaults = DefaultTextStyle.of(context);
    final text = defaults.style;
    return _Typeset(
      text: text,
      prefix: text.merge(_LineView.prefixFeatures),
      scaler: MediaQuery.textScalerOf(context),
      heightBehavior: defaults.textHeightBehavior,
      locale: Localizations.maybeLocaleOf(context),
      direction: Directionality.of(context),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _Typeset &&
      other.text == text &&
      other.prefix == prefix &&
      other.scaler == scaler &&
      other.heightBehavior == heightBehavior &&
      other.locale == locale &&
      other.direction == direction;

  @override
  int get hashCode =>
      Object.hash(text, prefix, scaler, heightBehavior, locale, direction);
}

/// Each line's height before the list builds it, so the list knows where
/// every line is without building the ones out of view, and can open on the
/// last.
///
/// A line of printable ASCII short enough to fit takes one line: it is never
/// wider than its length in the widest such glyph. Any other line is laid out
/// once, as its [Text] will be, and kept by its words.
class _Measure {
  _Typeset? _typeset;
  TextPainter? _painter;

  /// The widest printable ASCII glyph of the text, and of a prefix.
  double _advance = 0;
  double _prefixAdvance = 0;

  /// One line of the text, at the text size.
  double lineHeight = 0;

  /// The width a line's text wraps in.
  double _textWidth = 0;

  /// The width of the prefix column: the widest prefix, or 0 with none.
  double prefixWidth = 0;

  /// The height of each line, in the order of the lines last measured.
  List<double> extents = const [];
  List<LogLine> _measured = const [];

  /// The heights of the lines that took a layout, by their words.
  final _heights = <String, double>{};

  /// The width and height of the prefixes that took a layout.
  final _prefixes = <String, Size>{};

  /// Measures everything again, after a font load.
  void forget() => _typeset = null;

  void dispose() => _painter?.dispose();

  void update(BuildContext context, List<LogLine> lines, double width) {
    final typeset = _Typeset.of(context);
    if (typeset != _typeset) {
      _typeset = typeset;
      _painter?.dispose();
      _painter = TextPainter(
        textScaler: typeset.scaler,
        locale: typeset.locale,
        textHeightBehavior: typeset.heightBehavior,
        textDirection: typeset.direction,
      );
      final (advance, height) = _widestGlyph(typeset.text);
      _advance = advance;
      lineHeight = height;
      _prefixAdvance = _widestGlyph(typeset.prefix).$1;
      _prefixes.clear();
      _forgetLines();
    }

    // Words only ever measured once are forgotten as the log moves on.
    final bound = 2 * lines.length + 256;
    if (_heights.length > bound) _heights.clear();
    if (_prefixes.length > bound) _prefixes.clear();

    var widest = 0.0;
    var longest = 0;
    for (final line in lines) {
      final prefix = line.prefix;
      if (prefix == null || prefix.isEmpty) continue;
      if (_plain(prefix)) {
        longest = math.max(longest, prefix.length);
      } else {
        widest = math.max(widest, _prefix(prefix).width);
      }
    }
    prefixWidth = math.max(widest, longest * _prefixAdvance).ceilToDouble();

    final textWidth = math.max(
      0.0,
      width -
          2 * AdminSpacing.md -
          (prefixWidth > 0 ? prefixWidth + AdminSpacing.lg : 0),
    );
    if (textWidth != _textWidth) {
      _textWidth = textWidth;
      _forgetLines();
    }

    final measured = _measured;
    extents = [
      for (final (i, line) in lines.indexed)
        i < measured.length && identical(measured[i], line)
            ? extents[i]
            : _extentOf(line),
    ];
    _measured = List.of(lines);
  }

  void _forgetLines() {
    _heights.clear();
    _measured = const [];
  }

  double _extentOf(LogLine line) {
    final prefix = line.prefix;
    final prefixHeight = prefix == null || prefix.isEmpty
        ? 0.0
        : _plain(prefix)
        ? lineHeight
        : _prefix(prefix).height;
    return math.max(_textHeight(line.text), prefixHeight) +
        2 * AdminSpacing.xxs;
  }

  double _textHeight(String text) {
    // A line holds fewer glyphs than fit with half an advance to spare, so a
    // rounding in the font's advances never wraps one.
    if (text.isEmpty ||
        (text.length * _advance <= _textWidth - _advance / 2 && _plain(text))) {
      return lineHeight;
    }
    return _heights[text] ??= _layOut(
      text,
      _typeset!.text,
      direction: _directionOf(text),
      maxWidth: _textWidth,
    ).height;
  }

  Size _prefix(String prefix) => _prefixes[prefix] ??= _layOut(
    prefix,
    _typeset!.prefix,
    direction: _directionOf(prefix),
    maxLines: 1,
  );

  /// The size of [text] in [style], laid out as a [Text] lays it out.
  Size _layOut(
    String text,
    TextStyle style, {
    TextDirection? direction,
    int? maxLines,
    double maxWidth = double.infinity,
  }) {
    final painter = _painter!
      ..text = TextSpan(text: text, style: style)
      ..textDirection = direction ?? _typeset!.direction
      ..maxLines = maxLines
      ..layout(maxWidth: maxWidth);
    return painter.size;
  }

  /// The advance of the widest printable ASCII glyph in [style], and the
  /// height of a line of them.
  (double, double) _widestGlyph(TextStyle style) {
    var advance = 0.0;
    var height = 0.0;
    for (var unit = 0x20; unit <= 0x7E; unit++) {
      final size = _layOut(String.fromCharCode(unit), style);
      advance = math.max(advance, size.width);
      height = math.max(height, size.height);
    }
    return (advance, height);
  }
}

/// One line of the log: its prefix column, then its text, which wraps.
class _LineView extends StatefulWidget {
  /// What sets a prefix apart from the text: figures of one width, so times
  /// and durations line up.
  static const prefixFeatures = TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
  );

  final LogLine line;

  /// The prefix column's width, 0 when no line has a prefix.
  final double prefixWidth;

  /// Whether a line follows this one, so a selection past its end copies a
  /// line break.
  final bool breaks;

  const _LineView({
    required this.line,
    required this.prefixWidth,
    required this.breaks,
  });

  @override
  State<_LineView> createState() => _LineViewState();
}

class _LineViewState extends State<_LineView> {
  final _selection = _LineSelection();

  @override
  void dispose() {
    _selection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ambient = Directionality.of(context);
    final LogLine(:text, :prefix, :severity) = widget.line;
    final direction = _directionOf(text) ?? ambient;
    _selection
      ..blank = text.isEmpty
      ..breaks = widget.breaks
      // Selection orders a line's parts left to right, whichever way it
      // reads: right to left, the text comes first.
      ..textFirst = ambient == TextDirection.rtl;

    final tone = _toneOf(colors, severity);
    final body = Text(
      // Not user-facing: a blank line holds a space, so a selection can take
      // its line break.
      text.isEmpty ? ' ' : text,
      textDirection: direction,
      // Beside the prefix, whichever way the line reads.
      textAlign: direction == ambient ? TextAlign.start : TextAlign.end,
      style: tone == null ? null : TextStyle(color: tone),
    );

    Widget? column;
    if (prefix != null && prefix.isNotEmpty) {
      final prefixDirection = _directionOf(prefix) ?? ambient;
      column = Text(
        prefix,
        softWrap: false,
        maxLines: 1,
        textDirection: prefixDirection,
        // Against the text, whichever way the prefix reads.
        textAlign: prefixDirection == ambient ? TextAlign.end : TextAlign.start,
        style: _LineView.prefixFeatures.copyWith(color: colors.foregroundMuted),
      );
    }

    return MergeSemantics(
      child: SelectionContainer(
        delegate: _selection,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AdminSpacing.xxs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.prefixWidth > 0) ...[
                SizedBox(width: widget.prefixWidth, child: column),
                const Gap(AdminSpacing.lg),
              ],
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

/// A line's share of a selection across the log: its prefix and its text, a
/// tab between, and a line break once the selection runs on past the end of
/// the text, so a copy keeps the log's lines.
class _LineSelection extends StaticSelectionContainerDelegate {
  /// The line has no text, and shows a space in its place.
  bool blank = false;

  /// A line follows this one.
  bool breaks = false;

  /// The text is the first of the line's selectables rather than the last.
  bool textFirst = false;

  @override
  SelectedContent? getSelectedContent() {
    if (selectables.isEmpty) return null;
    final text = textFirst ? selectables.first : selectables.last;
    final prefix = selectables.length < 2
        ? null
        : (textFirst ? selectables.last : selectables.first)
              .getSelectedContent()
              ?.plainText;
    var words = text.getSelectedContent()?.plainText;
    if (prefix == null && words == null) return null;
    if (blank) words = null;

    final range = text.getSelection();
    final throughEnd =
        breaks &&
        range != null &&
        math.max(range.startOffset, range.endOffset) >= text.contentLength;
    final parts = [
      if (prefix != null && prefix.isNotEmpty) prefix,
      if (words != null && words.isNotEmpty) words,
    ];
    return SelectedContent(
      plainText: parts.join('\t') + (throughEnd ? '\n' : ''),
    );
  }
}
