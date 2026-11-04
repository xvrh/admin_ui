import 'package:material_ui/material_ui.dart';

import '../../common/text_metrics.dart';
import '../../common/ui/avatar.dart';
import '../../common/ui/icon_action.dart';
import '../../common/ui/popover.dart';
import '../../common/ui/popover_menu.dart';
import '../../common/ui/tappable.dart';
import '../../common/ui/tip.dart';
import '../../history/ui/quick_diff.dart' show DiffRestoreButton;
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';

/// One point in a field's version history (presentational; the host maps its
/// own history onto it).
class FieldVersion {
  final String label;
  final String author;
  final String initials;
  final Color color;
  final String time;
  final bool current;

  const FieldVersion({
    required this.label,
    required this.author,
    required this.initials,
    required this.color,
    required this.time,
    this.current = false,
  });
}

/// History / draft capability for one field+locale. Quiet when the draft matches
/// the [baseline]; stands out as "Edited" when it differs, opening a popup that
/// compares the draft with the baseline, reverts, and lists past versions.
class HistoryButton extends StatelessWidget {
  final String draft;

  /// The value the draft is compared with, such as the last saved or released
  /// one; null when there is none.
  final String? baseline;

  /// The baseline's label beside the draft in the popup; null reads the kit's
  /// default for the app's language.
  final String? baselineLabel;

  final List<FieldVersion> versions;
  final VoidCallback? onRevert;

  const HistoryButton({
    super.key,
    required this.draft,
    this.baseline,
    this.baselineLabel,
    this.versions = const [],
    this.onRevert,
  });

  /// The draft differs from the [baseline] — the button shows "Edited", so a
  /// [FieldShell] drops its own marker.
  bool get modified => baseline != null && draft != baseline;

  @override
  Widget build(BuildContext context) {
    return Popover(
      align: PopoverAlign.end,
      anchor: (context, controller) => _Anchor(
        modified: modified,
        on: controller.isOpen,
        onTap: controller.toggle,
      ),
      content: (context, controller) => _Panel(
        draft: draft,
        baseline: baseline,
        baselineLabel: baselineLabel,
        versions: versions,
        modified: modified,
        onRevert: onRevert == null
            ? null
            : () {
                onRevert!();
                controller.close();
              },
      ),
    );
  }
}

class _Anchor extends StatelessWidget {
  final bool modified;
  final bool on;
  final VoidCallback onTap;

  const _Anchor({
    required this.modified,
    required this.on,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = context.adminL10n.fields.versionHistory;
    if (!modified) {
      return IconAction(
        Icons.history,
        label: label,
        size: IconActionSize.inline,
        selected: on,
        expanded: on,
        onPressed: onTap,
      );
    }

    var colors = context.colors;
    var radius = context.radii.radiusSmall;
    // token-literal: the modified tint
    var tint = colors.warning.withValues(alpha: 0.14);
    return Tip(
      message: label,
      excludeFromSemantics: true,
      child: Tappable.states(
        onTap: onTap,
        semanticLabel: label,
        expanded: on,
        focusRadius: radius,
        builder: (context, states) {
          var overlay = states.contains(WidgetState.pressed)
              ? colors.pressedOverlay
              : states.contains(WidgetState.hovered)
              ? colors.hoverOverlay
              : null;
          return Container(
            height:
                IconActionSize.inline.box +
                textGrowthOf(context, context.type.caption),
            padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.md),
            decoration: BoxDecoration(
              color: overlay == null ? tint : Color.alphaBlend(overlay, tint),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: colors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const Gap(AdminSpacing.sm),
                Text(
                  context.adminL10n.edited,
                  style: context.type
                      .weighted(context.type.caption, FontWeight.w600)
                      .copyWith(color: colors.warningText),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String draft;
  final String? baseline;
  final String? baselineLabel;
  final List<FieldVersion> versions;
  final bool modified;
  final VoidCallback? onRevert;

  const _Panel({
    required this.draft,
    required this.baseline,
    required this.baselineLabel,
    required this.versions,
    required this.modified,
    required this.onRevert,
  });

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
          if (modified) _compare(context),
          Padding(
            padding: const EdgeInsets.all(AdminSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, v) in versions.indexed) ...[
                  if (i > 0) const Gap(AdminSpacing.lg),
                  _version(context, v),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final heading = context.adminL10n.fields.versionHistory;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.lg,
        vertical: AdminSpacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.borderSubtle)),
      ),
      // Cased like a field label, and as tall as the comments thread's
      // heading row, so the two capability popovers match.
      child: Container(
        constraints: const BoxConstraints(minHeight: 24),
        alignment: AlignmentDirectional.centerStart,
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
    );
  }

  Widget _compare(BuildContext context) {
    final l10n = context.adminL10n;
    final colors = context.colors;
    // token-literal: the modified tint, fainter under text
    final tint = colors.warning.withValues(alpha: 0.08);
    // Secondary text sits on the warning tint, not the popover's surface.
    final muted = colors.readableOn(
      colors.foregroundMuted,
      surfaces: [Color.alphaBlend(tint, colors.surface)],
    );
    final border = context.stroke.hairline;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AdminSpacing.lg,
        AdminSpacing.lg,
        AdminSpacing.lg,
        0,
      ),
      // Content 12 in from the box's edge, border included.
      padding: EdgeInsets.all(AdminSpacing.lg - border),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(context.radii.radius),
        border: Border.all(
          // token-literal: the modified card's edge
          color: colors.warning.withValues(alpha: 0.25),
          width: border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.type.fieldLabelText(l10n.fields.pendingEdit),
            semanticsLabel: l10n.fields.pendingEdit,
            style: context.type.fieldLabel.copyWith(color: colors.warningText),
          ),
          const Gap(AdminSpacing.md),
          _diffLine(
            context,
            baselineLabel ?? l10n.fields.baseline,
            baseline ?? '',
            muted,
            muted: muted,
            strike: true,
          ),
          const Gap(AdminSpacing.xs),
          _diffLine(
            context,
            l10n.edited,
            draft,
            colors.foreground,
            muted: muted,
          ),
          if (onRevert case final onRevert?) ...[
            const Gap(AdminSpacing.md),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: DiffRestoreButton(
                tooltip: l10n.restoreLiveVersion,
                onPressed: onRevert,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _diffLine(
    BuildContext context,
    String label,
    String value,
    Color color, {
    required Color muted,
    bool strike = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: context.type
                .weighted(context.type.caption, FontWeight.w600)
                .copyWith(color: muted),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: context.type.bodySmall.copyWith(
              color: color,
              decoration: strike ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _version(BuildContext context, FieldVersion v) {
    final title = context.type.bodyStrong;
    final line = title.fontSize! * (title.height ?? 1);
    const dot = 8.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Centred on the title's first line.
        Padding(
          padding: EdgeInsets.only(top: (line - dot) / 2),
          child: Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              color: v.current
                  ? context.colors.primary
                  : context.colors.foregroundSubtle,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const Gap(AdminSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                v.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: title,
              ),
              const Gap(AdminSpacing.xxs),
              Row(
                children: [
                  Avatar(
                    initials: v.initials,
                    color: v.color,
                    size: context.iconSizes.lg,
                  ),
                  const Gap(AdminSpacing.sm),
                  Flexible(
                    child: Text(
                      '${v.author} · ${v.time}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.type.caption,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
