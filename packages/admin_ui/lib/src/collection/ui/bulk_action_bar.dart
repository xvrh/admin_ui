import 'package:material_ui/material_ui.dart';

import '../../common/ui/button.dart';
import '../../common/ui/icon_action.dart';
import '../../common/ui/menu.dart';
import '../../common/ui/menu_button.dart';
import '../../common/ui/tappable.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/sizes.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import 'collection_toolbar.dart';

/// One action in a [BulkActionBar]. [primary]/[danger] pick the button weight;
/// a null [onPressed] disables it.
class BulkAction {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool primary;
  final bool danger;

  const BulkAction(
    this.label, {
    this.icon,
    this.onPressed,
    this.primary = false,
    this.danger = false,
  });
}

/// The selection toolbar: the tinted bar that takes the toolbar's place once
/// rows are selected. Shows the count, a clear (×), an optional
/// select-all-across-pages link, and the [actions] on the right.
///
/// It is [CollectionToolbar.heightOf] tall — a one-line toolbar's height — so
/// swapping one for the other moves nothing, and holds the same medium
/// controls. When the row is too narrow for everything, the actions and the
/// select-all link fold into a "More actions" menu, Clear shrinks to its ×,
/// and the count ellipsizes.
///
/// The count reads "3 selected" in the app's language, with no noun, which
/// only the Screen knows: give one through [selectedLabel] and
/// [allSelectedLabel], each a whole message with its own plural forms.
///
/// Pure View — the Screen swaps it in for [CollectionToolbar] when the selection
/// is non-empty (`selection.isEmpty ? toolbar : bulkBar`, or a
/// `CollectionHeader`) and supplies the callbacks. Cross-page selection is
/// app-driven: pass [onSelectAllMatching] (with [matchingTotal]) to offer it,
/// and flip [allMatchingSelected] once the Screen has switched to whole-query
/// mode.
class BulkActionBar extends StatelessWidget {
  final int count;
  final List<BulkAction> actions;
  final VoidCallback onClear;

  /// Overrides the "{count} selected" label, as in "3 products selected".
  /// In whole-query mode, unless [allSelectedLabel] is set, it is given
  /// [matchingTotal] and read as all of them: "All 137 products selected".
  final String Function(int count)? selectedLabel;

  /// Overrides the whole-query label, "All {total} selected", as in "All
  /// 137 products selected".
  final String Function(int total)? allSelectedLabel;

  /// Total rows matching the active query — shown in the select-all link / mode.
  final int? matchingTotal;

  /// True once the whole query is selected (not just the page).
  final bool allMatchingSelected;

  /// Offers "Select all {matchingTotal}" when non-null and not already in
  /// whole-query mode. The Screen wires it to its own bulk-by-query path.
  final VoidCallback? onSelectAllMatching;

  const BulkActionBar({
    super.key,
    required this.count,
    required this.actions,
    required this.onClear,
    this.selectedLabel,
    this.allSelectedLabel,
    this.matchingTotal,
    this.allMatchingSelected = false,
    this.onSelectAllMatching,
  });

  static const _padX = AdminSpacing.md;

  bool get _wholeQuery => allMatchingSelected && matchingTotal != null;

  /// "{count} selected", or in whole-query mode "All {total} selected".
  String _label(BuildContext context) {
    final strings = context.adminL10n;
    if (!_wholeQuery) {
      return selectedLabel?.call(count) ?? strings.selectedCount(count);
    }
    final total = matchingTotal!;
    if (allSelectedLabel case final label?) return label(total);
    if (selectedLabel case final label?) {
      return strings.collection.allOf(total, label(total));
    }
    return strings.collection.allSelected(total);
  }

  String? _selectAllLabel(BuildContext context) {
    if (_wholeQuery || onSelectAllMatching == null) return null;
    final total = matchingTotal;
    return total == null
        ? MaterialLocalizations.of(context).selectAllButtonLabel
        : context.adminL10n.collection.selectAllCount(total);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: CollectionToolbar.heightOf(context),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: _padX),
      decoration: BoxDecoration(
        color: colors.primarySubtle,
        borderRadius: BorderRadius.circular(context.radii.radius),
        // token-literal: the bar's edge, a primary line softer than a selection
        border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) =>
            constraints.maxWidth >= _fullWidth(context)
            ? _full(context)
            : _compact(context),
      ),
    );
  }

  Widget _full(BuildContext context) {
    final selectAll = _selectAllLabel(context);
    return Row(
      children: [
        Button.ghost(
          context.adminL10n.collection.clear,
          icon: Icons.close,
          size: ControlSize.medium,
          onPressed: onClear,
        ),
        const Gap(AdminSpacing.sm),
        Expanded(
          child: Row(
            children: [
              Flexible(child: _count(context)),
              if (selectAll != null) ...[
                const Gap(AdminSpacing.md),
                _Link(label: selectAll, onTap: onSelectAllMatching!),
              ],
            ],
          ),
        ),
        const Gap(AdminSpacing.md),
        for (final (i, a) in actions.indexed) ...[
          if (i > 0) const Gap(AdminSpacing.sm),
          _actionButton(a),
        ],
      ],
    );
  }

  Widget _compact(BuildContext context) {
    final selectAll = _selectAllLabel(context);
    final strings = context.adminL10n;
    final entries = [
      if (selectAll != null)
        MenuItem(
          selectAll,
          icon: Icons.select_all_rounded,
          onSelect: onSelectAllMatching,
        ),
      if (selectAll != null && actions.isNotEmpty) const MenuDivider(),
      for (final a in actions)
        MenuItem(
          a.label,
          icon: a.icon,
          danger: a.danger,
          onSelect: a.onPressed,
        ),
    ];
    return Row(
      children: [
        IconAction(
          Icons.close,
          label: strings.clearSelection,
          size: IconActionSize.medium,
          onPressed: onClear,
        ),
        const Gap(AdminSpacing.sm),
        Expanded(child: _count(context)),
        if (entries.isNotEmpty) ...[
          const Gap(AdminSpacing.sm),
          MenuButton(
            icon: Icons.more_horiz,
            tooltip: strings.moreActions,
            size: IconActionSize.medium,
            entries: entries,
          ),
        ],
      ],
    );
  }

  Widget _count(BuildContext context) => Text(
    _label(context),
    maxLines: 1,
    softWrap: false,
    overflow: TextOverflow.ellipsis,
    style: context.type.bodyStrong,
  );

  /// The width the full row needs inside the bar's padding: every control at
  /// its natural size, with at least the gap before the actions. A medium [Button] is its label and
  /// optional icon between paddings of half its height less 4.
  double _fullWidth(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    double text(String s, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: s, style: style),
        textDirection: direction,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final width = painter.width.ceilToDouble();
      painter.dispose();
      return width;
    }

    final type = context.type;
    final buttonText = type.button;
    final padX = context.sizes.medium / 2 - 4;
    double button(String label, {required bool icon}) =>
        2 * padX + (icon ? 16 + AdminSpacing.md : 0) + text(label, buttonText);

    final selectAll = _selectAllLabel(context);
    var width =
        button(context.adminL10n.collection.clear, icon: true) +
        AdminSpacing.sm +
        text(_label(context), type.bodyStrong);
    if (selectAll != null) {
      width +=
          AdminSpacing.md +
          text(selectAll, type.weighted(type.body, FontWeight.w600));
    }
    width += AdminSpacing.md;
    for (final (i, a) in actions.indexed) {
      if (i > 0) width += AdminSpacing.sm;
      width += button(a.label, icon: a.icon != null);
    }
    return width;
  }

  Widget _actionButton(BulkAction a) {
    if (a.danger) {
      return Button.danger(
        a.label,
        icon: a.icon,
        size: ControlSize.medium,
        onPressed: a.onPressed,
      );
    }
    if (a.primary) {
      return Button.primary(
        a.label,
        icon: a.icon,
        size: ControlSize.medium,
        onPressed: a.onPressed,
      );
    }
    return Button(
      a.label,
      icon: a.icon,
      size: ControlSize.medium,
      onPressed: a.onPressed,
    );
  }
}

class _Link extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Link({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = colors.readableOn(
      colors.primaryText,
      surfaces: [colors.primarySubtle],
    );
    return Tappable.builder(
      onTap: onTap,
      focusRadius: context.radii.radiusSmall,
      // At least a 24px target, however short the line.
      builder: (context, hover) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 24),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Text(
            label,
            maxLines: 1,
            style: context.type
                .weighted(context.type.body, FontWeight.w600)
                .copyWith(
                  color: color,
                  decoration: hover ? TextDecoration.underline : null,
                  decorationColor: color,
                ),
          ),
        ),
      ),
    );
  }
}
