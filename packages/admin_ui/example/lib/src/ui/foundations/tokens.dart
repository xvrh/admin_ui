import 'dart:math' as math;

import 'package:admin_ui/admin_ui.dart';
import 'package:flutter/widget_previews.dart';
import 'package:material_ui/material_ui.dart';

import '../../preview_shell.dart';
import '../demo_kit.dart';

/// Visual reference for the theme tokens — the spacing rhythm, type ramp,
/// motion, stroke widths, icon sizes, every palette role with its live
/// contrast, elevation, the focus ring and radii that every component is
/// built from.
class TokensDemo extends StatelessWidget {
  @Preview(name: 'Tokens', wrapper: adminUiPreview)
  const TokensDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DemoPage(
      maxWidth: 720,
      children: [
        const DemoSection('Spacing'),
        for (final (name, value) in _spacing)
          Padding(
            padding: const EdgeInsets.only(bottom: AdminSpacing.md),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Text(name, style: context.type.caption),
                ),
                Container(height: 12, width: value, color: c.primary),
                const Gap(AdminSpacing.md),
                Text(value.toStringAsFixed(0), style: context.type.bodyMuted),
              ],
            ),
          ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Type ramp'),
        _note(
          context,
          'Each role at its size / line height (and letter spacing, when not '
          '0), from the theme\'s AdminTypeSpec.ramp.',
        ),
        for (final (name, sample, style) in _ramp(context))
          _type(context, name, sample, style),
        const Gap(AdminSpacing.xl),

        const DemoSection('Motion'),
        _note(
          context,
          'context.motion: the durations are zero while the platform asks for '
          'less motion; the curves stay.',
        ),
        _motion(context),
        const Gap(AdminSpacing.xl),

        const DemoSection('Stroke'),
        _stroke(context),
        const Gap(AdminSpacing.xl),

        const DemoSection('Icon sizes'),
        _iconSizes(context),
        const Gap(AdminSpacing.xl),

        for (final (title, note, roles) in _roles(c)) ...[
          DemoSection(title),
          if (note != null) _note(context, note),
          Wrap(
            spacing: AdminSpacing.md,
            runSpacing: AdminSpacing.md,
            children: [
              for (final (name, color) in roles) _swatch(context, name, color),
            ],
          ),
          const Gap(AdminSpacing.xl),
        ],

        const DemoSection('Navigation'),
        _note(
          context,
          'A sidebar on background: rest, hover (navHoverFill) and selected '
          '(navSelectedFill, navSelectedText and the navIndicator bar, none '
          'when transparent).',
        ),
        _nav(context),
        const Gap(AdminSpacing.xl),

        const DemoSection('Contrast pairs'),
        _note(
          context,
          'Measured live on this palette: text pairs need 4.5:1, control '
          'boundaries and the focus ring 3:1.',
        ),
        Wrap(
          spacing: AdminSpacing.md,
          runSpacing: AdminSpacing.lg,
          children: [for (final pair in _pairs(c)) _pair(context, pair)],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Elevation'),
        _elevation(context),
        const Gap(AdminSpacing.xl),

        const DemoSection('Focus ring'),
        _note(
          context,
          'width ${_number(context.focus.width)} · offset '
          '${_number(context.focus.offset)} · ${_hex(c.focusRing)}',
        ),
        Wrap(
          spacing: AdminSpacing.xxl,
          runSpacing: AdminSpacing.lg,
          children: [
            _focused(
              context,
              label: 'Primary',
              fill: c.primary,
              foreground: c.onPrimary,
            ),
            _focused(
              context,
              label: 'Secondary',
              fill: c.surface,
              foreground: c.foreground,
              border: c.border,
            ),
            _focused(
              context,
              label: 'Input',
              fill: c.surface,
              foreground: c.placeholder,
              border: c.controlBorder,
              width: 180,
            ),
          ],
        ),
        const Gap(AdminSpacing.xl),

        const DemoSection('Radii'),
        _note(
          context,
          'The scale, then the component roles: menus and popovers, dialogs, '
          'tags and pills, checkboxes.',
        ),
        Wrap(
          spacing: AdminSpacing.lg,
          runSpacing: AdminSpacing.lg,
          children: [
            for (final (n, r) in _radii(context)) _radius(context, n, r),
          ],
        ),
      ],
    );
  }

  /// Every typography role: (name, sample, style).
  List<(String, String, TextStyle)> _ramp(BuildContext context) {
    final t = context.type;
    final ink = context.colors.foreground;
    return [
      ('pageTitle', 'Page title', t.pageTitle),
      ('heading', 'Section heading', t.heading),
      ('sectionLabel', 'Section label', t.sectionLabel),
      (
        'fieldLabel',
        t.fieldLabelText('Field label'),
        t.fieldLabel.copyWith(color: ink),
      ),
      ('fieldText', 'Field value', t.fieldText),
      (
        'fieldMessage',
        'Field message',
        t.fieldMessage.copyWith(color: context.colors.dangerText),
      ),
      ('body', 'Body — primary text', t.body),
      ('bodyStrong', 'Body strong', t.bodyStrong),
      ('bodyMuted', 'Body muted', t.bodyMuted),
      ('bodySmall', 'Body small — dense control text', t.bodySmall),
      ('caption', 'Caption / helper line', t.caption),
      ('micro', 'MICRO BADGE', t.micro),
      ('button', 'Button label', t.button.copyWith(color: ink)),
      ('buttonSmall', 'Small button label', t.buttonSmall.copyWith(color: ink)),
      ('mono', '{"id": 42, "ok": true}', t.mono),
      ('monoSmall', 'const answer = 42;', t.monoSmall),
    ];
  }

  Widget _type(
    BuildContext context,
    String name,
    String sample,
    TextStyle style,
  ) {
    final size = style.fontSize!;
    final line = size * (style.height ?? 1);
    final tracking = style.letterSpacing ?? 0;
    final metrics = [
      '${_number(size)}/${_number(line)}',
      if (tracking != 0) '${tracking > 0 ? '+' : ''}${_number(tracking)}',
    ].join(' ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          SizedBox(width: 110, child: Text(name, style: context.type.caption)),
          SizedBox(
            width: 112,
            child: Text(metrics, style: context.type.monoSmall),
          ),
          Expanded(child: Text(sample, style: style)),
        ],
      ),
    );
  }

  /// The theme's durations as bars to scale, and its curves plotted: the
  /// authored motion, so the page reads the same under reduced motion.
  Widget _motion(BuildContext context) {
    final c = context.colors;
    final motion = context.adminTokens.motion;
    final slowest = motion.pulse.inMilliseconds.toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (name, duration) in [
          ('fast', motion.fast),
          ('medium', motion.medium),
          ('slow', motion.slow),
          ('pulse', motion.pulse),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(name, style: context.type.caption),
                ),
                SizedBox(
                  width: 112,
                  child: Text(
                    '${duration.inMilliseconds}ms',
                    style: context.type.monoSmall,
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: duration.inMilliseconds / slowest,
                      child: Container(
                        height: AdminSpacing.sm,
                        decoration: BoxDecoration(
                          color: c.primary,
                          borderRadius: BorderRadius.circular(
                            context.radii.radiusSmall,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const Gap(AdminSpacing.md),
        Wrap(
          spacing: AdminSpacing.lg,
          runSpacing: AdminSpacing.lg,
          children: [
            for (final (name, curve) in [
              ('standard', motion.standard),
              ('enter', motion.enter),
              ('exit', motion.exit),
              ('emphasized', motion.emphasized),
            ])
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 72,
                    padding: const EdgeInsets.all(AdminSpacing.md),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(
                        context.radii.radiusSmall,
                      ),
                      border: Border.all(color: c.border),
                    ),
                    child: CustomPaint(
                      painter: _CurvePainter(
                        curve,
                        color: c.primary,
                        axis: c.borderSubtle,
                        width: context.stroke.indicator,
                      ),
                    ),
                  ),
                  const Gap(AdminSpacing.xs),
                  Text(name, style: context.type.caption),
                ],
              ),
          ],
        ),
      ],
    );
  }

  /// Each stroke width as a rule in the colour it draws in.
  Widget _stroke(BuildContext context) {
    final c = context.colors;
    final s = context.stroke;
    return Column(
      children: [
        for (final (name, width, color) in [
          ('hairline', s.hairline, c.border),
          ('control', s.control, c.controlBorder),
          ('controlStrong', s.controlStrong, c.controlBorder),
          ('fieldFocus', s.fieldFocus, c.focusRing),
          ('fieldError', s.fieldError, c.danger),
          ('indicator', s.indicator, c.primary),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: AdminSpacing.md),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(name, style: context.type.caption),
                ),
                SizedBox(
                  width: 112,
                  child: Text(
                    '${_number(width)}px',
                    style: context.type.monoSmall,
                  ),
                ),
                Expanded(
                  child: Container(height: width, color: color),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// One glyph at each icon size.
  Widget _iconSizes(BuildContext context) {
    final sizes = context.iconSizes;
    return Wrap(
      spacing: AdminSpacing.xxl,
      runSpacing: AdminSpacing.lg,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        for (final (name, size) in [
          ('xs', sizes.xs),
          ('sm', sizes.sm),
          ('md', sizes.md),
          ('lg', sizes.lg),
          ('xl', sizes.xl),
        ])
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star_outline_rounded,
                size: size,
                color: context.colors.foregroundSecondary,
              ),
              const Gap(AdminSpacing.xs),
              Text('$name ${_number(size)}', style: context.type.caption),
            ],
          ),
      ],
    );
  }

  Widget _note(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminSpacing.md),
      child: Text(text, style: context.type.caption),
    );
  }

  /// A role's colour over [AdminPalette.surface], so a translucent overlay
  /// reads as it renders on a card.
  Widget _swatch(BuildContext context, String name, Color color) {
    final c = context.colors;
    final radius = BorderRadius.circular(context.radii.radiusSmall);
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: radius,
              border: Border.all(color: c.border),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(color: color, borderRadius: radius),
            ),
          ),
          const Gap(AdminSpacing.xs),
          Text(
            _breakable(name),
            style: context.type.caption.copyWith(color: c.foregroundSecondary),
          ),
          Text(_hex(color), style: context.type.caption),
        ],
      ),
    );
  }

  Widget _pair(BuildContext context, _Pair pair) {
    final c = context.colors;
    final ratio = contrastRatio(pair.foreground, pair.background);
    final pass = ratio >= pair.min;
    final radius = BorderRadius.circular(context.radii.radiusSmall);
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 44),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: pair.background,
              borderRadius: radius,
              border: Border.all(color: c.border),
            ),
            child: pair.min < 4.5
                ? Container(
                    width: 56,
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(color: pair.foreground, width: 2),
                    ),
                  )
                : Text(
                    'Aa',
                    style: context.type.bodyStrong.copyWith(
                      color: pair.foreground,
                      fontSize: 17,
                    ),
                  ),
          ),
          const Gap(AdminSpacing.xs),
          Text(
            '${pair.foregroundName} on ${pair.backgroundName}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.type.caption.copyWith(color: c.foregroundSecondary),
          ),
          Row(
            children: [
              Icon(
                pass ? Icons.check_rounded : Icons.close_rounded,
                size: 14,
                color: pass ? c.successText : c.dangerText,
              ),
              const Gap(AdminSpacing.xxs),
              Flexible(
                child: Text(
                  '${ratio.toStringAsFixed(2)} : 1 · min ${_number(pair.min)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.caption,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _elevation(BuildContext context) {
    final c = context.colors;
    final e = context.elevation;
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.xxl),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(context.radii.radius),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          for (final (name, shadows) in [
            ('sm', e.sm),
            ('md', e.md),
            ('lg', e.lg),
          ]) ...[
            Expanded(
              child: Container(
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(context.radii.radius),
                  border: Border.all(color: c.border),
                  boxShadow: shadows,
                ),
                child: Text(name, style: context.type.bodyStrong),
              ),
            ),
            if (name != 'lg') const Gap(AdminSpacing.xxl),
          ],
        ],
      ),
    );
  }

  /// A control drawn with the theme's focus ring: [AdminFocusSpec.width] wide,
  /// [AdminFocusSpec.offset] outside the edge, or inside it when negative. An
  /// [AdminPalette.surface] band separates the ring from the control — the gap
  /// outside, or a 1px line within an inset ring (Carbon's `$focus-inset`), so
  /// the ring shows on a fill of its own colour.
  Widget _focused(
    BuildContext context, {
    required String label,
    required Color fill,
    required Color foreground,
    Color? border,
    double? width,
  }) {
    final c = context.colors;
    final spec = context.focus;
    final radius = context.radii.radius;
    Widget band(double outset, double stroke, Color color) => Positioned(
      left: -outset,
      top: -outset,
      right: -outset,
      bottom: -outset,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(math.max(0, radius + outset)),
          border: Border.all(color: color, width: stroke),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 36),
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.xl),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(radius),
            border: border == null ? null : Border.all(color: border),
          ),
          child: Align(
            alignment: width == null ? Alignment.center : Alignment.centerLeft,
            widthFactor: width == null ? 1 : null,
            child: Text(
              label,
              style: context.type.button.copyWith(color: foreground),
            ),
          ),
        ),
        if (spec.offset > 0) band(spec.offset, spec.offset, c.surface),
        if (spec.offset < 0) band(spec.offset, 1, c.surface),
        band(spec.offset + spec.width, spec.width, c.focusRing),
      ],
    );
  }

  /// Three rail items — rest, hover, selected — drawn from the nav roles.
  Widget _nav(BuildContext context) {
    final c = context.colors;
    Widget item(
      String label,
      IconData icon, {
      bool hover = false,
      bool selected = false,
    }) {
      final fg = selected ? c.navSelectedText : c.foregroundSecondary;
      return Container(
        height: 36 + textGrowthOf(context, context.type.body),
        margin: const EdgeInsets.only(bottom: AdminSpacing.xs),
        decoration: BoxDecoration(
          color: selected ? c.navSelectedFill : (hover ? c.navHoverFill : null),
          borderRadius: BorderRadius.circular(context.radii.radiusSmall),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: selected ? c.navIndicator : null,
                borderRadius: BorderRadius.circular(context.radii.radiusSmall),
              ),
            ),
            const Gap(AdminSpacing.md - 3),
            Icon(icon, size: 16, color: fg),
            const Gap(AdminSpacing.md),
            Text(
              label,
              style: (selected ? context.type.bodyStrong : context.type.body)
                  .copyWith(color: fg),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 240,
      padding: const EdgeInsets.all(AdminSpacing.md),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(context.radii.radius),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          item('Dashboard', Icons.space_dashboard_outlined),
          item('Pages', Icons.description_outlined, hover: true),
          item('Media', Icons.photo_library_outlined, selected: true),
        ],
      ),
    );
  }

  Widget _radius(BuildContext context, String name, double r) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 44,
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(r),
            border: Border.all(color: context.colors.border),
          ),
        ),
        const Gap(AdminSpacing.xs),
        Text('$name ${r.toStringAsFixed(0)}', style: context.type.caption),
      ],
    );
  }

  static const _spacing = [
    ('xxs', AdminSpacing.xxs),
    ('xs', AdminSpacing.xs),
    ('sm', AdminSpacing.sm),
    ('md', AdminSpacing.md),
    ('lg', AdminSpacing.lg),
    ('xl', AdminSpacing.xl),
    ('xxl', AdminSpacing.xxl),
    ('xxxl', AdminSpacing.xxxl),
  ];

  /// Every palette role, grouped: (title, note, roles).
  List<(String, String?, List<(String, Color)>)> _roles(AdminPalette c) {
    final syntax = c.syntax;
    return [
      (
        'Surfaces',
        'surface is the lightest in both modes (cards, inputs, popovers); '
            'background is the page; surfaceMuted a muted well set off from '
            'surface, between the two or below the page as the theme chooses.',
        [
          ('surface', c.surface),
          ('background', c.background),
          ('surfaceMuted', c.surfaceMuted),
        ],
      ),
      (
        'Text',
        null,
        [
          ('foreground', c.foreground),
          ('foregroundSecondary', c.foregroundSecondary),
          ('foregroundMuted', c.foregroundMuted),
          ('foregroundSubtle', c.foregroundSubtle),
          ('foregroundFaint', c.foregroundFaint),
          ('placeholder', c.placeholder),
          ('foregroundMutedOnTint', c.foregroundMutedOnTint),
        ],
      ),
      (
        'Borders',
        'border and borderSubtle divide and frame; controlBorder outlines a '
            'control that must be found to be used.',
        [
          ('border', c.border),
          ('borderSubtle', c.borderSubtle),
          ('controlBorder', c.controlBorder),
        ],
      ),
      (
        'Primary',
        null,
        [
          ('primary', c.primary),
          ('primaryHover', c.primaryHover),
          ('primaryActive', c.primaryActive),
          ('onPrimary', c.onPrimary),
          ('primaryText', c.primaryText),
          ('primarySubtle', c.primarySubtle),
          ('primaryFaint', c.primaryFaint),
          ('primaryStrong', c.primaryStrong),
          ('controlAccent', c.controlAccent),
          ('controlAccentHover', c.controlAccentHover),
          ('onControlAccent', c.onControlAccent),
        ],
      ),
      for (final (name, accent, text, on) in [
        ('Danger', c.danger, c.dangerText, c.onDanger),
        ('Success', c.success, c.successText, c.onSuccess),
        ('Warning', c.warning, c.warningText, c.onWarning),
        ('Info', c.info, c.infoText, c.onInfo),
      ])
        (
          name,
          null,
          [
            ('accent', accent),
            ('text', text),
            ('on', on),
            ('fill', c.statusFill(accent)),
            ('border', c.statusBorder(accent)),
            if (name == 'Danger') ...[
              ('dangerHover', c.dangerHover),
              ('dangerActive', c.dangerActive),
            ],
          ],
        ),
      (
        'Lists & navigation',
        'listHighlight marks a row on a surface overlay (menus, the palette, '
            'comboboxes); separator divides one. The nav roles paint a '
            'sidebar on background.',
        [
          ('listHighlight', c.listHighlight),
          ('separator', c.separator),
          ('navSelectedFill', c.navSelectedFill),
          ('navHoverFill', c.navHoverFill),
          ('navSelectedText', c.navSelectedText),
          ('navIndicator', c.navIndicator),
        ],
      ),
      (
        'Focus & overlays',
        'Overlays are shown over surface. The state layer: hover '
            '${_percent(c.stateLayer.hover)}, focus '
            '${_percent(c.stateLayer.focus)}, pressed '
            '${_percent(c.stateLayer.pressed)}, dragged '
            '${_percent(c.stateLayer.dragged)}; a saturated tint '
            '${_percent(c.stateLayer.tintHover)} / '
            '${_percent(c.stateLayer.tintPressed)}.',
        [
          ('focusRing', c.focusRing),
          ('hoverOverlay', c.hoverOverlay),
          ('focusOverlay', c.focusOverlay),
          ('pressedOverlay', c.pressedOverlay),
          ('draggedOverlay', c.draggedOverlay),
          ('primaryHoverOverlay', c.primaryHoverOverlay),
          ('primaryPressedOverlay', c.primaryPressedOverlay),
          ('scrim', c.scrim),
          ('imageScrim', c.imageScrim),
          ('shadow', c.shadow),
        ],
      ),
      ('Chart', null, [for (final (i, x) in c.chart.indexed) ('chart[$i]', x)]),
      (
        'Syntax',
        null,
        [
          ('key', syntax.key),
          ('string', syntax.string),
          ('number', syntax.number),
          ('literal', syntax.literal),
          ('punctuation', syntax.punctuation),
          ('comment', syntax.comment),
        ],
      ),
      (
        'Marks & rules',
        null,
        [
          ('highlight', c.highlight),
          ('modifiedFill', c.modifiedFill),
          ('tabDivider', c.tabDivider),
        ],
      ),
    ];
  }

  List<_Pair> _pairs(AdminPalette c) => [
    _Pair('foreground', c.foreground, 'surface', c.surface),
    _Pair('foreground', c.foreground, 'background', c.background),
    _Pair('foreground', c.foreground, 'primarySubtle', c.primarySubtle),
    _Pair('foregroundMuted', c.foregroundMuted, 'surface', c.surface),
    _Pair('foregroundMuted', c.foregroundMuted, 'background', c.background),
    _Pair('placeholder', c.placeholder, 'surface', c.surface),
    _Pair('primaryText', c.primaryText, 'surface', c.surface),
    _Pair('primaryText', c.primaryText, 'primarySubtle', c.primarySubtle),
    _Pair('onPrimary', c.onPrimary, 'primary', c.primary),
    _Pair('onPrimary', c.onPrimary, 'primaryHover', c.primaryHover),
    _Pair('onDanger', c.onDanger, 'danger', c.danger),
    _Pair('dangerText', c.dangerText, 'its fill', c.statusFill(c.danger)),
    _Pair('onSuccess', c.onSuccess, 'success', c.success),
    _Pair('successText', c.successText, 'its fill', c.statusFill(c.success)),
    _Pair('onWarning', c.onWarning, 'warning', c.warning),
    _Pair('warningText', c.warningText, 'its fill', c.statusFill(c.warning)),
    _Pair('onInfo', c.onInfo, 'info', c.info),
    _Pair('infoText', c.infoText, 'its fill', c.statusFill(c.info)),
    _Pair('focusRing', c.focusRing, 'surface', c.surface, min: 3),
    _Pair('focusRing', c.focusRing, 'background', c.background, min: 3),
    _Pair('controlBorder', c.controlBorder, 'surface', c.surface, min: 3),
    _Pair('controlBorder', c.controlBorder, 'background', c.background, min: 3),
    _Pair('controlAccent', c.controlAccent, 'surface', c.surface, min: 3),
    _Pair('controlAccent', c.controlAccent, 'background', c.background, min: 3),
    _Pair(
      'onControlAccent',
      c.onControlAccent,
      'controlAccent',
      c.controlAccent,
      min: 3,
    ),
    _Pair(
      'foregroundMutedOnTint',
      c.foregroundMutedOnTint,
      'tableRowSelected',
      c.tableRowSelected,
    ),
    _Pair(
      'foregroundMutedOnTint',
      c.foregroundMutedOnTint,
      'surfaceMuted',
      c.surfaceMuted,
    ),
    _Pair('navSelectedText', c.navSelectedText, 'its fill', c.navSelectedFill),
    if (c.navIndicator.a > 0)
      _Pair('navIndicator', c.navIndicator, 'background', c.background, min: 3),
  ];

  List<(String, double)> _radii(BuildContext context) => [
    ('sm', context.radii.radiusSmall),
    ('md', context.radii.radius),
    ('lg', context.radii.radiusLarge),
    ('menu', context.radii.radiusMenu),
    ('dialog', context.radii.radiusDialog),
    ('pill', context.radii.radiusPill),
    ('check', context.radii.radiusCheck),
  ];
}

/// A foreground drawn on a background, and the contrast it must reach.
class _Pair {
  final String foregroundName;
  final Color foreground;
  final String backgroundName;
  final Color background;
  final double min;

  const _Pair(
    this.foregroundName,
    this.foreground,
    this.backgroundName,
    this.background, {
    this.min = 4.5,
  });
}

String _hex(Color color) {
  final argb = color.toARGB32();
  final rgb = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
  final alpha = argb >>> 24;
  return alpha == 0xFF ? '#$rgb' : '#$rgb · ${(alpha / 2.55).round()}%';
}

String _number(double value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';

String _percent(double opacity) => '${_number(opacity * 100)}%';

/// [curve] plotted over its unit square: time along, progress up.
class _CurvePainter extends CustomPainter {
  final Curve curve;
  final Color color;
  final Color axis;
  final double width;

  const _CurvePainter(
    this.curve, {
    required this.color,
    required this.axis,
    required this.width,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, 0),
      Paint()..color = axis,
    );
    final path = Path()..moveTo(0, size.height);
    for (var i = 1; i <= 48; i++) {
      final t = i / 48;
      path.lineTo(size.width * t, size.height * (1 - curve.transform(t)));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.curve != curve ||
      old.color != color ||
      old.axis != axis ||
      old.width != width;
}

/// A camelCase role name that may wrap between its words
/// (`foreground|Secondary`), never mid-word.
String _breakable(String name) =>
    name.replaceAllMapped(RegExp('(?<=[a-z0-9])(?=[A-Z])'), (_) => '​');
