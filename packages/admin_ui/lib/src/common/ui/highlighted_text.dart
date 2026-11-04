import 'package:material_ui/material_ui.dart';

import '../../theme/tokens.dart';

/// Renders [text] with the [ranges] (flat `[start,end, …]` offsets) emphasized
/// in the accent colour — for showing where a search term matched within a
/// snippet. Ranges may come in any order and overlap: they are clamped to the
/// text, sorted and merged, so every character renders once. A reversed or
/// empty pair, or a trailing odd offset, is ignored. For search results: a
/// palette's hits, a table cell that matched a query.
class HighlightedText extends StatelessWidget {
  final String text;
  final List<int> ranges;
  final TextStyle? style;
  final Color? highlightColor;
  final int maxLines;

  const HighlightedText(
    this.text, {
    super.key,
    this.ranges = const [],
    this.style,
    this.highlightColor,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final base = style ?? context.type.body;
    if (ranges.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: base,
      );
    }
    final accent = context.type
        .weighted(base, FontWeight.w700)
        .copyWith(color: highlightColor ?? context.colors.primaryText);
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final (start, end) in _merged(text.length, ranges)) {
      if (start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, start), style: base));
      }
      spans.add(TextSpan(text: text.substring(start, end), style: accent));
      cursor = end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: base));
    }
    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// The non-empty `(start, end)` pairs of [ranges], clamped to `0..length`,
/// sorted, with overlapping and touching pairs merged.
List<(int, int)> _merged(int length, List<int> ranges) {
  final pairs = <(int, int)>[
    for (var i = 0; i + 1 < ranges.length; i += 2)
      if (ranges[i].clamp(0, length) < ranges[i + 1].clamp(0, length))
        (ranges[i].clamp(0, length), ranges[i + 1].clamp(0, length)),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  final merged = <(int, int)>[];
  for (final (start, end) in pairs) {
    if (merged.isNotEmpty && start <= merged.last.$2) {
      final (first, last) = merged.removeLast();
      merged.add((first, end > last ? end : last));
    } else {
      merged.add((start, end));
    }
  }
  return merged;
}
