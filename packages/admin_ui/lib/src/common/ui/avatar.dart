import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../theme/contrast.dart';
import '../../theme/tokens.dart';

/// Whether an [Avatar] is a circle or a rounded square.
enum AvatarShape { circle, rounded }

/// A user / entity avatar: an [image] when there is one, falling back to
/// [initials] on a coloured chip — while the image loads, and for good if it
/// fails. Pass an explicit [color], or let it derive a stable colour from the
/// theme's chart series, so each person reads consistently; the initials are
/// held to 4.5:1 on it.
///
/// Give it a [name] and it derives the initials, the colour and the accessible
/// name from it. Without a [name] or [semanticLabel] the avatar is decorative
/// and silent — the usual case beside a visible name.
class Avatar extends StatelessWidget {
  final String? initials;

  /// The person or entity: the source of [initials] when those are omitted,
  /// the seed of the auto colour, and the accessible name.
  final String? name;

  final ImageProvider? image;
  final Color? color;
  final double size;
  final AvatarShape shape;

  /// The accessible name, instead of [name].
  final String? semanticLabel;

  const Avatar({
    super.key,
    this.initials,
    this.name,
    this.image,
    this.color,
    this.size = 28,
    this.shape = AvatarShape.circle,
    this.semanticLabel,
  });

  /// The first letters of the first and last words of [name].
  static String _initialsOf(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.first.isEmpty) return '';
    final first = words.first.characters.first;
    return words.length == 1 ? first : first + words.last.characters.first;
  }

  /// A series colour picked by hashing [seed]. Entries within 1.5:1 of white
  /// (luminance above 0.65) or of black (below 0.025) are left out: a tint
  /// like Carbon's red-10 suits a chart but reads as a blank disc on a chip.
  Color _autoColor(List<Color> chart, String seed) {
    final mid = [
      for (final c in chart)
        if (relativeLuminance(c) case final l when l >= 0.025 && l <= 0.65) c,
    ];
    final palette = mid.isEmpty ? chart : mid;
    if (seed.isEmpty) return palette.first;
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return palette[hash % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final letters = initials ?? (name == null ? '' : _initialsOf(name!));
    final label = letters.characters.take(2).toString().toUpperCase();

    var bg = color ?? _autoColor(colors.chart, initials ?? name ?? '');
    final fg = colors.foregroundOn(bg);
    if (color == null && contrastRatio(fg, bg) < 4.5) {
      // A mid-tone series colour: shade it away from the initials until they
      // read.
      bg = colors.readableOn(bg, surfaces: [fg]);
    }

    final fallback = ColoredBox(
      color: bg,
      child: Center(
        // Sized to the mark, not the text: initials keep their size at any
        // text scale, as a CircleAvatar's do.
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          textScaler: TextScaler.noScaling,
          style: context.type.weighted(
            TextStyle(
              color: fg,
              // token-literal: initials scale with the mark, not the ramp
              fontSize: math.max(10, (size * 0.38).roundToDouble()),
              height: 1,
              // Even leading centres the caps on the chip.
              leadingDistribution: TextLeadingDistribution.even,
            ),
            FontWeight.w700,
          ),
        ),
      ),
    );

    final content = image == null
        ? fallback
        : Image(
            image: image!,
            fit: BoxFit.cover,
            width: size,
            height: size,
            excludeFromSemantics: true,
            frameBuilder: (_, child, frame, synchronous) =>
                frame == null && !synchronous ? fallback : child,
            errorBuilder: (_, _, _) => fallback,
          );

    final avatar = SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: shape == AvatarShape.circle
            ? BorderRadius.circular(size)
            : BorderRadius.circular(context.radii.radiusSmall),
        child: content,
      ),
    );
    final announced = semanticLabel ?? name;
    return announced == null
        ? ExcludeSemantics(child: avatar)
        : Semantics(
            image: true,
            label: announced,
            excludeSemantics: true,
            child: avatar,
          );
  }
}
