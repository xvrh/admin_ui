import 'package:material_ui/material_ui.dart';

import '../../i18n/locale_status.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../diff_model.dart';

/// How a diff is laid out: [unified] interleaves both sides in one block;
/// [split] shows before and after in two aligned columns.
enum DiffLayout { unified, split }

/// Inline word-level text diff. Word-diffs [before] → [after] and paints
/// additions underlined on a green wash, deletions struck through on a red
/// wash; the words keep the text colour. In
/// [DiffLayout.split] the before column shows only deletions, the after column
/// only additions.
///
/// A screen reader hears each run with its op — "deleted: Build, inserted:
/// Ship, faster" — and, split, each column as Before or After.
///
/// Given a [language], the text is laid out as that language's content
/// ([LaneLanguage]): an English value in an Arabic admin runs left to right
/// and starts at the left, its trailing period at the end.
class TextDiff extends StatelessWidget {
  final String before;
  final String after;
  final DiffLayout layout;

  /// Base style for the text; defaults to `context.type.body`.
  final TextStyle? style;

  /// The language the value is written in, such as 'ar' or 'pt-BR'. Its runs
  /// take that language's direction and locale, while the split columns keep
  /// the admin's order. Null or empty keeps the ambient direction, for a
  /// value that is not per language.
  final String? language;

  const TextDiff({
    super.key,
    required this.before,
    required this.after,
    this.layout = DiffLayout.unified,
    this.style,
    this.language,
  });

  @override
  Widget build(BuildContext context) {
    final segments = InlineDiff.words(before, after);
    final base = style ?? context.type.body;

    Widget text(_Side side) {
      final span = _span(context, segments, base, side);
      if (span == null) return _empty(context, base);
      return _inLanguage(context, Text.rich(span));
    }

    if (layout == DiffLayout.unified) return text(_Side.unified);

    Widget column(String name, _Side side) => Expanded(
      child: Semantics(container: true, label: name, child: text(side)),
    );

    final strings = context.adminL10n.display;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        column(strings.before, _Side.before),
        const Gap(AdminSpacing.xl),
        column(strings.after, _Side.after),
      ],
    );
  }

  /// [text] as content in [language]. A run in the other direction than the
  /// admin's takes the width it is given, so it starts at its own edge.
  Widget _inLanguage(BuildContext context, Widget text) {
    final code = language;
    if (code == null || code.isEmpty) return text;
    final ambient = Directionality.of(context);
    return LaneLanguage(
      code: code,
      child: Builder(
        builder: (context) => Directionality.of(context) == ambient
            ? text
            : Align(
                alignment: AlignmentDirectional.topStart,
                heightFactor: 1,
                child: text,
              ),
      ),
    );
  }

  /// The dash a side with no text shows, in the admin's language.
  Widget _empty(BuildContext context, TextStyle base) => Text(
    '—',
    semanticsLabel: context.adminL10n.display.empty,
    style: base.copyWith(color: context.colors.foregroundMuted),
  );

  /// The runs of [side], or null when it has no text.
  TextSpan? _span(
    BuildContext context,
    List<DiffSegment> segments,
    TextStyle base,
    _Side side,
  ) {
    final c = context.colors;
    final strings = context.adminL10n.display;
    // The words keep the text colour; the change is carried by a wash plus a
    // line — under for added, through for removed — so it reads without colour.
    final addedStyle = base.copyWith(
      // token-literal: an inserted run's wash
      background: Paint()..color = c.success.withValues(alpha: 0.24),
      decoration: TextDecoration.underline,
      decorationColor: c.successText,
    );
    final removedStyle = base.copyWith(
      // token-literal: a removed run's wash
      background: Paint()..color = c.danger.withValues(alpha: 0.2),
      decoration: TextDecoration.lineThrough,
      decorationColor: c.dangerText,
    );

    final children = <TextSpan>[];
    DiffOp? previous;
    void mark(String text, TextStyle style, DiffOp op) {
      // Only the word is washed: surrounding spaces stay plain, and a removal
      // butting straight into its replacement gets a thin gap between them.
      final lead = RegExp(r'^\s*').stringMatch(text)!;
      final core = text.trimLeft().trimRight();
      final trail = text.substring(lead.length + core.length);
      if (lead.isEmpty && previous == DiffOp.removed && op == DiffOp.added) {
        children.add(TextSpan(text: '\u2009', style: base));
      }
      if (lead.isNotEmpty) children.add(TextSpan(text: lead, style: base));
      if (core.isNotEmpty) {
        children.add(
          TextSpan(
            text: core,
            style: style,
            semanticsLabel: op == DiffOp.added
                ? strings.inserted(core)
                : strings.deleted(core),
          ),
        );
      }
      if (trail.isNotEmpty) children.add(TextSpan(text: trail, style: base));
      previous = trail.isEmpty ? op : null;
    }

    for (final seg in segments) {
      switch (seg.op) {
        case DiffOp.added:
          if (side == _Side.before) continue;
          mark(seg.text, addedStyle, DiffOp.added);
        case DiffOp.removed:
          if (side == _Side.after) continue;
          mark(seg.text, removedStyle, DiffOp.removed);
        case DiffOp.unchanged:
        case DiffOp.changed:
        case DiffOp.moved:
          children.add(TextSpan(text: seg.text, style: base));
          previous = null;
      }
    }

    if (children.isEmpty) return null;
    return TextSpan(children: children);
  }
}

enum _Side { unified, before, after }
