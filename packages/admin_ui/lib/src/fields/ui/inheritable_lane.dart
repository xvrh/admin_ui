import 'package:material_ui/material_ui.dart';

import '../../common/text_metrics.dart';
import '../../common/ui/icon_action.dart';
import '../../common/ui/menu.dart';
import '../../common/ui/popover.dart';
import '../../common/ui/tappable.dart';
import '../../common/ui/tip.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';
import '../../theme/typography.dart';

/// The state of one locale lane in a translatable field where inheritance is
/// explicit rather than implied by an absent value.
enum LaneMode {
  /// A live link to the source: reflects it automatically, never goes outdated.
  inherit,

  /// The locale holds its own value.
  custom,
}

/// The per-lane inheritance control: a borderless, text-only select whose label
/// is the current state (`Inherited ▾` / `Custom ▾`) and whose tooltip says
/// what that state does. It opens a [Menu] of the two modes, each with that
/// line under it and the current one checked, with the menu's keyboard model:
/// Enter, Space or ↓ opens it, the arrows move and Escape closes. Sits in the
/// lane strip via `laneTrailing`, beside the comments/history capabilities —
/// aligned with the locale code.
class InheritModeDropdown extends StatelessWidget {
  final LaneMode mode;
  final ValueChanged<LaneMode> onModeChanged;

  /// Source locale name for the menu copy, e.g. 'English'.
  final String sourceLabel;

  /// The thing being translated, woven into the copy: "Set your own
  /// {noun}". Null says "value" in the app's language.
  final String? noun;

  const InheritModeDropdown({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.sourceLabel,
    this.noun,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.adminL10n.fields;
    String title(LaneMode m) => switch (m) {
      LaneMode.inherit => l10n.inherited,
      LaneMode.custom => l10n.custom,
    };
    String description(LaneMode m) => switch (m) {
      LaneMode.inherit => l10n.inheritedDescription(sourceLabel),
      LaneMode.custom => l10n.customDescription(noun),
    };
    return Menu(
      align: PopoverAlign.end,
      entries: [
        for (final choice in LaneMode.values)
          MenuItem(
            title(choice),
            description: description(choice),
            checked: choice == mode,
            onSelect: () {
              if (choice != mode) onModeChanged(choice);
            },
          ),
      ],
      builder: (context, controller) => _Trigger(
        label: title(mode),
        description: description(mode),
        open: controller.isOpen,
        onTap: controller.toggle,
      ),
    );
  }
}

/// The select's face: the current mode in the primary text colour and a
/// caret, on the label row's inline slot with the kit's hover wash and focus
/// ring.
class _Trigger extends StatelessWidget {
  final String label;
  final String description;
  final bool open;
  final VoidCallback onTap;

  const _Trigger({
    required this.label,
    required this.description,
    required this.open,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = context.radii.radiusSmall;
    final style = context.type.weighted(
      context.type.caption.copyWith(color: colors.primaryText),
      FontWeight.w600,
    );
    return Tip(
      message: description,
      child: Tappable.states(
        onTap: onTap,
        semanticLabel: label,
        excludeSemantics: true,
        expanded: open,
        focusRadius: radius,
        builder: (context, states) {
          final overlay = states.contains(WidgetState.pressed)
              ? colors.pressedOverlay
              : states.contains(WidgetState.hovered)
              ? colors.hoverOverlay
              : null;
          final base = open ? colors.primaryFaint : null;
          return Container(
            height: IconActionSize.inline.box + textGrowthOf(context, style),
            padding: const EdgeInsetsDirectional.only(
              start: AdminSpacing.xs,
              end: AdminSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: overlay == null
                  ? base
                  : (base == null ? overlay : Color.alphaBlend(overlay, base)),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: style),
                const Gap(AdminSpacing.xxs),
                Icon(
                  Icons.expand_more_rounded,
                  size: context.iconSizes.sm,
                  color: colors.primaryText,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The body of an inheritable lane: when [inheriting], the source value
/// ([preview]) shown inert and in quiet tones — its text steps down to
/// `foregroundMuted` and its fills sink to `background`, so it recedes yet
/// still reads at 4.5:1 — with the lane's `Inherited` caption saying why;
/// otherwise the editable [custom] body. The treatment lives here so it can't
/// drift between field types.
class InheritedBody extends StatelessWidget {
  final bool inheriting;
  final Widget preview;
  final Widget custom;

  const InheritedBody({
    super.key,
    required this.inheriting,
    required this.preview,
    required this.custom,
  });

  @override
  Widget build(BuildContext context) {
    if (!inheriting) return custom;
    final theme = Theme.of(context);
    final tokens = context.adminTokens;
    final quiet = _quietTokens[tokens] ??= _quiet(tokens);
    return Theme(
      data: theme.copyWith(
        extensions: [
          for (final extension in theme.extensions.values)
            if (extension is! AdminTokens) extension,
          quiet,
        ],
      ),
      child: ExcludeFocus(child: IgnorePointer(child: preview)),
    );
  }
}

final _quietTokens = Expando<AdminTokens>('InheritedBody quiet tokens');

/// [tokens] with the foreground stepped down to `foregroundMuted` and the
/// control fill sunk to `background`, on which `foregroundMuted` still holds
/// 4.5:1.
AdminTokens _quiet(AdminTokens tokens) {
  final p = tokens.palette;
  final palette = p.copyWith(
    foreground: p.foregroundMuted,
    foregroundSecondary: p.foregroundMuted,
    surface: p.background,
    controlBorder: p.border,
  );
  return tokens.copyWith(
    palette: palette,
    typography: AdminTypography.from(palette, tokens.typography.spec),
  );
}
