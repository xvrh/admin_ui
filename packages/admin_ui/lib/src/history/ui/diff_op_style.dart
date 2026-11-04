import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../common/ui/severity.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/formats.dart';
import '../../l10n/sections/display_messages.dart';
import '../../theme/palette.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../diff_model.dart';

/// How one [DiffOp] reads wherever a diff shows it — a block's rail, a
/// record's tag, a count chip, a quick diff's label — so the same change
/// looks the same in every view: one word, one glyph, one count symbol and
/// one tone per op.
///
/// The tones are the status colours: added green, removed red, changed amber,
/// moved the info blue. They sit far apart in hue in every shipped palette.
/// The primary is never a diff tone, since several themes use their primary
/// as their info colour and changed would then read as moved. On a dark page
/// the changed fill turns a yellow amber toward orange: a yellow darkened
/// that far reads as olive, next to added's green.
@immutable
class DiffOpStyle {
  final DiffOp op;

  /// The op's word: Added, Removed, Changed, Moved or Unchanged, in the
  /// app's language.
  final String label;

  final IconData icon;

  /// The count chips' prefix: + − ~ ⇅, or = for unchanged.
  final String symbol;

  /// The raw tone, for rails and dots.
  final Color accent;

  /// The tone as text and small glyphs: at least 4.5:1 on [fill] and on the
  /// page.
  final Color text;

  /// The soft surface behind the op's label or block; transparent for
  /// unchanged.
  final Color fill;

  /// The feedback tone the op shares, for a [Tag]; null for unchanged.
  final Severity? severity;

  const DiffOpStyle._({
    required this.op,
    required this.label,
    required this.icon,
    required this.symbol,
    required this.accent,
    required this.text,
    required this.fill,
    required this.severity,
  });

  /// [op]'s style in the ambient theme and language.
  factory DiffOpStyle.of(BuildContext context, DiffOp op) =>
      DiffOpStyle.resolve(context.colors, op, context.adminL10n.display);

  /// [op]'s style in [colors], its [label] from [strings].
  factory DiffOpStyle.resolve(
    AdminPalette colors,
    DiffOp op, [
    DisplayMessages strings = const DisplayMessagesEn(),
  ]) {
    DiffOpStyle tone(
      String label,
      IconData icon,
      String symbol,
      Color accent,
      Color text,
      Severity severity, {
      Color? tint,
    }) => DiffOpStyle._(
      op: op,
      label: label,
      icon: icon,
      symbol: symbol,
      accent: accent,
      text: text,
      fill: colors.statusFill(tint ?? accent),
      severity: severity,
    );

    return switch (op) {
      DiffOp.added => tone(
        strings.diffAdded,
        Icons.add_rounded,
        '+',
        colors.success,
        colors.successText,
        Severity.success,
      ),
      DiffOp.removed => tone(
        strings.diffRemoved,
        Icons.remove_rounded,
        '−',
        colors.danger,
        colors.dangerText,
        Severity.danger,
      ),
      DiffOp.changed => tone(
        strings.diffChanged,
        Icons.edit_outlined,
        '~',
        colors.warning,
        colors.warningText,
        Severity.warning,
        tint: colors.brightness == Brightness.dark
            ? _gold(colors.warning)
            : null,
      ),
      DiffOp.moved => tone(
        strings.diffMoved,
        Icons.swap_vert_rounded,
        '⇅',
        colors.info,
        colors.infoText,
        Severity.info,
      ),
      DiffOp.unchanged => DiffOpStyle._(
        op: op,
        label: strings.diffUnchanged,
        icon: Icons.drag_handle_rounded,
        symbol: '=',
        accent: colors.border,
        text: colors.readableOn(
          colors.foregroundMuted,
          surfaces: [colors.surface, colors.background],
        ),
        fill: Colors.transparent,
        severity: null,
      ),
    };
  }
}

/// [warning] with its hue held at 40° at most: a gold, not a yellow.
Color _gold(Color warning) {
  final hsl = HSLColor.fromColor(warning);
  return hsl.withHue(math.min(hsl.hue, 40)).toColor();
}

/// "⇅ 5 → 3": where a moved block or record sat, and sits now. The arrow
/// points along the reading direction, and a screen reader hears "from
/// position 5 to 3".
class DiffMoveHint extends StatelessWidget {
  /// The 0-based positions before and after the move.
  final int from;
  final int to;

  final TextStyle style;

  /// The glyphs' size; the theme's extra-small icon when null.
  final double? iconSize;

  const DiffMoveHint(
    this.from,
    this.to, {
    super.key,
    required this.style,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final formats = context.adminFormats;
    final color = style.color;
    final iconSize = this.iconSize ?? context.iconSizes.xs;
    return Semantics(
      container: true,
      label: context.adminL10n.display.movedFromTo(from + 1, to + 1),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_vert_rounded, size: iconSize, color: color),
          const Gap(AdminSpacing.xxs),
          Text(formats.integer(from + 1), style: style),
          const Gap(AdminSpacing.xxs),
          Icon(Icons.arrow_forward_rounded, size: iconSize, color: color),
          const Gap(AdminSpacing.xxs),
          Text(formats.integer(to + 1), style: style),
        ],
      ),
    );
  }
}
