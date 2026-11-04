/// @docImport 'avatar.dart';
/// @docImport 'tag.dart';
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../text_metrics.dart';

/// One event in a [Timeline]. Supply a plain [title] or a [titleWidget] (for a
/// rich "**Maya** published the page" line). The node is an [icon] in an accent
/// ring, or a [leading] widget (an avatar) that replaces it; with neither it's a
/// small dot.
class TimelineEntry {
  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final String? timestamp;
  final IconData? icon;

  /// Node accent: its tint, ring and dot. The icon takes it as far as it needs
  /// to read on the tint. Defaults to the primary colour.
  final Color? color;

  /// Replaces the icon node entirely (e.g. an [Avatar]). Sized to ~28px.
  final Widget? leading;

  /// Trailing slot on the title row — a [Tag], a menu button, a timestamp.
  final Widget? trailing;

  const TimelineEntry({
    this.title,
    this.titleWidget,
    this.subtitle,
    this.timestamp,
    this.icon,
    this.color,
    this.leading,
    this.trailing,
  }) : assert(
         title != null || titleWidget != null,
         'Provide title or titleWidget',
       );
}

/// A vertical activity feed: [entries] on a connecting rail, newest-first by
/// convention (the caller orders them) — for audit logs, comment threads,
/// status changes.
class Timeline extends StatelessWidget {
  final List<TimelineEntry> entries;

  const Timeline({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < entries.length; i++)
          _Entry(
            entry: entries[i],
            first: i == 0,
            last: i == entries.length - 1,
          ),
      ],
    );
  }
}

const _nodeSize = 28.0;

/// The dot of a node with neither an icon nor a [TimelineEntry.leading]:
/// even, so it centres on whole pixels in the node.
const _dotSize = 8.0;

/// How strongly an entry's accent tints its node's fill, and its ring.
const _tintAlpha = 0.12;
const _ringAlpha = 0.45;

/// The rail's width: even, like [_nodeSize], so it centres under the node
/// on whole pixels.
const _railWidth = 2.0;

/// The rail's run of line above a node.
const _railLead = AdminSpacing.xxs;

class _Entry extends StatelessWidget {
  final TimelineEntry entry;
  final bool first;
  final bool last;

  const _Entry({required this.entry, required this.first, required this.last});

  @override
  Widget build(BuildContext context) {
    // The node and the title's first line share a centre: whichever is
    // shorter is pushed down by half the difference.
    final line = lineHeightOf(context, context.type.body);
    final nodeTop = _railLead + math.max(0.0, (line - _nodeSize) / 2);
    final titleTop = _railLead + math.max(0.0, (_nodeSize - line) / 2);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _rail(context, nodeTop),
          const Gap(AdminSpacing.lg),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: titleTop,
                bottom: last ? 0 : AdminSpacing.xl,
              ),
              child: _content(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rail(BuildContext context, double nodeTop) {
    final line = context.colors.borderSubtle;
    return SizedBox(
      width: _nodeSize,
      child: Column(
        children: [
          SizedBox(
            height: nodeTop,
            child: first ? null : Container(width: _railWidth, color: line),
          ),
          _node(context),
          Expanded(
            child: Container(
              width: _railWidth,
              color: last ? Colors.transparent : line,
            ),
          ),
        ],
      ),
    );
  }

  Widget _node(BuildContext context) {
    if (entry.leading != null) {
      return SizedBox(
        width: _nodeSize,
        height: _nodeSize,
        child: Center(child: entry.leading),
      );
    }
    final colors = context.colors;
    final accent = entry.color ?? colors.primary;
    final tint = accent.withValues(alpha: _tintAlpha);
    // The glyph keeps 3:1 on the tinted node whichever surface it sits on.
    final glyph = colors.readableOn(
      accent,
      surfaces: [
        Color.alphaBlend(tint, colors.surface),
        Color.alphaBlend(tint, colors.background),
      ],
      minContrast: 3,
    );
    return Container(
      width: _nodeSize,
      height: _nodeSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint,
        shape: BoxShape.circle,
        border: Border.all(
          color: accent.withValues(alpha: _ringAlpha),
          width: context.stroke.hairline,
        ),
      ),
      child: entry.icon != null
          ? Icon(entry.icon, size: context.iconSizes.sm, color: glyph)
          : Container(
              width: _dotSize,
              height: _dotSize,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
    );
  }

  Widget _content(BuildContext context) {
    final title = DefaultTextStyle.merge(
      style: context.type.body.copyWith(color: context.colors.foreground),
      child: entry.titleWidget ?? Text(entry.title!),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            if (entry.trailing != null) ...[
              const Gap(AdminSpacing.md),
              entry.trailing!,
            ],
          ],
        ),
        if (entry.subtitle != null) ...[
          const Gap(AdminSpacing.xs),
          Text(
            entry.subtitle!,
            style: context.type.caption.copyWith(
              color: context.colors.foregroundMuted,
            ),
          ),
        ],
        if (entry.timestamp != null) ...[
          const Gap(AdminSpacing.xs),
          Text(
            entry.timestamp!,
            style: context.type.micro.copyWith(
              color: context.colors.foregroundMuted,
            ),
          ),
        ],
      ],
    );
  }
}
