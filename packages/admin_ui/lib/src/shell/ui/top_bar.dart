/// @docImport '../../common/ui/menu.dart';
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../common/text_metrics.dart';
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
/// the sidebar's icons, and ends at the page gutter
/// ([PageHeader.gutterOf]), so the last action lines up with the page's.
/// A style with a `topBarPalette` draws the bar and everything in it in
/// that palette (Carbon's g100 header): build a [leading] or an action that
/// reads the colours itself with a context below the bar (a [Builder]) for
/// it to read that palette.
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
  /// the bar, in a [Builder], or it keeps the page's.
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
    return Container(
      height: context.shellStyle.topBarHeight + top,
      padding: EdgeInsetsDirectional.only(
        start: menu == null ? Shell.inset : menuButtonStartOf(context),
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
          return Row(
            children: [
              if (menu != null) ...[menu, const Gap(menuButtonGap)],
              if (leading != null) ...[leading!, const Gap(AdminSpacing.md)],
              Expanded(
                child: _Middle(
                  title: title,
                  titleMaxWidth: constraints.maxWidth * 0.4,
                  search: search,
                  compact: compact,
                  onSearch: onSearch,
                  searchLabel: searchLabel,
                ),
              ),
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const Gap(AdminSpacing.sm),
                actions[i],
              ],
            ],
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
              Icons.search_rounded,
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
