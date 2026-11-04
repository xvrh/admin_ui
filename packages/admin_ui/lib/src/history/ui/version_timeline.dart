import 'package:material_ui/material_ui.dart';

import '../../common/ui/avatar.dart';
import '../../common/ui/tag.dart';
import '../../common/ui/tappable.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../diff_model.dart';

/// The version rail: a vertical, newest-first timeline of [versions] with a
/// connecting spine on the start edge. Two endpoints — [baseId] (older) and
/// [compareId] (newer) — are highlighted and the span between them tinted, so
/// the selection reads as "comparing this range". Tapping a row calls [onTap];
/// the host decides which endpoint it sets. A host with no [Material] above it
/// gets the rail's own page surface.
class VersionTimeline extends StatelessWidget {
  /// Newest first.
  final List<VersionRef> versions;
  final String? baseId;
  final String? compareId;
  final ValueChanged<VersionRef>? onTap;

  const VersionTimeline({
    super.key,
    required this.versions,
    this.baseId,
    this.compareId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final compareIdx = versions.indexWhere((v) => v.id == compareId);
    final baseIdx = versions.indexWhere((v) => v.id == baseId);
    final lo = compareIdx < 0 ? -1 : compareIdx;
    final hi = baseIdx < 0 ? -1 : baseIdx;

    Widget rail = ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AdminSpacing.md),
      itemCount: versions.length,
      itemBuilder: (context, i) {
        final v = versions[i];
        final inSpan = lo >= 0 && hi >= 0 && i >= lo && i <= hi;
        return _Row(
          version: v,
          isBase: v.id == baseId,
          isCompare: v.id == compareId,
          inSpan: inSpan,
          first: i == 0,
          last: i == versions.length - 1,
          onTap: onTap == null ? null : () => onTap!(v),
        );
      },
    );
    rail = DefaultTextStyle.merge(style: context.type.body, child: rail);
    if (Material.maybeOf(context) == null) {
      rail = Material(color: context.colors.surface, child: rail);
    }
    return rail;
  }
}

class _Row extends StatelessWidget {
  final VersionRef version;
  final bool isBase;
  final bool isCompare;
  final bool inSpan;
  final bool first;
  final bool last;
  final VoidCallback? onTap;

  const _Row({
    required this.version,
    required this.isBase,
    required this.isCompare,
    required this.inSpan,
    required this.first,
    required this.last,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final endpoint = isBase || isCompare;
    final primary = context.colors.primary;
    final spineColor = inSpan
        // token-literal: the span's spine, softer than its endpoints
        ? primary.withValues(alpha: 0.55)
        : context.colors.borderSubtle;

    return Tappable.builder(
      onTap: onTap,
      disabledCursor: MouseCursor.defer,
      selected: endpoint,
      builder: (context, hover) => Container(
        color: endpoint
            ? primary.withValues(alpha: context.colors.stateLayer.selected)
            : (hover ? context.colors.hoverOverlay : null),
        padding: const EdgeInsets.fromLTRB(
          AdminSpacing.lg,
          0,
          AdminSpacing.lg,
          0,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _spine(context, spineColor, endpoint, primary),
              const Gap(AdminSpacing.lg),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AdminSpacing.lg,
                  ),
                  child: _content(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _spine(
    BuildContext context,
    Color line,
    bool endpoint,
    Color primary,
  ) {
    return SizedBox(
      width: 14,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: 2,
              color: first ? Colors.transparent : line,
            ),
          ),
          Container(
            width: endpoint ? 12 : 9,
            height: endpoint ? 12 : 9,
            decoration: BoxDecoration(
              color: endpoint ? primary : context.colors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: endpoint ? primary : context.colors.foregroundSubtle,
                width: 2,
              ),
            ),
          ),
          Expanded(
            child: Container(width: 2, color: last ? Colors.transparent : line),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context) {
    final v = version;
    final strings = context.adminL10n.display;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                v.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.type.bodyStrong,
              ),
            ),
            // Named as the diff's header names them: the newer endpoint
            // solid, the older one soft.
            if (isCompare)
              Tag(
                strings.after.toUpperCase(),
                color: context.colors.primary,
                variant: TagVariant.solid,
              )
            else if (isBase)
              Tag(
                strings.before.toUpperCase(),
                color: context.colors.primary,
                variant: TagVariant.soft,
              ),
          ],
        ),
        const Gap(AdminSpacing.sm),
        Row(
          children: [
            Avatar(initials: v.initials, color: v.color, size: 16),
            const Gap(AdminSpacing.sm),
            Flexible(
              child: Text(
                strings.authorAndTime(v.author, v.timestamp),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // On an endpoint's tint or a hovered row as well.
                style: context.type.caption.copyWith(
                  color: context.colors.foregroundMutedOnTint,
                ),
              ),
            ),
            const Gap(AdminSpacing.md),
            _statusTag(context, v),
          ],
        ),
      ],
    );
  }

  Widget _statusTag(BuildContext context, VersionRef v) {
    final c = context.colors;
    final l10n = context.adminL10n;
    final strings = l10n.display;
    final (label, color) = switch (v.status) {
      VersionStatus.draft => (l10n.edited, c.warning),
      VersionStatus.current => (strings.versionCurrent, c.primary),
      VersionStatus.published => (strings.versionPublished, c.success),
      VersionStatus.restored => (strings.versionRestored, c.info),
      VersionStatus.archived => (
        v.number == null
            ? strings.versionArchived
            : strings.versionNumber(v.number!),
        c.foregroundMuted,
      ),
    };
    return Tag(label, color: color, variant: TagVariant.soft);
  }
}
