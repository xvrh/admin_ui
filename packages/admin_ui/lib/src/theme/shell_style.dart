/// @docImport '../shell/ui/shell.dart';
library;

import 'dart:ui' show Color, lerpDouble;

import 'package:flutter/foundation.dart';

import 'palette.dart';
import 'radii.dart';
import 'sizes.dart';

/// How the sidebar marks its selected item beside the selection fill; see
/// [AdminShellStyle.indicator].
enum NavIndicator {
  /// No mark: the fill alone carries the selection (M3's stadium pill,
  /// Ant's selected item).
  none,

  /// A short bar at the item's leading edge, as tall as its glyph: Fluent's
  /// nav.
  bar,

  /// A rule down the item's whole leading edge: Carbon's side nav.
  edge,
}

/// What the [Shell]'s top bar runs across; see [AdminShellStyle.topBarSpan].
enum TopBarSpan {
  /// The whole window, over the sidebar, its leading (the logo) above the
  /// sidebar's icons: Carbon's UI shell, Ant's mixed layout.
  window,

  /// The page alone. The sidebar runs the window's height, and its head, as
  /// tall as the bar, holds the bar's leading (the logo), the rail's too:
  /// Ant's side layout.
  page,
}

/// The geometry of the app frame: the sidebar's widths, its items and their
/// selection mark, the top bar's height and what it spans, and optional
/// palettes that draw the sidebar or the top bar in another scheme than the
/// page (Carbon's g100 header, Ant's dark sider). Provided via
/// [AdminTokens]; read through `context.shellStyle`.
///
/// The defaults are the kit's own frame: a 240px sidebar that collapses to a
/// 64px rail, 36px items 4px apart, and a 56px top bar.
@immutable
class AdminShellStyle {
  /// The expanded sidebar.
  final double sidebarWidth;

  /// The collapsed sidebar, icons only.
  final double railWidth;

  /// A nav item's height, before it grows with the platform's text size.
  final double itemHeight;

  /// Between two nav items.
  final double itemGap;

  /// A nav item's inline padding, inside its hover and selection fill.
  final double itemPaddingX;

  /// Between the sidebar's edges and a nav item's fill; null leaves what
  /// [itemPaddingX] leaves of the shell's inset, so an item's glyph lines up
  /// under the top bar's leading slot. Either way the sidebar keeps room for
  /// a focus ring drawn outside the item.
  final double? itemMarginX;

  /// A nav item's corner; null takes `AdminRadii.radiusSmall`. 999 draws a
  /// stadium. See [itemRadiusOf].
  final double? itemRadius;

  /// A nav item's glyph; null takes `AdminIconSizes.md`. See
  /// [itemIconSizeOf].
  final double? itemIconSize;

  /// The selected item's mark; null picks it from the palette and the
  /// corner, as the kit always has. See [indicatorOf].
  final NavIndicator? indicator;

  /// The [NavIndicator.bar] or [NavIndicator.edge] mark's width.
  final double indicatorWidth;

  /// The top bar.
  final double topBarHeight;

  /// Whether the top bar runs across the window, over the sidebar, or across
  /// the page alone, beside a sidebar as tall as the window.
  final TopBarSpan topBarSpan;

  /// The palette the sidebar draws with, in place of the page's: its rail,
  /// items, selection and labels. Null draws it in the page's palette.
  final AdminPalette? sidebarPalette;

  /// The palette the top bar draws with, in place of the page's. Null draws
  /// it in the page's palette.
  final AdminPalette? topBarPalette;

  const AdminShellStyle({
    this.sidebarWidth = 240,
    this.railWidth = 64,
    this.itemHeight = 36,
    this.itemGap = 4,
    this.itemPaddingX = 8,
    this.itemMarginX,
    this.itemRadius,
    this.itemIconSize,
    this.indicator,
    this.indicatorWidth = 3,
    this.topBarHeight = 56,
    this.topBarSpan = TopBarSpan.window,
    this.sidebarPalette,
    this.topBarPalette,
  });

  /// A nav item's corner: [itemRadius], or [radii]'s `radiusSmall`.
  double itemRadiusOf(AdminRadii radii) => itemRadius ?? radii.radiusSmall;

  /// A nav item's glyph: [itemIconSize], or [icons]' `md`.
  double itemIconSizeOf(AdminIconSizes icons) => itemIconSize ?? icons.md;

  /// The selected item's mark, drawn in [palette] (the one the sidebar draws
  /// with) at the corner [radii] give an item: [indicator] when set;
  /// otherwise none where the palette's `navIndicator` is transparent, a
  /// rule down the edge where the item is square, and a bar beside the glyph
  /// where it is rounded.
  NavIndicator indicatorOf(AdminPalette palette, AdminRadii radii) =>
      indicator ??
      (palette.navIndicator.a == 0
          ? NavIndicator.none
          : itemRadiusOf(radii) == 0
          ? NavIndicator.edge
          : NavIndicator.bar);

  /// This style with [sidebarPalette] and [topBarPalette] rebranded with
  /// [seed] (see [AdminPalette.branded]), so the chrome follows a client's
  /// accent with the page.
  AdminShellStyle branded(Color seed) {
    if (sidebarPalette == null && topBarPalette == null) return this;
    return AdminShellStyle(
      sidebarWidth: sidebarWidth,
      railWidth: railWidth,
      itemHeight: itemHeight,
      itemGap: itemGap,
      itemPaddingX: itemPaddingX,
      itemMarginX: itemMarginX,
      itemRadius: itemRadius,
      itemIconSize: itemIconSize,
      indicator: indicator,
      indicatorWidth: indicatorWidth,
      topBarHeight: topBarHeight,
      topBarSpan: topBarSpan,
      sidebarPalette: sidebarPalette?.branded(seed),
      topBarPalette: topBarPalette?.branded(seed),
    );
  }

  /// A copy with the given members replaced. A null argument keeps the
  /// current value, so the nullable members cannot be cleared here; build a
  /// new style for that.
  AdminShellStyle copyWith({
    double? sidebarWidth,
    double? railWidth,
    double? itemHeight,
    double? itemGap,
    double? itemPaddingX,
    double? itemMarginX,
    double? itemRadius,
    double? itemIconSize,
    NavIndicator? indicator,
    double? indicatorWidth,
    double? topBarHeight,
    TopBarSpan? topBarSpan,
    AdminPalette? sidebarPalette,
    AdminPalette? topBarPalette,
  }) => AdminShellStyle(
    sidebarWidth: sidebarWidth ?? this.sidebarWidth,
    railWidth: railWidth ?? this.railWidth,
    itemHeight: itemHeight ?? this.itemHeight,
    itemGap: itemGap ?? this.itemGap,
    itemPaddingX: itemPaddingX ?? this.itemPaddingX,
    itemMarginX: itemMarginX ?? this.itemMarginX,
    itemRadius: itemRadius ?? this.itemRadius,
    itemIconSize: itemIconSize ?? this.itemIconSize,
    indicator: indicator ?? this.indicator,
    indicatorWidth: indicatorWidth ?? this.indicatorWidth,
    topBarHeight: topBarHeight ?? this.topBarHeight,
    topBarSpan: topBarSpan ?? this.topBarSpan,
    sidebarPalette: sidebarPalette ?? this.sidebarPalette,
    topBarPalette: topBarPalette ?? this.topBarPalette,
  );

  /// Interpolates the lengths; a nullable one set on one side only, the
  /// [indicator], the [topBarSpan] and the palettes come from the side [t]
  /// is nearer.
  static AdminShellStyle lerp(AdminShellStyle a, AdminShellStyle b, double t) {
    final near = t < 0.5 ? a : b;
    double d(double x, double y) => lerpDouble(x, y, t)!;
    double? o(double? x, double? y) =>
        x != null && y != null ? d(x, y) : (t < 0.5 ? x : y);
    return AdminShellStyle(
      sidebarWidth: d(a.sidebarWidth, b.sidebarWidth),
      railWidth: d(a.railWidth, b.railWidth),
      itemHeight: d(a.itemHeight, b.itemHeight),
      itemGap: d(a.itemGap, b.itemGap),
      itemPaddingX: d(a.itemPaddingX, b.itemPaddingX),
      itemMarginX: o(a.itemMarginX, b.itemMarginX),
      itemRadius: o(a.itemRadius, b.itemRadius),
      itemIconSize: o(a.itemIconSize, b.itemIconSize),
      indicator: near.indicator,
      indicatorWidth: d(a.indicatorWidth, b.indicatorWidth),
      topBarHeight: d(a.topBarHeight, b.topBarHeight),
      topBarSpan: near.topBarSpan,
      sidebarPalette: near.sidebarPalette,
      topBarPalette: near.topBarPalette,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminShellStyle &&
      other.sidebarWidth == sidebarWidth &&
      other.railWidth == railWidth &&
      other.itemHeight == itemHeight &&
      other.itemGap == itemGap &&
      other.itemPaddingX == itemPaddingX &&
      other.itemMarginX == itemMarginX &&
      other.itemRadius == itemRadius &&
      other.itemIconSize == itemIconSize &&
      other.indicator == indicator &&
      other.indicatorWidth == indicatorWidth &&
      other.topBarHeight == topBarHeight &&
      other.topBarSpan == topBarSpan &&
      other.sidebarPalette == sidebarPalette &&
      other.topBarPalette == topBarPalette;

  @override
  int get hashCode => Object.hash(
    sidebarWidth,
    railWidth,
    itemHeight,
    itemGap,
    itemPaddingX,
    itemMarginX,
    itemRadius,
    itemIconSize,
    indicator,
    indicatorWidth,
    topBarHeight,
    topBarSpan,
    sidebarPalette,
    topBarPalette,
  );

  @override
  String toString() =>
      'AdminShellStyle(sidebar $sidebarWidth / rail $railWidth, items '
      '$itemHeight + $itemGap, padding $itemPaddingX, margin '
      '${itemMarginX ?? 'auto'}, radius '
      '${itemRadius ?? 'radiusSmall'}, icon ${itemIconSize ?? 'md'}, '
      'indicator ${indicator?.name ?? 'auto'} $indicatorWidth, top bar '
      '$topBarHeight across the ${topBarSpan.name}'
      '${sidebarPalette == null ? '' : ', own sidebar palette'}'
      '${topBarPalette == null ? '' : ', own top bar palette'})';
}
