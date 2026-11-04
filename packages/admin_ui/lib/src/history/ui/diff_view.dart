import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';

import '../../common/text_metrics.dart';
import '../../common/ui/avatar.dart';
import '../../common/ui/button.dart';
import '../../common/ui/empty_state.dart';
import '../../common/ui/panel.dart';
import '../../common/ui/segmented.dart';
import '../../common/ui/tag.dart';
import '../../common/ui/tappable.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../l10n/formats.dart';
import '../../l10n/sections/display_messages.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/theme.dart' show fieldBorderSide;
import '../../theme/tokens.dart';
import '../diff_model.dart';
import 'block_diff.dart';
import 'diff_op_style.dart';
import 'quick_diff.dart';
import 'text_diff.dart';

/// The diff panel: a header naming the two endpoints (+ optional Restore), a
/// controls strip (layout · locales · unchanged), then a field-grouped,
/// locale-aware body — text fields word-diff, rich fields block-diff. Pure View;
/// fills its height and scrolls its body, so it drops into either a full-screen
/// route (beside a [VersionTimeline]) or a side sheet.
///
/// Below [compactWidth] — a side sheet — it tightens to the sheet's 16px
/// inset, the header's Restore becomes an icon button and the controls wrap,
/// so the endpoints keep their room and wrap rather than truncate. A host
/// with no [Material] above it gets the view's own page surface.
class DiffView extends StatefulWidget {
  /// The width below which the view lays out for a side sheet.
  static const compactWidth = 600.0;

  final VersionDiff diff;
  final DiffLayout initialLayout;
  final bool initialShowUnchanged;

  /// When set, a Restore action appears in the header.
  final VoidCallback? onRestore;

  /// The header's Restore label; the localized "Restore this version" when
  /// null.
  final String? restoreLabel;

  /// When set, a per-field (and per-record) Restore action appears on each
  /// changed card, rewinding just that part of the draft to the base version.
  final void Function(RestoreTarget target)? onRestorePart;

  /// Hide the layout / unchanged controls in tight surfaces.
  final bool showControls;

  const DiffView({
    super.key,
    required this.diff,
    this.initialLayout = DiffLayout.unified,
    this.initialShowUnchanged = false,
    this.onRestore,
    this.restoreLabel,
    this.onRestorePart,
    this.showControls = true,
  });

  @override
  State<DiffView> createState() => _DiffViewState();
}

class _DiffViewState extends State<DiffView> {
  late DiffLayout _layout = widget.initialLayout;
  late bool _showUnchanged = widget.initialShowUnchanged;
  late Set<String> _locales = widget.diff.locales.toSet();

  @override
  void didUpdateWidget(DiffView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.diff.locales;
    final after = widget.diff.locales;
    if (listEquals(before, after)) return;
    // Filters the reader chose survive; a locale new to this diff starts
    // shown, and one it no longer has is dropped.
    _locales = {
      for (final code in after)
        if (_locales.contains(code) || !before.contains(code)) code,
    };
    if (_locales.isEmpty) _locales = after.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget view = LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < DiffView.compactWidth;
        final inset = compact ? AdminSpacing.xl : AdminSpacing.xxl;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              diff: widget.diff,
              onRestore: widget.onRestore,
              restoreLabel:
                  widget.restoreLabel ??
                  context.adminL10n.display.restoreThisVersion,
              compact: compact,
              inset: inset,
            ),
            if (widget.showControls) _controls(context, compact, inset),
            Divider(height: 1, thickness: 1, color: colors.borderSubtle),
            Expanded(child: _body(context, inset)),
          ],
        );
      },
    );
    view = DefaultTextStyle.merge(style: context.type.body, child: view);
    if (Material.maybeOf(context) == null) {
      view = Material(color: colors.surface, child: view);
    }
    return view;
  }

  Widget _controls(BuildContext context, bool compact, double inset) {
    final strings = context.adminL10n.display;
    final layout = Segmented<DiffLayout>(
      value: _layout,
      onChanged: (v) => setState(() => _layout = v),
      segments: [
        SegmentOption(
          DiffLayout.unified,
          strings.unified,
          icon: Icons.notes_rounded,
        ),
        SegmentOption(
          DiffLayout.split,
          strings.split,
          icon: Icons.vertical_split_outlined,
        ),
      ],
    );
    final locales = widget.diff.locales.length > 1;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        inset,
        AdminSpacing.lg,
        inset,
        AdminSpacing.lg,
      ),
      child: compact
          ? Wrap(
              spacing: AdminSpacing.sm,
              runSpacing: AdminSpacing.md,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: AdminSpacing.md,
                  ),
                  child: layout,
                ),
                if (locales) ..._localeToggles(),
                _showUnchangedToggle(context),
              ],
            )
          : Row(
              children: [
                layout,
                const Gap(AdminSpacing.xl),
                if (locales)
                  Expanded(
                    child: Wrap(
                      spacing: AdminSpacing.sm,
                      runSpacing: AdminSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: _localeToggles(),
                    ),
                  )
                else
                  const Spacer(),
                _showUnchangedToggle(context),
              ],
            ),
    );
  }

  List<Widget> _localeToggles() => [
    for (final code in widget.diff.locales)
      _Toggle(
        label: code.toUpperCase(),
        active: _locales.contains(code),
        onTap: () => setState(() {
          if (_locales.contains(code) && _locales.length > 1) {
            _locales.remove(code);
          } else {
            _locales.add(code);
          }
        }),
      ),
  ];

  Widget _showUnchangedToggle(BuildContext context) {
    return _Toggle(
      label: context.adminL10n.display.diffUnchanged,
      icon: _showUnchanged
          ? Icons.visibility_outlined
          : Icons.visibility_off_outlined,
      active: _showUnchanged,
      onTap: () => setState(() => _showUnchanged = !_showUnchanged),
    );
  }

  Widget _body(BuildContext context, double inset) {
    final fields = [
      for (final f in widget.diff.fields)
        if (_showUnchanged || f.changed) f,
    ];
    if (fields.isEmpty) {
      final strings = context.adminL10n.display;
      return Center(
        child: EmptyState(
          icon: Icons.check_circle_outline_rounded,
          title: strings.noChanges,
          message: strings.versionsIdentical,
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        inset,
        AdminSpacing.md,
        inset,
        AdminSpacing.xxxl,
      ),
      children: [
        for (final f in fields)
          Padding(
            padding: const EdgeInsets.only(bottom: AdminSpacing.xl),
            child: _FieldDiffCard(
              field: f,
              layout: _layout,
              showUnchanged: _showUnchanged,
              activeLocales: _locales,
              onRestorePart: widget.onRestorePart,
            ),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final VersionDiff diff;
  final VoidCallback? onRestore;
  final String restoreLabel;
  final bool compact;
  final double inset;

  const _Header({
    required this.diff,
    required this.onRestore,
    required this.restoreLabel,
    required this.compact,
    required this.inset,
  });

  @override
  Widget build(BuildContext context) {
    final strings = context.adminL10n.display;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        inset,
        AdminSpacing.xl,
        inset,
        AdminSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _endpoint(context, diff.base, strings.before)),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? AdminSpacing.md : AdminSpacing.lg,
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: context.iconSizes.md,
              color: context.colors.foregroundMuted,
            ),
          ),
          Expanded(child: _endpoint(context, diff.compare, strings.after)),
          if (onRestore != null) ...[
            Gap(compact ? AdminSpacing.md : AdminSpacing.xl),
            if (compact)
              Button.icon(
                Icons.history_rounded,
                semanticLabel: restoreLabel,
                onPressed: onRestore,
              )
            else
              Button(
                restoreLabel,
                icon: Icons.history_rounded,
                onPressed: onRestore,
              ),
          ],
        ],
      ),
    );
  }

  Widget _endpoint(BuildContext context, VersionRef v, String role) {
    // Breaks fall between the author and the time, not inside either.
    String unbroken(String text) => text.replaceAll(' ', '\u00A0');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          role.toUpperCase(),
          style: context.type
              .weighted(context.type.micro, FontWeight.w700)
              .copyWith(letterSpacing: 0.6),
        ),
        const Gap(AdminSpacing.xs),
        Text(v.label, style: context.type.bodyStrong),
        const Gap(AdminSpacing.xs),
        Text.rich(
          TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: AdminSpacing.sm,
                  ),
                  child: Avatar(initials: v.initials, color: v.color, size: 15),
                ),
              ),
              TextSpan(
                text: context.adminL10n.display.authorAndTime(
                  unbroken(v.author),
                  unbroken(v.timestamp),
                ),
              ),
            ],
          ),
          style: context.type.caption,
        ),
      ],
    );
  }
}

class _FieldDiffCard extends StatelessWidget {
  final FieldDiff field;
  final DiffLayout layout;
  final bool showUnchanged;
  final Set<String> activeLocales;
  final void Function(RestoreTarget target)? onRestorePart;

  const _FieldDiffCard({
    required this.field,
    required this.layout,
    required this.showUnchanged,
    required this.activeLocales,
    this.onRestorePart,
  });

  @override
  Widget build(BuildContext context) {
    if (field.kind == DiffFieldKind.recordList) return _recordCard(context);

    final lanes = [
      for (final l in field.locales)
        if ((showUnchanged || l.changed) &&
            (!field.translatable || activeLocales.contains(l.locale)))
          l,
    ];
    if (lanes.isEmpty) return const SizedBox.shrink();

    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context),
          for (var i = 0; i < lanes.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: context.colors.borderSubtle,
              ),
            _lane(context, lanes[i]),
          ],
        ],
      ),
    );
  }

  Widget _recordCard(BuildContext context) {
    final records = [
      for (final r in field.records)
        if (showUnchanged || r.changed) r,
    ];
    if (records.isEmpty) return const SizedBox.shrink();

    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context),
          for (var i = 0; i < records.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: context.colors.borderSubtle,
              ),
            _RecordSection(
              fieldKey: field.fieldKey,
              record: records[i],
              layout: layout,
              showUnchanged: showUnchanged,
              activeLocales: activeLocales,
              onRestorePart: onRestorePart,
            ),
          ],
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AdminSpacing.xl,
        AdminSpacing.lg,
        AdminSpacing.xl,
        AdminSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceMuted,
        border: Border(bottom: BorderSide(color: context.colors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: field.label, style: context.type.sectionLabel),
                  const TextSpan(text: '  '),
                  TextSpan(
                    text: field.fieldKey,
                    style: context.type.micro.copyWith(
                      color: context.colors.foregroundMutedOnTint,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Gap(AdminSpacing.md),
          _CountChips(field: field, activeLocales: activeLocales),
          if (onRestorePart != null && field.changed) ...[
            const Gap(AdminSpacing.md),
            DiffRestoreButton(
              tooltip: context.adminL10n.display.restoreThisField,
              onPressed: () => onRestorePart!(RestoreTarget(field.fieldKey)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _lane(BuildContext context, LocaleDiff lane) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminSpacing.xl,
        AdminSpacing.lg,
        AdminSpacing.xl,
        AdminSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (field.translatable) ...[
            Tag(lane.locale.toUpperCase(), variant: TagVariant.outline),
            const Gap(AdminSpacing.lg),
          ],
          _laneBody(context, lane),
        ],
      ),
    );
  }

  Widget _laneBody(BuildContext context, LocaleDiff lane) {
    if (!lane.changed && !showUnchanged) return const SizedBox.shrink();

    // The value is content in the lane's language; the tag above it and the
    // card's chrome stay in the admin's.
    if (field.kind == DiffFieldKind.richText) {
      return BlockDiff(
        blocks: lane.blocks,
        layout: layout,
        showUnchanged: showUnchanged,
        language: lane.locale,
      );
    }
    return TextDiff(
      before: lane.before ?? '',
      after: lane.after ?? '',
      layout: layout,
      language: lane.locale,
    );
  }
}

/// One record inside a [DiffFieldKind.recordList] field: an op tag + label (+
/// move hint), then the record's changed child fields, rendered recursively.
class _RecordSection extends StatelessWidget {
  final String fieldKey;
  final RecordChange record;
  final DiffLayout layout;
  final bool showUnchanged;
  final Set<String> activeLocales;
  final void Function(RestoreTarget target)? onRestorePart;

  const _RecordSection({
    required this.fieldKey,
    required this.record,
    required this.layout,
    required this.showUnchanged,
    required this.activeLocales,
    this.onRestorePart,
  });

  @override
  Widget build(BuildContext context) {
    final tone = DiffOpStyle.of(context, record.op);
    final children = [
      for (final f in record.fields)
        if (showUnchanged || f.changed) f,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AdminSpacing.xl,
        AdminSpacing.lg,
        AdminSpacing.xl,
        AdminSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Tag(tone.label, severity: tone.severity),
              const Gap(AdminSpacing.md),
              Flexible(
                child: Text(
                  record.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.bodyStrong,
                ),
              ),
              if (record.shifted) ...[
                const Gap(AdminSpacing.md),
                DiffMoveHint(
                  record.fromIndex!,
                  record.toIndex!,
                  style: context.type.micro.copyWith(
                    color: context.colors.foregroundMuted,
                  ),
                ),
              ],
              if (onRestorePart != null) ...[
                const Spacer(),
                DiffRestoreButton(
                  tooltip: context.adminL10n.display.restoreThisItem,
                  onPressed: () => onRestorePart!(
                    RestoreTarget(fieldKey, recordId: record.id),
                  ),
                ),
              ],
            ],
          ),
          if (children.isNotEmpty) const Gap(AdminSpacing.lg),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Gap(AdminSpacing.md),
            _FieldDiffCard(
              field: children[i],
              layout: layout,
              showUnchanged: showUnchanged,
              activeLocales: activeLocales,
            ),
          ],
          if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AdminSpacing.sm),
              child: Text(
                context.adminL10n.display.noFieldChanges,
                style: context.type.bodyMuted,
              ),
            ),
        ],
      ),
    );
  }
}

/// Per-field summary chips: +added −removed ~changed ⇅moved (rich / records), or
/// a single tag for text-like fields. Announced as one line: "1 added, 2
/// changed".
class _CountChips extends StatelessWidget {
  final FieldDiff field;
  final Set<String> activeLocales;

  const _CountChips({required this.field, required this.activeLocales});

  static const _ops = [
    DiffOp.added,
    DiffOp.removed,
    DiffOp.changed,
    DiffOp.moved,
  ];

  @override
  Widget build(BuildContext context) {
    if (field.kind == DiffFieldKind.recordList) {
      final counts = <DiffOp, int>{};
      for (final r in field.records) {
        if (!r.changed) continue;
        counts[r.op] = (counts[r.op] ?? 0) + 1;
      }
      if (counts.isEmpty) return _unchanged(context);
      return _chips(context, counts);
    }

    final lanes = [
      for (final l in field.locales)
        if (l.changed &&
            (!field.translatable || activeLocales.contains(l.locale)))
          l,
    ];
    if (lanes.isEmpty) return _unchanged(context);

    if (field.kind == DiffFieldKind.richText) {
      final counts = <DiffOp, int>{};
      for (final l in lanes) {
        l.blockCounts.forEach((op, n) => counts[op] = (counts[op] ?? 0) + n);
      }
      return _chips(context, counts);
    }

    final tone = DiffOpStyle.of(context, lanes.first.op);
    return Tag(tone.label, severity: tone.severity);
  }

  /// [color] made readable on the card header's `surfaceMuted` fill.
  Color _onHeader(BuildContext context, Color color) =>
      context.colors.readableOn(color, surfaces: [context.colors.surfaceMuted]);

  Widget _unchanged(BuildContext context) => Text(
    context.adminL10n.display.diffUnchanged,
    style: context.type.caption.copyWith(
      color: context.colors.foregroundMutedOnTint,
    ),
  );

  Widget _chips(BuildContext context, Map<DiffOp, int> counts) {
    final muted = context.colors.foregroundMutedOnTint;
    final strings = context.adminL10n.display;
    final summary = strings.joinParts([
      for (final op in _ops)
        if (counts[op] case final n? when n > 0) _count(strings, op, n),
    ]);
    return Semantics(
      container: true,
      label: summary,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final op in _ops) _chip(context, op, counts[op] ?? 0, muted),
        ],
      ),
    );
  }

  static String _count(DisplayMessages strings, DiffOp op, int n) =>
      switch (op) {
        DiffOp.added => strings.addedCount(n),
        DiffOp.removed => strings.removedCount(n),
        DiffOp.moved => strings.movedCount(n),
        DiffOp.changed || DiffOp.unchanged => strings.changedCount(n),
      };

  Widget _chip(BuildContext context, DiffOp op, int n, Color muted) {
    final tone = DiffOpStyle.of(context, op);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AdminSpacing.sm),
      child: Text(
        '${tone.symbol}${context.adminFormats.integer(n)}',
        style: context.type
            .weighted(context.type.caption, FontWeight.w700)
            .copyWith(
              color: n > 0 ? _onHeader(context, tone.text) : muted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
      ),
    );
  }
}

/// A toggle button for the locale filter and the unchanged switch, drawn as
/// a lone segment of the [Segmented] beside it: the medium control height,
/// the field outline and radius, the body label, and the soft primary fill
/// while on. The pointer lays the neutral hover and press overlays over
/// either fill.
class _Toggle extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;

  const _Toggle({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final type = context.type;
    // A toggle button: a button's corner, as the Segmented beside it takes.
    final radius = context.radii.button(ControlSize.medium);
    final height = context.sizes.medium;
    return Tappable.states(
      onTap: onTap,
      selected: active,
      focusRadius: radius,
      builder: (context, states) {
        final pressed = states.contains(WidgetState.pressed);
        final hovered = states.contains(WidgetState.hovered);
        final overlay = pressed
            ? colors.pressedOverlay
            : hovered
            ? colors.hoverOverlay
            : null;
        final base = active ? colors.primarySubtle : colors.surface;
        // Muted text keeps 4.5:1 on the hover and press tints in its on-tint
        // shade, as a segment's does.
        final ink = active
            ? colors.primaryText
            : overlay != null
            ? colors.foregroundMutedOnTint
            : colors.foregroundMuted;
        return Container(
          // Taller by as much as the label grows at a large text size.
          height: height + textGrowthOf(context, type.body),
          padding: EdgeInsets.symmetric(
            horizontal: height / 2 - AdminSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: overlay == null ? base : Color.alphaBlend(overlay, base),
            borderRadius: BorderRadius.circular(radius),
            border: Border.fromBorderSide(
              fieldBorderSide(colors, const {}, stroke: context.stroke),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: context.iconSizes.md, color: ink),
                const Gap(AdminSpacing.sm),
              ],
              // Ellipsized where the toolbar leaves it less than its label.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: type
                      .weighted(type.body, FontWeight.w500)
                      .copyWith(color: ink),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
