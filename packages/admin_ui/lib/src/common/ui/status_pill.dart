import 'package:material_ui/material_ui.dart';

import '../../theme/spacing.dart';
import '../../theme/tokens.dart';

/// One status value's rendering: the word, the colour, and whether its dot is
/// a hollow ring (not-real-yet states) or filled.
class StatusMeta {
  final String label;

  /// The status accent: the dot, the pill's tint.
  final Color color;

  /// The label colour — the text-safe role for [color] (e.g. `successText` for
  /// `success`). Defaults to [color]; [StatusPill] still darkens (or lightens)
  /// it until it reads on the pill's tint.
  final Color text;

  final bool ring;

  const StatusMeta(this.label, this.color, {this.ring = false, Color? text})
    : text = text ?? color;
}

/// A status dot — filled disc or hollow ring (a state that is not real
/// yet), in a status colour.
///
/// The dot is decoration beside a word by default. Where it stands alone,
/// give it a [semanticLabel] so assistive technology reads the state that
/// the colour carries.
class StatusDot extends StatelessWidget {
  final Color color;
  final bool ring;
  final double size;

  /// What the dot means, read out in place of the colour; null leaves the
  /// dot out of the semantics tree.
  final String? semanticLabel;

  const StatusDot({
    super.key,
    required this.color,
    this.ring = false,
    this.size = 7,
    this.semanticLabel,
  });

  StatusDot.of(StatusMeta meta, {super.key, this.size = 7, this.semanticLabel})
    : color = meta.color,
      ring = meta.ring;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ring ? Colors.transparent : color,
        shape: BoxShape.circle,
        border: ring
            ? Border.all(color: color, width: context.stroke.controlStrong)
            : null,
      ),
    );
    final label = semanticLabel;
    if (label == null) return dot;
    return Semantics(container: true, label: label, child: dot);
  }
}

/// The small tinted status pill — a [StatusDot] plus the status word, colour
/// always paired with a label.
///
/// The accent tints the pill and draws the dot; the word is set in
/// [StatusMeta.text], held to 4.5:1 on that tint. The corners are the theme's
/// pill radius, and a word longer than the room it gets ends in an ellipsis.
class StatusPill extends StatelessWidget {
  final StatusMeta meta;

  const StatusPill(this.meta, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fill = c.statusFill(meta.color);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.sm,
        vertical: AdminSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(context.radii.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusDot.of(meta, size: 6),
          const Gap(AdminSpacing.sm),
          Flexible(
            child: Text(
              meta.label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: context.type
                  .weighted(context.type.micro, FontWeight.w600)
                  .copyWith(color: c.readableOn(meta.text, surfaces: [fill])),
            ),
          ),
        ],
      ),
    );
  }
}
