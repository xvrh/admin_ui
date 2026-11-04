import 'package:material_ui/material_ui.dart';

import '../../common/text_metrics.dart';
import '../../common/ui/checkbox.dart';
import '../../common/ui/icon_action.dart';
import '../../common/ui/popover.dart';
import '../../common/ui/popover_menu.dart';
import '../../common/ui/tappable.dart';
import '../../common/ui/tip.dart';
import '../../i18n/locale_status.dart';
import '../../l10n/admin_ui_localizations.dart';
import '../../theme/spacing.dart';
import '../../theme/tokens.dart';

/// Language selector: a pill listing the locale(s) in view that opens a picker.
///
/// In the picker, the **checkbox** toggles whether a locale is shown as a lane
/// (check several to edit side by side; the popover stays open). Tapping the
/// **row** switches to that locale alone and closes. The source is offered
/// automatically the first time you go multi — sorted first, still removable.
///
/// Its [value] is the set of locale codes in view, and [onChanged] reports a
/// new set as intent; the host decides what the field renders.
class LanguagePill extends StatelessWidget {
  /// The codes of the locales in view (at least one).
  final Set<String> value;

  /// The code of the locale being edited, marked in the picker.
  final String activeLocale;

  /// Every locale the picker offers.
  final List<LocaleInfo> locales;

  /// The code of the locale the others translate from, listed first.
  final String sourceLocale;

  final ValueChanged<Set<String>> onChanged;

  const LanguagePill({
    super.key,
    required this.value,
    required this.activeLocale,
    required this.locales,
    required this.sourceLocale,
    required this.onChanged,
  });

  /// Visible codes in display order — source first, then declared order.
  List<String> get _orderedCodes => [
    for (var l in locales)
      if (l.code == sourceLocale && value.contains(l.code)) l.code,
    for (var l in locales)
      if (l.code != sourceLocale && value.contains(l.code)) l.code,
  ];

  @override
  Widget build(BuildContext context) {
    return Popover(
      align: PopoverAlign.end,
      anchor: (context, controller) => _Pill(
        codes: _orderedCodes,
        on: controller.isOpen,
        onTap: controller.toggle,
      ),
      content: (context, controller) => _Picker(
        visible: value,
        activeLocale: activeLocale,
        locales: locales,
        sourceLocale: sourceLocale,
        onChanged: onChanged,
        onSwitch: (code) {
          onChanged({code});
          controller.close();
        },
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final List<String> codes;
  final bool on;
  final VoidCallback onTap;

  const _Pill({required this.codes, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = context.radii.radiusSmall;
    return Tappable.states(
      key: const Key('language-pill'),
      onTap: onTap,
      expanded: on,
      semanticLabel: context.adminL10n.fields.languages,
      focusRadius: radius,
      builder: (context, states) {
        final overlay = on
            ? null
            : states.contains(WidgetState.pressed)
            ? colors.pressedOverlay
            : states.contains(WidgetState.hovered)
            ? colors.hoverOverlay
            : null;
        final style = context.type.weighted(
          context.type.micro.copyWith(color: colors.primaryText),
          FontWeight.w600,
        );
        return Container(
          // The label row's inline slot, like every capability beside it,
          // taller by as much as the codes grow at a large text size.
          height: IconActionSize.inline.box + textGrowthOf(context, style),
          padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.md),
          decoration: BoxDecoration(
            color: on
                ? colors.primaryFaint
                : overlay == null
                ? colors.surface
                : Color.alphaBlend(overlay, colors.surface),
            border: Border.all(
              color: on ? colors.primary : colors.border,
              width: context.stroke.control,
            ),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 170),
                child: Text(
                  codes.map((c) => c.toUpperCase()).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
              const Gap(AdminSpacing.xxs),
              Icon(
                Icons.expand_more_rounded,
                size: context.iconSizes.sm,
                color: on
                    ? colors.foregroundMutedOnTint
                    : colors.foregroundMuted,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Picker extends StatefulWidget {
  final Set<String> visible;
  final String activeLocale;
  final List<LocaleInfo> locales;
  final String sourceLocale;
  final ValueChanged<Set<String>> onChanged;
  final ValueChanged<String> onSwitch;

  const _Picker({
    required this.visible,
    required this.activeLocale,
    required this.locales,
    required this.sourceLocale,
    required this.onChanged,
    required this.onSwitch,
  });

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  late final Set<String> _visible = {...widget.visible};

  List<LocaleInfo> get _ordered => [
    for (var l in widget.locales)
      if (l.code == widget.sourceLocale) l,
    for (var l in widget.locales)
      if (l.code != widget.sourceLocale) l,
  ];

  void _toggle(String code) {
    var checked = _visible.contains(code);
    if (checked && _visible.length == 1) return; // keep at least one in view
    setState(() {
      if (checked) {
        _visible.remove(code);
      } else {
        var crossingToMulti = _visible.length == 1;
        _visible.add(code);
        // Going from one locale to several: bring the source in as the
        // reference. It can still be unchecked afterwards.
        if (crossingToMulti) _visible.add(widget.sourceLocale);
      }
    });
    widget.onChanged({..._visible});
  }

  @override
  Widget build(BuildContext context) {
    return PopoverMenuSurface(
      width: 300,
      maxHeight: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var l in _ordered) _row(l),
          Divider(height: 1, color: context.colors.borderSubtle),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AdminSpacing.lg,
              vertical: AdminSpacing.md,
            ),
            child: Text(
              context.adminL10n.fields.languageMenuHint,
              style: context.type.caption.copyWith(
                color: context.colors.foregroundMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// One locale: its compare [Check] on the start, which toggles the lane,
  /// and the rest of the row, which switches to the locale alone. Both are
  /// at least a medium control tall.
  Widget _row(LocaleInfo l) {
    var checked = _visible.contains(l.code);
    var isActive = l.code == widget.activeLocale;
    final colors = context.colors;
    final l10n = context.adminL10n.fields;
    final language = languageNameOf(context, l.code);
    final code = context.type.weighted(
      context.type.micro.copyWith(color: colors.primaryText),
      FontWeight.w600,
    );
    final minHeight = BoxConstraints(minHeight: context.sizes.medium);
    return Container(
      color: isActive ? colors.primaryFaint : null,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Tappable.builder(
              key: ValueKey('lang-check-${l.code}'),
              onTap: () => _toggle(l.code),
              checked: checked,
              semanticLabel: l10n.compareLanguage(language),
              excludeSemantics: true,
              builder: (context, hovered) => Container(
                constraints: minHeight,
                color: hovered ? colors.hoverOverlay : Colors.transparent,
                padding: const EdgeInsetsDirectional.only(
                  start: AdminSpacing.lg,
                  end: AdminSpacing.md,
                ),
                alignment: Alignment.center,
                // The cell takes the tap, hover and focus; the box only shows
                // the state, in its enabled look.
                child: IgnorePointer(
                  child: ExcludeFocus(
                    child: Check(value: checked, onChanged: (_) {}),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Tip(
                message: l10n.switchToLanguage(language),
                child: Tappable.builder(
                  key: ValueKey('lang-switch-${l.code}'),
                  onTap: () => widget.onSwitch(l.code),
                  selected: isActive,
                  builder: (context, hovered) => Container(
                    constraints: minHeight,
                    color: hovered ? colors.hoverOverlay : Colors.transparent,
                    padding: const EdgeInsetsDirectional.only(
                      start: AdminSpacing.xs,
                      end: AdminSpacing.lg,
                    ),
                    child: Row(
                      children: [
                        // A column two letters wide, so the pills line up.
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 28),
                          child: Text(l.code.toUpperCase(), style: code),
                        ),
                        const Gap(AdminSpacing.xxs),
                        LocaleStatusPill(status: l.status),
                        const Gap(AdminSpacing.md),
                        Expanded(
                          child: isActive
                              ? Text(
                                  l10n.editing,
                                  textAlign: TextAlign.end,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: code,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
