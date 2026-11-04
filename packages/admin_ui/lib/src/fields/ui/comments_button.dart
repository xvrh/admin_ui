import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../common/text_metrics.dart';
import '../../common/ui/avatar.dart';
import '../../common/ui/button.dart';
import '../../common/ui/icon_action.dart';
import '../../common/ui/input_decoration.dart';
import '../../common/ui/popover.dart';
import '../../common/ui/popover_menu.dart';
import '../../common/ui/tappable.dart';
import '../../common/ui/tip.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/formats.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';

/// One comment in a field's thread. Presentational — the Screen maps the
/// domain `CommentThread`/`Comment` onto this.
class CommentEntry {
  final String author;
  final String initials;
  final Color color;
  final String time;
  final String body;

  const CommentEntry({
    required this.author,
    required this.initials,
    required this.color,
    required this.time,
    required this.body,
  });
}

/// Comments capability: an icon on the field's label row, with the open count
/// beside it, that opens the thread anchored to this field. Self-contained — it signals
/// intent ([onReply]/[onResolve]); the host wires the comments controller.
class CommentsButton extends StatelessWidget {
  final int count;
  final List<CommentEntry> messages;

  /// The anchored snippet this thread is pinned to, if any.
  final String? anchor;

  final VoidCallback? onResolve;
  final ValueChanged<String>? onReply;

  const CommentsButton({
    super.key,
    required this.count,
    this.messages = const [],
    this.anchor,
    this.onResolve,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Popover(
      align: PopoverAlign.end,
      anchor: (context, controller) => _Button(
        count: count,
        on: controller.isOpen,
        onTap: controller.toggle,
      ),
      content: (context, controller) => _Thread(
        messages: messages,
        anchor: anchor,
        onResolve: onResolve,
        onReply: onReply,
      ),
    );
  }
}

/// The label-row anchor: a 24px inline [IconAction], or with open threads
/// the glyph and their count side by side in the same 24px height, so the
/// count never leaves the row.
class _Button extends StatelessWidget {
  final int count;
  final bool on;
  final VoidCallback onTap;

  const _Button({required this.count, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = context.adminL10n.fields.comments(math.max(0, count));
    if (count <= 0) {
      return IconAction(
        Icons.mode_comment_outlined,
        label: label,
        size: IconActionSize.inline,
        selected: on,
        expanded: on,
        onPressed: onTap,
      );
    }
    final colors = context.colors;
    final radius = context.radii.radiusSmall;
    final size = IconActionSize.inline;
    return Tip(
      message: label,
      excludeFromSemantics: true,
      child: Tappable.states(
        onTap: onTap,
        semanticLabel: label,
        excludeSemantics: true,
        expanded: on,
        focusRadius: radius,
        builder: (context, states) {
          final overlay = states.contains(WidgetState.pressed)
              ? colors.pressedOverlay
              : states.contains(WidgetState.hovered)
              ? colors.hoverOverlay
              : null;
          final base = on ? colors.primarySubtle : null;
          return Container(
            height: size.box + textGrowthOf(context, context.type.caption),
            padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.xs),
            decoration: BoxDecoration(
              color: overlay == null
                  ? base
                  : (base == null ? overlay : Color.alphaBlend(overlay, base)),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mode_comment_outlined,
                  size: size.glyph,
                  color: colors.primaryText,
                ),
                const Gap(AdminSpacing.xs),
                Text(
                  _badgeCount(context, count),
                  style: context.type
                      .weighted(context.type.caption, FontWeight.w700)
                      .copyWith(color: colors.primaryText),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// [count] as a badge shows it, in the app's digits: 99+ past 99.
String _badgeCount(BuildContext context, int count) {
  final formats = context.adminFormats;
  return count > 99 ? '${formats.integer(99)}+' : formats.integer(count);
}

class _Thread extends StatefulWidget {
  final List<CommentEntry> messages;
  final String? anchor;
  final VoidCallback? onResolve;
  final ValueChanged<String>? onReply;

  const _Thread({
    required this.messages,
    this.anchor,
    this.onResolve,
    this.onReply,
  });

  @override
  State<_Thread> createState() => _ThreadState();
}

class _ThreadState extends State<_Thread> {
  final _reply = TextEditingController();

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  void _send() {
    var text = _reply.text.trim();
    if (text.isEmpty) return;
    widget.onReply?.call(text);
    _reply.clear();
  }

  @override
  Widget build(BuildContext context) {
    return PopoverMenuSurface(
      width: 320,
      maxHeight: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context),
          if (widget.anchor != null) _anchorQuote(context, widget.anchor!),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(AdminSpacing.lg),
                itemCount: widget.messages.length,
                itemBuilder: (context, i) =>
                    _message(context, widget.messages[i]),
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AdminSpacing.lg),
              ),
            ),
          ),
          _footer(context),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final heading = context.adminL10n.fields.commentsHeading(
      widget.messages.length,
    );
    final onResolve = widget.onResolve;
    return Container(
      // The resolve target's own inset brings its label to the 12px edge.
      padding: EdgeInsetsDirectional.fromSTEB(
        AdminSpacing.lg,
        AdminSpacing.xs,
        onResolve == null
            ? AdminSpacing.lg
            : AdminSpacing.lg - _ResolveAction.inset,
        AdminSpacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.borderSubtle)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: IconActionSize.inline.box),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  context.type.fieldLabelText(heading),
                  semanticsLabel: heading,
                  style: context.type.fieldLabel.copyWith(
                    color: context.colors.foregroundMuted,
                  ),
                ),
              ),
            ),
            if (onResolve != null) _ResolveAction(onPressed: onResolve),
          ],
        ),
      ),
    );
  }

  Widget _anchorQuote(BuildContext context, String anchor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AdminSpacing.lg,
        AdminSpacing.lg,
        AdminSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.md,
        vertical: AdminSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: context.colors.highlight,
        borderRadius: BorderRadius.circular(context.radii.radiusSmall),
      ),
      child: Text(
        context.adminL10n.fields.quoted('…$anchor…'),
        style: context.type.caption.copyWith(
          color: context.colors.readableOn(
            context.colors.foregroundMuted,
            surfaces: [context.colors.highlight],
          ),
        ),
      ),
    );
  }

  Widget _message(BuildContext context, CommentEntry m) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Avatar(
          initials: m.initials,
          color: m.color,
          size: context.iconSizes.xl,
        ),
        const Gap(AdminSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    m.author,
                    style: context.type
                        .weighted(context.type.bodySmall, FontWeight.w700)
                        .copyWith(color: context.colors.foreground),
                  ),
                  const Gap(AdminSpacing.sm),
                  Text(m.time, style: context.type.caption),
                ],
              ),
              const Gap(AdminSpacing.xxs),
              Text(
                m.body,
                style: context.type.body.copyWith(
                  color: context.colors.foregroundSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _footer(BuildContext context) {
    final messages = context.adminL10n.fields;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.lg,
        vertical: AdminSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.colors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _reply,
              style: fieldTextStyle(context),
              onSubmitted: (_) => _send(),
              decoration: fieldInputDecoration(
                context,
                hint: messages.replyPlaceholder,
              ),
            ),
          ),
          const Gap(AdminSpacing.md),
          Button.icon(
            Icons.arrow_upward,
            semanticLabel: messages.sendReply,
            variant: ButtonVariant.primary,
            onPressed: _send,
          ),
        ],
      ),
    );
  }
}

/// The thread's Resolve verb: a quiet success-toned label on a 24px target,
/// with the kit's hover wash and focus ring.
class _ResolveAction extends StatelessWidget {
  final VoidCallback onPressed;

  const _ResolveAction({required this.onPressed});

  /// Between the target's edge and its glyph.
  static const inset = AdminSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = context.radii.radiusSmall;
    return Tappable.states(
      onTap: onPressed,
      focusRadius: radius,
      builder: (context, states) {
        final overlay = states.contains(WidgetState.pressed)
            ? colors.pressedOverlay
            : states.contains(WidgetState.hovered)
            ? colors.hoverOverlay
            : null;
        final ink = colors.readableOn(
          colors.successText,
          surfaces: [
            colors.surface,
            Color.alphaBlend(colors.hoverOverlay, colors.surface),
            Color.alphaBlend(colors.pressedOverlay, colors.surface),
          ],
        );
        return Container(
          constraints: BoxConstraints(minHeight: IconActionSize.inline.box),
          padding: const EdgeInsets.symmetric(horizontal: inset),
          decoration: BoxDecoration(
            color: overlay,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, size: context.iconSizes.sm, color: ink),
              const Gap(AdminSpacing.xs),
              Text(
                context.adminL10n.fields.resolve,
                style: context.type
                    .weighted(context.type.caption, FontWeight.w600)
                    .copyWith(color: ink),
              ),
            ],
          ),
        );
      },
    );
  }
}
