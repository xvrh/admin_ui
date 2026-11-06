/// @docImport 'button.dart';
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../text_metrics.dart';
import 'tappable.dart';
import 'tip.dart';

/// A standalone page navigator: previous / next arrows around a run of page
/// numbers, with ellipses collapsing the middle on long ranges. Pages are
/// 1-based. A null [onChanged] (or a single page) renders a static control.
///
/// When the page count is unknown — a source that can't count its rows — pass
/// a null [pageCount] and say whether another page follows with [hasNext]:
/// only the arrows show.
///
/// Every page and arrow is a square of the theme's control height at [size],
/// so it lines up with a [Button] or a select of the same size. Every page
/// and arrow is a Tab stop activated with Enter or Space. Pages announce as
/// "Page N", the current one as selected; the arrows by Material's previous
/// and next page tooltips. The arrows point along the reading direction.
///
/// Decoupled from the collection table's own pager — use it for any paged view.
class Pagination extends StatelessWidget {
  final int page;

  /// The number of pages, or null when it is unknown.
  final int? pageCount;
  final ValueChanged<int>? onChanged;

  /// Whether a page follows [page], when [pageCount] is null.
  final bool hasNext;

  /// Page numbers kept on each side of the current page before collapsing to an
  /// ellipsis.
  final int siblings;

  final ControlSize size;

  /// The key of the previous-page arrow, to find it by in a test.
  final Key? previousKey;

  /// The key of the next-page arrow, to find it by in a test.
  final Key? nextKey;

  const Pagination({
    super.key,
    required this.page,
    required this.pageCount,
    this.onChanged,
    this.hasNext = false,
    this.siblings = 1,
    this.size = ControlSize.medium,
    this.previousKey,
    this.nextKey,
  });

  /// The page slots to render; null marks a collapsed (ellipsis) gap.
  static List<int?> pagesFor(int page, int pageCount, {int siblings = 1}) {
    if (pageCount <= 1) return [1];
    // Below the collapse threshold every page fits, so show them all rather
    // than hiding pages behind an ellipsis that saves no space.
    if (pageCount <= 2 * siblings + 5) {
      return [for (var i = 1; i <= pageCount; i++) i];
    }
    final start = math.max(2, page - siblings);
    final end = math.min(pageCount - 1, page + siblings);
    final out = <int?>[1];
    // A gap of exactly one page renders that page instead of an ellipsis.
    if (start > 3) {
      out.add(null);
    } else if (start == 3) {
      out.add(2);
    }
    for (var i = start; i <= end; i++) {
      out.add(i);
    }
    if (end < pageCount - 2) {
      out.add(null);
    } else if (end == pageCount - 2) {
      out.add(pageCount - 1);
    }
    out.add(pageCount);
    return out;
  }

  /// The width a [Pagination] built from these arguments takes under
  /// [context]'s theme — for a host that picks [siblings], or drops the page
  /// numbers, to fit the room it has.
  static double widthOf(
    BuildContext context, {
    required int page,
    required int? pageCount,
    int siblings = 1,
    ControlSize size = ControlSize.medium,
  }) {
    final slot = context.sizes.height(size);
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    var width = 2 * slot + AdminSpacing.xs;
    if (pageCount == null) return width;
    for (final p in pagesFor(page, pageCount, siblings: siblings)) {
      var w = slot;
      if (p != null) {
        final painter = TextPainter(
          text: TextSpan(
            text: '$p',
            style: _numberStyle(context, current: p == page),
          ),
          textDirection: direction,
          textScaler: scaler,
          maxLines: 1,
        )..layout();
        w = math.max(slot, painter.width.ceilToDouble() + 2 * AdminSpacing.sm);
        painter.dispose();
      }
      width += w + AdminSpacing.xs;
    }
    return width;
  }

  void _go(int p) {
    final count = pageCount;
    final inRange = count == null ? (p < page || hasNext) : p <= count;
    if (onChanged != null && p != page && p >= 1 && inRange) {
      onChanged!(p);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = pageCount;
    final slots = count == null
        ? const <int?>[]
        : pagesFor(page, count, siblings: siblings);
    final canNext = count == null ? hasNext : page < count;
    final material = MaterialLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PageButton.arrow(
          key: previousKey,
          icon: Icons.chevron_left_rounded,
          label: material.previousPageTooltip,
          size: size,
          onTap: onChanged != null && page > 1 ? () => _go(page - 1) : null,
        ),
        const Gap(AdminSpacing.xs),
        for (final slot in slots) ...[
          if (slot == null)
            _Ellipsis(size: size)
          else
            _PageButton.number(
              number: slot,
              current: slot == page,
              size: size,
              onTap: onChanged == null ? null : () => _go(slot),
            ),
          const Gap(AdminSpacing.xs),
        ],
        _PageButton.arrow(
          key: nextKey,
          icon: Icons.chevron_right_rounded,
          label: material.nextPageTooltip,
          size: size,
          onTap: onChanged != null && canNext ? () => _go(page + 1) : null,
        ),
      ],
    );
  }
}

TextStyle _numberStyle(BuildContext context, {required bool current}) => context
    .type
    .weighted(context.type.body, current ? FontWeight.w600 : FontWeight.w500)
    .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

/// One page or arrow: a square of the control height at its size (a page
/// number grows sideways past two digits), with the hover and press fills
/// of an icon action and the primary fill on the current page.
class _PageButton extends StatelessWidget {
  final int? number;
  final bool current;
  final IconData? icon;

  /// An arrow's name; a page announces its number.
  final String? label;
  final ControlSize size;

  /// Null in a static control, or on an arrow with nowhere to go. The
  /// current page keeps its tap target — a no-op — so it stays a Tab stop
  /// that announces as selected.
  final VoidCallback? onTap;

  const _PageButton.number({
    required int this.number,
    required this.current,
    required this.size,
    required this.onTap,
  }) : icon = null,
       label = null;

  const _PageButton.arrow({
    super.key,
    required IconData this.icon,
    required String this.label,
    required this.size,
    required this.onTap,
  }) : number = null,
       current = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = context.radii.radiusSmall;
    final slot = context.sizes.height(size);
    final glyph = size == ControlSize.small ? 16.0 : 18.0;
    final label = this.label ?? context.adminL10n.display.pageNumber(number!);

    Widget button = Tappable.states(
      onTap: onTap,
      semanticLabel: label,
      excludeSemantics: true,
      selected: number == null ? null : current,
      focusRadius: radius,
      builder: (context, states) {
        final enabled = !states.contains(WidgetState.disabled);
        final pressed = enabled && states.contains(WidgetState.pressed);
        final hovered = enabled && states.contains(WidgetState.hovered);
        final Color? fill = current
            ? colors.primary
            : pressed
            ? colors.pressedOverlay
            : hovered
            ? colors.hoverOverlay
            : null;
        final Widget content;
        if (number case final n?) {
          content = Text(
            '$n',
            maxLines: 1,
            style: _numberStyle(context, current: current).copyWith(
              color: current ? colors.onPrimary : colors.foregroundSecondary,
            ),
          );
        } else {
          content = Icon(
            icon,
            size: glyph,
            color: !enabled
                ? colors.foregroundSubtle
                : (hovered || pressed)
                ? colors.foregroundSecondary
                : colors.foregroundMuted,
          );
        }
        return Container(
          constraints: BoxConstraints(minWidth: slot),
          // Taller by as much as the numbers grow at a large text size.
          height:
              slot +
              textGrowthOf(context, _numberStyle(context, current: false)),
          alignment: Alignment.center,
          padding: number == null
              ? null
              : const EdgeInsets.symmetric(horizontal: AdminSpacing.sm),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: content,
        );
      },
    );
    if (number == null) {
      button = Tip(message: label, excludeFromSemantics: true, child: button);
    }
    return button;
  }
}

/// A collapsed run of pages: a horizontal ellipsis glyph centred in a page
/// slot, so it sits on the digits' centre line rather than their baseline.
class _Ellipsis extends StatelessWidget {
  final ControlSize size;
  const _Ellipsis({required this.size});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: context.sizes.height(size),
        child: Center(
          child: Icon(
            Icons.more_horiz,
            size: context.iconSizes.md,
            color: context.colors.foregroundMuted,
          ),
        ),
      ),
    );
  }
}
