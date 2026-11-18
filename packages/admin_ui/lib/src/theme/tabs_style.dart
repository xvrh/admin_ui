/// @docImport 'stroke.dart';
/// @docImport 'tokens.dart';
/// @docImport 'typography.dart';
library;

import 'dart:ui' show Color, FontWeight, lerpDouble;

import 'package:flutter/foundation.dart';

import 'palette.dart';
import 'sizes.dart';

/// What the selected tab of a line strip writes its label in; see
/// [AdminTabsStyle.selectedInk].
enum TabsSelectedInk {
  /// [AdminPalette.primaryText]: the kit's own, M3's primary tabs, Ant's.
  accent,

  /// [AdminPalette.foreground], the indicator alone carrying the accent:
  /// shadcn's line tabs, Fluent's, Carbon's.
  foreground,
}

/// What the other tabs write their labels in; see [AdminTabsStyle.restInk].
/// Under the pointer a label takes the next stronger one, and the strongest
/// takes the accent.
enum TabsRestInk {
  /// [AdminPalette.foregroundMuted].
  muted,

  /// [AdminPalette.foregroundSecondary]: M3's on-surface-variant, Fluent's
  /// second neutral, Carbon's `$text-secondary`.
  secondary,

  /// [AdminPalette.foreground]: Ant's `colorText`.
  foreground,
}

/// How wide the selected tab's indicator is; see
/// [AdminTabsStyle.indicatorWidth].
enum TabsIndicatorWidth {
  /// The tab's, edge to edge.
  tab,

  /// The tab's content's, short of its padding on either side: M3's primary
  /// tabs, Ant's ink bar, Fluent's.
  label,
}

/// The ends of the selected tab's indicator; see
/// [AdminTabsStyle.indicatorShape].
enum TabsIndicatorShape {
  /// Square.
  square,

  /// Rounded at the top, flat on the baseline: M3's primary tabs.
  roundedTop,

  /// Rounded at both ends: Fluent's.
  pill,
}

/// The rule a line strip stands on; see [AdminTabsStyle.rule].
enum TabsRule {
  /// A hairline in [AdminPalette.tabDivider].
  hairline,

  /// As thick as the indicator, which lies over it: Carbon's tabs each carry
  /// a 2px `$border-subtle` underline.
  indicator,

  /// None: shadcn's line tabs and Fluent's TabList stand on nothing.
  none,
}

/// The anatomy of a `Tabs` strip: its height at each size, what its labels
/// are written in and how heavily, the selected tab's indicator, and the
/// rule a line strip stands on. Provided via [AdminTokens]; read through
/// `context.tabsStyle`.
///
/// The defaults are the kit's own: 32, 40 and 48 tall, every label at the
/// button weight, the selected one in the accent over a square indicator as
/// wide as its tab, on a hairline.
@immutable
class AdminTabsStyle {
  /// The strip's height at [ControlSize.small].
  final double heightSmall;

  /// The strip's height at [ControlSize.medium].
  final double heightMedium;

  /// The strip's height at [ControlSize.large].
  final double heightLarge;

  /// What a line strip's selected label is written in. An enclosed strip's
  /// is always the foreground: its surface marks it.
  final TabsSelectedInk selectedInk;

  /// What the other labels are written in.
  final TabsRestInk restInk;

  /// The weight of a label; null is the button's, [AdminTypography.button].
  final FontWeight? labelWeight;

  /// The weight of the selected label where it differs: Fluent and Carbon
  /// set the selected tab semibold among regular ones. Null is
  /// [labelWeight]. A tab is as wide as its label at the heavier of the two,
  /// so selecting one never moves the others.
  final FontWeight? selectedLabelWeight;

  /// How wide the indicator is.
  final TabsIndicatorWidth indicatorWidth;

  /// The indicator's ends.
  final TabsIndicatorShape indicatorShape;

  /// The indicator's thickness; null is [AdminStroke.indicator].
  final double? indicatorThickness;

  /// The rule a line strip stands on.
  final TabsRule rule;

  const AdminTabsStyle({
    this.heightSmall = 32,
    this.heightMedium = 40,
    this.heightLarge = 48,
    this.selectedInk = TabsSelectedInk.accent,
    this.restInk = TabsRestInk.muted,
    this.labelWeight,
    this.selectedLabelWeight,
    this.indicatorWidth = TabsIndicatorWidth.tab,
    this.indicatorShape = TabsIndicatorShape.square,
    this.indicatorThickness,
    this.rule = TabsRule.hairline,
  }) : assert(heightSmall > 0 && heightMedium > 0 && heightLarge > 0),
       assert(indicatorThickness == null || indicatorThickness > 0);

  /// The strip's height at [size], before a label's growth at a large text
  /// size.
  double heightOf(ControlSize size) => switch (size) {
    ControlSize.small => heightSmall,
    ControlSize.medium => heightMedium,
    ControlSize.large => heightLarge,
  };

  /// A line strip's selected label in [colors].
  Color selectedInkOf(AdminPalette colors) => switch (selectedInk) {
    TabsSelectedInk.accent => colors.primaryText,
    TabsSelectedInk.foreground => colors.foreground,
  };

  /// An unselected label in [colors]: at rest, or one step stronger when
  /// [hovered].
  Color restInkOf(AdminPalette colors, {bool hovered = false}) =>
      switch (restInk) {
        TabsRestInk.muted =>
          hovered ? colors.foregroundSecondary : colors.foregroundMuted,
        TabsRestInk.secondary =>
          hovered ? colors.foreground : colors.foregroundSecondary,
        TabsRestInk.foreground =>
          hovered ? colors.primaryText : colors.foreground,
      };

  /// A copy with the given members replaced.
  AdminTabsStyle copyWith({
    double? heightSmall,
    double? heightMedium,
    double? heightLarge,
    TabsSelectedInk? selectedInk,
    TabsRestInk? restInk,
    FontWeight? labelWeight,
    FontWeight? selectedLabelWeight,
    TabsIndicatorWidth? indicatorWidth,
    TabsIndicatorShape? indicatorShape,
    double? indicatorThickness,
    TabsRule? rule,
  }) => AdminTabsStyle(
    heightSmall: heightSmall ?? this.heightSmall,
    heightMedium: heightMedium ?? this.heightMedium,
    heightLarge: heightLarge ?? this.heightLarge,
    selectedInk: selectedInk ?? this.selectedInk,
    restInk: restInk ?? this.restInk,
    labelWeight: labelWeight ?? this.labelWeight,
    selectedLabelWeight: selectedLabelWeight ?? this.selectedLabelWeight,
    indicatorWidth: indicatorWidth ?? this.indicatorWidth,
    indicatorShape: indicatorShape ?? this.indicatorShape,
    indicatorThickness: indicatorThickness ?? this.indicatorThickness,
    rule: rule ?? this.rule,
  );

  /// Interpolates the heights, and an [indicatorThickness] both sides
  /// author; the rest comes from the side [t] is nearer.
  static AdminTabsStyle lerp(AdminTabsStyle a, AdminTabsStyle b, double t) {
    if (t == 0) return a;
    if (t == 1) return b;
    final near = t < 0.5 ? a : b;
    return AdminTabsStyle(
      heightSmall: lerpDouble(a.heightSmall, b.heightSmall, t)!,
      heightMedium: lerpDouble(a.heightMedium, b.heightMedium, t)!,
      heightLarge: lerpDouble(a.heightLarge, b.heightLarge, t)!,
      selectedInk: near.selectedInk,
      restInk: near.restInk,
      labelWeight: near.labelWeight,
      selectedLabelWeight: near.selectedLabelWeight,
      indicatorWidth: near.indicatorWidth,
      indicatorShape: near.indicatorShape,
      indicatorThickness:
          a.indicatorThickness != null && b.indicatorThickness != null
          ? lerpDouble(a.indicatorThickness, b.indicatorThickness, t)
          : near.indicatorThickness,
      rule: near.rule,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminTabsStyle &&
      other.heightSmall == heightSmall &&
      other.heightMedium == heightMedium &&
      other.heightLarge == heightLarge &&
      other.selectedInk == selectedInk &&
      other.restInk == restInk &&
      other.labelWeight == labelWeight &&
      other.selectedLabelWeight == selectedLabelWeight &&
      other.indicatorWidth == indicatorWidth &&
      other.indicatorShape == indicatorShape &&
      other.indicatorThickness == indicatorThickness &&
      other.rule == rule;

  @override
  int get hashCode => Object.hash(
    heightSmall,
    heightMedium,
    heightLarge,
    selectedInk,
    restInk,
    labelWeight,
    selectedLabelWeight,
    indicatorWidth,
    indicatorShape,
    indicatorThickness,
    rule,
  );

  @override
  String toString() {
    final weight = labelWeight == null
        ? 'button weight'
        : 'w${labelWeight!.value}';
    final selected = selectedLabelWeight == null
        ? ''
        : '/w${selectedLabelWeight!.value}';
    return 'AdminTabsStyle($heightSmall/$heightMedium/$heightLarge, '
        '${restInk.name} to ${selectedInk.name}, $weight$selected, '
        '${indicatorShape.name} indicator as wide as its ${indicatorWidth.name}'
        '${indicatorThickness == null ? '' : ' $indicatorThickness thick'}, '
        '${rule.name} rule)';
  }
}
