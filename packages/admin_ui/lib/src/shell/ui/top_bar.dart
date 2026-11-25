/// @docImport '../../common/ui/menu.dart';
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

import '../../common/text_metrics.dart';
import '../../common/ui/chrome_theme.dart';
import '../../common/ui/icon_action.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'navigation_drawer.dart';
import 'page_header.dart';
import 'shell.dart';

/// The [Shell]'s top bar: an optional [leading] (e.g. a sidebar toggle) and
/// [title] at the start, an optional [search] slot, and trailing [actions]
/// (buttons, a user [Menu]). A strip of the raised `surface` (above the
/// page in both modes) with a hairline underneath, as tall as the theme's
/// `AdminShellStyle.topBarHeight`. Its content starts at [Shell.inset], over
/// the sidebar's icons, or at the page gutter in a shell without a sidebar,
/// and ends at the page gutter
/// ([PageHeader.gutterOf]), so the last action lines up with the page's.
/// A style whose `topBarSpan` is `TopBarSpan.page` runs the bar over the
/// page alone: its content then starts at the page gutter too, and beside
/// the sidebar its [leading] heads that sidebar instead.
/// A style with a `topBarPalette` draws the bar and everything in it in
/// that palette (Carbon's g100 header): build a [leading] or an action that
/// reads the colours itself with a context below the bar (a [Builder]) for
/// it to read that palette.
///
/// **When room runs out**, as on a phone at a large text size, the bar's
/// parts give way in an order. The [actions] and the menu button keep their
/// size. The search icon comes next: it keeps its place before the actions.
/// The [title] ellipsizes, to nothing if it must. Then [leading] is given
/// only the width that is left, where it had all it asked for: a brand
/// that can shrink (its name in a `Flexible`, ellipsized) folds toward its
/// mark, and one that cannot overflows its own box, not the bar's.
///
/// The [search] slot sits at the end, before the actions, [searchMaxWidth]
/// wide at most and narrower as room runs out. In a bar narrower than the
/// theme's medium breakpoint (`context.breakpoints.medium`), or when the
/// slot would drop under [searchMinWidth], it gives way to a search
/// [IconAction] calling [onSearch] (without [onSearch] the slot is simply
/// left out).
///
/// In a compact [Shell], and between its breakpoints beside a collapsed
/// rail, the bar leads
/// with [menuButton], which opens the shell's navigation drawer, its glyph
/// at [Shell.inset] like the page's title below it ([Shell.hasDrawer]). On a
/// device with insets the bar runs under the status bar and keeps its
/// content below it.
class TopBar extends StatelessWidget {
  /// The logo or sidebar toggle at the start. Drawn in the bar's palette,
  /// which a theme may set apart from the page's: a widget that reads the
  /// colours itself (`context.colors`, `context.type`) must be built below
  /// the bar, in a [Builder], or it keeps the page's. Under a bar that
  /// spans the page alone it heads the sidebar beside the page instead, in
  /// the sidebar's palette, and reads `Sidebar.isCollapsed` to fit the rail
  /// ([Shell]).
  final Widget? leading;
  final String? title;
  final Widget? search;

  /// Opens the search the [search] slot stands for, from the icon that
  /// replaces it in a narrow bar.
  final VoidCallback? onSearch;

  /// The accessible name and tooltip of that icon; Material's search label
  /// when null.
  final String? searchLabel;

  final List<Widget> actions;

  /// Leads the bar while its [Shell] has a drawer ([Shell.hasDrawer]), and
  /// opens it: a [ShellMenuButton] when null. Pass one to key it,
  /// or a trigger of your own calling [Shell.openDrawer], as large as a
  /// medium [IconAction].
  final Widget? menuButton;

  const TopBar({
    super.key,
    this.leading,
    this.title,
    this.search,
    this.onSearch,
    this.searchLabel,
    this.actions = const [],
    this.menuButton,
  });

  /// The bar's height under the default `AdminShellStyle`; a theme sets its
  /// own `topBarHeight`.
  static const height = 56.0;

  /// The room between the menu button and [leading].
  static const menuButtonGap = AdminSpacing.sm;

  /// Where the menu button starts: back from [Shell.inset] by its glyph's
  /// inset in its box, so its glyph, not its box, lines up with the page.
  static double menuButtonStartOf(BuildContext context) =>
      Shell.inset -
      (IconActionSize.medium.boxOf(context) - IconActionSize.medium.glyph) / 2;

  static const searchMinWidth = 160.0;
  static const searchMaxWidth = 280.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.shellStyle.topBarPalette;
    final bar = Builder(builder: _bar);
    return palette == null ? bar : ChromeTheme(palette: palette, child: bar);
  }

  Widget _bar(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final menu = Shell.hasDrawer(context)
        ? menuButton ?? const ShellMenuButton()
        : null;
    final leading = Shell.leadsSidebar(context) ? null : this.leading;
    // Over the page alone, the bar's content lines up with the page's.
    final start = Shell.barStartsAtPage(context)
        ? PageHeader.gutterOf(context)
        : Shell.inset;
    return Container(
      height: context.shellStyle.topBarHeight + top,
      padding: EdgeInsetsDirectional.only(
        // The menu button's glyph, not its box, starts there.
        start: menu == null
            ? start
            : start - (Shell.inset - menuButtonStartOf(context)),
        end: PageHeader.gutterOf(context),
        top: top,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(bottom: BorderSide(color: context.colors.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < context.breakpoints.medium;
          return _BarRow(
            textDirection: Directionality.of(context),
            // What the search icon needs, where the bar has one to show.
            middleMin: search != null && onSearch != null
                ? _Middle.searchIconExtentOf(context)
                : 0,
            menu: menu,
            leading: leading,
            middle: _Middle(
              title: title,
              titleMaxWidth: constraints.maxWidth * 0.4,
              search: search,
              compact: compact,
              onSearch: onSearch,
              searchLabel: searchLabel,
            ),
            actions: actions.isEmpty
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const Gap(AdminSpacing.sm),
                        actions[i],
                      ],
                    ],
                  ),
          );
        },
      ),
    );
  }
}

/// The room between the leading widget and the actions: the [title] at its
/// start, [titleMaxWidth] at most, and the search field (or its icon) at its
/// end, with a gap before the actions. The field takes the room the title
/// leaves, [TopBar.searchMaxWidth] at most, at the theme's control height
/// like the buttons beside it; short of [TopBar.searchMinWidth] it folds to
/// its icon, and the title ellipsises before the icon is squeezed out.
class _Middle extends StatelessWidget {
  final String? title;
  final double titleMaxWidth;
  final Widget? search;
  final bool compact;
  final VoidCallback? onSearch;
  final String? searchLabel;

  const _Middle({
    required this.title,
    required this.titleMaxWidth,
    required this.search,
    required this.compact,
    required this.onSearch,
    required this.searchLabel,
  });

  static const _gap = AdminSpacing.md;

  /// The width the search icon takes with the gap before the actions: the
  /// least the middle is given while the bar has one to show.
  static double searchIconExtentOf(BuildContext context) =>
      IconActionSize.medium.boxOf(context) + _gap;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    final style = context.type.heading;
    final wanted = title == null
        ? 0.0
        : math.min(titleMaxWidth, _measure(context, title, style));
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final search = this.search;
        Widget? slot;
        var slotWidth = 0.0;
        if (search != null) {
          final room = width - wanted - _gap * 2;
          if (!compact && room >= TopBar.searchMinWidth) {
            slotWidth = math.min(room, TopBar.searchMaxWidth);
            slot = SizedBox(
              width: slotWidth,
              // A search field's height, taller by as much as its text
              // grows at a large text size.
              height:
                  context.sizes.medium +
                  textGrowthOf(context, context.type.body),
              child: search,
            );
          } else if (onSearch != null) {
            slotWidth = IconActionSize.medium.boxOf(context);
            slot = IconAction(
              context.icons.search,
              label:
                  searchLabel ??
                  MaterialLocalizations.of(context).searchFieldLabel,
              onPressed: onSearch,
            );
          }
        }
        final titleWidth = math.max(
          0.0,
          math.min(wanted, width - (slot == null ? 0 : slotWidth + _gap * 2)),
        );
        return Row(
          children: [
            if (title != null)
              SizedBox(
                width: titleWidth,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
            const Spacer(),
            if (slot != null) ...[slot, const Gap(_gap)],
          ],
        );
      },
    );
  }

  static double _measure(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width.ceilToDouble();
    painter.dispose();
    return width;
  }
}

enum _BarSlot { menu, leading, middle, actions }

/// The bar's row: the menu button, the leading widget, the middle and the
/// actions, start to end, each centred in the bar's height.
///
/// A `Row` with the middle `Expanded`, but for one rule: where the menu
/// button, the leading widget and the actions leave the middle less than
/// [middleMin], the leading widget is laid out again in the width that
/// leaves it [middleMin]. With room to spare the leading widget is as wide
/// as it asks to be, unbounded as a row's child is, so one that fills the
/// width it is given (a `Row`) keeps its own.
class _BarRow extends SlottedMultiChildRenderObjectWidget<_BarSlot, RenderBox> {
  final Widget? menu;
  final Widget? leading;
  final Widget middle;
  final Widget? actions;
  final double middleMin;
  final TextDirection textDirection;

  const _BarRow({
    required this.menu,
    required this.leading,
    required this.middle,
    required this.actions,
    required this.middleMin,
    required this.textDirection,
  });

  @override
  Iterable<_BarSlot> get slots => _BarSlot.values;

  @override
  Widget? childForSlot(_BarSlot slot) => switch (slot) {
    _BarSlot.menu => menu,
    _BarSlot.leading => leading,
    _BarSlot.middle => middle,
    _BarSlot.actions => actions,
  };

  @override
  _RenderBarRow createRenderObject(BuildContext context) =>
      _RenderBarRow(middleMin: middleMin, textDirection: textDirection);

  @override
  void updateRenderObject(BuildContext context, _RenderBarRow renderObject) {
    renderObject
      ..middleMin = middleMin
      ..textDirection = textDirection;
  }
}

class _RenderBarRow extends RenderBox
    with SlottedContainerRenderObjectMixin<_BarSlot, RenderBox> {
  _RenderBarRow({required this._middleMin, required this._textDirection});

  double get middleMin => _middleMin;
  double _middleMin;
  set middleMin(double value) {
    if (value == _middleMin) return;
    _middleMin = value;
    markNeedsLayout();
  }

  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  /// Start to end: the order they are painted, hit and read in.
  @override
  Iterable<RenderBox> get children => [
    for (final slot in _BarSlot.values) ?childForSlot(slot),
  ];

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() {
    final size = this.size = constraints.biggest;
    // As a row gives its children: any width, the bar's height at most.
    final loose = BoxConstraints(maxHeight: size.height);
    Size layout(RenderBox? child, BoxConstraints constraints) {
      if (child == null) return Size.zero;
      child.layout(constraints, parentUsesSize: true);
      return child.size;
    }

    final menu = childForSlot(_BarSlot.menu);
    final leading = childForSlot(_BarSlot.leading);
    final middle = childForSlot(_BarSlot.middle);
    final actions = childForSlot(_BarSlot.actions);
    final menuGap = menu == null ? 0.0 : TopBar.menuButtonGap;
    final leadingGap = leading == null ? 0.0 : AdminSpacing.md;

    final menuSize = layout(menu, loose);
    final actionsSize = layout(actions, loose);
    final fixed = menuSize.width + menuGap + leadingGap + actionsSize.width;
    var leadingSize = layout(leading, loose);
    final room = math.max(0.0, size.width - fixed - middleMin);
    if (leadingSize.width > room) {
      leadingSize = layout(leading, loose.copyWith(maxWidth: room));
    }
    final middleWidth = math.max(0.0, size.width - fixed - leadingSize.width);
    layout(
      middle,
      BoxConstraints(
        minWidth: middleWidth,
        maxWidth: middleWidth,
        maxHeight: size.height,
      ),
    );

    final rtl = textDirection == TextDirection.rtl;
    var x = 0.0;
    void place(RenderBox? child, double gapAfter) {
      if (child == null) return;
      final box = child.size;
      (child.parentData! as BoxParentData).offset = Offset(
        rtl ? size.width - x - box.width : x,
        (size.height - box.height) / 2,
      );
      x += box.width + gapAfter;
    }

    place(menu, menuGap);
    place(leading, leadingGap);
    place(middle, 0);
    place(actions, 0);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    for (final child in children) {
      context.paintChild(
        child,
        offset + (child.parentData! as BoxParentData).offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final child in children.toList().reversed) {
      final at = (child.parentData! as BoxParentData).offset;
      final hit = result.addWithPaintOffset(
        offset: at,
        position: position,
        hitTest: (result, position) =>
            child.hitTest(result, position: position),
      );
      if (hit) return true;
    }
    return false;
  }
}
