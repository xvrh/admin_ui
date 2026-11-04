/// @docImport '../../common/ui/popover.dart';
library;

import 'package:material_ui/material_ui.dart';

import '../../common/ui/icon_action.dart';
import '../../common/ui/popover_menu.dart';
import '../../common/ui/tappable.dart';
import '../../common/ui/tip.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../diff_model.dart';
import 'diff_op_style.dart';
import 'text_diff.dart';

/// The compact draft-vs-live comparison behind a field's "Edited" marker: one
/// section per changed lane (or per changed record), word-diffed where the
/// value is text. A popover-sized digest of the full diff view — reviewing
/// everything at once stays with the publish sheet.
class FieldQuickDiff extends StatelessWidget {
  final FieldDiff diff;

  /// Lane labels ("EN", "Shared") default to the locale code, and to the
  /// localized "Shared" for the lane that is not per language; override to
  /// humanize.
  final String Function(String locale)? laneLabel;

  /// Rewinds the whole field to its published value. Null hides the action.
  final VoidCallback? onRevert;

  const FieldQuickDiff(this.diff, {super.key, this.laneLabel, this.onRevert});

  String _lane(BuildContext context, String locale) =>
      laneLabel?.call(locale) ??
      (locale.isEmpty ? context.adminL10n.display.sharedLane : locale);

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];
    if (diff.records.isNotEmpty) {
      for (final r in diff.records) {
        if (!r.changed) continue;
        sections.add(_record(context, r));
      }
    } else {
      for (final lane in diff.locales) {
        if (!lane.changed) continue;
        sections.add(_laneSection(context, lane));
      }
    }
    return QuickDiffSurface(
      title: diff.label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const Gap(AdminSpacing.md),
            sections[i],
          ],
          if (onRevert != null) ...[
            const Gap(AdminSpacing.md),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: DiffRestoreButton(
                tooltip: context.adminL10n.restoreLiveVersion,
                onPressed: onRevert!,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _laneSection(BuildContext context, LocaleDiff lane) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LaneChip(_lane(context, lane.locale)),
        const Gap(AdminSpacing.xs),
        if (lane.blocks.isNotEmpty)
          _blocks(context, lane)
        else
          TextDiff(
            before: lane.before ?? '',
            after: lane.after ?? '',
            style: context.type.bodySmall,
            language: lane.locale,
          ),
      ],
    );
  }

  Widget _blocks(BuildContext context, LocaleDiff lane) {
    final changed = [
      for (final b in lane.blocks)
        if (b.op != DiffOp.unchanged) b,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < changed.length; i++) ...[
          if (i > 0) const Gap(AdminSpacing.sm),
          BlockQuickDiff(changed[i], language: lane.locale),
        ],
      ],
    );
  }

  Widget _record(BuildContext context, RecordChange r) {
    final changedFields = [
      for (final f in r.fields)
        if (f.changed) f,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            DiffOpTag(r.op == DiffOp.unchanged ? DiffOp.changed : r.op),
            const Gap(AdminSpacing.sm),
            Flexible(
              child: Text(
                r.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.type.bodyStrong,
              ),
            ),
            if (r.shifted) _moveHint(context, r.fromIndex!, r.toIndex!),
          ],
        ),
        for (final f in changedFields)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AdminSpacing.xl,
              top: AdminSpacing.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.label,
                  style: context.type.weighted(
                    context.type.caption,
                    FontWeight.w600,
                  ),
                ),
                for (final lane in f.locales)
                  if (lane.changed)
                    TextDiff(
                      before: lane.before ?? '',
                      after: lane.after ?? '',
                      style: context.type.bodySmall,
                      language: lane.locale,
                    ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One block's compact draft-vs-live comparison: the op tag plus a word diff
/// (or the non-text summary). Shared by the field popover and the gutter-bar
/// popover; [onRevert] adds the per-block restore action.
class BlockQuickDiff extends StatelessWidget {
  final BlockChange change;
  final VoidCallback? onRevert;

  /// The language the block is written in, such as 'ar' or 'pt-BR': its text
  /// takes that language's direction ([TextDiff.language]). Null or empty
  /// keeps the ambient direction.
  final String? language;

  const BlockQuickDiff(this.change, {super.key, this.onRevert, this.language});

  @override
  Widget build(BuildContext context) {
    final body = change.summary != null
        ? Text(
            change.summary!,
            style: context.type.bodySmall.copyWith(
              color: context.colors.foregroundMuted,
            ),
          )
        : TextDiff(
            before: change.before ?? '',
            after: change.after ?? '',
            style: context.type.bodySmall,
            language: language,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            DiffOpTag(change.op),
            if (change.shifted)
              _moveHint(context, change.fromIndex!, change.toIndex!),
            if (onRevert != null) ...[
              const Spacer(),
              DiffRestoreButton(
                tooltip: context.adminL10n.display.restoreLiveBlock,
                onPressed: onRevert!,
              ),
            ],
          ],
        ),
        const Gap(AdminSpacing.xs),
        body,
      ],
    );
  }
}

/// The popover surface both quick diffs render on: the kit's
/// [PopoverMenuSurface] — its menu radius, shadow and hairline edge — capped
/// in width and height, scrolling past a screenful and, in a [Popover], past
/// the room beside its anchor.
class QuickDiffSurface extends StatelessWidget {
  final String? title;
  final Widget child;

  const QuickDiffSurface({super.key, this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopoverMenuSurface(
      maxWidth: 380,
      maxHeight: 420,
      fitAvailableHeight: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AdminSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title case final title?) ...[
              // The field's label, cased as the field shell sets it.
              Semantics(
                header: true,
                child: Text(
                  context.type.fieldLabelText(title),
                  semanticsLabel: title,
                  style: context.type.fieldLabel.copyWith(
                    color: context.colors.foregroundMuted,
                  ),
                ),
              ),
              const Gap(AdminSpacing.sm),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// A quick diff's [DiffMoveHint], set off from the tag before it.
Widget _moveHint(BuildContext context, int from, int to) => Padding(
  padding: const EdgeInsetsDirectional.only(start: AdminSpacing.sm),
  child: DiffMoveHint(
    from,
    to,
    style: context.type.caption.copyWith(
      color: context.colors.readableOn(context.colors.foregroundMuted),
    ),
  ),
);

class _LaneChip extends StatelessWidget {
  final String label;

  const _LaneChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: context.type
          .weighted(context.type.caption, FontWeight.w700)
          .copyWith(letterSpacing: 0.3),
    );
  }
}

/// The colored one-word op label — Added, Changed, Moved, Removed — in the
/// op's [DiffOpStyle] tone.
class DiffOpTag extends StatelessWidget {
  final DiffOp op;

  const DiffOpTag(this.op, {super.key});

  @override
  Widget build(BuildContext context) {
    final style = DiffOpStyle.of(context, op);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.sm,
        vertical: AdminSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: style.fill,
        borderRadius: BorderRadius.circular(context.radii.radiusSmall),
      ),
      child: Text(
        style.label,
        style: context.type
            .weighted(context.type.micro, FontWeight.w700)
            .copyWith(color: style.text),
      ),
    );
  }
}

/// The diff views' one revert verb: a quiet "Restore", whose [tooltip] names
/// what it rewinds — this field, this item, this block.
class DiffRestoreButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onPressed;

  const DiffRestoreButton({
    super.key,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Readable on a card header's muted fill as well as the page.
    final idle = colors.foregroundMutedOnTint;
    return Tip(
      message: tooltip,
      child: Tappable.states(
        onTap: onPressed,
        focusRadius: context.radii.radiusSmall,
        builder: (context, states) {
          final pressed = states.contains(WidgetState.pressed);
          final active = pressed || states.contains(WidgetState.hovered);
          final color = active ? colors.foregroundSecondary : idle;
          return Container(
            constraints: BoxConstraints(minHeight: IconActionSize.inline.box),
            padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.sm),
            decoration: BoxDecoration(
              color: pressed
                  ? colors.pressedOverlay
                  : (active ? colors.hoverOverlay : null),
              borderRadius: BorderRadius.circular(context.radii.radiusSmall),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.undo_rounded,
                  size: context.iconSizes.sm,
                  color: color,
                ),
                const Gap(AdminSpacing.xs),
                Text(
                  context.adminL10n.display.restore,
                  style: context.type
                      .weighted(context.type.caption, FontWeight.w600)
                      .copyWith(color: color),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
