import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'icon_action.dart';
import 'menu.dart';
import 'skeleton.dart';
import 'tappable.dart';
import 'tip.dart';

/// One node in a [Breadcrumbs] trail.
///
/// A null [onTap] renders the crumb as plain text; the last crumb is always the
/// current page and is never a link regardless of [onTap]. [siblings], when
/// present, hang a dropdown off the crumb so the reader can jump laterally to a
/// peer page. [loading] shows a skeleton placeholder while an async label (a
/// record title, a page name) resolves.
class Crumb {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final List<Crumb>? siblings;
  final bool loading;

  const Crumb(
    this.label, {
    this.icon,
    this.onTap,
    this.siblings,
    this.loading = false,
  });
}

/// A breadcrumb navigation trail: a row of crumbs separated by a chevron.
///
/// All crumbs except the last are links (those with an [Crumb.onTap]); the last
/// is the current page, shown emphasised and non-interactive. When the trail
/// grows past [maxItems], or past the width it is given, the middle collapses
/// behind a `…` menu: [itemsBeforeCollapse] head and [itemsAfterCollapse] tail
/// crumbs stay visible, and as the width shrinks further the collapse widens
/// until only the first and the current crumb remain, the current one
/// ellipsising as a last resort. Each label caps at [itemMaxWidth] and
/// ellipsises, with a tooltip for the full text.
///
/// Every crumb carries the same side padding (the hover wash and focus ring
/// around a link), and the trail is drawn that far outside its start edge, so
/// the first label lines up with the content below. The separator flips
/// direction under RTL.
class Breadcrumbs extends StatelessWidget {
  final List<Crumb> items;

  /// Glyph drawn between crumbs. Defaults to a direction-aware chevron.
  final IconData? separator;

  /// Collapse the middle of the trail once the count exceeds this. Null
  /// collapses by width alone.
  final int? maxItems;
  final int itemsBeforeCollapse;
  final int itemsAfterCollapse;

  /// Max width of a single crumb label before it ellipsises.
  final double itemMaxWidth;

  /// The navigation landmark's name, read as a screen reader enters it; the
  /// localized "Breadcrumb" when null.
  final String? semanticLabel;

  const Breadcrumbs(
    this.items, {
    super.key,
    this.separator,
    this.maxItems = 4,
    this.itemsBeforeCollapse = 1,
    this.itemsAfterCollapse = 1,
    this.itemMaxWidth = 200,
    this.semanticLabel,
  });

  /// The one glyph size of the trail: separators, crumb icons, affordances.
  static final _iconSize = IconActionSize.inline.glyph;

  /// Side padding of every crumb, which the hover wash fills.
  static const _padX = AdminSpacing.sm;

  /// Around a separator, so a label sits [_padX] + this from the chevron.
  static const _separatorPad = AdminSpacing.xxs;

  /// Around the `…` action, so its glyph sits as far from the chevrons as a
  /// label does.
  static final _overflowPad =
      _padX - (IconActionSize.inline.box - IconActionSize.inline.glyph) / 2;

  static const _skeletonWidth = 72.0;

  /// The least of the current crumb kept visible before the head crumbs
  /// ellipsise too.
  static const _minCurrentWidth = 48.0;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      explicitChildNodes: true,
      role: SemanticsRole.navigation,
      label: semanticLabel ?? context.adminL10n.display.breadcrumb,
      child: LayoutBuilder(
        builder: (context, constraints) =>
            _trail(context, constraints.maxWidth),
      ),
    );
  }

  Widget _trail(BuildContext context, double maxWidth) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // The chevron mirrors itself right to left, pointing along the trail.
    final sep = separator ?? Icons.chevron_right_rounded;
    final n = items.length;
    final last = n - 1;

    final labels = [
      for (var i = 0; i < n; i++) _labelWidth(context, items[i], i == last),
    ];
    final widths = [for (var i = 0; i < n; i++) _extent(items[i], labels[i])];
    final separatorWidth = _iconSize + _separatorPad * 2;
    final overflowWidth = IconActionSize.inline.box + _overflowPad * 2;

    // [head] crumbs from the start and [tail] from the end stay; the rest
    // go behind the `…`.
    var head = n;
    var tail = 0;
    final maxItems = this.maxItems;
    if (maxItems != null &&
        n > maxItems &&
        itemsBeforeCollapse + itemsAfterCollapse < n) {
      head = itemsBeforeCollapse.clamp(0, n);
      tail = itemsAfterCollapse.clamp(0, n - head);
    }
    double extent() {
      final hidden = n - head - tail;
      var width = 0.0;
      for (var i = 0; i < n; i++) {
        if (i < head || i >= n - tail) width += widths[i];
      }
      final slots = head + tail + (hidden > 0 ? 1 : 0);
      if (hidden > 0) width += overflowWidth;
      return width + separatorWidth * (slots - 1);
    }

    final bounded = maxWidth.isFinite;
    if (bounded && n > 2 && extent() > maxWidth) {
      if (head + tail >= n) {
        head = itemsBeforeCollapse.clamp(0, n - 1);
        tail = n - head;
      }
      while (tail > 1 && extent() > maxWidth) {
        tail--;
      }
      while (head > 1 && extent() > maxWidth) {
        head--;
      }
    }
    final squeezed = bounded && extent() > maxWidth;
    // So narrow that even the head crumbs must give way beside a sliver of
    // the current one.
    final cramped =
        squeezed && extent() - widths[last] + _minCurrentWidth > maxWidth;

    final nodes = <Widget>[];
    void crumb(int i) {
      final current = i == last;
      final flexible = bounded && (current || cramped);
      final node = _CrumbView(
        items[i],
        isCurrent: current,
        maxWidth: itemMaxWidth,
        flexible: flexible,
        tooltip: labels[i] > itemMaxWidth || (flexible && squeezed),
      );
      nodes.add(flexible ? Flexible(child: node) : node);
    }

    for (var i = 0; i < head; i++) {
      crumb(i);
    }
    if (n - head - tail > 0) {
      nodes.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _overflowPad),
          child: _OverflowCrumb(items.sublist(head, n - tail)),
        ),
      );
    }
    for (var i = n - tail; i < n; i++) {
      crumb(i);
    }

    final row = <Widget>[];
    for (var i = 0; i < nodes.length; i++) {
      if (i > 0) row.add(_Separator(sep));
      row.add(nodes[i]);
    }

    return Transform.translate(
      offset: Offset(rtl ? _padX : -_padX, 0),
      child: Row(mainAxisSize: MainAxisSize.min, children: row),
    );
  }

  /// The one-line width of [crumb]'s label in its style.
  double _labelWidth(BuildContext context, Crumb crumb, bool current) {
    if (crumb.loading) return 0;
    final painter = TextPainter(
      text: TextSpan(text: crumb.label, style: _style(context, current)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width.ceilToDouble();
    painter.dispose();
    return width;
  }

  /// The width a crumb takes in the trail: its padding, icon, capped label and
  /// sibling caret.
  double _extent(Crumb crumb, double label) {
    if (crumb.loading) return _skeletonWidth + _padX * 2;
    var width = _padX * 2 + math.min(label, itemMaxWidth);
    if (crumb.icon != null) width += _iconSize + AdminSpacing.xs;
    if (crumb.siblings?.isNotEmpty ?? false) {
      width += IconActionSize.inline.box;
    }
    return width;
  }

  static TextStyle _style(BuildContext context, bool current) =>
      current ? context.type.bodyStrong : context.type.body;
}

class _Separator extends StatelessWidget {
  final IconData icon;
  const _Separator(this.icon);

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Breadcrumbs._separatorPad,
      ),
      child: Icon(
        icon,
        size: Breadcrumbs._iconSize,
        color: context.colors.foregroundFaint,
      ),
    ),
  );
}

/// A single crumb: skeleton, the current page, plain text or a link —
/// optionally paired with a sibling dropdown.
class _CrumbView extends StatelessWidget {
  final Crumb crumb;
  final bool isCurrent;
  final double maxWidth;

  /// Whether the crumb sits in a [Flexible] and its label may shrink below
  /// [maxWidth].
  final bool flexible;

  /// Whether the label is cut short, so a tooltip carries it whole.
  final bool tooltip;

  const _CrumbView(
    this.crumb, {
    required this.isCurrent,
    required this.maxWidth,
    required this.flexible,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    if (crumb.loading) {
      return const _CrumbBox(
        child: Skeleton(width: Breadcrumbs._skeletonWidth, height: 12),
      );
    }

    Widget label;
    if (isCurrent) {
      label = Semantics(
        label: context.adminL10n.display.currentPage(crumb.label),
        excludeSemantics: true,
        child: _CrumbBox(
          child: _content(context, Breadcrumbs._style(context, true)),
        ),
      );
    } else if (crumb.onTap == null) {
      label = _CrumbBox(
        child: _content(
          context,
          context.type.body.copyWith(color: context.colors.foregroundSecondary),
        ),
      );
    } else {
      label = _link(context);
    }
    if (tooltip) {
      label = Tip(
        message: crumb.label,
        excludeFromSemantics: true,
        child: label,
      );
    }

    final siblings = crumb.siblings;
    if (siblings == null || siblings.isEmpty) return label;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (flexible) Flexible(child: label) else label,
        Menu(
          minWidth: 160,
          builder: (context, c) => IconAction(
            Icons.expand_more_rounded,
            label: context.adminL10n.display.switchPage,
            size: IconActionSize.inline,
            expanded: c.isOpen,
            onPressed: c.toggle,
          ),
          entries: [
            for (final s in siblings)
              MenuItem(s.label, icon: s.icon, onSelect: s.onTap),
          ],
        ),
      ],
    );
  }

  Widget _link(BuildContext context) {
    final colors = context.colors;
    final radius = context.radii.radiusSmall;
    final rest = colors.readableOn(colors.foregroundMuted);
    return Tappable.states(
      onTap: crumb.onTap,
      link: true,
      focusRadius: radius,
      builder: (context, states) {
        final pressed = states.contains(WidgetState.pressed);
        final lit =
            pressed ||
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused);
        final wash = pressed
            ? colors.primaryPressedOverlay
            : (lit ? colors.primaryHoverOverlay : null);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: wash,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: _CrumbBox(
            child: _content(
              context,
              context.type.body.copyWith(
                color: lit ? colors.primaryText : rest,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _content(BuildContext context, TextStyle style) {
    final text = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Text(
        crumb.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (crumb.icon != null) ...[
          Icon(crumb.icon, size: Breadcrumbs._iconSize, color: style.color),
          const Gap(AdminSpacing.xs),
        ],
        if (flexible) Flexible(child: text) else text,
      ],
    );
  }
}

/// A crumb's padded box: [Breadcrumbs._padX] each side, and at least a 24px
/// target.
class _CrumbBox extends StatelessWidget {
  final Widget child;

  const _CrumbBox({required this.child});

  static const _minHeight = 24.0;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: _minHeight),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: Breadcrumbs._padX),
      child: Align(
        widthFactor: 1,
        heightFactor: 1,
        alignment: AlignmentDirectional.centerStart,
        child: child,
      ),
    ),
  );
}

/// The collapsed middle of an overflowing trail: a `…` trigger opening a menu of
/// the hidden crumbs.
class _OverflowCrumb extends StatelessWidget {
  final List<Crumb> collapsed;
  const _OverflowCrumb(this.collapsed);

  @override
  Widget build(BuildContext context) {
    return Menu(
      builder: (context, c) => IconAction(
        Icons.more_horiz_rounded,
        label: context.adminL10n.display.showMore(collapsed.length),
        size: IconActionSize.inline,
        expanded: c.isOpen,
        onPressed: c.toggle,
      ),
      entries: [
        for (final crumb in collapsed)
          MenuItem(crumb.label, icon: crumb.icon, onSelect: crumb.onTap),
      ],
    );
  }
}
