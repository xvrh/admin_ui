import 'package:material_ui/material_ui.dart';

import '../../l10n/formats.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';

/// A small count bubble — the notification dot on a bell, an unread tally, a
/// "3 issues" marker. Named to dodge Material's own [Badge].
///
/// Wrap a [child] (an icon) to overlay the bubble on its top-end corner — the
/// bubble's centre sits on the corner, so a wider count grows outward rather
/// than over the icon — or pass no child for a standalone inline bubble. With
/// [dot] it's a bare status dot. A null or zero [count] hides the bubble
/// unless [showZero] is set.
class CountBadge extends StatelessWidget {
  final int? count;

  /// Show a bare dot instead of a number.
  final bool dot;

  /// Counts above this render as `max+` (e.g. `99+`). Digits are the app
  /// locale's (see [AdminFormats.integer]).
  final int max;

  /// Bubble colour. Defaults to the danger red. The count is drawn in white or
  /// near-black, whichever reads better on it.
  final Color? color;

  /// The surface the overlaid bubble sits on: a ring of it around the bubble
  /// cuts it out of the [child]. Defaults to the nearest opaque surface above
  /// it — a [Material], a [ColoredBox] or a filled box decoration, such as a
  /// panel's — else the page colour.
  final Color? ringColor;

  /// Read instead of the bare number (or, for a [dot], instead of nothing) —
  /// e.g. "3 unread notifications".
  final String? semanticLabel;

  /// Overlay the bubble on this widget. Null renders the bubble on its own.
  final Widget? child;

  final bool showZero;

  const CountBadge({
    super.key,
    this.count,
    this.dot = false,
    this.max = 99,
    this.color,
    this.ringColor,
    this.semanticLabel,
    this.child,
    this.showZero = false,
  });

  bool get _visible => dot || (count != null && (count! > 0 || showZero));

  @override
  Widget build(BuildContext context) {
    var bubble = _visible ? _bubble(context) : null;
    if (bubble != null && semanticLabel != null) {
      bubble = Semantics(
        label: semanticLabel,
        excludeSemantics: true,
        child: bubble,
      );
    }

    if (child == null) {
      return bubble ?? const SizedBox.shrink();
    }
    if (bubble == null) return child!;

    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child!,
        PositionedDirectional(
          top: 0,
          end: 0,
          child: FractionalTranslation(
            translation: Offset(rtl ? -0.5 : 0.5, -0.5),
            child: bubble,
          ),
        ),
      ],
    );
  }

  /// The overlaid bubble's cut-out ring, drawn outside its edge so the bubble
  /// keeps its standalone size.
  BoxBorder? _ring(BuildContext context) {
    if (child == null) return null;
    return Border.all(
      color: ringColor ?? _surface(context) ?? context.colors.surface,
      width: 1.5,
      strokeAlign: BorderSide.strokeAlignOutside,
    );
  }

  static Color? _surface(BuildContext context) {
    Color? found;
    context.visitAncestorElements((element) {
      final color = switch (element.widget) {
        Material(:final type, :final color)
            when type != MaterialType.transparency =>
          color,
        ColoredBox(:final color) => color,
        DecoratedBox(
          :final BoxDecoration decoration,
          position: DecorationPosition.background,
        ) =>
          decoration.color,
        _ => null,
      };
      if (color != null && color.a == 1) {
        found = color;
        return false;
      }
      return true;
    });
    return found;
  }

  Widget _bubble(BuildContext context) {
    final bg = color ?? context.colors.danger;
    if (dot) {
      return Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: _ring(context),
        ),
      );
    }

    final formats = context.adminFormats;
    final text = count! > max
        ? '${formats.integer(max)}+'
        : formats.integer(count!);
    // IntrinsicWidth keeps the pill sized to its digits: a Container with
    // `alignment` set otherwise expands to fill bounded width (e.g. as a Wrap or
    // Column child). The label never wraps: some fonts measure a hair wider
    // laid out than their intrinsic width, which would stack the digits.
    return IntrinsicWidth(
      child: Container(
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.xs),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          // All six reference systems draw count badges as full pills,
          // whatever their tag corners.
          // token-literal: a pill in every theme
          borderRadius: BorderRadius.circular(999),
          border: _ring(context),
        ),
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: context.type
              .weighted(context.type.micro, FontWeight.w700)
              .copyWith(color: context.colors.foregroundOn(bg), height: 1.1),
        ),
      ),
    );
  }
}
