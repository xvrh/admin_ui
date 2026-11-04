import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'icon_action.dart';

/// Which edge a [SideSheet] slides in from, in the reading direction: [end]
/// is the right edge in left-to-right text and the left edge in right-to-left.
enum SideSheetSide { start, end }

/// Slides [builder] in from an edge as a modal panel — scrim, focus trap,
/// Escape / tap-to-dismiss and the return value are handled here. The
/// builder returns the surface too, a [SideSheet]: the host only sizes and
/// places it, and gives it no `Material` or text style of its own. The
/// side-sheet counterpart to `showModal`. Returns whatever the content
/// pops. The scrim is the palette's `scrim` unless [barrierColor]
/// overrides it. The sheet slides over the theme's `motion.slow`, easing in
/// on `motion.enter` and out on `motion.exit`, and appears at once under
/// reduced motion.
Future<T?> showSideSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  SideSheetSide side = SideSheetSide.end,
  double width = 420,
  bool barrierDismissible = true,
  Color? barrierColor,
}) {
  final motion = context.motion;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrierColor ?? context.colors.scrim,
    transitionDuration: motion.slow,
    pageBuilder: (context, _, _) => _SideSheetHost(
      side: side,
      width: width,
      child: Builder(builder: builder),
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: motion.enter,
        reverseCurve: motion.exit,
      );
      final begin = side == SideSheetSide.end
          ? const Offset(1, 0)
          : const Offset(-1, 0);
      return SlideTransition(
        position: Tween(begin: begin, end: Offset.zero).animate(curved),
        textDirection: Directionality.of(context),
        child: child,
      );
    },
  );
}

class _SideSheetHost extends StatelessWidget {
  final SideSheetSide side;
  final double width;
  final Widget child;

  const _SideSheetHost({
    required this.side,
    required this.width,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final capped = math.min(width, MediaQuery.sizeOf(context).width);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      // Takes focus on open so Escape works at once, but is no Tab stop.
      child: Focus(
        autofocus: true,
        skipTraversal: true,
        child: Align(
          alignment: side == SideSheetSide.end
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: SizedBox(width: capped, height: double.infinity, child: child),
        ),
      ),
    );
  }
}

/// The side-sheet surface: a full-height edge panel with an optional [title] +
/// trailing [actions] and a close affordance in a 48px header, a scrolling
/// [child] body, and an optional pinned [footer] (e.g. Cancel / Save). Render
/// it via [showSideSheet]; it's a plain widget so the catalog can show it
/// inline too. Assistive technology announces it as a dialog named by
/// [title], or by [semanticLabel] when it has none.
///
/// It keeps its content out of the device's insets (a notch, the status
/// bar, the home indicator), each part drawing its background under the
/// ones at its edges: the header takes the top inset and the footer the
/// bottom one, the body the edges they leave it, and every part the inset
/// at the sheet's outer edge. With [safeArea] false the body's insets are
/// left to [child], for one that paints its own background under them and
/// keeps its content clear itself, as a `Sidebar` does in its own colour.
class SideSheet extends StatelessWidget {
  final String? title;

  /// Trailing header widgets, shown before the close button.
  final List<Widget> actions;

  final Widget child;

  /// Pinned bottom row, split from the body by a hairline (often an action row).
  final Widget? footer;

  /// Dismiss handler for the × button. Defaults to popping the route, so the
  /// header always shows the button.
  final VoidCallback? onDismiss;

  /// The edge the sheet sits on — its hairline border runs along the other,
  /// inner edge.
  final SideSheetSide side;

  /// Whether the sheet keeps its body out of the device's insets. False
  /// leaves them to [child]; the header and footer keep out of theirs
  /// either way.
  final bool safeArea;

  /// The dialog's name for assistive technology when there is no [title]:
  /// for a sheet whose content heads itself.
  final String? semanticLabel;

  const SideSheet({
    super.key,
    this.title,
    this.actions = const [],
    required this.child,
    this.footer,
    this.onDismiss,
    this.side = SideSheetSide.end,
    this.safeArea = true,
    this.semanticLabel,
  });

  bool get _hasHeader => title != null || actions.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final close = onDismiss ?? () => Navigator.of(context).maybePop();
    final edge = BorderSide(color: context.colors.border);
    final onLeft =
        (side == SideSheetSide.start) ==
        (Directionality.of(context) == TextDirection.ltr);
    const closeSize = IconActionSize.small;
    final label = title ?? semanticLabel;

    /// [child] as a part of the sheet reaching the [top] or [bottom] of the
    /// screen, and its outer edge: kept clear of the insets there when
    /// [pad], and told of none elsewhere, which the other parts take.
    Widget part(
      Widget child, {
      bool top = false,
      bool bottom = false,
      bool pad = true,
    }) => MediaQuery.removePadding(
      context: context,
      removeLeft: !onLeft,
      removeRight: onLeft,
      removeTop: !top,
      removeBottom: !bottom,
      child: pad
          ? SafeArea(
              left: onLeft,
              right: !onLeft,
              top: top,
              bottom: bottom,
              child: child,
            )
          : child,
    );

    return Semantics(
      scopesRoute: true,
      namesRoute: label != null,
      explicitChildNodes: true,
      label: label,
      role: SemanticsRole.dialog,
      child: DecoratedBox(
        decoration: BoxDecoration(boxShadow: context.elevation.lg),
        child: Material(
          color: context.colors.surface,
          // Physical: the edges of [side], resolved against the direction.
          shape: onLeft ? Border(right: edge) : Border(left: edge),
          // Under the content: a child with a background of its own (a
          // sidebar) draws its own edge.
          borderOnForeground: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_hasHeader) ...[
                part(
                  top: true,
                  SizedBox(
                    height: _headerHeight,
                    child: Padding(
                      // The close glyph, not its hit box, lines up with the
                      // body's 16px inset.
                      padding: EdgeInsetsDirectional.only(
                        start: AdminSpacing.xl,
                        end:
                            AdminSpacing.xl -
                            (closeSize.box - closeSize.glyph) / 2,
                      ),
                      child: Row(
                        children: [
                          if (title != null) ...[
                            Expanded(
                              child: Semantics(
                                header: true,
                                child: Text(
                                  title!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.type.heading,
                                ),
                              ),
                            ),
                            // A long title stops short of the controls, as a
                            // Modal's does.
                            const Gap(AdminSpacing.md),
                          ] else
                            const Spacer(),
                          for (final action in actions) ...[
                            action,
                            const Gap(AdminSpacing.sm),
                          ],
                          IconAction.close(size: closeSize, onPressed: close),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  height: context.stroke.hairline,
                  color: context.colors.separator,
                ),
              ],
              Expanded(
                child: part(
                  top: !_hasHeader,
                  bottom: footer == null,
                  pad: safeArea,
                  child,
                ),
              ),
              if (footer != null) ...[
                Container(
                  height: context.stroke.hairline,
                  color: context.colors.separator,
                ),
                part(
                  bottom: true,
                  Padding(
                    padding: const EdgeInsets.all(AdminSpacing.lg),
                    child: footer!,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The header row's height, on the 8px grid.
const _headerHeight = 48.0;
