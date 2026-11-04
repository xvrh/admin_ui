import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// The active theme's anatomy tokens, drawn from the tokens alone: a field's
/// box in each state (`resolveFieldChrome` through `fieldDecoration`), a
/// stock `TextField` on the theme's `FieldBorder`, the button and shell
/// geometry, and the palettes the frame draws its sidebar and top bar in.
class AnatomyDemo extends StatelessWidget {
  @Preview(name: 'Anatomy', wrapper: adminUiPreview)
  const AnatomyDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.adminTokens;
    final field = tokens.field;
    final button = tokens.button;
    final shell = tokens.shell;
    final radii = tokens.radii;
    String n(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
    String sizes(double Function(ControlSize) of) =>
        ControlSize.values.map((s) => n(of(s))).join(' / ');
    final heights = tokens.sizes;
    return DemoPage(
      maxWidth: 720,
      children: [
        const DemoSection('Field'),
        _note(
          context,
          '${field.variant.name}, focus by ${field.focusIndicator.name}'
          '${field.accentFocus ? ' in controlAccent' : ' in focusRing'}'
          '${field.accentHover ? ', hover in the eased accent' : ''}; '
          'radiusField ${n(radii.radiusField)}.',
        ),
        Wrap(
          spacing: AdminSpacing.lg,
          runSpacing: AdminSpacing.lg,
          children: [
            for (final (name, states) in _states) _FieldBox(name, states),
          ],
        ),
        const Gap(AdminSpacing.lg),
        DemoVariant(
          'A stock TextField, on the input theme',
          SizedBox(
            width: 280,
            child: TextField(
              style: fieldTextStyle(context),
              decoration: const InputDecoration(hintText: 'Hint'),
            ),
          ),
        ),

        const DemoSection('Button'),
        for (final (label, value) in [
          ('corner (s / m / l)', sizes(radii.button)),
          (
            'padding',
            sizes((s) => button.paddingOf(s, heights.height(s)).start),
          ),
          ('min width', sizes(button.minWidthOf)),
          (
            'label weight',
            '${button.labelWeight ?? tokens.typography.spec.strong}',
          ),
          (
            'content',
            '${button.labelAlignment.name}, icon ${button.iconPlacement.name}',
          ),
          ('disabled', button.disabled.name),
          (
            'variants',
            [
              if (button.filledSecondary) 'filled secondary',
              if (button.strongOutline) 'strong outline',
              if (button.accentGhost) 'accent ghost',
              if (button.accentHover) 'accent hover',
            ].join(', '),
          ),
        ])
          _value(context, label, value),
        const Gap(AdminSpacing.xl),

        const DemoSection('Shell'),
        _value(
          context,
          'sidebar / rail',
          '${n(shell.sidebarWidth)} / ${n(shell.railWidth)}',
        ),
        _value(
          context,
          'item',
          '${n(shell.itemHeight)} tall, ${n(shell.itemGap)} apart, '
              'padding ${n(shell.itemPaddingX)}, corner '
              '${n(shell.itemRadiusOf(radii))}, icon '
              '${n(shell.itemIconSizeOf(tokens.iconSizes))}',
        ),
        _value(
          context,
          'selection mark',
          '${shell.indicatorOf(shell.sidebarPalette ?? tokens.palette, radii).name}'
              ' ${n(shell.indicatorWidth)}',
        ),
        _value(context, 'top bar', n(shell.topBarHeight)),
        const Gap(AdminSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopBarStrip(shell.topBarPalette ?? tokens.palette),
            const Gap(AdminSpacing.lg),
            _SidebarStrip(shell.sidebarPalette ?? tokens.palette),
          ],
        ),
      ],
    );
  }

  static const _states = <(String, Set<WidgetState>)>[
    ('rest', {}),
    ('hovered', {WidgetState.hovered}),
    ('focused', {WidgetState.focused}),
    ('invalid', {WidgetState.error}),
    ('invalid, focused', {WidgetState.error, WidgetState.focused}),
    ('disabled', {WidgetState.disabled}),
  ];

  Widget _note(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: AdminSpacing.md),
    child: Text(text, style: context.type.caption),
  );

  Widget _value(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: AdminSpacing.xs),
    child: Row(
      children: [
        SizedBox(width: 150, child: Text(label, style: context.type.caption)),
        Expanded(child: Text(value, style: context.type.monoSmall)),
      ],
    ),
  );
}

/// One field box in [states], its content kept still as the edges change.
class _FieldBox extends StatelessWidget {
  final String name;
  final Set<WidgetState> states;

  const _FieldBox(this.name, this.states);

  @override
  Widget build(BuildContext context) {
    final tokens = context.adminTokens;
    final radius = BorderRadius.circular(tokens.radii.radiusField);
    final rest = resolveFieldChrome(tokens, const {}).border;
    final edges = resolveFieldChrome(tokens, states).border;
    final pad = EdgeInsets.symmetric(
      horizontal: tokens.sizes.fieldPaddingX,
      vertical: AdminSpacing.xs,
    );
    final disabled = states.contains(WidgetState.disabled);
    return SizedBox(
      width: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: context.type.caption),
          const Gap(AdminSpacing.xs),
          Container(
            // At least the control height; taller with a larger text size.
            constraints: BoxConstraints(minHeight: tokens.sizes.medium),
            padding: pad + rest - edges,
            decoration: fieldDecoration(tokens, states, radius),
            foregroundDecoration: fieldForegroundDecoration(
              tokens,
              states,
              radius,
            ),
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              'Value',
              style: fieldTextStyle(context, enabled: !disabled),
            ),
          ),
        ],
      ),
    );
  }
}

/// A slice of the top bar in [palette]: its surface, the hairline under it,
/// a title and a muted action.
class _TopBarStrip extends StatelessWidget {
  final AdminPalette palette;

  const _TopBarStrip(this.palette);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      constraints: BoxConstraints(minHeight: context.shellStyle.topBarHeight),
      padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.lg),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          Text(
            'Top bar',
            style: context.type.bodyStrong.copyWith(color: palette.foreground),
          ),
          const Spacer(),
          Icon(
            Icons.notifications_none_rounded,
            size: context.iconSizes.lg,
            color: palette.foregroundSecondary,
          ),
        ],
      ),
    );
  }
}

/// A slice of the sidebar in [palette]: a selected item, with the mark
/// `indicatorOf` picks beside its fill, over a resting one, on its rail.
class _SidebarStrip extends StatelessWidget {
  final AdminPalette palette;

  const _SidebarStrip(this.palette);

  @override
  Widget build(BuildContext context) {
    final shell = context.shellStyle;
    final corner = shell.itemRadiusOf(context.radii);
    final glyph = shell.itemIconSizeOf(context.iconSizes);
    final mark = shell.indicatorOf(palette, context.radii);
    Widget item(String label, {required bool selected}) {
      final fg = selected
          ? palette.navSelectedText
          : palette.foregroundSecondary;
      final row = Container(
        constraints: BoxConstraints(minHeight: shell.itemHeight),
        padding: EdgeInsets.symmetric(horizontal: shell.itemPaddingX),
        decoration: BoxDecoration(
          color: selected ? palette.navSelectedFill : null,
          borderRadius: BorderRadius.circular(corner),
        ),
        child: Row(
          children: [
            Icon(Icons.dashboard_outlined, size: glyph, color: fg),
            const Gap(AdminSpacing.md),
            Text(label, style: context.type.body.copyWith(color: fg)),
          ],
        ),
      );
      final edge = mark == NavIndicator.edge;
      return Padding(
        padding: EdgeInsets.only(bottom: shell.itemGap),
        child: !selected || mark == NavIndicator.none
            ? row
            : Stack(
                children: [
                  row,
                  // As the sidebar draws it: a rule down the leading edge,
                  // or a bar as tall as the glyph.
                  PositionedDirectional(
                    start: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: shell.indicatorWidth,
                        height: edge ? shell.itemHeight : glyph,
                        decoration: BoxDecoration(
                          color: palette.navIndicator,
                          borderRadius: edge
                              ? BorderRadiusDirectional.horizontal(
                                  start: Radius.circular(corner),
                                )
                              : BorderRadius.circular(corner),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      );
    }

    return Container(
      width: 200,
      padding: const EdgeInsets.all(AdminSpacing.md),
      color: palette.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          item('Selected', selected: true),
          item('Item', selected: false),
        ],
      ),
    );
  }
}
