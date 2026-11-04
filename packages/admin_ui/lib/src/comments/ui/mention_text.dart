import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/contrast.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../mentions.dart';

/// A stored comment body as the reader sees it: each `<@id>` token as
/// `@Name`, the name resolved by [nameOf] as it renders, in the theme's link
/// colour at its strong weight; the rest in [style] (the body style when
/// null). Where the link colour reads as the text's own — a neutral primary,
/// as shadcn's — each mention also sits on a chip, a wash of that colour, so
/// it stands apart in every theme.
///
/// The text can be selected and copied, mentions by their names. Under a
/// [SelectionArea] it takes part in that one, so a selection can run on
/// past it; elsewhere it is its own, unless [selectable] is false — for a
/// body inside a row that takes taps.
class MentionText extends StatelessWidget {
  /// The body, mentions as tokens ([tokenizeMentions]).
  final String body;

  /// A mentioned user's display name, by id.
  final String Function(String id) nameOf;

  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  /// Whether the text can be selected where no [SelectionArea] is above it.
  final bool selectable;

  const MentionText(
    this.body, {
    super.key,
    required this.nameOf,
    this.style,
    this.maxLines,
    this.overflow,
    this.selectable = true,
  });

  /// Under this contrast with the text around it, the link colour does not
  /// set a mention apart.
  static const _apart = 1.5;

  @override
  Widget build(BuildContext context) {
    final type = context.type;
    final colors = context.colors;
    final base = style ?? type.body;
    final ink = base.color ?? DefaultTextStyle.of(context).style.color;
    final chip = ink != null && contrastRatio(colors.primaryText, ink) < _apart;
    final mention = type
        .weighted(base, type.spec.strong)
        .copyWith(color: colors.primaryText);
    final mentions = <TextRange>[];
    var offset = 0;
    final spans = <TextSpan>[];
    for (final run in mentionRuns(body, nameOf)) {
      final isMention = run.mentionId != null;
      if (isMention) {
        mentions.add(TextRange(start: offset, end: offset + run.text.length));
      }
      spans.add(TextSpan(text: run.text, style: isMention ? mention : null));
      offset += run.text.length;
    }
    Widget text = Text.rich(
      TextSpan(style: base, children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
    if (chip && mentions.isNotEmpty) {
      text = _MentionChips(
        ranges: mentions,
        color: colors.primaryText.withValues(alpha: colors.stateLayer.selected),
        radius: context.radii.radiusSmall,
        child: text,
      );
    }
    if (!selectable || SelectionContainer.maybeOf(context) != null) {
      return text;
    }
    return SelectionArea(child: text);
  }
}

/// Paints a rounded [color] chip behind each of [ranges] of the text below
/// it, a line at a time, without moving the text.
class _MentionChips extends SingleChildRenderObjectWidget {
  final List<TextRange> ranges;
  final Color color;
  final double radius;

  const _MentionChips({
    required this.ranges,
    required this.color,
    required this.radius,
    required Widget super.child,
  });

  @override
  _RenderMentionChips createRenderObject(BuildContext context) =>
      _RenderMentionChips(ranges, color, radius);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderMentionChips renderObject,
  ) {
    renderObject
      ..ranges = ranges
      ..color = color
      ..radius = radius;
  }
}

class _RenderMentionChips extends RenderProxyBox {
  _RenderMentionChips(this._ranges, this._color, this._radius);

  /// How far a chip reaches past its glyphs: a step of the spacing scale
  /// across, a hairline down, so chips on two lines of body text keep
  /// apart.
  static const _padding = EdgeInsets.symmetric(
    horizontal: AdminSpacing.xxs,
    // token-literal: under the line's leading, below the spacing scale
    vertical: 1,
  );

  List<TextRange> _ranges;
  set ranges(List<TextRange> value) {
    if (listEquals(value, _ranges)) return;
    _ranges = value;
    markNeedsPaint();
  }

  Color _color;
  set color(Color value) {
    if (value == _color) return;
    _color = value;
    markNeedsPaint();
  }

  double _radius;
  set radius(double value) {
    if (value == _radius) return;
    _radius = value;
    markNeedsPaint();
  }

  /// The paragraph under the single-child wrappers `Text` puts above it (a
  /// mouse region under a [SelectionArea]).
  RenderParagraph? get _paragraph {
    RenderObject? node = child;
    while (node is RenderObjectWithChildMixin<RenderBox>) {
      node = node.child;
    }
    return node is RenderParagraph ? node : null;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final paragraph = _paragraph;
    if (paragraph != null) {
      final transform = paragraph.getTransformTo(this);
      final paint = Paint()..color = _color;
      final radius = Radius.circular(_radius);
      for (final range in _ranges) {
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: range.start, extentOffset: range.end),
        );
        for (final box in boxes) {
          final rect = MatrixUtils.transformRect(transform, box.toRect());
          context.canvas.drawRRect(
            RRect.fromRectAndRadius(
              _padding.inflateRect(rect).shift(offset),
              radius,
            ),
            paint,
          );
        }
      }
    }
    super.paint(context, offset);
  }
}
