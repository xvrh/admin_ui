/// @docImport 'toast.dart';
library;

import 'package:material_ui/material_ui.dart';

import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'alert.dart';
import 'icon_action.dart';
import 'severity.dart';
import 'tappable.dart';
import 'text_link.dart';

/// A full-bleed notice bar — pinned across the top of an app frame or page to
/// carry a standing message (scheduled maintenance, a trial ending, an
/// environment warning). Unlike an [Alert] it spans the full width with no
/// rounded card; unlike a [Toast] it persists until dismissed.
///
/// The tone drives the tint and icon via [Severity]; an inline bold [title]
/// precedes the [message], with an optional trailing [action] and a dismiss
/// affordance via [onDismiss]. The text wraps, and the icon, the action and
/// the close stay on its first line, as an [Alert]'s do, so a one-line bar
/// is as tall with them as without. [maxLines] clips a long message behind a
/// "Show more" toggle.
///
/// Being a widget, it takes its action as a widget, as an [Alert] does; a
/// [Toast], which is data handed to a scope, takes an action label and
/// callback instead.
class AnnouncementBar extends StatefulWidget {
  final Severity severity;
  final String message;
  final String? title;
  final Widget? action;
  final VoidCallback? onDismiss;

  /// Overrides the severity's default leading glyph.
  final IconData? icon;

  /// Whether the leading glyph shows; false starts the text at the padding.
  final bool showIcon;

  /// Caps the content width and centres it — for wide app frames where a
  /// full-bleed run of text would be hard to read.
  final double? maxContentWidth;

  /// Clips the text to this many lines, ending in an ellipsis. While it runs
  /// longer, a "Show more" toggle after it shows the rest (and "Show less"
  /// clips it again). Null, the default, shows all of it.
  final int? maxLines;

  const AnnouncementBar(
    this.message, {
    super.key,
    this.severity = Severity.info,
    this.title,
    this.action,
    this.onDismiss,
    this.icon,
    this.showIcon = true,
    this.maxContentWidth,
    this.maxLines,
  }) : assert(maxLines == null || maxLines > 0);

  @override
  State<AnnouncementBar> createState() => _AnnouncementBarState();
}

class _AnnouncementBarState extends State<AnnouncementBar> {
  bool _expanded = false;

  /// Whether the layout shows the toggle, which only then takes focus.
  bool _moreShown = false;

  @override
  Widget build(BuildContext context) {
    final style = severityStyleOf(context, widget.severity);
    const close = IconActionSize.inline;
    final title = widget.title;
    final action = widget.action;
    final onDismiss = widget.onDismiss;
    final maxLines = widget.maxLines;
    final collapsed = maxLines != null && !_expanded;
    final l10n = context.adminL10n.inputs;

    final text = TextSpan(
      children: [
        if (title != null)
          TextSpan(text: '$title  ', style: context.type.bodyStrong),
        TextSpan(
          text: widget.message,
          style: context.type.body.copyWith(
            color: context.colors.foregroundSecondary,
          ),
        ),
      ],
    );

    Widget content = firstLineRow(
      firstLine: firstLineHeight(context, text),
      textDirection: Directionality.of(context),
      trailingGap: action != null ? AdminSpacing.lg : AdminSpacing.sm,
      icon: widget.showIcon
          ? Icon(
              widget.icon ?? style.icon,
              size: context.iconSizes.lg,
              color: style.foreground,
            )
          : null,
      body: Text.rich(
        text,
        maxLines: collapsed ? maxLines : null,
        overflow: collapsed ? TextOverflow.ellipsis : null,
      ),
      more: maxLines == null
          ? null
          : ExcludeFocus(
              excluding: !_moreShown,
              child: _MoreToggle(
                label: _expanded ? l10n.showLess : l10n.showMore,
                expanded: _expanded,
                color: style.foreground,
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
            ),
      overflows: maxLines == null
          ? null
          : (width) => _overflows(context, text, maxLines, width),
      onMoreShown: (shown) {
        if (mounted) setState(() => _moreShown = shown);
      },
      trailing: action == null && onDismiss == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ?action,
                if (action != null && onDismiss != null)
                  const Gap(AdminSpacing.sm),
                if (onDismiss != null)
                  IconAction.close(
                    size: close,
                    label: MaterialLocalizations.of(context)
                        .modalBarrierDismissLabel,
                    onPressed: onDismiss,
                  ),
              ],
            ),
    );

    if (widget.maxContentWidth != null) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.maxContentWidth!),
          child: content,
        ),
      );
    }

    return Material(
      color: style.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: style.border)),
        ),
        // The close glyph, not its hit box, keeps the 16px inset.
        padding: EdgeInsetsDirectional.only(
          start: AdminSpacing.xl,
          end: onDismiss == null
              ? AdminSpacing.xl
              : AdminSpacing.xl - (close.box - close.glyph) / 2,
        ),
        child: content,
      ),
    );
  }
}

/// The "Show more" toggle after a clipped message: a [TextLink]'s label in
/// the severity's text colour, which reads on the bar's tint where the
/// primary one may not, in a target at least 24px tall centred on it.
class _MoreToggle extends StatelessWidget {
  final String label;
  final bool expanded;
  final Color color;
  final VoidCallback onPressed;

  const _MoreToggle({
    required this.label,
    required this.expanded,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tappable.states(
      onTap: onPressed,
      semanticLabel: label,
      excludeSemantics: true,
      expanded: expanded,
      focusRadius: context.radii.radiusSmall,
      builder: (context, states) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 24),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          heightFactor: 1,
          child: Text(
            label,
            style: TextLink.styleOf(context, states, color: color),
          ),
        ),
      ),
    );
  }
}

/// Whether [text], laid out as the bar's [Text] under [context] at [width],
/// runs past [maxLines].
bool _overflows(
  BuildContext context,
  InlineSpan text,
  int maxLines,
  double width,
) {
  final inherited = DefaultTextStyle.of(context);
  final painter = TextPainter(
    text: TextSpan(style: inherited.style, children: [text]),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    textHeightBehavior:
        inherited.textHeightBehavior ??
        DefaultTextHeightBehavior.maybeOf(context),
    maxLines: maxLines,
  )..layout(maxWidth: width);
  final overflows = painter.didExceedMaxLines;
  painter.dispose();
  return overflows;
}
